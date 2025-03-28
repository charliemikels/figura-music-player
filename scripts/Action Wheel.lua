local root_action_wheel_page = action_wheel:newPage()
action_wheel:setPage(root_action_wheel_page)
-- root_action_wheel_page:setAction(-1, require("scripts/abc_player/abc_player"))

local midi_player_core_api = require("scripts/music_player/core")
local music_player_api = midi_player_core_api:build_default_experiance()
music_player_api.library
    :get_song_by_sorted_index(1)
    :start_data_processor()
    :register_callback(
        function(future)
            print("Callback ran")
            print(future)
            print(future:is_done())
            print(future:has_error())
            print(future:get_value())
        end
    )

return root_action_wheel_page
