
-- Quick script to test the exporting features. Probably could git ignore this.

local known_avatars_with_tl_fmp = {}    ---@type table<UUID, SongPlayerExportedInfoApi>
local last_checked_uuid = nil

---Creates a function that automatically steps through a table with each call, and recovers if a key returns nil
---@generic K
---@generic V
---@param target table<K, V>|fun():table<K, V>
---@return fun(): key:K, value:V
local function create_get_next_function(target)
    local get_table
    if type(target) == "table" then
        get_table = function() return target end
    else
        get_table = target
    end

    local last_key = nil
    local function get_next()
        local current_state_of_table = get_table()
        local key, value = next(current_state_of_table, current_state_of_table[last_key] and last_key or nil)
        if not key then -- either the list is empty, or the last tested key was the last key.
            key, value = next(current_state_of_table, nil)
        end
        last_key = key
        return key, value
    end
    return get_next
end

---@param our_reference SongPlayerExportedInfoApi
---@param external_api SongPlayerExportedInfoApi
local function has_api_changed(our_reference, external_api)
    return our_reference.time_player_initialized() ~= external_api.time_player_initialized()
end

local next_world_var = create_get_next_function(world.avatarVars)
local next_known_music_player_avatar = create_get_next_function(known_avatars_with_tl_fmp)

events.TICK:register(function() -- passively find avatars with TL_FMP
    local avatar_uuid, avatar_vars = next_world_var()

    if avatar_vars["TL_FMP_exported_song_info_api"] and not known_avatars_with_tl_fmp[avatar_uuid] then -- first time seeing this avatar with vars for TL_FMP
        known_avatars_with_tl_fmp[avatar_uuid] = avatar_vars["TL_FMP_exported_song_info_api"]

        -- local new_found_api = avatar_vars["TL_FMP_exported_song_info_api"] ---@type SongPlayerExportedInfoApi
        -- -- new_found_api.add_song_start_callback(function(song_uuid)
        -- --     -- host:setActionbar("Song: "..song_uuid, true)

        -- --     local bpm_print_update_loop_name = "TEST_FISH_FISH_TEST!!"
        -- --     local last_beat = -1
        -- --     new_found_api.add_song_metronome_update_callback(song_uuid, function(metronome_info)
        -- --         events.TICK:remove(bpm_print_update_loop_name)

        -- --         events.TICK:register(
        -- --             function ()
        -- --                 local this_beat = math.floor(metronome_info.get_current_beat() )

        -- --                 local current_beat_printable = math.floor(metronome_info.get_current_measure() +1) .. " . " .. math.floor(metronome_info.get_current_beat_in_measure()+1) .. "  |  " .. string.format("%.3f", metronome_info.get_current_beat())

        -- --                 if last_beat ~= this_beat then
        -- --                     last_beat = this_beat

        -- --                     if math.floor(metronome_info.get_current_beat_in_measure()) == 0 then
        -- --                         host:setActionbar("▊▊▊▊▊▊▊▊▊▊▊▊▊ ".. current_beat_printable .." ▊▊▊▊▊▊▊▊▊▊▊▊▊")
        -- --                     else
        -- --                         host:setActionbar("▊ ".. current_beat_printable .." ▊")
        -- --                     end

        -- --                 else
        -- --                     host:setActionbar(current_beat_printable)
        -- --                 end

        -- --             end,
        -- --             bpm_print_update_loop_name
        -- --         )

        -- --     end)


        -- --     new_found_api.add_song_stop_callback(song_uuid, function()
        -- --         -- print("Song ended")
        -- --         events.TICK:remove(bpm_print_update_loop_name)
        -- --     end)


        -- -- end)
        return
    end

    local success, result = pcall(has_api_changed, known_avatars_with_tl_fmp[avatar_uuid], avatar_vars["TL_FMP_exported_song_info_api"])
    if success and result then  -- Avatar was once valid and is not any more.
        -- print("lost TL_FMP avatar: "..fmp_avatar_uuid)
        known_avatars_with_tl_fmp[avatar_uuid] = nil
    end
end)


events.TICK:register(function ()
	local fmp_avatar_uuid, fmp_exported_api = next_known_music_player_avatar()
	if not fmp_avatar_uuid then return end
	local song_uuids_with_position = fmp_exported_api:get_all_playing_song_uuids_and_positions()
	if next(song_uuids_with_position) then
	    print("song detected")
	    -- this avatar is playing a song.
	end
end)
