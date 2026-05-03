

local function escape_patern_matching_magic_characters(string_to_escape)
    return string_to_escape:gsub("([^%w])", "%%%1")
end

---@class LocalSongScript
---@field data PacketDataString[]
---@field name string

local song_script_returns = {}
local local_song_holders = {}      ---@type SongHolder[]
local local_song_processor_future_controllers = {}      ---@type TL_FutureController[]    -- inexes will be in sync with the local_songs list

local local_songs_directory_path = "./local_songs"
local pattern_to_exclude = string.gsub(local_songs_directory_path, "%.%/(%a-)", "%1").."$"  -- Basicaly `"./thing"` → `"thing$"
for _, script in pairs(listFiles(local_songs_directory_path, true)) do
    if not string.match(script, pattern_to_exclude) then
        local require_success, require_return = pcall(function() return require(script) end)
        if not require_success then
            print("Error: Failed to require local song script `"..script.."`. This script will be skipped. Full error below:\n\n"..tostring(require_return))
        else
            ---@cast require_return LocalSongScript
            if not (require_return and type(require_return) == "table" and require_return.data and require_return.name) then
                print(tostring(script).." exists, but does not look like a local song")
            else
                print("Found local song:", require_return.name)
                local tl_futures_api = require("./futures") ---@type TL_FuturesAPI
                local future_controller, return_future = tl_futures_api.new_future("ProcessedSong")

                ---@type SongHolder
                local detected_potential_song = {
                    uuid = client.intUUIDToString(client.generateUUID()),
                    id = "",    -- TODO
                    name = require_return.name,
                    short_name = require_return.name,
                    start_or_get_data_processor = function()
                        -- for local songs, start_data_processor is sorta a lie. The data procesor has already started on avatar init, but works slowly.
                        return return_future
                    end,
                    processed_song = nil,
                    source = { ---@type LocalDataSource
                        type = "local",
                        raw_data = require_return.data
                    },
                }
                table.insert(local_song_holders, detected_potential_song)
                table.insert(local_song_processor_future_controllers, future_controller)  -- index should be in sync with the local song
                table.insert(song_script_returns, require_return)
            end
        end
    end
end

-- We've built a list of local songs and assigned processors to them. We can start our tick loop and fill them in one by one.
-- TODO


---@class LocalSongApi
---@field get_local_song_holders fun():SongHolder[]
---@field convert_song_to_local fun(song:SongHolder)
local local_songs_api = {
    get_local_song_holders = function() return local_song_holders end,
    convert_song_to_local = function(song) end
}

return local_songs_api
