
-- This script creates a UI built out of Action Wheel parts that makes it easy for end users to find, select, and play songs.
--
-- Under the hood it uses Network's network_song_player to automaticaly sync up what the host does with all the clients.
--
-- Note that at this time, Local songs are detected by this script, but still use the pings and the network scripts
-- to send them to clients.


local song_library_api = require("./libraries")     ---@type LibrariesApi   -- TODO: Only used to fallback to a default library. Shouldn't this be core's job to bind it all? we could drop this requirement.
local config_cahe_api = require("./config_cache")   ---@type ConfigCacheAPI
local networking_api = require("./networking")      ---@type SongNetworkingApi
local song_player_api = require("./song_player")         ---@type SongPlayerAPI  -- TODO: This is only used to gather instrument information. Is there a way to split player and instrument info?

local do_debug_prints = false
local function print_host(...) if host:isHost() or do_debug_prints then print(...) end end


local spinner_states = {[1] = "▙",[2] = "▛",[3] = "▜",[4] = "▟",}
local function get_spinner()
    local spinner_State =
        math.floor(
            (client.getSystemTime()/1000)    -- Time in Seconds
            *1.5    -- Speedup
            %1      -- Clamp to 0-1
            *4      -- Scale to 0-3
        )+1         -- Slide to 1-4
    return spinner_states[spinner_State]
end

local progress_bar_character = "▊"  -- the same width as a space in Minecraft's font
if client.compareVersions("1.20", client.getVersion() ) > 0 then
	progress_bar_character = "▍"	-- 1.20 updated a lot of Minecraft's fonts. Use this character instead if we are on a pre-1.20 version of Minecraft
end

---Returns a progress bar with a spinner
---@param width integer     -- Width in number of characters
---@param progress number   -- Will be clamped to between 0 and 1.
---@return string
local function progress_bar(width, progress)
    if progress < 0 then progress = 0 elseif progress > 1 then progress = 1 end

	local num_bars = math.floor((width+1) * progress)
	local progress_bar_string = "▎" .. string.rep(progress_bar_character, num_bars) .. (num_bars <= width and get_spinner() or "") .. string.rep(" ", math.max(0, width - num_bars)) .. "▎"
	return progress_bar_string  -- As it turns out, Lua actualy optimizes this declare, set, return pattern into the same number of instructions as just returning and skipping the local part.
end

--- Creates an action wheel UI
---
--- This function spits out an Action. The caller will need to place this action into an active action wheel before the User can call it.
---@param song_library Library? The Library used for this UI. Defaults to `song_library_api:build_default_library()`.
---@param enter_songbook_title string? The title of the enter songbook action. Defaults to `"Songbook"`
---@return Action enter_songbook_action The action used to enter the songbook. Place this action into your actionwheel.
local function new_action_wheel_ui(song_library, enter_songbook_title)

    -- This function is likely to be called by an end user, double check if they're useing a `.` or `:` to call this function.
    ---@diagnostic disable-next-line: undefined-field
    if song_library and song_library.new_action_wheel_ui then
        -- If here, then song_library is actualy `self`
        error("Please use `.` instead of `:` when calling `new_action_wheel_ui()`")
    end

    if not song_library then song_library = song_library_api:build_default_library() end

    if not host:isHost() then
        -- Listen, the viewer probably can't access the Action wheel anyways
        -- (it would certenly not be visible at least), and any automation the host
        -- might want to do should be done with the API functions anyways.
        -- So let's… just return an empty action.
        --
        -- Saves us from burning a whole bunch of instructions for something
        -- we can't/shouldn't really use.
        return action_wheel:newAction()
    end

    if not keybinds:getKeybinds()["Scroll song list faster"] then
        keybinds:newKeybind(
            "Scroll song list faster",
            keybinds:getVanillaKey("key.sprint")
        )
    end

    -- Allows for exiting the songbook back to the Avatar's original action wheel page.
    local previous_action_wheel_page = nil

    local music_player_action_wheel_page = action_wheel:newPage()

    ---Stores the actions belonging to this action_wheel_ui
    ---@type table<string, Action>
    local actions = {}

    ---@type table<string, {processor_future: TL_Future?, error: string?, net_player_controller: SongPlayerController}>
    local song_processors_and_player_controllers = {}

    local num_songs_to_display_in_selector = 16

    local selected_song_index = 1           -- Matches a song in song_library. Library is sorted in alphabetical order.
    local playing_song_library_id = nil     -- If the UI is playing a song, this var will match the library ID of the playing song. (For use with libreries, processors, data, configs, etc.)
    local playing_song_controller = nil     ---@type SongPlayerController? -- If the UI is playing a song, this var will match the transfer ID of the playing song. (For use with network API)

    --- Updates the title text in `actions.select_song` (This is the main "song list" render.)
    local function update_song_selector_title()
        -- TODO: This, and a few other functions could be methods that take in `self`. we can then initilize them at init time, instead of building them every instance.
        -- However, since at this point everything is host-only, and host is likely to only call it once, it's not a high priority fix.

        if not host:isHost() then return "Song list" end
        if not next(song_library.song_holders) then
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

        if playing_song_controller then
            selector_title_string = selector_title_string .. "Currently playing: \"" .. song_library:get_song_by_id(playing_song_library_id).name .."\""
            if playing_song_controller and playing_song_controller.get_progress() then
                selector_title_string = selector_title_string .. "\n"

                if playing_song_controller.get_progress() < 0 then  -- TODO: since ading this logic, song_player_controllers now have get_buffer_progress and other useful functions for moments like this. Upgrade?
                    -- Song is buffering and has not started
                    selector_title_string = selector_title_string
                        .. "Buffering: Ready in "
                        .. tostring(math.floor(
                            1+ (playing_song_controller.get_start_time() - client.getSystemTime()) / 1000
                        ))
                        .. "s"
                else
                    selector_title_string = selector_title_string
                        -- .. "("
                        .. tostring(math.floor(
                            (playing_song_controller.get_start_time() + playing_song_controller.get_duration() - client.getSystemTime()) / 1000
                        ))
                        .."s | "

                        .. tostring(math.floor(
                            playing_song_controller.get_progress() * 100
                        ))
                        .."%"
                end
            else
                selector_title_string = selector_title_string .. "\nStarting..."
            end
            selector_title_string = selector_title_string .. " " .. get_spinner() .. "\n"
            selector_title_string = selector_title_string .. "\n"
        end

        selector_title_string = selector_title_string .. "Song List:\n"

        for index = start_index, end_index do
            local this_row = ""
            local this_row_song = song_library:get_song_by_sorted_index(index)

            -- Selector
            this_row = this_row .. (index == selected_song_index and "→" or "  ")

            -- Status
            if      song_processors_and_player_controllers[this_row_song.id]
                and song_processors_and_player_controllers[this_row_song.id].net_player_controller
                and song_processors_and_player_controllers[this_row_song.id].net_player_controller.is_playing()
            then
                -- song is playing
                this_row = this_row .. "♬"
            elseif song_processors_and_player_controllers[this_row_song.id] then
                if song_processors_and_player_controllers[this_row_song.id].error then
                    this_row = this_row .. "🚫"
                elseif not song_processors_and_player_controllers[this_row_song.id].net_player_controller then
                    -- Song is in the midle of being processed.
                    -- (We know because the player has not been built yet, but an entry in this table was created)
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
        selector_title_string = selector_title_string .. "\n\n"

        -- info on the hovered song

        local selected_song_id = song_library:get_song_by_sorted_index(selected_song_index).id

        if not song_processors_and_player_controllers[selected_song_id] then
            selector_title_string = selector_title_string .. "Click to prepare this song"
        else
            local processor_error = song_processors_and_player_controllers[selected_song_id].error
            local processor = song_processors_and_player_controllers[selected_song_id].processor_future
            local player_controller = song_processors_and_player_controllers[selected_song_id].net_player_controller

            if processor_error then
                selector_title_string = selector_title_string .. "This song threw an error and cannot be played.\n"
                    .. "Click to print error."
            elseif processor and not processor:is_done() then
                selector_title_string = selector_title_string .. "Song is being processed."
                    -- .. "\n" .. progress_bar(25, processor:get_progress()) .. " " .. (math.floor(processor:get_progress()*1000)/10)
                    -- TODO: Add a new watcher (or update the existing one) that ticks update_song_selector if there are any on-going processors (so that spinners and preogress bars can work.)

            elseif processor and processor:is_done() and not (player_controller and player_controller:is_playing()) then
                if playing_song_controller and playing_song_controller:is_playing() then
                    selector_title_string = selector_title_string .. "Click to stop the currently playing song"
                else
                    selector_title_string = selector_title_string .. "Click to play song"
                end
            elseif player_controller and player_controller:is_playing() then
                selector_title_string = selector_title_string .. "Playing. Click to stop song"
            end
        end

        -- selector_title_string = selector_title_string .. "\nSong ID:\n" .. selected_song_id

        actions.select_song:title(selector_title_string)
    end

    ---Returns if it's safe to enter the config page
    ---@return boolean is_safe
    ---@return string err -- If is_safe is false, then err will include the reason why.
    local function can_enter_config_page()
        local target_song = song_library:get_song_by_sorted_index(selected_song_index)
        if not target_song then
            return false, "No selected song"
        end
        if not song_processors_and_player_controllers[target_song.id] or not next(song_processors_and_player_controllers[target_song.id]) then
            return false, "Unable to configure unprocessed songs. Processed songs have a check (✓) in the song list."
        end
        if song_processors_and_player_controllers[target_song.id].error then
            return false, "This song had an error durring processing and cannot be configured."
        end
        if not song_processors_and_player_controllers[target_song.id].processor_future:is_done() then
            return false, "This song is still being processed and cannot be configured yet."
        end
        -- networking_api.get_player_for_transfered_song(playing_song_transfer_id).is_playing()
        if target_song.id == playing_song_library_id then
            return false, "Cannot configure a playing song. Please stop the song and try again."
        end
        return true, ""
    end

    --- Updates the icon and title text in `actions.enter_config_page`
    local function update_enter_config_page_ui()
        local song_at_selected_index = song_library:get_song_by_sorted_index(selected_song_index)

        local res, err = can_enter_config_page()
        if res then
            actions.enter_config_page:setItem("minecraft:command_block")
            if song_at_selected_index and song_at_selected_index.name then
                actions.enter_config_page:setTitle("Configure song `"..song_at_selected_index.name.."`")
            else
                error("Somehow we found a song that could be configured, but song_at_selected_index in nil")
            end
        else
            actions.enter_config_page:setItem("minecraft:bedrock")
            actions.enter_config_page:setTitle("Config Disabled".. (err and ("\n"..err) or ""))

        end

    end

    --- Update all UI text on the main page.
    local function update_main_page_ui()
        if not host:isHost() then return end

        update_enter_config_page_ui()
        update_song_selector_title()
    end


    --- Will be passed to song players so they can help us clean up when they are done playing.
    ---@param stop_reason SongPlayerStopReason
    local function stop_callback(stop_reason)
        playing_song_controller = nil
        playing_song_library_id = nil
        if stop_reason ~= "emergency" then
            update_main_page_ui()
        end
    end

    --- Will be passed to song players so we can piggyback off of their update loop instead of managing our own
    local function update_callback()
        if action_wheel:isEnabled() then update_main_page_ui() end
    end



    actions.enter_songbook = action_wheel:newAction()
        :title(enter_songbook_title or "Songbook")
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

    ---@param config SongPlayerConfig
    local function add_ui_speciffic_config_fields(config)
        config.source_entity = player
    end

    actions.select_song = action_wheel:newAction()
        :item("minecraft:music_disc_wait")
        :title("Song selector") -- Set with update_main_page_ui_text()
        :onScroll(function (scroll_direction, _)
            local natural_scroll = false
            local scroll_amount = keybinds:getKeybinds()["Scroll song list faster"]:isPressed() and 20 or 1
            selected_song_index = selected_song_index + scroll_amount * scroll_direction * (natural_scroll and 1 or -1)

            -- Scroll wrap
            if selected_song_index > #song_library.sorted_song_holders then selected_song_index = 1 end
            if selected_song_index < 1 then selected_song_index = #song_library.sorted_song_holders end

            update_main_page_ui()
        end)
        :onLeftClick(function(_)
            local target_song = song_library:get_song_by_sorted_index(selected_song_index)
            if not song_processors_and_player_controllers[target_song.id] then song_processors_and_player_controllers[target_song.id] = {} end
            if song_processors_and_player_controllers[target_song.id].error then
                print_host(song_processors_and_player_controllers[target_song.id].error)
            elseif not song_processors_and_player_controllers[target_song.id].processor_future then
                song_processors_and_player_controllers[target_song.id].processor_future = target_song:start_or_get_data_processor()
                song_processors_and_player_controllers[target_song.id].processor_future:register_callback(function(finished_future)
                    if finished_future:has_error() then
                        song_processors_and_player_controllers[target_song.id].error = finished_future:get_error()
                        print_host("Filed to process song `"..tostring(target_song.id) .."`.")
                        print_host(song_processors_and_player_controllers[target_song.id].error)
                        update_main_page_ui()
                        return
                    end

                    local song_player_config = target_song.included_config
                    local cached_config = config_cahe_api.load_song_config(target_song.id)
                    if not song_player_config or next(cached_config) ~= nil then
                        -- Prioritize cached config if there is something in the cache.
                        -- config_cahe_api.load_song_config always returns some sort of valid config, even if there's nothing in the cache.
                        song_player_config = cached_config
                    end

                    add_ui_speciffic_config_fields(song_player_config)

                    local networked_player = networking_api.new_network_player(target_song.processed_song, song_player_config)

                    networked_player.register_stop_callback(stop_callback)
                    networked_player.register_update_callback(update_callback)

                    song_processors_and_player_controllers[target_song.id].net_player_controller = networked_player
                    update_main_page_ui()
                end)
            elseif song_processors_and_player_controllers[target_song.id].net_player_controller then
                -- song is ready to play, but we should only play one song at a time using this UI.
                if not playing_song_controller
                    and not song_processors_and_player_controllers[target_song.id].net_player_controller.is_playing()
                then
                    if networking_api.outgoing_packet_queue_progress() < 1 then
                        -- If, for whatever reason, the avatar is useing the networking API elsewhere and the packet queue is full, refuse to start the song.
                        -- This is a sort of bandaid fix as the current logic will correctly enqueue the song and the networking library does eventualy play it,
                        -- but the UI looses track of the enqueued song before it plays.
                        --
                        -- However, any user that is attempting to play two songs at once over the network probably knowss what they're doing.
                        --
                        -- TODO: Fix the UI looseing track of songs that are in the packet queue, but not playing yet.
                        print("The packet queue is already bussy. Are there multiple music players useing the network?")
                    else
                        playing_song_controller = song_processors_and_player_controllers[target_song.id].net_player_controller
                        playing_song_library_id = target_song.id
                        playing_song_controller.play()
                    end
                else
                    playing_song_controller.stop()
                    -- playing_song_controller and playing_song_library_id will be set to `nil` by the stop_callback function
                end
            end

            update_main_page_ui()
        end)
    update_song_selector_title()



    -- Config page
    -- This page needs to let us select what instrument playes which track.
    local song_config_action_wheel_page = action_wheel:newPage()

    ---@class ConfigPageState
    ---@field targeted_song SongHolder
    ---@field targeted_song_config SongPlayerConfig
    ---@field selected_track_index integer
    ---@field selected_instrument_index integer
    ---@field instrument_keys (string|"Default")[]  -- "Default" is a reserved instrument name, and is a stand-in for `nil` (no selected instrument)
    local config_page_state = {}

    local default_instrument_name = "Default"
    local function update_config_instrument_picker_ui()
        local instrument_picker_title = "[ { 'text': '"
            .."Editing \"" .. config_page_state.targeted_song.short_name:gsub("'", "\\'")
            .. "\", track " .. string.format("%02d", config_page_state.selected_track_index)
            .. "\n" .. "Track Name: \"" .. config_page_state.targeted_song.processed_song.tracks[config_page_state.selected_track_index].recommended_instrument_name .. "\""
            .. "\n" .. "Select an instrument with left click"

        local number_of_instruments = #config_page_state.instrument_keys
        local num_instruments_to_display = num_songs_to_display_in_selector

        -- get index range
        local start_index = config_page_state.selected_instrument_index - math.floor(num_instruments_to_display / 2)
        local end_index = start_index + num_instruments_to_display

        -- Don't overscroll if near the start or end of the list
        if start_index < 1 then
            start_index = 1
            end_index = math.min(number_of_instruments, num_instruments_to_display +1)
        elseif end_index > number_of_instruments then
            end_index = number_of_instruments
            start_index = math.max(end_index - num_instruments_to_display, 1)
        end

        local currently_chosen_instrument_on_selected_track = (
            config_page_state.targeted_song_config.instrument_selections
            and config_page_state.targeted_song_config.instrument_selections[config_page_state.selected_track_index]
            and config_page_state.targeted_song_config.instrument_selections[config_page_state.selected_track_index].name
            or  default_instrument_name
                -- TODO: I remember wanting to rework instrument fallbacks. Each instrument probably should be in charge of their own, so that if an instrument comes back, it can recover.
        )

        local bell_emoji = "🔔"  -- my code editor at the moment can't display this. Might need to debug my fonts or something.

        local feature_icon_lookup = {
            percussion  = "🥁", -- Drum kit
            pitch_bend  = "🛝", -- slide         "↝",
            sustain     = "🗘"   --"🏎"   -- Race car
        }

        instrument_picker_title = instrument_picker_title .. "\n"
        for k = start_index, end_index do
            local current_instrument_key = config_page_state.instrument_keys[k] or default_instrument_name

            local current_instrument_features = (current_instrument_key == default_instrument_name and {} or song_player_api.get_instrument_features(current_instrument_key))
            local current_instrument_features_sorted = {}   ---@type string[]
            for key, available in pairs(current_instrument_features) do
                if available then
                    table.insert(current_instrument_features_sorted, key)
                end
            end
            table.sort(current_instrument_features_sorted, function(a, b)
                return string.lower(a) < string.lower(b)
            end)

            local features_icon_string = ""
            for _, sorted_key in pairs(current_instrument_features_sorted) do
                features_icon_string = features_icon_string .. " " .. (feature_icon_lookup[sorted_key] or sorted_key)
            end

            instrument_picker_title = instrument_picker_title
                .. "\n"
                .. (config_page_state.selected_instrument_index == k and "→" or "  ")
                .. (current_instrument_key == currently_chosen_instrument_on_selected_track and bell_emoji or "  ")
                .. " "
                .. (
                    (current_instrument_key == default_instrument_name or (song_player_api.is_instrument_available(current_instrument_key)) )
                    and current_instrument_key
                    or ("'}, { 'text'='" .. current_instrument_key .. "', 'color'='dark_gray'}, {'text'='")
                )
                .. "'}, { 'text'='" .. features_icon_string .. "', 'color'='dark_gray'}, {'text'='"

        end
        -- instrument_picker_title = instrument_picker_title .. "\n"
        --
        instrument_picker_title = instrument_picker_title .. "' } ]"

        actions.config_page_select_track_instrument:setTitle(instrument_picker_title)
    end

    local function update_config_track_picker_ui()
        local track_picker_title = "Editing \"".. config_page_state.targeted_song.short_name .."\""
        track_picker_title = track_picker_title .. "\n" .. "Scroll to select a track"
        track_picker_title = track_picker_title .. "\n"

        local number_of_tracks = #config_page_state.targeted_song.processed_song.tracks
        local tracks_to_display = num_songs_to_display_in_selector / 2

        -- get index range
        local start_index = config_page_state.selected_track_index - math.floor(tracks_to_display / 2)
        local end_index = start_index + tracks_to_display

        -- Don't overscroll if near the start or end of the list
        if start_index < 1 then
            start_index = 1
            end_index = math.min(number_of_tracks, tracks_to_display +1)
        elseif end_index > number_of_tracks then
            end_index = number_of_tracks
            start_index = math.max(end_index - tracks_to_display, 1)
        end

        for k = start_index, end_index do
            local current_track = config_page_state.targeted_song.processed_song.tracks[k]

            track_picker_title = track_picker_title
                .. "\n"
                .. (config_page_state.selected_track_index == k and "→" or "  ")
                .. " " .. string.format("%02d", k)
                .. " "
                .. "\"" .. current_track.recommended_instrument_name .. "\""
                .. "\n    ⮡ "
                .. (
                    config_page_state.targeted_song_config.instrument_selections
                    and config_page_state.targeted_song_config.instrument_selections[k]
                    and config_page_state.targeted_song_config.instrument_selections[k].name
                    or current_track.instrument_type_id == 1 and "Default (Percussion)" or "Default"
                )
        end

        track_picker_title = track_picker_title .. "\n\n" .. "(Showing track number, track name, and selected instrument)"

        actions.config_page_select_track:setTitle(track_picker_title)
    end

    actions.config_page_confirm = action_wheel:newAction()
        :title("Confirm and save changes")
        :item("minecraft:written_book")
        :onLeftClick(function (_)
            config_cahe_api.write_song_config(config_page_state.targeted_song.id, config_page_state.targeted_song_config)

            add_ui_speciffic_config_fields(config_page_state.targeted_song_config)
            song_processors_and_player_controllers[config_page_state.targeted_song.id].net_player_controller.set_new_config(config_page_state.targeted_song_config)

            action_wheel:setPage(music_player_action_wheel_page)
            config_page_state = nil
        end)

    actions.config_page_cancel = action_wheel:newAction()
        :title("Cancel and discard changes")
        :item("minecraft:tnt")
        :onLeftClick(function (_)
            -- We can just exit the config page since actions.enter_config_page will reset the config page state anyways.
            -- But just in case:
            config_page_state = nil
            action_wheel:setPage(music_player_action_wheel_page)
        end)

    actions.config_page_select_track = action_wheel:newAction()
        :title("Select Track")
        :item("minecraft:rail")
        :onScroll(function (scroll_direction, _)
            local natural_scroll = false
            local scroll_amount = keybinds:getKeybinds()["Scroll song list faster"]:isPressed() and 20 or 1
            config_page_state.selected_track_index = config_page_state.selected_track_index + scroll_amount * scroll_direction * (natural_scroll and 1 or -1)

            local total_track_count = #config_page_state.targeted_song.processed_song.tracks

            -- Scroll wrap
            if config_page_state.selected_track_index > total_track_count then config_page_state.selected_track_index = 1 end
            if config_page_state.selected_track_index < 1 then config_page_state.selected_track_index = total_track_count end

            update_config_track_picker_ui()
            update_config_instrument_picker_ui()
        end)

    actions.config_page_select_track_instrument = action_wheel:newAction()
        :title("Select Instrument")
        :item("minecraft:note_block")
        :onScroll(function (scroll_direction, _)
            local natural_scroll = false
            local scroll_amount = keybinds:getKeybinds()["Scroll song list faster"]:isPressed() and 20 or 1

            config_page_state.selected_instrument_index = config_page_state.selected_instrument_index + scroll_amount * scroll_direction * (natural_scroll and 1 or -1)

            local total_instrument_count = #config_page_state.instrument_keys

            if config_page_state.selected_instrument_index > total_instrument_count then config_page_state.selected_instrument_index = 1 end
            if config_page_state.selected_instrument_index < 1 then config_page_state.selected_instrument_index = total_instrument_count end

            -- update_config_track_picker_ui()
            update_config_instrument_picker_ui()
        end)
        :onLeftClick(function (_)   -- Apply the selection to config_page_state.targeted_song_config

            local new_name = config_page_state.instrument_keys[config_page_state.selected_instrument_index]

            ---@type InstrumentSelection
            local new_selection = nil

            if new_name ~= default_instrument_name then
                -- default_instrument_name is a reserved instrument name representing no set instrument.
                new_selection = { name = new_name }
            end

            if not config_page_state.targeted_song_config.instrument_selections then config_page_state.targeted_song_config.instrument_selections = {} end
            config_page_state.targeted_song_config.instrument_selections[config_page_state.selected_track_index] = new_selection

            update_config_track_picker_ui()
            update_config_instrument_picker_ui()
        end)
        :onRightClick(function (_)
            -- TODO: A way to test instrument (right click?)
        end)

    actions.enter_config_page = action_wheel:newAction()
        :title("Song Config")
        :item("minecraft:bedrock") -- :item("minecraft:command_block") --:texture(textures:fromVanilla("Search", "textures/gui/sprites/icon/search.png"))
        :onLeftClick(function(_)

            -- local target_song = song_library:get_song_by_sorted_index(selected_song_index)
            local it_is_safe_to_enter, err = can_enter_config_page()
            if not it_is_safe_to_enter then
                print_host(err)
                return
            end

            local targeted_song = song_library:get_song_by_sorted_index(selected_song_index)
            config_page_state = {
                targeted_song = targeted_song,
                targeted_song_config = config_cahe_api.load_song_config(targeted_song.id),
                selected_track_index = 1,
                selected_instrument_index = 1,
                instrument_keys = song_player_api.get_instrument_keys() -- reload instruments every time we enter the configurator.
            }
            table.insert(config_page_state.instrument_keys, 1, default_instrument_name) -- throw in a fake "default" instrument at the top of the list.

            update_config_track_picker_ui()
            update_config_instrument_picker_ui()

            update_enter_config_page_ui()
            action_wheel:setPage(song_config_action_wheel_page)
        end)
    update_enter_config_page_ui()


    music_player_action_wheel_page:setAction(1,actions.exit_songbook)
    music_player_action_wheel_page:setAction(2,actions.enter_config_page)
    music_player_action_wheel_page:setAction(-1,actions.select_song)

    song_config_action_wheel_page:setAction(1,actions.config_page_confirm)
    song_config_action_wheel_page:setAction(2,actions.config_page_cancel)
    song_config_action_wheel_page:setAction(3,actions.config_page_select_track)
    song_config_action_wheel_page:setAction(4,actions.config_page_select_track_instrument)

    return actions.enter_songbook
end


---@class SongPlayerUiAPI
local song_player_ui_api = {
    new_action_wheel_ui = new_action_wheel_ui
}

return song_player_ui_api
