local root_action_wheel_page = action_wheel:newPage()
action_wheel:setPage(root_action_wheel_page)
-- root_action_wheel_page:setAction(-1, require("scripts/abc_player/abc_player"))

-- More or less: the current checklist
-- - [-] Ping Networking
--   - [ ] Buffer_time calc is sometimes wrong (See Specialist. Buffers correctly for the set buffer time, but still outruns the song. By ~8 packets)
-- - [ ] UI (including config and prefrences)
-- - [ ] Use commands to save a processed song so that it can be uploaded with the avatar
-- - [ ] Port the ABC player to a new processor
-- - [x] Minecraft Note Block instruments
-- - [ ] Figura Piano instrument
-- - [ ] Load instruments from other avatars
-- - [ ] test if I can force the viewer to load an offline avatar by making them render a player head
-- - [ ] Register callback functions through song controller for song end / meta event received / etc.
-- - [ ] Figura Drum Kit instrument
--       https://discord.com/channels/1129805506354085959/1340798228165300224/1340798228165300224
--       /give @p minecraft:player_head[minecraft:profile={id:[I;1039887675,1961051688,-1756947787,-2031944347],name:"Drum"}]

local midi_player_core_api = require("scripts/music_player/core")
local song_player_api = require("scripts/music_player/player")
local music_player_api = midi_player_core_api:build_default_experiance()
local selected_song = music_player_api.library:get_song_by_sorted_index(7)
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

        ---@type ProcessedSong
        local processed_song = completed_future:get_value()
        ---@case processed_song ProcessedSong
        printTable(processed_song)
        printTable(processed_song.tracks)
        print("giving song to player")
        -- printTable(song_player_api.get_instrument_keys())

        ---@type SongPlayerConfig
        local song_player_config = {
            default_normal_instrument = {name = "Triangle Sine"},
            default_percussion_instrument = {name = "Percussion"},
            instrument_selections = {
                -- [1] = {name = "MC/Flute"},
                -- [2] = {name = "MC/Harp"},
                -- [3] = {name = "MC/Harp"},
                -- [6] = {name = "MC/Chime"},
                -- -- [5] = {name = "Muted"},
                -- [9] = {name = "MC/Bass"},
                -- [10] = {name = "MC/Bass"},
                -- [11] = {name = "MC/Guitar"},
                -- [14] = {name = "MC/Guitar"},
            },
            -- source_pos = vec(0, -0.6, -5.40),
            source_entity = player,     -- Consider: storing the entity's UUID instead. When we send the UUID through packets, the entity might not be loaded for the viewer, and so this eventualy resolves to 'nil'
            info_display_type = nil,
            play_immediately = true
        }

        -- local controller = song_player_api.new_player(processed_song, song_player_config)
        -- controller.play()

        local networking = require("scripts/music_player/networking")
        local packets = networking.song_to_packets(processed_song, song_player_config)

        networking.ping_packets(packets)

        -- printTable(packets)
        -- for _, packet in ipairs(packets) do
        --     networking.local_receive_packet(packet)
        -- end

        -- printTable(networking.list_transfered_songs()[1].song)
        -- printTable(networking.list_transfered_songs()[1].song.tracks)
        -- local tmp_counter = 0
        -- events.TICK:register(function()
        --     tmp_counter = tmp_counter +1
        --     print(tmp_counter);
        --     if tmp_counter == 120 then
        --         packages.update_config_for_transfered_song(
        --             1,
        --             {
        --                 default_normal_instrument = {name = "MC/Harp"}
        --             }
        --         )
        --     end
        --     if tmp_counter >= 240 then
        --         packages.update_config_for_transfered_song(
        --             1,
        --             {
        --                 default_normal_instrument = {name = "Triangle Sine"}
        --             }
        --         )
        --         events.TICK:remove("TMP_FAKE_DELAY")
        --     end
        -- end, "TMP_FAKE_DELAY")



    end
)

return root_action_wheel_page
