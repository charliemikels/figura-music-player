local root_action_wheel_page = action_wheel:newPage()
action_wheel:setPage(root_action_wheel_page)
root_action_wheel_page:setAction(-1, require("scripts/abc_player/abc_player"))

return root_action_wheel_page
