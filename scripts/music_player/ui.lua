

local song_library_api = require("./libraries")     ---@type LibrariesApi
local config_cahe_api = require("./config_cache")   ---@type ConfigCacheAPI
local networking_api = require("./networking")      ---@type SongNetworkingApi

local do_debug_prints = false
local function print_host(...) if host:isHost() or do_debug_prints then print(...) end end


local spinner_states = {[1] = "▙",[2] = "▛",[3] = "▜",[4] = "▟",}
local function get_spinner()
	local spinner_State =
		math.floor(
			(client.getSystemTime()/1000)	-- Time in Seconds
			*1.5	-- Speedup
			%1		-- Clamp to 0-1
			*4		-- Scale to 0-3
		)+1			-- Scale to 1-4
	return spinner_states[spinner_State]
end

local function new_action_wheel_ui()
    if not keybinds:getKeybinds()["Scroll song list faster"] then
        keybinds:newKeybind(
    		"Scroll song list faster",
    		keybinds:getVanillaKey("key.sprint")
    	)
    end

    local previous_action_wheel_page = nil
    local music_player_action_wheel_page = action_wheel:newPage()

    ---@type table<string, Action>
    local actions = {}

    ---@type table<string, {processor_future: TL_Future?, error: string?, packets: string[]?, transfer_song_id: integer?}>
    local processed_songs_and_players = {}

    local song_library = host:isHost() and song_library_api:build_default_library() or song_library_api:build_library() -- Default lib uses files API. Avoid if not host.
    printTable(song_library.songs)

    local num_songs_to_display_in_selector = 16


    local selected_song_index = 1           -- Matches a song in song_library. Library is sorted in alphabetical order.
    local playing_song_library_id = nil     -- If the UI is playing a song, this var will match the library ID of the playing song. (For use with libreries, processors, data, configs, etc.)
    local playing_song_transfer_id = nil    -- If the UI is playing a song, this var will match the transfer ID of the playing song. (For use with network API)

    ---Updates the title text in `actions.select_song` (This is the main "song list" render.)
    local function update_song_selector_title()
        if not host:isHost() then return "Song list" end
        if not next(song_library.songs) then
            return "Song list\nNo songs found. Check the `[figura root]/data/TL_Songbook` directory."
        end

        -- get index range
        local start_index = selected_song_index - math.floor(num_songs_to_display_in_selector / 2)
    	local end_index = start_index + num_songs_to_display_in_selector

        -- Don't overscroll if near the start or end of the list
    	if start_index < 1 then
    		start_index = 1
    		end_index = math.min(song_library:get_library_length(), num_songs_to_display_in_selector +1)
    	elseif end_index > song_library:get_library_length() then
    		end_index = song_library:get_library_length()
    		start_index = math.max(end_index - num_songs_to_display_in_selector ,1)
    	end

        local selector_title_string = ""

        if playing_song_transfer_id then
            selector_title_string = selector_title_string .. "Currently playing: \"" .. song_library:get_song_by_id(playing_song_library_id).name .."\""
            local song_player = networking_api.get_player_for_transfered_song(playing_song_transfer_id)
            if  song_player and song_player.get_progress() then
                selector_title_string = selector_title_string
                    .. " ("
                    .. tostring(math.floor(
                        song_player.get_progress() * 100
                    ))
                    .."%)"
            end
            selector_title_string = selector_title_string .. " " .. get_spinner() .. "\n"
        end

        selector_title_string = selector_title_string .. "Song List:\n"

        for index = start_index, end_index do
            local this_row = ""
            local this_row_song = song_library:get_song_by_sorted_index(index)

            -- Selector
            this_row = this_row .. (index == selected_song_index and "→" or "  ")

            -- Status
            if this_row_song.id == playing_song_library_id then
                -- song is playing
                this_row = this_row .. "♬"
            elseif processed_songs_and_players[this_row_song.id] then
                if processed_songs_and_players[this_row_song.id].error then
                    this_row = this_row .. "🚫"
                elseif not processed_songs_and_players[this_row_song.id].packets then
                    -- Song is in the midle of being processed.
                    -- (We know because no packets have been built yet, but an entry in this table was created)
                    this_row = this_row .. "⏳"
                else
                    this_row = this_row .. "✓ "
                end
            else
                this_row = this_row .. "  "
            end
            this_row = this_row .. this_row_song.name

            selector_title_string = selector_title_string .. "\n" .. this_row
        end
        selector_title_string = selector_title_string .. "\n\n" .. "INFO ABOUT THIS SONG HERE"

        actions.select_song:title(selector_title_string)
    end

    --- Update all UI text on the main page.
    local function update_main_page_ui_text()
        if not host:isHost() then return end

        update_song_selector_title()
    end

    -- monitors the status of the playing song and updates some components accordingly (mostly just progress bars and spinners).
    local function playing_watcher()
        if     not playing_song_transfer_id
            or not networking_api.get_player_for_transfered_song(playing_song_transfer_id)
            or not networking_api.get_player_for_transfered_song(playing_song_transfer_id).is_playing()
        then
            update_main_page_ui_text()
            playing_song_transfer_id = nil
            playing_song_library_id = nil
            events.TICK:remove(playing_watcher)
        end

        if not action_wheel:isEnabled() then return end

        update_main_page_ui_text()
    end



    actions.enter_songbook = action_wheel:newAction()
        :title("Songbook")
		:item("minecraft:jukebox")
		:onLeftClick(function()
			previous_action_wheel_page = action_wheel:getCurrentPage()
			action_wheel:setPage(music_player_action_wheel_page)
		end)

	actions.exit_songbook = action_wheel:newAction()
		:title("Back")
		:item("minecraft:arrow")
		:onLeftClick(function()
			action_wheel:setPage(previous_action_wheel_page)
			previous_action_wheel_page = nil
		end)

	actions.select_song = action_wheel:newAction()
	    :item("minecraft:music_disc_wait")
	    :title("Song selector") -- Set with update_main_page_ui_text()
	    :onScroll(function (scroll_direction, _)
			local natural_scroll = false
			local scroll_amount = keybinds:getKeybinds()["Scroll song list faster"]:isPressed() and 20 or 1
			selected_song_index = selected_song_index + scroll_amount * scroll_direction * (natural_scroll and 1 or -1)

			-- Scroll wrap
			if selected_song_index > #song_library.sorted_songs then selected_song_index = 1 end
			if selected_song_index < 1 then selected_song_index = #song_library.sorted_songs end

			update_main_page_ui_text()
		end)
		:onLeftClick(function(_)
		    local target_song = song_library:get_song_by_sorted_index(selected_song_index)
			if not processed_songs_and_players[target_song.id] then processed_songs_and_players[target_song.id] = {} end
			if processed_songs_and_players[target_song.id].error then
			    print_host(processed_songs_and_players[target_song.id].error)
		    elseif not processed_songs_and_players[target_song.id].processor_future then
				processed_songs_and_players[target_song.id].processor_future = target_song:start_data_processor()
				processed_songs_and_players[target_song.id].processor_future:register_callback(function(finished_future)
                    if finished_future:has_error() then
                        processed_songs_and_players[target_song.id].error = finished_future:get_error()
                        print_host("Filed to process song `"..tostring(target_song.id) .."`.")
                        print_host(processed_songs_and_players[target_song.id].error)
                        update_main_page_ui_text()
                        return
                    end
                    local processed_song = finished_future:get_value()

                    local song_player_config = config_cahe_api.load_song_config(target_song.id)
                    song_player_config.source_entity = player
                    song_player_config.play_immediately = true

                    local packets, transfer_id = networking_api.song_to_packets(processed_song, song_player_config)

                    processed_songs_and_players[target_song.id].packets = packets
                    processed_songs_and_players[target_song.id].transfer_song_id = transfer_id
                    update_main_page_ui_text()
				end)
			elseif processed_songs_and_players[target_song.id].packets then
			    -- song is ready to send, but we should only play one song at a time using this UI.
			    if not playing_song_transfer_id or not networking_api.get_player_for_transfered_song(playing_song_transfer_id).is_playing() then
					playing_song_transfer_id = processed_songs_and_players[target_song.id].transfer_song_id
					playing_song_library_id = target_song.id
                    networking_api.ping_packets(processed_songs_and_players[target_song.id].packets)
                    events.TICK:register(playing_watcher)
                else
                    networking_api.cancel_all_pings()
                    networking_api.stop_transfered_song(playing_song_transfer_id)
                    playing_song_transfer_id = nil
                    playing_song_library_id = nil
                    events.TICK:remove(playing_watcher)
				end
			end

			update_main_page_ui_text()
		end)
	update_song_selector_title()



	-- Config page
	-- This page needs to let us select what instrument playes which track.
	-- Eventualy, it will also need to let us configure each instrument.
	local song_config_action_wheel_page = action_wheel:newPage()

	---@class aw_ui_song_config_page_state
	local config_page_state = {

	}


	actions.config_page_confirm = action_wheel
	    :newAction()
		:title("Confirm and save changes")
	    :item("minecraft:written_book")
		:onLeftClick(function (_)
		    action_wheel:setPage(music_player_action_wheel_page)
	    end)

	actions.config_page_cancel = action_wheel
	    :newAction()
		:title("Cancel and discard changes")
	    :item("minecraft:tnt")
		:onLeftClick(function (_)
		    action_wheel:setPage(music_player_action_wheel_page)
	    end)

	actions.enter_config_page = action_wheel:newAction()
	    :title("Song Config")
		-- :item("minecraft:command_block")
		:item("minecraft:bedrock")--:texture(textures:fromVanilla("Search", "textures/gui/sprites/icon/search.png"))
		:onLeftClick(function(_)
			local target_song = song_library:get_song_by_sorted_index(selected_song_index)
			if not processed_songs_and_players[target_song.id] or not next(processed_songs_and_players[target_song.id]) then
		        print_host("Unable to configure unprocessed songs. Processed songs have a check (✓) in the song list.")
				return
			end
			if processed_songs_and_players[target_song.id].error then
				print_host("This song had an error durring processing and cannot be configured.")
				return
			end
			-- networking_api.get_player_for_transfered_song(playing_song_transfer_id).is_playing()
			if target_song.id == playing_song_library_id then
                print_host("Cannot configure a playing song. Please stop the song and try again.")
    			return
			end

			-- TODO: Consider making song config stuff a right-click action in the song selector.



			-- local song_tracks = target_song.processed_data.tracks[1].recommended_instrument_name
			--

			action_wheel:setPage(song_config_action_wheel_page)
		end)



	music_player_action_wheel_page:setAction(1,actions.exit_songbook)
	music_player_action_wheel_page:setAction(2,actions.enter_config_page)
	music_player_action_wheel_page:setAction(-1,actions.select_song)

	song_config_action_wheel_page:setAction(1,actions.config_page_confirm)
	song_config_action_wheel_page:setAction(2,actions.config_page_cancel)

    return actions.enter_songbook
end


return {
    new_action_wheel_ui = new_action_wheel_ui
}
