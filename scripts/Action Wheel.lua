local root_action_wheel_page = action_wheel:newPage()
action_wheel:setPage(root_action_wheel_page)
-- root_action_wheel_page:setAction(-1, require("scripts/abc_player/abc_player"))

if host:isHost() then
    local default_library = require("scripts/music_player/libraries"):build_default_library()
    local song = default_library:get_song_by_sorted_index(124+5) -- 10: rush e full. 14: Starbound Atlas. 124: keyboard cat
    local song_processor_future = song:start_or_get_data_processor()
    song_processor_future:register_callback(function(_)
        -- print("Instruction test")
        -- local starting_ammount = avatar:getCurrentInstructions()
        -- print("starting_ammount:", starting_ammount)
        -- local exported_json = toJson(song.processed_data)
        -- local post_tojson = avatar:getCurrentInstructions()
        -- print("instructions after toJson", post_tojson - starting_ammount)  -- OK: going to and from json is actualy extreamly cheep instruction-wise. Space-wise it's pretty rough.

        -- local networking_api = require("scripts/music_player/networking")   ---@type SongNetworkingApi
        local config_api = require("scripts/music_player/config_cache")     ---@type ConfigCacheAPI
        local music_player_api = require("scripts/music_player/player")     ---@type SongPlayerAPI
        local song_config = config_api.load_song_config(song.id)
        song_config.source_entity = player

        local song_player_controller = music_player_api.new_player(song.processed_song, song_config)
        -- local song_player_controller = networking_api.new_network_player(song.processed_song, song_config)
        song_player_controller.play()

        local function update_callback()
            print(song_player_controller:get_progress())
            print("STOP")
            song_player_controller.remove_update_callback(update_callback)
        end

        song_player_controller.register_update_callback(update_callback)

        local function play_once_more(_)
            print("Let's go again keyboard cat")
            song_player_controller.remove_stop_callback(play_once_more)
            print("But only once more")
            song_player_controller.play()   -- TODO: hold up. that didn't play again.
        end

        song_player_controller.register_stop_callback(play_once_more)

        -- local localizer = require("scripts/music_player/local_song_builder")   ---@type LocalSongBuilderApi
        -- localizer.export_song_to_local(song.processed_song, song_config)

    end)
end


-- More or less: the current checklist
-- - [ ] Port the ABC player to a new processor
-- - [ ] Figura Drum Kit instrument
--       https://discord.com/channels/1129805506354085959/1340798228165300224/1340798228165300224
--       /give @p minecraft:player_head[minecraft:profile={id:[I;1039887675,1961051688,-1756947787,-2031944347],name:"Drum"}]

if host:isHost() then -- TODO: it's host only b/c build_default_library() calls file API. should we instead have build_default_library() skip filesAPI if non-host? (possibly allows for local songs)
    local ui_api = require("scripts/music_player/ui")
    local default_library = require("scripts/music_player/libraries"):build_default_library()
    local enter_music_player_action_wheel_ui = ui_api.new_action_wheel_ui(default_library)
    root_action_wheel_page:setAction(-1, enter_music_player_action_wheel_ui)
end
return root_action_wheel_page
