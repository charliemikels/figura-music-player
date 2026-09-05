
-- Small example script for using the external data system.
--
-- Constantly Searches the world vars for instances of TL_FMP, and checks for any playing songs.
-- Will visualize metronome data for nearest song.
--
-- The constant search isn't necessary. You could instead make a "get nearest FMP Song" that just gets called once.

local apis_for_known_fmp_avatars = {}    ---@type table<UUID, SongPlayerExportedInfoApi>


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
local next_known_fmp_avatar = create_get_next_function(apis_for_known_fmp_avatars)

---@param avatar_uuid UUID
---@param avatar_vars { [string]:any }
local function detect_and_record_new_fmp_avatars(avatar_uuid, avatar_vars)
    if avatar_vars["TL_FMP_exported_song_info_api"] and not apis_for_known_fmp_avatars[avatar_uuid] then -- first time seeing this avatar with vars for TL_FMP
        apis_for_known_fmp_avatars[avatar_uuid] = avatar_vars["TL_FMP_exported_song_info_api"]
        return
    end
end

local nearest_song_avatar_uuid = nil    ---@type UUID?
local nearest_song_uuid = nil           ---@type UUID?

---@param avatar_uuid UUID?
---@param avatar_vars { [string]:any }
local function detect_and_remove_now_invalid_fmp_avatars(avatar_uuid, avatar_vars)
    local success, result = pcall(has_api_changed, apis_for_known_fmp_avatars[avatar_uuid], avatar_vars["TL_FMP_exported_song_info_api"])
    -- print(success, result)
    if success and result then  -- Avatar was once valid and is not any more.
        -- print("lost TL_FMP avatar: "..fmp_avatar_uuid)
        apis_for_known_fmp_avatars[avatar_uuid] = nil
        if avatar_uuid == nearest_song_avatar_uuid then -- this avatar was once the nearest avatar.
            nearest_song_avatar_uuid = nil
            nearest_song_uuid = nil
        end
    end
end

local last_beat = -1
local display_loop_event = events.TICK
local display_loop_name = "display_loop ".. client.intUUIDToString(client:generateUUID())
local function kill_display_loop()
    last_beat = -1
    display_loop_event:remove(display_loop_name)
end

local function display_loop()
    local success, nearest_song_is_still_playing = pcall(function()
        return nearest_song_avatar_uuid and nearest_song_uuid and apis_for_known_fmp_avatars[nearest_song_avatar_uuid] and world.avatarVars()[nearest_song_avatar_uuid]["TL_FMP_exported_song_info_api"].get_song_name(nearest_song_uuid)
    end)
    if success and nearest_song_is_still_playing then
        local current_api = apis_for_known_fmp_avatars[nearest_song_avatar_uuid]
        if current_api.get_song_is_buffering_or_needs_to_buffer(nearest_song_uuid) then
            host:setActionbar("Buffering \""..current_api.get_song_name(nearest_song_uuid).."\" | "..math.ceil(current_api.get_song_remaining_buffer_time(nearest_song_uuid)/1000).."s")
            return
        end

        local metronome_info = current_api.get_metronome_info(nearest_song_uuid)


        local local_inner_string =
            (avatar:getUUID() ~= nearest_song_avatar_uuid and "Nearby: " or "Playing: ")
            .. "\"" .. current_api.get_song_name(nearest_song_uuid) .. "\""
            .. "  |  " .. math.ceil(current_api.get_song_remaining_time(nearest_song_uuid)/1000).."s ".. math.floor(current_api.get_song_progress(nearest_song_uuid)*100).."%"
            .. "  |  " .. math.floor(metronome_info.get_current_measure() +1) .. " . " .. math.floor(metronome_info.get_current_beat_in_measure()+1)
            .. " ("..string.format("%.3f", metronome_info.get_current_beat())..")"


        local this_beat = math.floor(metronome_info.get_current_beat() )

        if last_beat ~= this_beat then
            last_beat = this_beat

            if math.floor(metronome_info.get_current_beat_in_measure()) == 0 then
                host:setActionbar("▊▊▊▊▊▊▊▊▊▊▊▊▊ ".. local_inner_string .." ▊▊▊▊▊▊▊▊▊▊▊▊▊")
            else
                host:setActionbar("▊ ".. local_inner_string .." ▊")
            end

        else
            host:setActionbar(local_inner_string)
        end

    else
        kill_display_loop()
    end
end


events.TICK:register(function() -- passively find avatars with TL_FMP

    -- check all avatars

    local avatar_uuid, avatar_vars = next_world_var()
    detect_and_record_new_fmp_avatars(avatar_uuid, avatar_vars)
    detect_and_remove_now_invalid_fmp_avatars(avatar_uuid, avatar_vars)

    -- specifically re-check the avatars we know have FMP
    local fmp_avatar_uuid, fmp_exported_api = next_known_fmp_avatar()
    local this_avatar_is_playing_at_least_one_song = fmp_exported_api and next(fmp_exported_api:get_all_playing_song_uuids_and_positions()) ~= nil
    if this_avatar_is_playing_at_least_one_song then
        if display_loop_event:getRegisteredCount(display_loop_name) < 1 then -- start display event if it's not running yet.
            display_loop_event:register(display_loop, display_loop_name)
        end

        local success, current_nearest_song_position = pcall(function() return apis_for_known_fmp_avatars[nearest_song_avatar_uuid].get_song_position(nearest_song_uuid) end)
        local current_song_distance_to_player = success and current_nearest_song_position
            and (client:getCameraPos() - current_nearest_song_position):lengthSquared()
            or math.huge -- set distance to beat.

        for test_song_uuid, test_song_position in pairs(apis_for_known_fmp_avatars[fmp_avatar_uuid]:get_all_playing_song_uuids_and_positions()) do
            local test_song_distance_to_camera = (client:getCameraPos() - test_song_position):lengthSquared()
            if test_song_distance_to_camera < current_song_distance_to_player then
                current_song_distance_to_player = test_song_distance_to_camera
                nearest_song_avatar_uuid = fmp_avatar_uuid
                nearest_song_uuid = test_song_uuid
            end
        end
    end
end)
