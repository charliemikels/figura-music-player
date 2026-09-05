
-- Small example script for using the external data system.
--
-- Constantly Searches the world vars for instances of TL_FMP, and checks for any playing songs.
-- Will visualize metronome data for nearest song.
--
-- The constant search isn't necessary. You could instead make a "get nearest FMP Song" that just gets called once.

local known_avatars_with_tl_fmp = {}    ---@type table<UUID, {api:SongPlayerExportedInfoApi, song_position_pairs:{ [UUID]: Vector3}}>


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

---@param our_reference {api:SongPlayerExportedInfoApi} -- {api:SongPlayerExportedInfoApi, song_position_pairs:{ [UUID]: Vector3}}
---@param external_api {api:SongPlayerExportedInfoApi}
local function has_api_changed(our_reference, external_api)
    return our_reference.api.time_player_initialized() ~= external_api.api.time_player_initialized()
end

local next_world_var = create_get_next_function(world.avatarVars)
local next_known_fmp_avatar = create_get_next_function(known_avatars_with_tl_fmp)

---@param avatar_uuid UUID
---@param avatar_vars { [string]:any }
local function detect_and_record_new_fmp_avatars(avatar_uuid, avatar_vars)
    if avatar_vars["TL_FMP_exported_song_info_api"] and not known_avatars_with_tl_fmp[avatar_uuid] then -- first time seeing this avatar with vars for TL_FMP
        known_avatars_with_tl_fmp[avatar_uuid] = {
            api = avatar_vars["TL_FMP_exported_song_info_api"],
            -- song_position_pairs = {}
        }

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
end

local nearest_song_avatar_uuid = nil    ---@type UUID?
local nearest_song_uuid = nil           ---@type UUID?

---@param avatar_uuid UUID?
---@param avatar_vars { [string]:any }
local function detect_and_remove_now_invalid_fmp_avatars(avatar_uuid, avatar_vars)
    local success, result = pcall(has_api_changed, known_avatars_with_tl_fmp[avatar_uuid], avatar_vars["TL_FMP_exported_song_info_api"])
    -- print(success, result)
    if success and result then  -- Avatar was once valid and is not any more.
        -- print("lost TL_FMP avatar: "..fmp_avatar_uuid)
        known_avatars_with_tl_fmp[avatar_uuid] = nil
        if avatar_uuid == nearest_song_avatar_uuid then -- this avatar was once the nearest avatar.
            nearest_song_avatar_uuid = nil
            nearest_song_uuid = nil
        end
    end
end

---@param fmp_avatar_uuid UUID?
---@param fmp_exported_api {api:SongPlayerExportedInfoApi, song_position_pairs:{ [UUID]: Vector3}}
---@return boolean there_is_a_new_song
local function update_song_position_pairs_for_fmp_avatar(fmp_avatar_uuid, fmp_exported_api)
	if not fmp_avatar_uuid then return false end

	local song_uuids_and_positions = fmp_exported_api.api:get_all_playing_song_uuids_and_positions()

	fmp_exported_api.song_position_pairs = song_uuids_and_positions
	return (next(song_uuids_and_positions) and true or false)
end

local last_beat = -1
local display_loop_event = events.TICK
local display_loop_name = "display_loop ".. client.intUUIDToString(client:generateUUID())
local function kill_display_loop()
    print("Killing loop")
    last_beat = -1
    display_loop_event:remove(display_loop_name)
end

local function display_loop()
    local success, song_is_in_playing_list = pcall(function()
        return nearest_song_avatar_uuid and nearest_song_uuid and known_avatars_with_tl_fmp[nearest_song_avatar_uuid] and world.avatarVars()[nearest_song_avatar_uuid]["TL_FMP_exported_song_info_api"].get_song_name(nearest_song_uuid)
    end)
    if success and song_is_in_playing_list then
        local current_api = known_avatars_with_tl_fmp[nearest_song_avatar_uuid].api
        if current_api.get_song_is_buffering_or_needs_to_buffer(nearest_song_uuid) then
            host:setActionbar("Buffering \""..current_api.get_song_name(nearest_song_uuid).."\" | "..math.ceil(current_api.get_song_remaining_buffer_time(nearest_song_uuid)/1000).."s")
            return
        end

        local metronome_info = current_api.get_metronome_info(nearest_song_uuid)


        local local_inner_string =
            current_api.get_song_name(nearest_song_uuid)
            .. "  |  " .. math.ceil(current_api.get_song_remaining_time(nearest_song_uuid)/1000).."s ".. math.floor(current_api.get_song_progress(nearest_song_uuid)*100).."%"
            .. "  |  " .. "m"..math.floor(metronome_info.get_current_measure() +1) .. " . " .. "b"..math.floor(metronome_info.get_current_beat_in_measure()+1)
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
    local this_avatar_is_playing_at_least_one_song = update_song_position_pairs_for_fmp_avatar(fmp_avatar_uuid, fmp_exported_api)
    if this_avatar_is_playing_at_least_one_song then
        if display_loop_event:getRegisteredCount(display_loop_name) < 1 then -- start display event if it's not running yet.
            display_loop_event:register(display_loop, display_loop_name)
        end

        local success, current_nearest_song_position = pcall(function() return known_avatars_with_tl_fmp[nearest_song_avatar_uuid].api.get_song_position(nearest_song_uuid) end)
        local current_song_distance_to_player = success and current_nearest_song_position
            and (client:getCameraPos() - current_nearest_song_position):lengthSquared()
            or math.huge -- set distance to beat.

        for test_song_uuid, test_song_position in pairs(known_avatars_with_tl_fmp[fmp_avatar_uuid].api:get_all_playing_song_uuids_and_positions()) do
            local test_song_distance_to_camera = (client:getCameraPos() - test_song_position):lengthSquared()
            if test_song_distance_to_camera < current_song_distance_to_player then
                current_song_distance_to_player = test_song_distance_to_camera
                nearest_song_avatar_uuid = fmp_avatar_uuid
                nearest_song_uuid = test_song_uuid
            end
        end
    end
end)
