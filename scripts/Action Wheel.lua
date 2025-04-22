local root_action_wheel_page = action_wheel:newPage()
action_wheel:setPage(root_action_wheel_page)
-- root_action_wheel_page:setAction(-1, require("scripts/abc_player/abc_player"))

local midi_player_core_api = require("scripts/music_player/core")
local music_player_api = midi_player_core_api:build_default_experiance()
local future_of_music = music_player_api.library:get_song_by_sorted_index(1):start_data_processor()
future_of_music:register_callback(
        function(future)
            print("Callback ran")
            print("is done:", future:is_done())
            print("has error:", future:has_error())
            print("value:", future:get_value_or_get_error())
        end
    )
print("Expected type:", future_of_music:get_expected_value_type())

return root_action_wheel_page
