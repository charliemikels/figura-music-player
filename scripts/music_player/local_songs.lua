
local tl_futures_api = require("./futures") ---@type TL_FuturesAPI
local decoder_api = require("./packet_decoder") ---@type PacketDecoderApi

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

---@alias Base64String string


---@param base64_string Base64String
---@return string?
local function base64_to_string(base64_string)
    -- buffers can injest all sorts of binary-ish data, and can output it to any other it supports
    -- HOPEFULLY because it does something under the hood, we can dodge the usual instruction cost
    -- from rolling our own base64 decoder/encoder system.
    local converter_buffer = data:createBuffer(#base64_string)
    converter_buffer:writeBase64(base64_string)
    converter_buffer:setPosition(0)
    local normal_string = converter_buffer:readByteArray(#base64_string)
    converter_buffer:clear()
    converter_buffer:close()
    return normal_string
end

---@param base64_string Base64String
---@return string?
local function safe_base64_to_string(base64_string)
    local b64_start_instruction_count = avatar:getCurrentInstructions()
    local success, value = pcall(base64_to_string, base64_string)
    local after_pcall_instruction_count = avatar:getCurrentInstructions()
    print_debug("base64 conversion used "..(after_pcall_instruction_count - b64_start_instruction_count) .." instructions", true, true)
    if success then return value end

    return nil
end



---@class LocalSongScript
---@field name string
---@field durration number
---@field num_instructions integer
---@field header Base64String
---@field config Base64String
---@field data Base64String[]

-- Used to test the the requires if they have the needed keys and types.
--
-- The LSP is able to understand this declaration, so at runtime, it's a known-good value.
---@type LocalSongScript
local local_song_template = {
    name = "template",
    header = "",
    config = "",
    data = {},
    durration = 0,
    num_instructions = 0,
}


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
            name = "TBD",       -- TODO: extract the name name from the script path. (we know the base directory from `local_songs_directory_path`, and I think we can know the file ext. (is ext nessesary?))
            short_name = "TBD", -- This can remain TDB, it'll be populated when we actualy require the script
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

-- at this point, all possible local songs have been added to the library

---Standardized way to ignore scripts that have failed.
---@param script_index integer
---@param error_msg string
local function remove_script_from_loop_with_error(script_index, error_msg)
    local script_path = possible_script_paths[script_index]
    future_controllers_by_script_path[script_path]:set_done_with_error(error_msg)
    print_debug("`"..script_path.."`: "..error_msg, true, true)
    table.remove(possible_script_paths, script_index)
end

local script_index = 1
local packet_index_for_script = 1
local local_song_tick_loop_functions
local_song_tick_loop_functions = {
    require_the_script_songs = function()
        print_debug("require: index: "..script_index..", count: "..#possible_script_paths)
        if script_index > #possible_script_paths then   -- There are no more scripts to require, we can move to next function
            print_debug("Local Processor: continueing to header_processing", false, true)
            script_index = 1
            events.TICK:remove(local_song_tick_loop_functions.require_the_script_songs)
            events.TICK:register(local_song_tick_loop_functions.header_processing)
            return
        end

        local script_path = possible_script_paths[script_index]

        print_debug("Attempting to require() `"..script_path.."`…", false, true)

        local require_success, require_result = pcall(function()
            return require(script_path) ---@type LocalSongScript
        end)
        if not require_success then
            ---@cast require_result string
            remove_script_from_loop_with_error(script_index, "require failed with error: `"..require_result.."`")
            return
        end

        -- type checking

        if not type(require_result) == "table" then
            remove_script_from_loop_with_error(script_index, "require returned a "..type(require_result).." instead of a table.")
            return
        end

        -- key existance and type checking.

        for k, v in pairs(local_song_template) do
            if not require_result[k] then
                remove_script_from_loop_with_error(script_index, "Missing key: `"..k.."`")
                return
            end
            if type(require_result[k]) ~= type(v) then
                remove_script_from_loop_with_error(script_index, "Key `"..k.."` is a `"..type(require_result[k]).."` but should be a `"..type(v).."`")
                return
            end
        end

        print_debug("`"..script_path.."` passed require() checks", false, true)

        song_holders_by_script_path[script_path].source.result_of_require = require_result
        song_holders_by_script_path[script_path].short_name = safe_base64_to_string(require_result.name)
        future_controllers_by_script_path[script_path]:set_progress(0.1)

        -- advance to next song

        script_index = script_index + 1
    end,

    header_processing = function()
        print_debug("Header: index: "..script_index..", count: "..#possible_script_paths)
        if script_index > #possible_script_paths then
            script_index = 1
            events.TICK:remove(local_song_tick_loop_functions.header_processing)
            events.TICK:register(local_song_tick_loop_functions.config_processing)
            return
        end

        local script_path = possible_script_paths[script_index]
        local result_of_require = song_holders_by_script_path[script_path].source.result_of_require

        local header_pcall_success, header_pcall_value = pcall(function()
            return decoder_api.new_song_from_header_packet(safe_base64_to_string(result_of_require.header))
        end)
        if not header_pcall_success then
            ---@cast header_pcall_value string
            remove_script_from_loop_with_error(script_index, "header_to_song failed with error: `"..header_pcall_value.."`")
            return
        end

        if not header_pcall_value.duration == result_of_require.durration then
            remove_script_from_loop_with_error(script_index, "Header durration `"..header_pcall_value.duration.."` does not match declared durration `"..result_of_require.durration.."`")
            return
        end

        print_debug("`"..script_path.."` passed header checks", false, true)

        song_holders_by_script_path[script_path].processed_song = header_pcall_value

        script_index = script_index + 1
    end,
    config_processing = function()
        print_debug("Config: index: "..script_index..", count: "..#possible_script_paths)
        -- TODO: we'll need some way to actualy store packets in the song, or at least a way to keep them together. (`song.default_config`?)
        if script_index > #possible_script_paths then
            script_index = 1
            events.TICK:remove(local_song_tick_loop_functions.config_processing)
            events.TICK:register(local_song_tick_loop_functions.data_processing)
            return
        end

        local script_path = possible_script_paths[script_index]
        local result_of_require = song_holders_by_script_path[script_path].source.result_of_require




        script_index = script_index + 1
    end,
    data_processing = function()
        print_debug("Data: index: "..script_index..", count: "..#possible_script_paths)
        -- TODO:
        -- - get one packet from the current song and process it. Don't forget head and config packets. (should each packet type be diffrent state functions?)
        -- - update song's future controller as we go through.
        -- - once all packets read, check if final instruction count matches the count we expect. error if bad. (local_song_builder did something funky??)
        -- - if all good set processor to done.

        if script_index > #possible_script_paths then
            script_index = 1
            events.TICK:remove(local_song_tick_loop_functions.data_processing)
            print("done")
            return
        end

        script_index = script_index + 1
    end,
}

print_debug("Starting local song TICK loop…", false, true)
events.TICK:register(local_song_tick_loop_functions.require_the_script_songs)

---@class LocalSongApi
---@field get_local_song_holders fun():SongHolder[]
---@field convert_song_to_local fun(song:SongHolder)
local local_songs_api = {
    get_local_song_holders = function() return song_holder_list end,
}

return local_songs_api
