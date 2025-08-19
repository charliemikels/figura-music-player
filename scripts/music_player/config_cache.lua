
local config_path = "TL_music_player_saved_configs"

---Wrapper function to ensure we allways open and close the config file.
---@param fn any
---@param ... unknown
local function load_run_and_unload_our_config(fn, ...)
    local original_name = config:getName()
    config:setName(config_path)
    local return_data = fn(...)
    config:setName(original_name)
    return return_data
end


local approved_keys_to_save = {
    default_normal_instrument = true,
    default_percussion_instrument = true,
    instrument_selections = true
}

---comment
---@param song_id string            A unique identifier for a song.
---@param song_config SongPlayerConfig
local function write_song_config(song_id, song_config)
    print("SAVING", song_id, song_config)
    -- We only want to save a handfull of keys. Mostly just instrument selection.
    -- The script should take responcibility for actual playback controll
    ---@type SongPlayerConfig
    local coppied_song_config = {}
    for k, v in pairs(song_config) do
        print("checking key:", k)
        if approved_keys_to_save[k] then
            print("supported key:", k, v)
            coppied_song_config[k] = v
        end
    end
    config:save(song_id, coppied_song_config)
end

local function load_song_config(song_id)
    print("READING", song_id, "from", config:getName())
    return config:load(song_id)
end

local function delete_song_config(song_id)
    config:save(song_id, nil)
end

local function delete_all_config_data()
    local config_data = config:load()
    for key, _ in pairs(config_data) do
        config:save(key, nil)
    end
end

return {
    write_song_config  =  function(song_id, song_config)  return load_run_and_unload_our_config(write_song_config, song_id, song_config)  end,
    load_song_config   =  function(song_id)               return load_run_and_unload_our_config(load_song_config, song_id)                end,
    delete_song_config =  function(song_id)               return load_run_and_unload_our_config(delete_song_config, song_id)              end,
    -- delete_all_config_data = function(song_id) return load_run_and_unload_our_config(delete_all_config_data, song_id) end,
}
