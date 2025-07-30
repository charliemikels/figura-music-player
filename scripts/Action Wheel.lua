local root_action_wheel_page = action_wheel:newPage()
action_wheel:setPage(root_action_wheel_page)
-- root_action_wheel_page:setAction(-1, require("scripts/abc_player/abc_player"))

local midi_player_core_api = require("scripts/music_player/core")
local music_player_api = midi_player_core_api:build_default_experiance()
local selected_song = music_player_api.library:get_song_by_sorted_index(4)
-- 1: FEZ/Compass.mid - Uses 2 Midi devices (`0` and `1`) and has unused channels.
-- 4: Specialist (shorter)
print("selected song: ", selected_song.name)
local future_of_music = selected_song:start_data_processor()
future_of_music:register_callback(
        function(future)
            print("Callback 1 ran")
            print("is done:", future:is_done())
            print("has error:", future:has_error())
            print("value:", future:get_value_or_get_error())

            future_of_music:register_callback(
                    function(new_future)
                        print("Callback 3")
                        print("This callback is set inside of another one. so it is guarrentied to be registered after the future is done")
                        print("It should run last")
                    end
                )
        end
    )
future_of_music:register_callback(
        function(new_future)
            print("Callback 2 ran.")
        end
    )
print("Expected type:", future_of_music:get_expected_value_type())

return root_action_wheel_page
