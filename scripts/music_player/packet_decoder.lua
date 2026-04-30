local packet_enums_api = require("./packet_enums") ---@type PacketEnumsAPI

-- decoder creates processed songs and configs for those songs.

-- There should be no ping functions here. This entire file must be runable on the viewer.


local do_debug_prints = false
local function print_debug(...) if do_debug_prints then print(...) end end
local function printTable_debug(...) if do_debug_prints then printTable(...) end end
local function print_host(...) if host:isHost() or do_debug_prints then print(...) end end


---A hacky way to combine two int-indexed tables
---@generic T:table
---@param table_1 T     This table is modified to include table_2's contents
---@param table_2 table
---@return T
local function union_tables(table_1, table_2)
    for _, v in ipairs(table_2) do
        table.insert(table_1, v)
    end
    return table_1
end

---Convert an integer (or nil) into a variable-length-quantity byte list
---@param integer integer?
---@return Byte[]
local function int_to_vlq(integer)
    if integer == nil then
        -- 0x80 (10000000) is not a valid first byte in the sequence.
        -- The first byte will either be `0x00`, or have a `1` somewhere in the data to start the number.
        -- 0x08 is legal in the middle of the sequence, but never as the initial.
        -- We can use this exception to represent nils in our packets.
        return { 0x80 }
    end
    local bytes = { integer % 128 }
    integer = math.floor(integer / 128)
    while integer > 0 do
        table.insert(bytes, 1, 0x80 + (integer % 128))
        integer = math.floor(integer / 128)
    end
    return bytes
end

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
    local str = string.char(table.unpack( reader.bytes, reader.index, reader.index+len_string-1 ))
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

---Converts a table of bytes (ints from 0 to 255) into a string
---@param data_bytes PacketDataBytes
---@return PacketDataString
local function packet_data_bytes_to_string(data_bytes)
    local data_string = string.char(table.unpack(data_bytes))
    return data_string
end

---Converts a string into a table of bytes
---@param data_string PacketDataString
---@return PacketDataBytes
local function packet_data_string_to_bytes(data_string)
    local data_bytes = table.pack(string.byte(data_string, 1, -1))
    data_bytes.n = nil
    return data_bytes
end





-- ---Immediatly converts an entire ProcessedSong and any config data into a list of packets
-- ---@param processed_song Song
-- ---@param player_config SongPlayerConfig
-- ---@return BundledPacket[]
-- local function song_to_packets(processed_song, player_config)
--     ---A unique ID for each song since the avatar loaded.
--     local transfered_song_id = songs_turned_into_packets_so_far
--     songs_turned_into_packets_so_far = songs_turned_into_packets_so_far +1

--     local all_data_packets, buffer_delay =  packet_encoder_api.build_data_packets_and_buffer_time(processed_song)
--     local header_packet = packet_encoder_api.build_header_packets(processed_song, buffer_delay)
--     local config_packet = packet_encoder_api.build_config_packet(player_config)

--     ---@type BundledPacket[]
--     local final_packet_list = {}
--     if (#header_packet + #config_packet) < max_packet_length then -- there is enough space to combine the header and config packets.

--         -- TODO: now that we're sending many small packets quickly, instead of large packets slower, is it worth while to combine header and config packets?

--         local joined_header_and_config = {}
--         union_tables(joined_header_and_config, header_packet)
--         union_tables(joined_header_and_config, config_packet)

--         table.insert(final_packet_list, {
--             transfered_song_id = transfered_song_id,
--             packet_type = packet_enums_api.packet_type_ids.header,
--             packet_data_string = packet_data_bytes_to_string(joined_header_and_config)
--         })
--     else
--         table.insert(final_packet_list, {
--             transfered_song_id = transfered_song_id,
--             packet_type = packet_enums_api.packet_type_ids.header,
--             packet_data_string = packet_data_bytes_to_string(header_packet)
--         })
--         table.insert(final_packet_list, {
--             transfered_song_id = transfered_song_id,
--             packet_type = packet_enums_api.packet_type_ids.config,
--             packet_data_string = packet_data_bytes_to_string(config_packet)
--         })
--     end

--     for _, data_packet in ipairs(all_data_packets) do
--         table.insert(final_packet_list, {
--             transfered_song_id = transfered_song_id,
--             packet_type = packet_enums_api.packet_type_ids.data,
--             packet_data_string = packet_data_bytes_to_string(data_packet)
--         })
--     end

--     return final_packet_list
-- end

local control_packet_codes = packet_enums_api.control_packet_codes

---@param control_code ControlPacketCode
---@return PacketDataString
local function make_control_packet(control_code)
    return packet_data_bytes_to_string( int_to_vlq(control_code) )
end

-- The colection of songs received from the Host (or whatever called add_packet_to_song).
-- These are indexed by a host-controlled integer, and are uniquely identifiable in this way.
---@type table<integer, {song: Song, player: SongPlayerController}>
local collected_incoming_songs = {}

-- list of transfer IDs that we must have missed
--
-- Allows us to throw a warning the first time, and ignore followup missing songs.
---@type table<integer, boolean>
local missed_incoming_songs = {}







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

---Reads a data packet out of a Reader.
---@param reader PacketReader           Where the packet id and transfer song ID have already been read
---@param transfered_song_id integer    Index into collected_incoming_songs
local function receive_data_packet(reader, transfered_song_id)
    if not collected_incoming_songs[transfered_song_id] then
        if not missed_incoming_songs[transfered_song_id] then
            print_debug("Received a data packet for song with transfer ID `"..tostring(transfered_song_id).."` before receiving a header packet for the song. Future lost data packets for this song will be ignored.")
            missed_incoming_songs[transfered_song_id] = true
        end
        return
    end
    local song = collected_incoming_songs[transfered_song_id].song
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

            table.insert(song.instructions, instruction)

        else -- Track index is nil, this is a modifier for an instruction we have (probably) already seen.

            local assigned_instruction_modifier_id = vlq_to_int_from_reader(reader)
            local modifier_type_id = vlq_to_int_from_reader(reader)
            local modifier_value = vlq_to_int_from_reader(reader)

            local modifier_type = packet_enums_api.modifier_number_to_key[modifier_type_id]

            if modifiable_instructions[assigned_instruction_modifier_id] and modifier_type then

                local un_deltaed_start_time = instruction_start_delta + packet_start_time + modifiable_instructions[assigned_instruction_modifier_id].start_time

                ---@type NoteModifier
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

---Reads a config packet out of a Reader.
---Returns nothing, but modifies collected_incoming_songs[transfered_song_id]
---@param reader PacketReader           Where the packet id and transfer song ID have already been read
---@param transfered_song_id integer    Index into collected_incoming_songs
local function receive_config_packet(reader, transfered_song_id)
    ---@type SongPlayerConfig
    local config_data = {}

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
                print_debug("There was an error getting the entity with uuid:", uuid_string)
                if not success
                    then print_debug("world.getEntity returned this error:", possible_entity)
                    else print_debug("world.getEntity returned nil (Entity not loaded).")
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
            print_debug("config assigned", instrument_name, "to track", track_number)
        end
    end

    config_data.primary_update_event_key = bytes_with_len_to_string_from_reader(reader)
    config_data.fallback_update_event_key = bytes_with_len_to_string_from_reader(reader)

    local boolean_configs = int_to_bool_list(vlq_to_int_from_reader(reader), 1)
    config_data.play_immediately = boolean_configs[1]

    if not collected_incoming_songs[transfered_song_id].player then
        -- This config packet must be inside of a header packet. It is our job to create the player.

        ---@type SongPlayerAPI
        local player_api = require("./player")
        collected_incoming_songs[transfered_song_id].player =
            player_api.new_player(collected_incoming_songs[transfered_song_id].song, config_data)
    else
        collected_incoming_songs[transfered_song_id].player.set_new_config(config_data)
    end
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

    -- collected_incoming_songs[transfered_song_id] = {
    --     song = incoming_song,
    --     player = nil
    -- }

    -- if reader.index <= #reader.bytes then -- There is still data in the reader, the rest is config data.
    --     receive_config_packet(reader, transfered_song_id)
    -- else
    --     -- there is no config data, let's initilize a blank player

    --     ---@type SongPlayerAPI
    --     local player_api = require("./player")
    --     collected_incoming_songs[transfered_song_id].player =
    --         player_api.new_player(collected_incoming_songs[transfered_song_id].song, nil)
    -- end

    return incoming_song
end

---@type table<ControlPacketCode, fun(controller:SongPlayerController, reader:PacketReader)>
local control_packet_handelers = {
    [control_packet_codes.start] = function(controller, _)  controller:play() end,
    [control_packet_codes.stop] = function(controller, _)   controller:stop() end,
    [control_packet_codes.remove] = function(_, _)
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

    ---@type fun(partial_song:Song, packet_data:PacketDataString):Song
    add_config_to_song_from_packet = function(partial_song, packet_data) return {} end,

    ---@type fun(partial_song:Song, packet_data:PacketDataString):Song
    add_instructions_to_song_from_packet = function(partial_song, packet_data)

        return {}
    end,

    controll_player_from_packet = controll_player_from_packet
}

return packet_receiver_api
