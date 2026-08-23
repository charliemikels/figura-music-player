
-- Quick script to test the exporting features. Probably could git ignore this.

local known_avatars_with_tl_fmp = {}    ---@type table<UUID, SongPlayerExportedInfoApi>
local last_checked_uuid = nil


---@param our_reference SongPlayerExportedInfoApi
---@param external_api SongPlayerExportedInfoApi
local function has_api_changed(our_reference, external_api)
    return our_reference.time_player_initialized() ~= external_api.time_player_initialized()
end

events.TICK:register(function()
    -- I would love to figure out a way to discover avatars advertising TL_FMP that doesn't involve a constant loop over the avatarVars table.
    -- But I think the only way to do that would be to edit the avatar_vars metatable and change some on_update logic to forward events.
    -- I think we'll just leave that as an exercise for the Viewer.

    -- step through list

    local fmp_avatar_uuid, this_avatar_vars = next(world.avatarVars(), last_checked_uuid)
    last_checked_uuid = fmp_avatar_uuid
    if fmp_avatar_uuid == nil then return end

    -- NOTE: Depending on how and when the song_player script is required, `this_avatar_vars["TL_FMP_exported_song_info_api"]` may not exist until after the avatar plays its first song.
    --
    if this_avatar_vars["TL_FMP_exported_song_info_api"] and not known_avatars_with_tl_fmp[fmp_avatar_uuid] then -- first time seeing this avatar with vars for TL_FMP
        -- print("found TL_FMP avatar: "..fmp_avatar_uuid)

        local new_found_api = this_avatar_vars["TL_FMP_exported_song_info_api"] ---@type SongPlayerExportedInfoApi
        new_found_api.add_song_start_callback(function(song_uuid)
            -- host:setActionbar("Song: "..song_uuid, true)

            local bpm_print_update_loop_name = "TEST_FISH_FISH_TEST!!"
            local last_beat = -1
            new_found_api.add_song_metronome_update_callback(song_uuid, function(metronome_info)
                events.TICK:remove(bpm_print_update_loop_name)

                events.TICK:register(
                    function ()
                        local this_beat = math.floor(metronome_info.get_current_beat() )

                        local current_beat_printable = math.floor(metronome_info.get_current_measure() +1) .. " . " .. math.floor(metronome_info.get_current_beat_in_measure()+1) .. "  |  " .. string.format("%.3f", metronome_info.get_current_beat())

                        if last_beat ~= this_beat then
                            last_beat = this_beat

                            if math.floor(metronome_info.get_current_beat_in_measure()) == 0 then
                                host:setActionbar("▊▊▊▊▊▊▊▊▊▊▊▊▊ ".. current_beat_printable .." ▊▊▊▊▊▊▊▊▊▊▊▊▊")
                            else
                                host:setActionbar("▊ ".. current_beat_printable .." ▊")
                            end

                        else
                            host:setActionbar(current_beat_printable)
                        end

                    end,
                    bpm_print_update_loop_name
                )

            end)


            new_found_api.add_song_stop_callback(song_uuid, function()
                -- print("Song ended")
                events.TICK:remove(bpm_print_update_loop_name)
            end)


        end)

        known_avatars_with_tl_fmp[fmp_avatar_uuid] = new_found_api
        return
    end


    local success, result = pcall(has_api_changed, known_avatars_with_tl_fmp[fmp_avatar_uuid], this_avatar_vars["TL_FMP_exported_song_info_api"])
    if success and result then  -- Avatar was once valid and is not any more.
        -- print("lost TL_FMP avatar: "..fmp_avatar_uuid)
        known_avatars_with_tl_fmp[fmp_avatar_uuid] = nil
    end
end)
