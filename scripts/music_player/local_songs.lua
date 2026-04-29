

local function escape_patern_matching_magic_characters(string_to_escape)
    return string_to_escape:gsub("([^%w])", "%%%1")
end

---@class LocalSongScript
---@field data PacketDataString[]
---@field name string

local song_script_returns = {}
local local_songs = {}      ---@type Song[]

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

                ---@type Song
                local detected_song = {
                    id = "",
                    name = require_return.name,
                    short_name = require_return.name,
                    start_data_processor = function()
                        local data = require_return.data
                        -- TODO: expose more of the network API
                        return nil
                    end,
                    processed_data = nil,
                    source = { ---@type LocalDataSource
                        type = "local",
                        raw_data = require_return.data
                    },
                }
                table.insert(local_songs, detected_song)
                table.insert(song_script_returns, require_return)
            end
        end
    end





end


---@class LocalSongApi
---@field get_local_songs fun():Song[]
---@field convert_song_to_local fun(song:Song)
local local_songs_api = {
    get_local_songs = function() return local_songs end,
    convert_song_to_local = function(song) end
}

return local_songs_api
