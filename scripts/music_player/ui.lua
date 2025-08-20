
local function new_action_wheel_ui()
    if not keybinds:getKeybinds()["Scroll song list faster"] then
        keybinds:newKeybind(
    		"Scroll song list faster",
    		keybinds:getVanillaKey("key.sprint")
    	)
    end

    local music_player_action_wheel_page = action_wheel:newPage()
    local previous_action_wheel_page = nil

    ---@type table<string, {processor_future: TL_Future?, player: PlayingSongController}>
    local processed_songs_and_players = {}

    ---@type LibrariesApi
    local song_library_api = require("./libraries")
    local song_library = host:isHost() and song_library_api:build_default_library() or song_library_api:build_library() -- Default lib uses files API. Avoid if not host.
    printTable(song_library.songs)

    local selected_song_index = 30
    local selected_song = song_library:get_song_by_sorted_index(selected_song_index)

    local num_songs_to_display_in_selector = 16

    ---Returns a string sutable for use in actions.select_song:setTitle()
    ---@return string
    local function update_song_selector_title()
        if not host:isHost() then return "Song list" end
        if #song_library.sorted_songs == 0 then
            return "Song list\nNo songs found. Check the `[figura root]/data/TL_Songbook` directory."
        end

        local start_index = selected_song_index - math.floor(num_songs_to_display_in_selector / 2)
    	local end_index = start_index + num_songs_to_display_in_selector

    	if start_index < 1 then
    		start_index = 1
    		end_index = math.min(#song_library.sorted_songs, num_songs_to_display_in_selector +1)
    	elseif end_index > #song_library.sorted_songs then
    		end_index = #song_library.sorted_songs
    		start_index = math.max(end_index - num_songs_to_display_in_selector ,1)
    	end

        local return_string = "Song List:"
        for index = start_index, end_index do
            local this_row = ""
            local this_row_song = song_library:get_song_by_sorted_index(index)
            this_row = this_row .. (index == selected_song_index and "→" or "  ")
            this_row = this_row .. this_row_song.name

            return_string = return_string .. "\n" .. this_row
        end

        return return_string
    end

    ---@type table<string, Action>
    local actions = {}
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

	actions.select_song = action_wheel:newAction():title(update_song_selector_title()):item("minecraft:music_disc_wait")
	    :onScroll(function (scroll_direction, self)
			local natural_scroll = false
			local scroll_amount = keybinds:getKeybinds()["Scroll song list faster"]:isPressed() and 20 or 1
			selected_song_index = selected_song_index + scroll_amount * scroll_direction * (natural_scroll and 1 or -1)

			if selected_song_index > #song_library.sorted_songs then selected_song_index = 1 end
			if selected_song_index < 1 then selected_song_index = #song_library.sorted_songs end
			actions.select_song:title(update_song_selector_title())
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
