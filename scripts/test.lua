
-- Quick script to test the exporting features. Probably could git ignore this.



local function post_init()
    events.TICK:remove(post_init)



    local my_vars = world.avatarVars()[avatar:getUUID()]
    local exported_song_info_api = my_vars["TL_FMP_exported_song_info_api"]    ---@type SongPlayerExportedInfoApi

    local add_song_start_callback = exported_song_info_api.add_song_start_callback
    print(add_song_start_callback)
    add_song_start_callback(function(uuid)
        print("SONG with UUID: "..tostring(uuid).." just started playing")
        -- error("bad function")
    end)



    print("hello")
    print(post_init)



    -- local function infinite_loop()
    --     local sum = 0
    --     print("IN THE LOOP")
    --     while true do
    --         sum = sum + 1
    --         -- print(sum)
    --     end
    -- end

    -- print("starting loop")
    -- -- print( pcall(infinite_loop) )
    -- print("out of the loop")
end
events.TICK:register(post_init)
