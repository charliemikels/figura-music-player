

local function new_action_wheel_ui()
    local music_player_action_wheel_page = action_wheel:newPage()
    local previous_action_wheel_page = nil

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

	actions.select_song = action_wheel:newAction():item("minecraft:music_disc_wait")
	actions.config_song = action_wheel:newAction():texture(textures:fromVanilla("Search", "textures/gui/sprites/icon/search.png"))



	music_player_action_wheel_page:setAction(1,actions.exit_songbook)
	music_player_action_wheel_page:setAction(2,actions.config_song)
	music_player_action_wheel_page:setAction(-1,actions.select_song)

    return actions.enter_songbook
end


return {
    new_action_wheel_ui = new_action_wheel_ui
}
