
-- Test file to just immediatly start a song.
-- This will help us dodge the packet logic while testing out
-- the new TrackInstruction system.

events.ENTITY_INIT:register(function ()
    print("Attempting to start a song")
    if host:isHost() then
        local default_library = require("scripts/music_player/libraries"):build_default_library()
        local song = default_library:get_song_by_sorted_index(1)
        local song_processor_future = song:start_or_get_data_processor()

        song_processor_future:register_on_done_callback(function(done_future)
            -- local done_song = done_future:get_value_or_throw_error()
            local config_api = require("scripts/music_player/config_cache")     ---@type ConfigCacheAPI
            local music_player_api = require("scripts/music_player/song_player")     ---@type SongPlayerAPI
            local song_config = config_api.load_song_config(song.id)
            song_config.source_entity = player

            local song_player_controller = music_player_api.new_player(song.processed_song, song_config)

            song_player_controller.play()
        end)
    end
end)
