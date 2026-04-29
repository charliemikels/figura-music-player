local packet_decoder_api = require("./packet_decoder")  ---@type PacketDecoderApi
local packet_encoder_api = require("./packet_encoder")  ---@type PacketEncoderApi
local packet_enums_api   = require("./packet_enums")    ---@type PacketEnumsAPI

-- In bytes. (-2 because storing packets as a string adds 2 bytes to encode the packet string's length)
local max_packet_length = packet_encoder_api.get_max_packet_length()

-- How long the ping system should try to wait before sending another packet.
-- (Tick event adds 50 milis (1/20th of a second) of possible drift to account for.)
local target_milis_between_packets = packet_encoder_api.get_target_milis_between_packets()


local do_debug_prints = false
local function print_debug(...) if do_debug_prints then print(...) end end
local function printTable_debug(...) if do_debug_prints then printTable(...) end end
local function print_host(...) if host:isHost() or do_debug_prints then print(...) end end


local songs_turned_into_packets_so_far = 0  -- used to build a unique ID number for each transfered song


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

---@alias PacketDataBytes Byte[]

--- When sending raw data through pings, Strings are far more efficient than tables.
---
--- The final size will be the length of the SongPacket table + 2 bytes for the string's length info.
---@alias PacketDataString string

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


local packet_ids = packet_enums_api.packet_type_ids

---@type table<string, integer>
local modifier_type_to_number_lookup = {
    volume = 1,
    pitch_wheel = 2,
    -- pan = 3,
}


---Immediatly converts an entire ProcessedSong and any config data into a list of packets
---@param processed_song Song
---@param player_config SongPlayerConfig
---@return BundledPacket[]
local function song_to_packets(processed_song, player_config)
    ---A unique ID for each song since the avatar loaded.
    local transfered_song_id = songs_turned_into_packets_so_far
    songs_turned_into_packets_so_far = songs_turned_into_packets_so_far +1

    local all_data_packets, buffer_delay =  packet_encoder_api.build_data_packets_and_buffer_time(processed_song)
    local header_packet = packet_encoder_api.build_header_packets(processed_song, buffer_delay)
    local config_packet = packet_encoder_api.build_config_packet(player_config)

    ---@type BundledPacket[]
    local final_packet_list = {}
    if (#header_packet + #config_packet) < max_packet_length then -- there is enough space to combine the header and config packets.

        -- TODO: now that we're sending many small packets quickly, instead of large packets slower, is it worth while to combine header and config packets?

        local joined_header_and_config = {}
        union_tables(joined_header_and_config, header_packet)
        union_tables(joined_header_and_config, config_packet)

        table.insert(final_packet_list, {
            transfered_song_id = transfered_song_id,
            packet_type = packet_ids.header,
            packet_data_string = packet_data_bytes_to_string(joined_header_and_config)
        })
    else
        table.insert(final_packet_list, {
            transfered_song_id = transfered_song_id,
            packet_type = packet_ids.header,
            packet_data_string = packet_data_bytes_to_string(header_packet)
        })
        table.insert(final_packet_list, {
            transfered_song_id = transfered_song_id,
            packet_type = packet_ids.config,
            packet_data_string = packet_data_bytes_to_string(config_packet)
        })
    end

    for _, data_packet in ipairs(all_data_packets) do
        table.insert(final_packet_list, {
            transfered_song_id = transfered_song_id,
            packet_type = packet_ids.data,
            packet_data_string = packet_data_bytes_to_string(data_packet)
        })
    end

    return final_packet_list
end

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
---@param bytes PacketDataBytes
---@return PacketReader
local function new_packet_reader(bytes)
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

---Parces a header packet out of a Reader. Packet type and transfered_song_id have already been received since they start every packet.
---@param reader PacketReader           Where the packet id and transfer song ID have already been read
---@param transfered_song_id integer    Index into collected_incoming_songs
---@return Song        A processed song that likely has no instructions
local function receive_header_packet(reader, transfered_song_id)
    -- This is a header packet. Even if the song with this ID already exists, the host is clearly sending a new one. Purge this data.
    -- The host should never send a 2nd song with the same ID, but it might happen if the host has reloaded their script.
    -- Purging this data means we loose controll over it, but the host must have already lost control, so it's kinda OK actualy.
    collected_incoming_songs[transfered_song_id] = {}

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
    local incoming_processed_song = {
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

    collected_incoming_songs[transfered_song_id] = {
        song = incoming_processed_song,
        player = nil
    }

    if reader.index <= #reader.bytes then -- There is still data in the reader, the rest is config data.
        receive_config_packet(reader, transfered_song_id)
    else
        -- there is no config data, let's initilize a blank player

        ---@type SongPlayerAPI
        local player_api = require("./player")
        collected_incoming_songs[transfered_song_id].player =
            player_api.new_player(collected_incoming_songs[transfered_song_id].song, nil)
    end

    return incoming_processed_song
end

---@type table<ControlPacketCode, fun(transfered_song_id:integer)>
local control_packet_handelers = {
    [control_packet_codes.start] = function(transfered_song_id)
        if collected_incoming_songs[transfered_song_id] then
            collected_incoming_songs[transfered_song_id].player:play()
        end
    end,
    [control_packet_codes.stop] = function(transfered_song_id)
        if collected_incoming_songs[transfered_song_id] then
            collected_incoming_songs[transfered_song_id].player:stop()
        end
    end,
    [control_packet_codes.remove] = function(transfered_song_id)
        if collected_incoming_songs[transfered_song_id] then
            collected_incoming_songs[transfered_song_id] = nil
        end
    end,
}


---@param reader PacketReader           Where the packet id and transfer song ID have already been read
---@param transfered_song_id integer    Index into collected_incoming_songs
local function receive_control_packet(reader, transfered_song_id)
    local control_code = vlq_to_int_from_reader(reader)
    if control_packet_handelers[control_code] then
        control_packet_handelers[control_code](transfered_song_id)
    else
        print_debug("unrecognized controll code `"..tostring(control_code).."` for transfered song #"..tostring(transfered_song_id))
    end
end

-- function lookup table for packet receiver
---@type table<PacketTypeIDs, fun(reader: PacketReader, transfered_song_id: integer)>
local packet_receiving_functions = {
    [packet_ids.control] = receive_control_packet,
    [packet_ids.header] = receive_header_packet,
    [packet_ids.data] = receive_data_packet,
    [packet_ids.config] = receive_config_packet,
}


local local_receive_packet_loop_is_running = false
local incoming_packed_packets = {}  ---@type {transfer_id:integer, packet_type:PacketTypeIDs, packet_data:PacketDataString}[]

--- Primary function to receive packets. Distributes packets to the correct receiving functions.
---
--- There seems to be a rare chance that two pings may be bundled and processed in the same tick.
--- By running in a tick event, we ensure that, on the off chance we receive two pings on the same tick, that we process them on diffrent ticks.
---@see local_receive_packet
local function local_receive_packet_loop()
    local packed_packet_data = table.remove(incoming_packed_packets, 1)   -- table.remove is usualy inneficient when popping from the front. But we shouldn't have more than like 2 packets in here at a time, so should be fine.

    local packet_data = packet_data_string_to_bytes(packed_packet_data.packet_data)
    local reader = new_packet_reader(packet_data)
    local packet_id = packed_packet_data.packet_type
    local transfered_song_id = packed_packet_data.transfer_id
    packet_receiving_functions[packet_id](reader, transfered_song_id)

    if #incoming_packed_packets == 0 then
        events.TICK:remove(local_receive_packet_loop)
        local_receive_packet_loop_is_running = false
    end
end

--- Receives a packet and passes it to the TICK event loop.
---
--- Pings appear to have their own instruction limits sepperate from TICK or RENDER or whatever, but this limit isn't displayed anywhere.
--- Furehtermore, if we send pings too quickly, it seems that pings may get bundled and processed on the same tick, meaning the instruction
--- cost of pings can occasionaly double without warning.
---
--- Dispatch to our own TICK loop, so that we can control when we process these pings, and prevent doubleing up.
---
--- @see avatar:getCurrentInstructions
---
--- That said, if my assumption is correct, then the ping "event" gives us free instructions to work with. It may be worth while
--- to find a new way to process pings so that we don't share TICK instructions with the rest of the avatar.
---
---@see local_receive_packet_loop
---@param transfer_id integer
---@param packet_type PacketTypeIDs
---@param packed_packet_data PacketDataString
local function local_receive_packet(transfer_id, packet_type, packed_packet_data)
    table.insert(incoming_packed_packets, {transfer_id = transfer_id, packet_type = packet_type, packet_data = packed_packet_data})
    if not local_receive_packet_loop_is_running then
        local_receive_packet_loop_is_running = true
        events.TICK:register(local_receive_packet_loop)

    end
end

--- primary ping function. It receives a packet and sends it off for processing
--- On the off chance that pings need to be unique (idk at the moment): `TL_FMP` → Tanner Limes Figura Mucic Player
---@param transfer_id integer
---@param packet_type PacketTypeIDs
---@param incoming_packet PacketDataString
function pings.TL_FMP_receive_packet(transfer_id, packet_type, incoming_packet)
    local_receive_packet(transfer_id, packet_type, incoming_packet)
end

---@param transfer_id integer
---@param packet_type PacketTypeIDs
---@param outgoing_packed_packet PacketDataString
local function ping_packet_immediatly(transfer_id, packet_type, outgoing_packed_packet)
    pings.TL_FMP_receive_packet(transfer_id, packet_type, outgoing_packed_packet)
end

---@alias BundledPacket {transfered_song_id: integer, packet_type: PacketTypeIDs, packet_data_string: PacketDataString}    -- a light weight way to keep a packet tied to it's packet ID and transfer ID.

---@alias PacketQueue BundledPacket[]

local outgoing_packet_queue_index = 1   ---@type integer        Index into outgoing_packet_queue. Using an index so that we don't have to remove items from the list.
local outgoing_bundled_packets_queue = {}        ---@type PacketQueue

local ping_loop_start_time

local ping_loop_identifier = "TL_FMP_song_data_ping_loop"

local function stop_and_cleanup_packet_ping_loop()
    outgoing_bundled_packets_queue = {}
    outgoing_packet_queue_index = 1
    ping_loop_start_time = nil
    events.WORLD_TICK:remove(ping_loop_identifier)
end

--- Searches upcoming packets in outgoing_packet_queue and skips/removes any that match transfered_song_id_to_cancel
---
--- Only really useful if there are multiple songs in the queue, which should never happen if the HOST is only useing ui.lua.
--- But if the host is doing something clever with multiple players, or multiple UIs, this fn is nessesary.
---
--- Item removal logic based on https://stackoverflow.com/a/53038524
---@see stop_and_cleanup_packet_ping_loop
---@param transfered_song_id_to_cancel integer
local function remove_packets_from_outgoing_queue_by_transfer_id(transfered_song_id_to_cancel)
    local size_of_hole = 0

    for search_index =
        outgoing_packet_queue_index, -- we can ignore packets that we've already sent.
        #outgoing_bundled_packets_queue
    do
        local should_delete_packet = outgoing_bundled_packets_queue[search_index].transfered_song_id == transfered_song_id_to_cancel
        if not should_delete_packet then
            if (size_of_hole > 0) then
                -- We want to keep this value, but there's a hole in the list. Slide the value so that we fill the hole.
                outgoing_bundled_packets_queue[search_index - size_of_hole] = outgoing_bundled_packets_queue[search_index]
                outgoing_bundled_packets_queue[search_index] = nil
            end
        else
            if outgoing_packet_queue_index == search_index then
                -- In this situation, we can just skip the packet instead of modifying the table
                outgoing_packet_queue_index = outgoing_packet_queue_index + 1
            else
                outgoing_bundled_packets_queue[search_index] = nil
                size_of_hole = size_of_hole + 1
            end
        end
    end

    -- Any nils we created should have propigated to the end of the queue by now.
    -- But since lua considers the length to the index of the last non-nil value,
    -- it effectively means the list has shrunk, so #outgoing_packet_queue sould
    -- accuratly represent the new size.
    if outgoing_packet_queue_index > #outgoing_bundled_packets_queue then stop_and_cleanup_packet_ping_loop() end
end

--- outgoing_packet_queue needs to stay in order, so it's simpler to keep an index
--- (outgoing_packet_queue_index) rather than to actualy remove packets from the list.
--- But this does mean that outgoing_packet_queue will constantly grow since no items
--- are removed.
---
--- Typicaly this isn't really a problem, because the queue gets reset  whenever we
--- reach the end, but if some power user is constantly dumping stuff into the network,
--- we might not reach it.
---
--- It's at least nice to have this function around
local function remove_already_sent_packets_from_outgoing_packet_queue()
    if outgoing_packet_queue_index == 1 then
        -- outgoing_packet_queue has no sent packets
        return
    end

    -- table.move() isn't available in Lua 5.2, but combineing pack and unpack should get us close enough
    local new_outgoing_packet_queue = table.pack(table.unpack(outgoing_bundled_packets_queue, outgoing_packet_queue_index))
    new_outgoing_packet_queue.n = nil   -- table.pack adds an `n` field that we don't want.
    outgoing_bundled_packets_queue = new_outgoing_packet_queue   ---@type PacketQueue

    outgoing_packet_queue_index = 1
    if outgoing_packet_queue_index > #outgoing_bundled_packets_queue then stop_and_cleanup_packet_ping_loop() end
end

--- Host-side event loop to emit pings from the ping queue
local function ping_loop()
    if ping_loop_start_time + (target_milis_between_packets * (outgoing_packet_queue_index -1)) < client:getSystemTime() then
        -- we can emit another packet
        -- Note that this condition may be true in situations where the time between
        -- two packets is slightly _less_ than target_milis_between_packets.
        -- It will still be the average, but enabling us to send a packet slightly
        -- early will avoid the "slip" caused from missing the perfect time to emmit a packet.

        print_debug("pinging packet #"..tostring(outgoing_packet_queue_index).."/"..tostring(#outgoing_bundled_packets_queue).."…")

        pings.TL_FMP_receive_packet(
            outgoing_bundled_packets_queue[outgoing_packet_queue_index].transfered_song_id,
            outgoing_bundled_packets_queue[outgoing_packet_queue_index].packet_type,
            outgoing_bundled_packets_queue[outgoing_packet_queue_index].packet_data_string
        )

        outgoing_packet_queue_index = outgoing_packet_queue_index + 1

        -- check if list is empty
        if outgoing_packet_queue_index > #outgoing_bundled_packets_queue then print_host("All pings sent."); stop_and_cleanup_packet_ping_loop() end
    end
end

--- Reusable start-the-ping-loop function. Does not start the loop if it's already running
local function check_or_start_ping_loop()
    if ping_loop_start_time then
        return
    else
        print_debug("Starting ping loop")
        events.WORLD_TICK:register(ping_loop, ping_loop_identifier)
        ping_loop_start_time = client:getSystemTime()
    end
end

---Adds a single packet to the packet queue.
---
--- Probably unnessesary. most of the time that we want to ping something,
--- we either want to ping it ASAP, or we're pinging bulk data.
---@param outgoing_bundled_packet BundledPacket
local function ping_packet(outgoing_bundled_packet)
    table.insert(outgoing_bundled_packets_queue, outgoing_bundled_packet)
    check_or_start_ping_loop()
end

---Add several packets to the packet queue
---@param outgoing_bundled_packets BundledPacket[]
local function ping_packets(outgoing_bundled_packets)
    for _, bundled_packet in ipairs(outgoing_bundled_packets) do
        table.insert(outgoing_bundled_packets_queue, bundled_packet)
    end
    check_or_start_ping_loop()
end

---@return number
local function outgoing_packet_queue_progress()
    if #outgoing_bundled_packets_queue == 0 then return 1 end
    return outgoing_packet_queue_index / #outgoing_bundled_packets_queue
end

--- A SongPlayer wrapper that plays the a song on all clients (viewers and host).
---
--- Use this instead of manualy working with the networking / packet building process.
---
--- Host Only. May turn a song into packets (expensive) and call ping functions.
---@param processed_song Song
---@param player_config SongPlayerConfig
---@return SongPlayerController
local function new_network_song_player(processed_song, player_config)
    local song_player_api = require("./player")      ---@type SongPlayerAPI
    if not host:isHost() then -- The caller is a viewer. They will not be able to do any syncronization with other clients, so just give them a normal player.
        return song_player_api.new_player(processed_song, player_config)
    end

    -- local our_song_player_controller = song_player_api.new_player(processed_song, player_config)
    -- ---@class SongPlayerController
    -- net_player = {}
    -- for k,fn in pairs(our_song_player_controller) do net_player[k] = fn end

    if processed_song.is_local then -- The song is local. we just need to tell the viewer to create a player and play the song.
        -- TODO
    else -- The song is not local. We need to turn the song into packets and send that over
        -- TODO
    end

    -- TODO: Set up the remote player. Immediatly ping the song's header packets (Or whatever method we need to do for local songs).
    --       This will be enough to create a remote/transfered player with an empty config.


    -- TODO: Get the remote player build a controller arround it. For most set functions, we'll need to ping data over. But we can also look at ourself for most other actions.


    -- TODO: Figure out how we want to represent local songs with a newtwork relationship.



    -- TODO: Remove play_immediatly as a config paramiter. We don't need to do magic to get things to play if we can just talk to the remote player with control codes.

    -- This wraper needs to
    --  - [ ] Know if a song will processable/accessable to client already. (If it's a local song)
    --      - [ ] Allways assume the client will need to build the data. (otherwise, caller could just use a normal player).
    --      - [ ] If song is non-local, convert the song into packets and know how to ping them.
    --      - [ ]
    --  - [ ] TODO: should we have sepparate host/client players? Honestly probably not. We can re-use the transfer-song ideas and only deal with the "remote" player. This wrapper will make it feel host-ish to the caller.




    -- ---@class NetworkedSongPlayer




    return {}
end

---@class SongNetworkingApi
---@field new_network_song_player fun(processed_song:Song, player_config:SongPlayerConfig):SongPlayerController
---@field song_to_packets       fun(processed_song:Song, player_config:SongPlayerConfig):BundledPacket[]
---@field local_receive_packet  fun(packed_packet_data:PacketDataString)
---@field ping_packets          fun(outgoing_packed_packets:PacketDataString[])
---@field outgoing_packet_queue_progress    fun():number
---@field play_transfered_song  fun(transfered_song_id:integer)         Sends a controll packet to play the selected song.
---@field stop_transfered_song  fun(transfered_song_id:integer)         Sends a controll packet to stop the selected song, and removes any remaining queued packets for the song.
---@field remove_transfered_song  fun(transfered_song_id:integer)       Sends a controll packet to delete the selected song. This simply removes the song from the transfered_songs list. A player playing this song may still hold onto it.
---@field cancel_all_pings fun()        Deletes all pings in the queued pings list and stops the update loop.
---@field get_player_for_transfered_song fun(transfered_song_id:integer):SongPlayerController  Treat this as read-only. Edits to this player will only be seen by the host.
---@field get_target_milis_between_packets fun():integer                Returns `target_milis_between_packets`, so that we can make time-estemations from packet rate.
return {
    new_network_song_player = new_network_song_player,
    song_to_packets = song_to_packets,
    local_receive_packet = local_receive_packet,    -- adds a packet to it's targeted song.
    ping_packets = ping_packets,
    outgoing_packet_queue_progress = outgoing_packet_queue_progress,
    play_transfered_song = function(transfered_song_id)
        ping_packet_immediatly(transfered_song_id, packet_ids.control, make_control_packet(control_packet_codes.start))
    end,
    stop_transfered_song = function(transfered_song_id)
        ping_packet_immediatly(transfered_song_id, packet_ids.control, make_control_packet(control_packet_codes.stop))
        remove_packets_from_outgoing_queue_by_transfer_id(transfered_song_id) -- Does not cancel the above packet, since ping_packet_immediatly bypasses the packet queue
    end,
    remove_transfered_song = function(transfered_song_id)
        ping_packet_immediatly(transfered_song_id, packet_ids.control, make_control_packet(control_packet_codes.remove))
    end,
    cancel_all_pings       = function() stop_and_cleanup_packet_ping_loop() end,
    get_player_for_transfered_song = function(transfered_song_id) return collected_incoming_songs[transfered_song_id] and collected_incoming_songs[transfered_song_id].player or nil end,
    get_target_milis_between_packets = function() return target_milis_between_packets end,
}
