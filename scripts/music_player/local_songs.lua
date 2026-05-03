
local tl_futures_api = require("./futures") ---@type TL_FuturesAPI

local do_debug_prints = true
--- Logs a message to the console. But if do_debug_prints is true, it also logs to chat. Use do_debug_prints=true to debug viewers.
---@param message string
---@param is_warning boolean?
---@param allways_log boolean?
local function print_debug(message, is_warning, allways_log)
    if do_debug_prints then print(message) end
    if do_debug_prints or allways_log then
        if is_warning then
            host:warnToLog(message)
        else
            host:writeToLog(message)
        end
    end
end


---@class LocalSongScript
---@field name string
---@field durration number
---@field num_instructions integer
---@field header PacketDataString
---@field config PacketDataString
---@field data PacketDataString[]


local possible_script_paths = {}             ---@type string[]
local song_holders_by_script_path = {}       ---@type table<string, SongHolder>
local future_controllers_by_script_path = {} ---@type table<string, TL_FutureController>

local song_holder_list = {}                  ---@type SongHolder[]

-- Find possible local songs

local local_songs_directory_path = "./local_songs"
local pattern_to_exclude = local_songs_directory_path:gsub("%.%/(%a-)", "%1").."$"  -- Basicaly `"./thing"` → `"thing$"`
for _, script_path in pairs(listFiles(local_songs_directory_path, true)) do
    if not string.match(script_path, pattern_to_exclude) then
        table.insert(possible_script_paths, script_path)

        print_debug("Found posible local song: `"..script_path.."`")

        local future_controller, return_future = tl_futures_api.new_future("Song")

        ---@type SongHolder
        local detected_potential_song = {
            uuid = client.intUUIDToString(client.generateUUID()),
            id = script_path,
            name = "TBD",       -- TODO: we can use the string functions to make this a pinch more useful (we can trim the dir root using `local_songs_directory_path`)
            short_name = "TBD",
            start_or_get_data_processor = function()
                return return_future
            end,
            processed_song = nil,
            source = { ---@type LocalDataSource
                type = "local",
                script_path = script_path
            },
        }

        song_holders_by_script_path[script_path] = detected_potential_song
        future_controllers_by_script_path[script_path] = future_controller
        table.insert(song_holder_list, detected_potential_song)
    end
end

-- We've built a list of local songs and assigned processors to them. We can start our tick loop to check them and fill them in one by one.
-- TODO

---@class LocalSongApi
---@field get_local_song_holders fun():SongHolder[]
---@field convert_song_to_local fun(song:SongHolder)
local local_songs_api = {
    get_local_song_holders = function() return song_holder_list end,
}

return local_songs_api
