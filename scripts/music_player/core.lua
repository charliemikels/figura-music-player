
-- Tiny little standard entry point for the music player script for most use cases.
--
-- check the doc comment for core_api.build_default_ui_action for example useage.



---@class CoreApi
local core_api = {

    --- Returns an action that you can put into your Action Wheel to access the music player
    ---
    ---
    --- Example:
    ---
    --- ```lua
    --- local root_action_wheel_page = action_wheel:newPage()
    --- action_wheel:setPage(root_action_wheel_page)
    ---
    --- local core = require("scripts.music_player.core")
    --- local enter_songbook_action = core.build_default_ui_action()
    ---
    --- root_action_wheel_page:setAction(-1, enter_songbook_action)
    --- ```
    ---
    --- or if you're crazy, you can do this in one line.
    ---
    --- ```lua
    --- action_wheel:setPage(action_wheel:newPage():setAction(-1, require("scripts.music_player.core").build_default_ui_action()))
    --- ```
    ---
    ---@return Action enter_songbook_action
    build_default_ui_action = function()

        local _ = require("./networking")   -- We want to make sure that the viewer definitly has the networking library ready to go.

        local library_api = require("./libraries") ---@type LibrariesApi
        local library = library_api:build_default_library()

        local ui_api = require("./ui")  ---@type SongPlayerUiAPI
        local action = ui_api.new_action_wheel_ui(library)

        return action
    end
}

return core_api
