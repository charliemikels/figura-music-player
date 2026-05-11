local root_action_wheel_page = action_wheel:newPage()
action_wheel:setPage(root_action_wheel_page)

local core = require("scripts.music_player.core")
local enter_songbook_action = core.build_default_ui_action()

root_action_wheel_page:setAction(-1, enter_songbook_action)
