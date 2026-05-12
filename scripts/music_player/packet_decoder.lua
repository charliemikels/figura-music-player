
-- A set of functions that builds songs, headers, and config info out of streams of characters.
--
-- This is primaraly used by the Networking system, but also by the local song importer.



local packet_enums_api = require("./packet_enums") ---@type PacketEnumsAPI

-- decoder creates processed songs and configs for those songs.

-- There should be no ping functions here. This entire file must be runable on the viewer.


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
local function printTable_debug(...) if do_debug_prints then printTable(...) end end
local function print_host(...) if host:isHost() or do_debug_prints then print(...) end end

---Convert a variable-length-quantity into an integer (or a nil) and advances PacketReader's index.
---@param packet_reader PacketReader
---@return integer?
local function vlq_to_int_from_reader(packet_reader)
    local bytes = packet_reader.bytes
    if bytes[packet_reader.index] == 0x80 then
        -- see comment block inside int_to_vlq
        packet_reader.index = packet_reader.index + 1
        return nil
    end
    local result = 0
    local byte
    repeat
        byte = bytes[packet_reader.index]
        if not byte then error("vlq_to_int ran out of bytes to read.") end
        result = result * 128 + (byte % 128)
        packet_reader.index = packet_reader.index + 1
    until byte < 128
    return result
end

---Reads a string (including the length at the beginning) out of a PacketReader's bytes
---@param reader PacketReader
---@return string?
local function bytes_with_len_to_string_from_reader(reader)
    local len_string = vlq_to_int_from_reader(reader)
    if len_string == nil then return nil end
    local str = string.char(table.unpack(
        reader.bytes,
        reader.index,
        reader.index + len_string - 1
    ))
    reader.index = reader.index + len_string
    return str
end

--- Effectively converts 5 → `101` → {1, 0, 1}.
--- If expected_len > results_list, append false to left side (`101` → `00101`)
--- Used to assign percussion tracks to incoming songs
---@param int integer       usualy pulled right from vlq_to_int_from_packet
---@param length integer    the expected length of this list. (determines how many leading `0`s there will be)
---@return (0|1)[]
local function int_to_bit_list(int, length)
    local bits = {}
    for bit_index = length, 1, -1 do
        local bit = math.fmod(int, 2)
        bits[bit_index] = bit
        int = math.floor((int - bit) / 2)
    end
    return bits
end

--- Effectively converts 5 → `101` → {true, false, true}.
--- Same as int_to_bit_list, but returns boolian[] instead of 0|1[]
---@param int integer       usualy pulled right from vlq_to_int_from_packet
---@param length integer    the expected length of this list. (determines how many leading `false`s there will be)
---@return boolean[]
local function int_to_bool_list(int, length)
    local bit_list = int_to_bit_list(int, length)
    local bool_list = {}
    for index, bit in ipairs(bit_list) do bool_list[index] = bit == 1 end
    return bool_list
end

---Converts a string into a table of bytes
---@param data_string PacketDataString
---@return PacketDataBytes
local function packet_data_string_to_bytes(data_string)
    local data_bytes = table.pack(string.byte(data_string, 1, -1))
    data_bytes.n = nil
    return data_bytes
end


---A helper that wraps a list of bytes with an index,
---@param packet_data PacketDataString
---@return PacketReader
local function new_packet_reader(packet_data)
    local bytes = packet_data_string_to_bytes(packet_data)
    ---@class PacketReader
    local reader = {
        bytes = bytes,  ---@type PacketDataBytes
        index = 1,      ---@type integer
    }
    return reader
end


---@param song Song     Will be modified by the function
---@param packet_data PacketDataString
local function add_instructions_to_song_from_packet(song, packet_data)

    local reader = new_packet_reader(packet_data)

    local modifiable_instructions =  song.packet_decoder_info.instructions_with_modifier_ids
    local packet_start_time = vlq_to_int_from_reader(reader)
    repeat
        local instruction_start_delta = vlq_to_int_from_reader(reader)
        local track_index = vlq_to_int_from_reader(reader)
        if track_index then -- Track index is provided. This is a normal instruction

            local duration = vlq_to_int_from_reader(reader)
            local note = vlq_to_int_from_reader(reader)
            local start_velocity = vlq_to_int_from_reader(reader)

            ---@type Instruction
            local instruction = {
                start_time = instruction_start_delta + packet_start_time,
                track_index = track_index,
                duration = duration,
                note = note,
                start_velocity = start_velocity,
                modifiers = {}
            }

            local assigned_instruction_modifier_id = vlq_to_int_from_reader(reader)
            if assigned_instruction_modifier_id then
                modifiable_instructions[assigned_instruction_modifier_id] = instruction
            end

            if track_index == 0 then -- this instruction is a song-level meta event. Let's populate the meta data field
                instruction.meta_event_data = {}
                local num_fields_to_get = vlq_to_int_from_reader(reader)
                for i = 1, num_fields_to_get do
                    local meta_key = bytes_with_len_to_string_from_reader(reader)
                    local meta_val = vlq_to_int_from_reader(reader)
                    instruction.meta_event_data[meta_key] = meta_val
                end
            end

            table.insert(song.instructions, instruction)

        else -- Track index is nil, this is a modifier for an instruction we have (probably) already seen.

            local assigned_instruction_modifier_id = vlq_to_int_from_reader(reader)
            local modifier_type_id = vlq_to_int_from_reader(reader)
            local modifier_value = vlq_to_int_from_reader(reader)

            local modifier_type = packet_enums_api.modifier_number_to_key[modifier_type_id]

            if modifiable_instructions[assigned_instruction_modifier_id] and modifier_type then

                local un_deltaed_start_time = instruction_start_delta + packet_start_time + modifiable_instructions[assigned_instruction_modifier_id].start_time

                ---@type InstructionModifier
                local modifier = {
                    start_time = un_deltaed_start_time,
                    type = modifier_type,
                    value = modifier_value
                }

                table.insert(modifiable_instructions[assigned_instruction_modifier_id].modifiers, modifier)
            end
        end
    until reader.index > #reader.bytes
end

--- Returns a config packet
---
--- Does nothing with the config cache library. We're assumeing whoever built this packet built it ready-to-go. (Also this script will run on the viewer anyways, so no access to the cache stuff anyways.)
---@param packet_data PacketDataString
---@return SongPlayerConfig
local function new_config_from_packet(packet_data)
    ---@type SongPlayerConfig
    local config_data = {}

    local reader = new_packet_reader(packet_data)

    local source_pos_bool_list = vlq_to_int_from_reader(reader)
    if source_pos_bool_list == nil then
        -- The boolean list used to flag info about the source is missing. Source info was not provided.
    else
        local bool_list = int_to_bool_list(source_pos_bool_list, 7)
        local source_is_entity = bool_list[1]
        if source_is_entity then
            local flip_uuid_int_1 = bool_list[4]
            local flip_uuid_int_2 = bool_list[5]
            local flip_uuid_int_3 = bool_list[6]
            local flip_uuid_int_4 = bool_list[7]

            local uuid_part_1 = vlq_to_int_from_reader(reader) * (flip_uuid_int_1 and -1 or 1)
            local uuid_part_2 = vlq_to_int_from_reader(reader) * (flip_uuid_int_2 and -1 or 1)
            local uuid_part_3 = vlq_to_int_from_reader(reader) * (flip_uuid_int_3 and -1 or 1)
            local uuid_part_4 = vlq_to_int_from_reader(reader) * (flip_uuid_int_4 and -1 or 1)

            local uuid_string = client.intUUIDToString(uuid_part_1, uuid_part_2, uuid_part_3, uuid_part_4)

            local success, possible_entity = pcall(world.getEntity, uuid_string)
            if success and possible_entity then
                config_data.source_entity = possible_entity
            else
                print_debug("There was an error getting the entity with uuid: " .. uuid_string, true)
                if not success
                    then print_debug("world.getEntity returned this error: " .. possible_entity, true)
                    else print_debug("world.getEntity returned nil (Entity not loaded).", true)
                end
            end

        else
            local flip_x = bool_list[2]
            local flip_y = bool_list[3]
            local flip_z = bool_list[4]
            local add_half_x = bool_list[5]
            local add_half_y = bool_list[6]
            local add_half_z = bool_list[7]

            local abs_floor_x = vlq_to_int_from_reader(reader)
            local abs_floor_y = vlq_to_int_from_reader(reader)
            local abs_floor_z = vlq_to_int_from_reader(reader)

            local source_x_pos = (abs_floor_x + (add_half_x and 0.5 or 0)) * (flip_x and -1 or 1)
            local source_y_pos = (abs_floor_y + (add_half_y and 0.5 or 0)) * (flip_y and -1 or 1)
            local source_z_pos = (abs_floor_z + (add_half_z and 0.5 or 0)) * (flip_z and -1 or 1)

            config_data.source_pos = vec(source_x_pos, source_y_pos, source_z_pos)
            -- print_debug(config_data.source_pos)
        end
    end

    local default_normal_instrument_name = bytes_with_len_to_string_from_reader(reader)
    local default_percussion_instrument_name = bytes_with_len_to_string_from_reader(reader)

    config_data.default_normal_instrument = ( default_normal_instrument_name and { name = default_normal_instrument_name } or nil )
    config_data.default_percussion_instrument = ( default_percussion_instrument_name and { name = default_percussion_instrument_name } or nil )

    local num_configed_track_instruments = vlq_to_int_from_reader(reader)
    if num_configed_track_instruments and num_configed_track_instruments > 0 then
        config_data.instrument_selections = {}
        for _ = 1, num_configed_track_instruments do
            local track_number = vlq_to_int_from_reader(reader)
            local instrument_name = bytes_with_len_to_string_from_reader(reader)
            config_data.instrument_selections[track_number] = { name = instrument_name }
            print_debug("config assigned instrument " .. instrument_name .. " to track " .. tostring(track_number))
        end
    end

    config_data.primary_update_event_key = bytes_with_len_to_string_from_reader(reader)
    config_data.fallback_update_event_key = bytes_with_len_to_string_from_reader(reader)

    -- local boolean_configs = int_to_bool_list(vlq_to_int_from_reader(reader), 1)
    -- config_data.play_immediately = boolean_configs[1]

    return config_data
end

--- Creates and returns a new song from a header packet.
---@param packet_data_string PacketDataString
---@return Song
local function new_song_from_header_packet(packet_data_string)
    local reader = new_packet_reader(packet_data_string)

    local name = bytes_with_len_to_string_from_reader(reader)
    local duration = vlq_to_int_from_reader(reader)

    local num_tracks = vlq_to_int_from_reader(reader)
    local track_type_id_flags = int_to_bit_list(vlq_to_int_from_reader(reader), num_tracks)
    ---@type Track[]
    local tracks = {}
    for i, type in ipairs(track_type_id_flags) do
        tracks[i] = {instrument_type_id = type}
    end

    local buffer_delay = vlq_to_int_from_reader(reader)

    ---@type Song
    local incoming_song = {
        name = name,
        duration = duration,
        tracks = tracks,
        instructions = {},
        buffer_delay = buffer_delay,
        buffer_start_time = nil, -- will be auto-filled by player.lua once it gets its first instruction.
        packet_decoder_info = {
            instructions_with_modifier_ids = {}
        }
    }

    return incoming_song
end

---@type table<ControlPacketCode, fun(controller:SongPlayerController, reader:PacketReader)>
local control_packet_handelers = {
    [packet_enums_api.control_packet_codes.start] = function(controller, _)  controller:play() end,
    [packet_enums_api.control_packet_codes.stop] = function(controller, _)   controller:stop() end,
    [packet_enums_api.control_packet_codes.remove] = function(_, _)
        -- This controll code is for network management. It tells a client they can delete a song we've sent
    end,
}

---@param controller SongPlayerController
---@param packet_data PacketDataString
---@return SongPlayerController
local function controll_player_from_packet(controller, packet_data)
    local reader = new_packet_reader(packet_data)
    local control_code = vlq_to_int_from_reader(reader)
    if control_packet_handelers[control_code] then
        control_packet_handelers[control_code](controller, reader)
    else
        error("Unrecognized control code `"..tostring(control_code).."`")
    end

    return controller
end

---@class PacketDecoderInfo -- Stored inside a Song so that we can have information about any ongoing decoding processes
---@field instructions_with_modifier_ids table<integer, Instruction>

---@class PacketDecoderApi
local packet_receiver_api = {
    new_song_from_header_packet = new_song_from_header_packet,
    new_config_from_packet = new_config_from_packet,
    add_instructions_to_song_from_packet = add_instructions_to_song_from_packet,
    controll_player_from_packet = controll_player_from_packet
}

return packet_receiver_api
