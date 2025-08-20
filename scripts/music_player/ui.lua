

local song_library_api = require("./libraries")     ---@type LibrariesApi
local config_cahe_api = require("./config_cache")   ---@type ConfigCacheAPI
local networking_api = require("./networking")      ---@type SongNetworkingApi

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

    ---@type table<string, {processor_future: TL_Future?, packets: string[]?, transfer_song_id: integer?}>
    local processed_songs_and_players = {}

    local song_library = host:isHost() and song_library_api:build_default_library() or song_library_api:build_library() -- Default lib uses files API. Avoid if not host.
    printTable(song_library.songs)

    local selected_song_index = 1

    local num_songs_to_display_in_selector = 16


    ---Returns a string sutable for actions.select_song:title(update_song_selector_title())
    ---@return string
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

        local return_string = "Song List:\n"
        for index = start_index, end_index do
            local this_row = ""
            local this_row_song = song_library:get_song_by_sorted_index(index)
            this_row = this_row .. (index == selected_song_index and "→" or "  ")
            this_row = this_row .. this_row_song.name

            return_string = return_string .. "\n" .. this_row
        end
        return_string = return_string .. "\n\n" .. "INFO ABOUT THIS SONG HERE"

        return return_string
    end


    -- local text_update_jobs = 0
    -- local function text_update_loop()
    --     if text_update_jobs == 0 then events.TICK:remove(text_update_loop) end
    --     if not action_wheel:isEnabled() then return end

    --     update_song_selector_title()
    -- end

    -- local function new_text_update_job()

    -- end


    local playing_song_transfer_id = nil


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
	    :title(update_song_selector_title())
	    :onScroll(function (scroll_direction, self)
			local natural_scroll = false
			local scroll_amount = keybinds:getKeybinds()["Scroll song list faster"]:isPressed() and 20 or 1
			selected_song_index = selected_song_index + scroll_amount * scroll_direction * (natural_scroll and 1 or -1)

			if selected_song_index > #song_library.sorted_songs then selected_song_index = 1 end
			if selected_song_index < 1 then selected_song_index = #song_library.sorted_songs end
			actions.select_song:title(update_song_selector_title())
		end)
		:onLeftClick(function(self)
		    local target_song = song_library:get_song_by_sorted_index(selected_song_index)
			if not processed_songs_and_players[target_song.id] then processed_songs_and_players[target_song.id] = {} end
		    if not processed_songs_and_players[target_song.id].processor_future then
				processed_songs_and_players[target_song.id].processor_future = target_song:start_data_processor()
				processed_songs_and_players[target_song.id].processor_future:register_callback(function(finished_future)
                    if finished_future:has_error() then error("we need to handle this error"); return end
                    local processed_song = finished_future:get_value()

                    ---@type SongPlayerConfig
                    local song_player_config = config_cahe_api.load_song_config(target_song.id)
                    song_player_config.source_entity = player
                    song_player_config.play_immediately = true

                    local packets, transfer_id = networking_api.song_to_packets(processed_song, song_player_config)

                    processed_songs_and_players[target_song.id].packets = packets
                    processed_songs_and_players[target_song.id].transfer_song_id = transfer_id
				end)
			elseif processed_songs_and_players[target_song.id].packets then
			    -- song is ready to send, but we should only play one song at a time using this UI.
			    if not playing_song_transfer_id then
					-- playing_song_transfer_id is not set. no song playing. Play this one.
					playing_song_transfer_id = processed_songs_and_players[target_song.id].transfer_song_id
                    networking_api.ping_packets(processed_songs_and_players[target_song.id].packets)
                elseif playing_song_transfer_id == processed_songs_and_players[target_song.id].transfer_song_id then
                    print("--TODO: Method to stop a networked song in progress. (Make dedicated `stop` packet)")
                else
                    print("--TODO: A song was already started.")
                    -- TODO: consider a dedicated "start/stop" button below the song picker.
				end
			end

			update_song_selector_title()
		end)


	actions.config_song = action_wheel:newAction():title("Song Config"):item("minecraft:command_block")--:texture(textures:fromVanilla("Search", "textures/gui/sprites/icon/search.png"))



	music_player_action_wheel_page:setAction(1,actions.exit_songbook)
	music_player_action_wheel_page:setAction(2,actions.config_song)
	music_player_action_wheel_page:setAction(-1,actions.select_song)

    return actions.enter_songbook
end


return {
    new_action_wheel_ui = new_action_wheel_ui
}
