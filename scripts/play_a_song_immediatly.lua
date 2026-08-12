
-- Test file to just immediately start a song.
-- This will help us dodge the packet logic while testing out
-- the new TrackInstruction system.

-- events.ENTITY_INIT:register(function ()
--     if host:isHost() then
--         print("Attempting to start a song")
--         local default_library = require("scripts/music_player/libraries"):build_default_library()
--         local song = default_library:get_song_by_sorted_index(6) -- 18 Through the fire and the flames
--         local song_processor_future = song:start_or_get_data_processor()

--         print(song.id)

--         song_processor_future:register_on_done_callback(function(done_future)
--             local done_song = done_future:get_value_or_throw_error()
--             local config_api = require("scripts/music_player/config_cache")     ---@type ConfigCacheAPI
--             -- local music_player_api = require("scripts/music_player/song_player")     ---@type SongPlayerAPI
--             local networking_api = require("scripts/music_player/networking")     ---@type SongNetworkingApi
--             local song_config = config_api.load_song_config(song.id)
--             song_config.source_entity = player

--             local song_player_controller = networking_api.new_network_player(done_song, song_config)

--             song_player_controller.play()
--         end)
--     end
-- end)
