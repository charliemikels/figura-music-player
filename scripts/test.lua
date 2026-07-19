
-- Quick script to test the exporting features. Probably could git ignore this.

local known_avatars_with_tl_fmp = {}    ---@type table<UUID, SongPlayerExportedInfoApi>
local last_checked_uuid = nil


-- local avatar_vars = world.avatarVars()

-- local function post_init()
--     events.TICK:remove(post_init)

--     -- printTable(world.avatarVars())

--     -- local my_vars = world.avatarVars()[avatar:getUUID()]
--     -- local exported_song_info_api = my_vars["TL_FMP_exported_song_info_api"]    ---@type SongPlayerExportedInfoApi

--     -- local add_song_start_callback = exported_song_info_api.add_song_start_callback
--     -- print(add_song_start_callback)
--     -- add_song_start_callback(function(uuid)
--     --     print("SONG with UUID: "..tostring(uuid).." just started playing")
--     --     -- error("bad function")
--     -- end)



--     -- print("hello")
--     -- print(post_init)



--     -- local function infinite_loop()
--     --     local sum = 0
--     --     print("IN THE LOOP")
--     --     while true do
--     --         sum = sum + 1
--     --         -- print(sum)
--     --     end
--     -- end

--     -- print("starting loop")
--     -- -- print( pcall(infinite_loop) )
--     -- print("out of the loop")
-- end
-- events.TICK:register(post_init)

---@param our_reference SongPlayerExportedInfoApi
---@param external_api SongPlayerExportedInfoApi
local function has_api_changed(our_reference, external_api)
    return our_reference.time_player_initialized() ~= external_api.time_player_initialized()
end

-- ---comment
-- ---@param song_uuid UUID
-- local function on_song_start(song_uuid)
--     print("External test stuff. Song started.", song_uuid)
--     -- TODO: Initialize metronome events.
--     host:setActionbar("Song: "..song_uuid, true)

--     exported_info.add_song_stop_callback(song_uuid, function()
--         print("Song ended")
--     end)
-- end

events.TICK:register(function()
    -- I would love to figure out a way to discover avatars advertising TL_FMP that doesn't involve a constant loop over the avatarVars table.
    -- But I think the only way to do that would be to edit the avatar_vars metatable and change some on_update logic to forward events.
    -- I think we'll just leave that as an exercise for the Viewer.

    local fmp_avatar_uuid, vars = next(world.avatarVars(), last_checked_uuid)
    last_checked_uuid = fmp_avatar_uuid
    if fmp_avatar_uuid == nil then return end

    if vars["TL_FMP_exported_song_info_api"] and not known_avatars_with_tl_fmp[fmp_avatar_uuid] then -- first time seeing an avatar with TL_FMP
        print("found TL_FMP avatar: "..fmp_avatar_uuid)

        local new_found_api = vars["TL_FMP_exported_song_info_api"] ---@type SongPlayerExportedInfoApi
        new_found_api.add_song_start_callback(function(song_uuid)
            print("External test stuff. Song started.", song_uuid)
            host:setActionbar("Song: "..song_uuid, true)

            new_found_api.add_song_stop_callback(song_uuid, function()
                print("Song ended")
            end)
        end)

        known_avatars_with_tl_fmp[fmp_avatar_uuid] = new_found_api

        return
    end

    local success, result = pcall(has_api_changed, known_avatars_with_tl_fmp[fmp_avatar_uuid], vars["TL_FMP_exported_song_info_api"])

    if success and result then
        print("lost TL_FMP avatar: "..fmp_avatar_uuid)
        known_avatars_with_tl_fmp[fmp_avatar_uuid] = nil
    end
end)
