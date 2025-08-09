local root_action_wheel_page = action_wheel:newPage()
action_wheel:setPage(root_action_wheel_page)
-- root_action_wheel_page:setAction(-1, require("scripts/abc_player/abc_player"))

-- More or less: the current checklist
-- - [ ] Ping Networking
-- - [ ] UI (including config and prefrences)
-- - [ ] Use commands to save a processed song so that it can be uploaded with the avatar
-- - [ ] Port the ABC player to a new processor
-- - [x] Minecraft Note Block instruments
-- - [ ] Figura Piano instrument
-- - [ ] Load instruments from other avatars
-- - [ ] test if I can force the viewer to load an offline avatar by making them render a player head
-- - [ ] Register callback functions through song controller for song end / meta event received / etc.

local midi_player_core_api = require("scripts/music_player/core")
local song_player_api = require("scripts/music_player/player")
local music_player_api = midi_player_core_api:build_default_experiance()
local selected_song = music_player_api.library:get_song_by_sorted_index(9)
-- 2: Balatro - uses significant pitch wheel in the synths
-- 3: FEZ/Compass.mid - Uses 2 Midi devices (`0` and `1`) and has unused channels.
-- 6: Specialist (shorter)
-- 9: SSMB4 - has like 18 tracks
-- 56: Katamari Cherry Blosom Color Season. Very heavy. Good candidate for caching.
-- 60: Little Big Adventure Twinsens Oddysey - Title: `"End of track" event but there is still data to read` error
-- 119: keyboard cat
-- 115: Wii Sports
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
        printTable(processed_song.tracks)
        print("giving song to player")
        -- printTable(song_player_api.get_instrument_keys())
        local controller = song_player_api.new_player(processed_song, {
            default_normal_instrument = {name = "Triangle Sine"},
            default_percussion_instrument = {name = "Percussion"},
            instrument_selections = {
                -- [1] = {name = "MC/Banjo"},
                -- [2] = {name = "MC/Guitar"},
                -- [3] = {name = "MC/Harp"},
                -- [5] = {name = "MC/Guitar"},
                [6] = {name = "MC/Bass"},
                [7] = {name = "MC/Harp"},
                [8] = {name = "MC/Guitar"},
                [11] = {name = "MC/Guitar"},
                [14] = {name = "MC/Harp"},
                [15] = {name = "MC/Chime"},
                [16] = {name = "MC/Flute"},
                [17] = {name = "MC/Harp"},
                [18] = {name = "MC/Flute"},



            },
            source_entity = player,
            info_display_type = nil
        })
        controller.play()
    end
)

return root_action_wheel_page
