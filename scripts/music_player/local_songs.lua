
-- Essentialy a special version of file_processor.lua, but specifficaly for local song files.
-- Local songs are songs that are uploaded with the avatar and don't need pings for viewers
-- to play them.
--
---@see local_song_builder.lua



local tl_futures_api = require("./futures") ---@type TL_FuturesAPI
local decoder_api = require("./packet_decoder") ---@type PacketDecoderApi

local do_debug_prints = false
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
local future_controllers_by_script_path = {}    ---@type table<string, TL_FutureController>
local song_player_configs_by_script_path = {}   ---@type table<string, SongPlayerConfig>

local song_holder_list = {}                  ---@type SongHolder[]

-- Find possible local songs

local local_songs_directory_path = "./local_songs"
local local_songs_directory_path_but_just_what_is_after_the_slash = local_songs_directory_path:gsub(".*%.%/(%a-)", "%1")
local pattern_to_exclude = local_songs_directory_path_but_just_what_is_after_the_slash.."$"  -- tests if local song is the last thing in the list (the found path is a path to ourself)

for _, script_path in pairs(listFiles(local_songs_directory_path, true)) do
    if not string.match(script_path, pattern_to_exclude) then
        table.insert(possible_script_paths, script_path)

        print_debug("Found posible local song: `"..script_path.."`")

        local future_controller, return_future = tl_futures_api.new_future("Song")

        ---@type SongHolder
        local detected_potential_song = {
            uuid = client.intUUIDToString(client.generateUUID()),
            id = script_path,
            name = "⌂/"..script_path:gsub(".-"..local_songs_directory_path_but_just_what_is_after_the_slash:gsub("([^%w])","%%%1").."%.", ""),
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

---comment
---@param script_index integer
---@param error_msg string
local function remove_script_from_loop_with_error(script_index, error_msg)
    local script_path = possible_script_paths[script_index]
    future_controllers_by_script_path[script_path]:set_done_with_error(error_msg)
    print_debug("`"..script_path.."`: "..error_msg, true, true)
    table.remove(possible_script_paths, script_index)
end

local script_index = 1
local data_packet_index_for_script = 1
local local_song_tick_loop_functions
local_song_tick_loop_functions = {
    require_the_script_songs = function()
        -- print_debug("require: index: "..script_index..", count: "..#possible_script_paths)
        if script_index > #possible_script_paths then   -- There are no more scripts to require, we can move to next function
            print_debug("Local Processor: Require step done", false, true)
            script_index = 1
            events.TICK:remove(local_song_tick_loop_functions.require_the_script_songs)
            events.TICK:register(local_song_tick_loop_functions.header_processing)
            return
        end

        local script_path = possible_script_paths[script_index]

        print_debug("Attempting to require() `"..script_path.."`…")

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

        print_debug("`"..script_path.."` passed require() checks")

        song_holders_by_script_path[script_path].source.result_of_require = require_result
        song_holders_by_script_path[script_path].short_name = require_result.name
        future_controllers_by_script_path[script_path]:set_progress(0.1)

        -- advance to next song

        script_index = script_index + 1
    end,


    header_processing = function()
        -- print_debug("Header: index: "..script_index..", count: "..#possible_script_paths)
        if script_index > #possible_script_paths then
            script_index = 1
            events.TICK:remove(local_song_tick_loop_functions.header_processing)
            events.TICK:register(local_song_tick_loop_functions.config_processing)
            return
        end

        local script_path = possible_script_paths[script_index]
        local result_of_require = song_holders_by_script_path[script_path].source.result_of_require

        local header_pcall_success, header_pcall_value = pcall(function()
            return decoder_api.new_song_from_header_packet(result_of_require.header)
        end)
        if not header_pcall_success then
            ---@cast header_pcall_value string
            remove_script_from_loop_with_error(
                script_index,
                "header_to_song failed with error: `"..header_pcall_value.."`"
            )
            return
        end

        if not header_pcall_value.duration == result_of_require.durration then
            remove_script_from_loop_with_error(
                script_index,
                "Header durration `"..header_pcall_value.duration
                    .."` does not match declared durration `"
                    ..result_of_require.durration.."`"
            )
            return
        end

        print_debug("`"..script_path.."` passed header checks")

        header_pcall_value.is_local = true

        song_holders_by_script_path[script_path].processed_song = header_pcall_value
        future_controllers_by_script_path[script_path]:set_progress(0.15)

        script_index = script_index + 1
    end,


    config_processing = function()
        -- print_debug("Config: index: "..script_index..", count: "..#possible_script_paths)

        if script_index > #possible_script_paths then
            script_index = 1
            events.TICK:remove(local_song_tick_loop_functions.config_processing)
            events.TICK:register(local_song_tick_loop_functions.data_processing)
            return
        end

        local script_path = possible_script_paths[script_index]
        local result_of_require = song_holders_by_script_path[script_path].source.result_of_require

        local config_pcall_success, config_pcall_value = pcall(function()
            return decoder_api.new_config_from_packet(result_of_require.config)
        end)
        if not config_pcall_success then
            ---@cast config_pcall_value string
            remove_script_from_loop_with_error(
                script_index,
                "new_config_from_packet failed with error: `"..config_pcall_value.."`"
            )
            return
        end

        print_debug("`"..script_path.."` passed config checks")

        song_player_configs_by_script_path[script_path] = config_pcall_value
        song_holders_by_script_path[script_path].included_config = config_pcall_value
        future_controllers_by_script_path[script_path]:set_progress(0.2)

        script_index = script_index + 1
    end,


    data_processing = function()

        -- print_debug("Data: script_index: "..script_index.." of "..#possible_script_paths..". packet "..data_packet_index_for_script.."." )

        if script_index > #possible_script_paths then
            script_index = 1
            events.TICK:remove(local_song_tick_loop_functions.data_processing)
            print_debug("Local song processor loop has finished.")
            return
        end

        local script_path = possible_script_paths[script_index]
        local song_holder = song_holders_by_script_path[script_path]
        local result_of_require = song_holder.source.result_of_require
        local processed_song = song_holder.processed_song

        if #result_of_require.data < data_packet_index_for_script then -- we're out of packets to process
            if #processed_song.instructions == result_of_require.num_instructions then -- instruction count matched what we expected

                print_debug("Localy song `"..processed_song.name.."` was built successfuly", false, true)

                future_controllers_by_script_path[script_path]:set_done_with_value(processed_song)
            else    -- there's an instruction count mismatch.
                remove_script_from_loop_with_error(
                    script_index,
                    "final instruction list does not match the expected number of instructions."
                        .. " Expected: "..result_of_require.num_instructions
                        ..", got: "..#processed_song.instructions
                )
            end
            data_packet_index_for_script = 1
            script_index = script_index + 1 -- move to next script
            return
        end


        local data_pcall_success, data_pcall_value = pcall(function()
            return decoder_api.add_instructions_to_song_from_packet(
                processed_song,
                result_of_require.data[data_packet_index_for_script]
            )
        end)
        if not data_pcall_success then
            ---@cast data_pcall_value string
            remove_script_from_loop_with_error(
                script_index,
                "new_config_from_packet failed with error: `"..data_pcall_value.."`"
            )
            return
        end

        -- no need for an extra saveing step, add_instructions_to_song_from_packet will update song for us, even inside the pcall.

        -- progress from [0 to 0.2] is reserved by header and config processors. we can go from (0.2, 1.0]  -- TODO: is that the right `()` / `[]` syntax for ranges?
        local data_progress = math.map(data_packet_index_for_script, 0, #result_of_require.data, 0.2, 1.0)  -- TODO: Map was like strangely heavy in one spot. check that it's fine, or write our own logic. (I think we already did in midi processor.)

        future_controllers_by_script_path[script_path]:set_progress(data_progress)

        data_packet_index_for_script = data_packet_index_for_script +1
    end,
}

print_debug("Starting local song TICK loop…", false, true)
events.TICK:register(local_song_tick_loop_functions.require_the_script_songs)

---@class LocalSongApi
---@field get_local_song_holders fun():SongHolder[]
local local_songs_api = {
    get_local_song_holders = function() return song_holder_list end,
}

return local_songs_api
