
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

local function on_song_start(uuid)
    print("External test stuff. Song started.", uuid)
    -- TODO: Initialize metronome events.
    host:setActionbar("Song: "..uuid, true)
end

events.TICK:register(function()
    -- I would love to figure out a way to discover avatars advertising TL_FMP that doesn't involve a constant loop over the avatarVars table.
    -- But I think the only way to do that would be to edit the avatar_vars metatable and change some on_update logic to forward events.
    -- I think we'll just leave that as an exercise for the Viewer.

    local uuid, vars = next(world.avatarVars(), last_checked_uuid)
    last_checked_uuid = uuid
    if uuid == nil then return end

    if vars["TL_FMP_exported_song_info_api"] and not known_avatars_with_tl_fmp[uuid] then -- first time seeing an avatar with TL_FMP
        print("found TL_FMP avatar: "..uuid)

        local new_found_api = vars["TL_FMP_exported_song_info_api"] ---@type SongPlayerExportedInfoApi
        new_found_api.add_song_start_callback(on_song_start)

        known_avatars_with_tl_fmp[uuid] = new_found_api

        return
    end

    local success, result = pcall(has_api_changed, known_avatars_with_tl_fmp[uuid], vars["TL_FMP_exported_song_info_api"])

    if success and result then
        print("lost TL_FMP avatar: "..uuid)
        known_avatars_with_tl_fmp[uuid] = nil
    end
end)
