local root_action_wheel_page = action_wheel:newPage()
action_wheel:setPage(root_action_wheel_page)
-- root_action_wheel_page:setAction(-1, require("scripts/abc_player/abc_player"))

local midi_player_core_api = require("scripts/music_player/core")
local song_player_api = require("scripts/music_player/player")
local music_player_api = midi_player_core_api:build_default_experiance()
local selected_song = music_player_api.library:get_song_by_sorted_index(4)
-- 1: FEZ/Compass.mid - Uses 2 Midi devices (`0` and `1`) and has unused channels.
-- 4: Specialist (shorter)
print("selected song: ", selected_song.name)
local future_of_music = selected_song:start_data_processor()
future_of_music:register_callback(
    function(future)
        print("--==  SONG PROCESSED  ==--")
        if future:has_error() then
            print("There was an error")
            local the_error = future:get_error()
            print(the_error)
            return
        end

        local processed_song = future:get_value()
        ---@case processed_song ProcessedSong
        printTable(processed_song)
        print("giving song to player")
        song_player_api.play_song_local(processed_song, {
            default_normal_instrument = {name = "print"},
            default_percussion_instrument = {name = "print"},
            source = vec(0, 58, 0),
            info_display_type = nil
        })
    end
)

return root_action_wheel_page
