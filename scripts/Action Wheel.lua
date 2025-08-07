local root_action_wheel_page = action_wheel:newPage()
action_wheel:setPage(root_action_wheel_page)
-- root_action_wheel_page:setAction(-1, require("scripts/abc_player/abc_player"))

local midi_player_core_api = require("scripts/music_player/core")
local song_player_api = require("scripts/music_player/player")
local music_player_api = midi_player_core_api:build_default_experiance()
local selected_song = music_player_api.library:get_song_by_sorted_index(115)
-- 1: Balatro - uses significant pitch wheel in the synths
-- 2: FEZ/Compass.mid - Uses 2 Midi devices (`0` and `1`) and has unused channels.
-- 5: Specialist (shorter)
-- 115: keyboard cat
-- 111: Wii Sports
print("selected song: ", selected_song.name)
local future_of_music = selected_song:start_data_processor()
future_of_music:register_callback(
    function(completed_future)
        print("--==  SONG PROCESSED  ==--")
        if completed_future:has_error() then
            print("There was an error")
            local the_error = completed_future:get_error()
            print(the_error)
            return
        end

        local processed_song = completed_future:get_value()
        ---@case processed_song ProcessedSong
        printTable(processed_song)
        print("giving song to player")
        local controller = song_player_api.new_player(processed_song, {
            default_normal_instrument = {name = "Triangle Sine"},
            default_percussion_instrument = {name = "Percussion"},
            -- source_pos = vec(0,0,0),
            source_entity = player,
            info_display_type = nil
        })
        controller.play()
        --
        -- printTable(sounds["scripts.music_player.instruments.triangle_sine.triangle_sine"]:play())
        -- printTable(sounds:getCustomSounds())
    end
)

return root_action_wheel_page
