
-- Ping limits:
-- Fewer than 32 pings in one second (~32 milis between packets min)
-- Fewer than 1024 bytes per second (~1 byte/mili)

local max_packet_length = 75-2            -- In bytes. (-2 because storing packets as a string adds 2 bytes to encode the packet string's length)
local target_milis_between_packets = 150   -- How long the ping system should try to wait before sending another packet. (Tick event adds 50 milis of possible drift to account for.)
-- ~6.6 packets/second, 75 bytes per packet, ~500 bytes per second. Roughly half of avatar's total ping quota.


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

---Converts a string into a table of bytes, where the length is placed just before the string.
---@param str string?
---@return Byte[]
local function string_to_bytes_with_len(str)
    if str == nil then return int_to_vlq(nil) end
    local tableized_string = table.pack( string.byte(str, 1, -1) )
    local tableized_length = int_to_vlq(tableized_string.n)
    tableized_string.n = nil
    return union_tables(tableized_length, tableized_string)
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
--- Used to assign percussion tracks to incomming songs
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

--- Effectively converts {1, 0, 1} → `101` → 5
---@param bits (1|0)[]
---@return integer
local function bit_list_to_number(bits)
    return tonumber(table.concat(bits), 2)
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

--- Effectively converts {true, false, true} → `101` → 5
---@param bools boolean[]
---@return integer
local function bool_list_to_number(bools)
    local bits = {}
    for index, bool in ipairs(bools) do bits[index] = (bool and 1 or 0) end
    return tonumber(table.concat(bits), 2)
end

---@alias SongPacket Byte[]

--- When sending raw data through pings, Strings are far more efficient than tables.
---
--- The final size will be the length of the SongPacket table + 2 bytes for the string's length info.
---@alias PackedSongPacket string Strings

---Converts a table of bytes (ints from 0 to 255) into a string
---@param unpacked_packet SongPacket
---@return PackedSongPacket
local function pack_packet(unpacked_packet)
    local packed_packet = string.char(table.unpack(unpacked_packet))
    return packed_packet
end

---Converts a string into a table of bytes
---@param packed_packet PackedSongPacket
---@return SongPacket
local function unpack_packet(packed_packet)
    local unpacked_packet = table.pack(string.byte(packed_packet, 1, -1))
    unpacked_packet.n = nil
    return unpacked_packet
    -- Shout out to using table.pack to unpack our packets, and table.unpack to pack out packets.
    -- emperor-palpatine-ironic.gif
end


---A helper that wraps a list of bytes with an index,
---@param bytes SongPacket
---@return PacketReader
local function new_packet_reader(bytes)
    ---@class PacketReader
    local reader = {
        bytes = bytes,  ---@type SongPacket
        index = 1,      ---@type integer
    }
    return reader
end

---@enum SongPacketTypeIDs
local packet_ids = {
    control = 0,   -- A very tiny packet to send a few simple control codes.
    header = 1, -- Includeds initial like name, duration, track_types
    data = 2,   -- Bulk of the packet stream
    config = 3, -- A packet that might appear to update a song's configuration
}

--- Builds a config packet out of a SongPlayerConfig table.
---
--- This can be used at any time to update a remote song's configuration.
---@param player_config SongPlayerConfig
---@return SongPacket
local function build_config_packet_body(player_config)

    local config_packet_body = {}

    -- Source Entity / Position data
    do
        -- Do block because this section is long and my code editor can auto nest this

        local source_table = {}
        -- 7 bools. First bool marks if source is an entity.
        -- If entity, next two bools unused, then last 4 bytes mark what parts of the uuid should be flipped.
        -- If not entity, next 3 bools are for flipping the sign, and the last 3 are for adding 0.5 to the end.
        --      On the receiving side, add the 0.5 before flipping the sign.
        local truth_table = {}
        local source_is_entity
        if player_config.source_entity then
            source_is_entity = true

            local uuid_int_1, uuid_int_2, uuid_int_3, uuid_int_4
            local flip_uuid_int_1 = false
            local flip_uuid_int_2 = false
            local flip_uuid_int_3 = false
            local flip_uuid_int_4 = false

            uuid_int_1, uuid_int_2, uuid_int_3, uuid_int_4 = client.uuidToIntArray(player_config.source_entity:getUUID())

            flip_uuid_int_1 = (uuid_int_1 < 0)
            flip_uuid_int_2 = (uuid_int_2 < 0)
            flip_uuid_int_3 = (uuid_int_3 < 0)
            flip_uuid_int_4 = (uuid_int_4 < 0)

            truth_table = { source_is_entity, false, false, flip_uuid_int_1, flip_uuid_int_2, flip_uuid_int_3, flip_uuid_int_4 }

            union_tables(source_table, int_to_vlq(bool_list_to_number(truth_table)))
            union_tables(source_table, int_to_vlq(math.floor(math.abs(uuid_int_1))))
            union_tables(source_table, int_to_vlq(math.floor(math.abs(uuid_int_2))))
            union_tables(source_table, int_to_vlq(math.floor(math.abs(uuid_int_3))))
            union_tables(source_table, int_to_vlq(math.floor(math.abs(uuid_int_4))))

        elseif player_config.source_pos then
            source_is_entity = false

            local abs_floor_x, abs_floor_y, abs_floor_z
            local flip_x
            local flip_y
            local flip_z
            local add_half_x
            local add_half_y
            local add_half_z

            flip_x = (player_config.source_pos.x < 0)
            flip_y = (player_config.source_pos.y < 0)
            flip_z = (player_config.source_pos.z < 0)

            -- We convert to ints through our packet system, but it would be
            -- pretty common for sounds to be at the center of a block. (coords ≈ n.5)
            -- So we need a wat to account for these situations

            local abs_pos_x = math.abs(player_config.source_pos.x)
            abs_floor_x = math.floor(abs_pos_x)
            add_half_x = 0.25 < (abs_pos_x - abs_floor_x) and (abs_pos_x - abs_floor_x) < 0.75

            local abs_pos_y = math.abs(player_config.source_pos.y)
            abs_floor_y = math.floor(abs_pos_y)
            add_half_y = 0.25 < (abs_pos_y - abs_floor_y) and (abs_pos_y - abs_floor_y) < 0.75

            local abs_pos_z = math.abs(player_config.source_pos.z)
            abs_floor_z = math.floor(abs_pos_z)
            add_half_z = 0.25 < (abs_pos_z - abs_floor_z) and (abs_pos_z - abs_floor_z) < 0.75


            truth_table = { source_is_entity, flip_x, flip_y, flip_z, add_half_x, add_half_y, add_half_z}
            union_tables(source_table, int_to_vlq(bool_list_to_number(truth_table)))
            union_tables(source_table, int_to_vlq(abs_floor_x))
            union_tables(source_table, int_to_vlq(abs_floor_y))
            union_tables(source_table, int_to_vlq(abs_floor_z))
        else
            -- no source data given at data at all send nil.
            union_tables(source_table, int_to_vlq( nil ))
        end

        union_tables(config_packet_body, source_table)
    end

    -- Default instruments
    union_tables(config_packet_body, string_to_bytes_with_len(
        player_config.default_normal_instrument
        and player_config.default_normal_instrument.name
        or nil
    ))
    union_tables(config_packet_body, string_to_bytes_with_len(
        player_config.default_percussion_instrument
        and player_config.default_percussion_instrument.name
        or nil
    ))
    -- TODO: serialize instrument params

    local instrument_selections = {}
    local configured_track_count = 0
    for track_id, selected_instrument in pairs(player_config.instrument_selections or {}) do
        configured_track_count = configured_track_count + 1
        union_tables(instrument_selections, int_to_vlq(track_id))
        union_tables(instrument_selections, string_to_bytes_with_len(selected_instrument.name))
        -- TODO: serialize instrument params
    end
    union_tables(config_packet_body, int_to_vlq(configured_track_count))
    union_tables(config_packet_body, instrument_selections)

    -- events
    union_tables(config_packet_body, string_to_bytes_with_len(player_config.primary_update_event_key))
    union_tables(config_packet_body, string_to_bytes_with_len(player_config.fallback_update_event_key))

    -- boolean-based-configs

    local boolean_configs = {
        (player_config.play_immediately and true or false),
    }
    union_tables(config_packet_body, int_to_vlq(bool_list_to_number(boolean_configs)))

    return config_packet_body
end

--- Builds a most of a header packet out of a processed song
---
--- It is missing buffer time information. That must be
--- appended to the end of this packet as a VLQ after the
--- rest of the song has been figured out
---
--- You probably want to use `song_to_packets` instead of calling this fn directly.
---
---@see song_to_packets
---@param processed_song ProcessedSong
---@return SongPacket
local function build_header_packet_without_buffer_delay(processed_song)
    local packet = {}
    union_tables(packet, string_to_bytes_with_len(processed_song.name))

    union_tables(packet, int_to_vlq(
        math.ceil(processed_song.duration) -- At 144FPS, the player can only update every 5ms ceil to drop sub-milisecond precission.
    ))

    local track_type_bits = {}
    for _, track in ipairs(processed_song.tracks) do
        table.insert(track_type_bits, track.instrument_type_id)
    end
    union_tables(packet, int_to_vlq(#track_type_bits))
    union_tables(packet, int_to_vlq(bit_list_to_number(track_type_bits)))
    return packet
end

---@type table<string, integer>
local modifier_type_to_number_lookup = {
    volume = 1,
    pitch_wheel = 2,
    -- pan = 3,
}

---@alias DataPacketPart Byte[] Can represent an instruction, or a modifier for an earlier instruction

--- For use with song_instruction_to_packet_parts()
---
--- A simple wraper so that I can reuse the "add modifier" code
---@param modifier NoteModifier                 The modifier to add
---@param instruction_modifier_list_id integer  The note ID to add this modifier to.
---@return {start_time: number, packet_part: DataPacketPart}
local function modifier_to_packet_part(modifier, instruction_start_time, instruction_modifier_list_id)
    ---@type DataPacketPart
    local modifier_packet_part = {}
    union_tables(modifier_packet_part, int_to_vlq(math.floor(modifier.start_time - instruction_start_time)))
    union_tables(modifier_packet_part, int_to_vlq(nil))
        -- nil signals that this is a modifier for an instruction we've (probably) already sent
        -- meta tracks in the song itself use track_id == 0, so we're safe to use nil
    union_tables(modifier_packet_part, int_to_vlq(instruction_modifier_list_id))
    union_tables(modifier_packet_part, int_to_vlq(modifier_type_to_number_lookup[modifier.type]))
    union_tables(modifier_packet_part, int_to_vlq(modifier.value))
    return {start_time = modifier.start_time, packet_part = modifier_packet_part}
end

---@param instruction Instruction
---@param packet_start_time number      The start time of the current packet. Used to calculate the delta for this instruction.
---@param modifiers_tracker table
---@return {instruction_part_and_start: {start_time: number, packet_part: DataPacketPart}, modifier_parts_and_starts: {start_time: number, packet_part: DataPacketPart}[] }
local function song_instruction_to_packet_parts(instruction, packet_start_time, modifiers_tracker)
    local modifier_packet_parts = {}

    local instruction_packet_part_and_start = {start_time = instruction.start_time, packet_part = {}}

    union_tables(instruction_packet_part_and_start.packet_part, int_to_vlq(math.floor(instruction.start_time - packet_start_time)))
    union_tables(instruction_packet_part_and_start.packet_part, int_to_vlq(instruction.track_index))
    union_tables(instruction_packet_part_and_start.packet_part, int_to_vlq(math.floor(instruction.duration)))
    union_tables(instruction_packet_part_and_start.packet_part, int_to_vlq(instruction.note))
    union_tables(instruction_packet_part_and_start.packet_part, int_to_vlq(instruction.start_velocity))

    if not (instruction.modifiers and next(instruction.modifiers)) then
        union_tables(instruction_packet_part_and_start.packet_part, int_to_vlq(nil))  -- no modifiers.
    else
        -- this instruction has modifiers
        -- Assign a unique note modifier tracker ID

        local instruction_modifier_list_id = modifiers_tracker.id_counter
        modifiers_tracker.id_counter = modifiers_tracker.id_counter + 1
        union_tables(instruction_packet_part_and_start.packet_part, int_to_vlq(instruction_modifier_list_id))


        -- Stores some modifiers sorted by type. Used to drop some modifiers and reduce temporal resolution
        ---@type table<string, {first_start_time: integer, total_added: integer, last_added: NoteModifier?, last_seen: NoteModifier}>
        local modifier_subset_tracker = {}

        -- make new packet parts for each modifier
        for _, modifier in ipairs(instruction.modifiers) do
            if not modifier_type_to_number_lookup[modifier.type] then
                if not modifiers_tracker.total_number_of_unrecognized_modifier_types_by_type[modifier.type] then
                    modifiers_tracker.total_number_of_unrecognized_modifier_types_by_type[modifier.type] = 1
                    print_debug("song_instruction_to_packet_parts: unrecognized modifier type: `"..tostring(modifier.type).."`. See Modifier", modifier, "in instruction", instruction)
                else
                    modifiers_tracker.total_number_of_unrecognized_modifier_types_by_type[modifier.type] = modifiers_tracker.total_number_of_unrecognized_modifier_types_by_type[modifier.type] + 1
                end
            else
                if not modifier_subset_tracker[modifier.type] then
                    -- first of this type.

                    table.insert(modifier_packet_parts, modifier_to_packet_part(
                        modifier,
                        instruction.start_time,
                        instruction_modifier_list_id
                    ))

                    modifier_subset_tracker[modifier.type] = {
                        first_start_time = modifier.start_time,
                        total_added = 1,
                        last_added = modifier,
                        last_seen = modifier
                    }

                else

                    if      modifier_subset_tracker[modifier.type].last_seen.start_time ~= modifier_subset_tracker[modifier.type].last_added.start_time
                        and modifier_subset_tracker[modifier.type].last_seen.start_time + (30) < modifier.start_time
                    then
                        -- The last_seen modifier was not added, but there is too much time between that last modifier and this modifier.
                        -- The last_seen modifier might have been a "bookend" modifier. We should re-include it just in case.

                        table.insert(modifier_packet_parts, modifier_to_packet_part(
                            modifier_subset_tracker[modifier.type].last_seen,
                            instruction.start_time,
                            instruction_modifier_list_id
                        ))
                        modifier_subset_tracker[modifier.type].total_added = modifier_subset_tracker[modifier.type].total_added + 1
                        modifier_subset_tracker[modifier.type].last_added = modifier_subset_tracker[modifier.type].last_seen
                    end


                    if  modifier.start_time >= (
                            modifier_subset_tracker[modifier.type].first_start_time
                            + (20 * modifier_subset_tracker[modifier.type].total_added)
                        )
                    then
                        -- this modifier is at the right time. Add it.

                        table.insert(modifier_packet_parts, modifier_to_packet_part(modifier, instruction.start_time, instruction_modifier_list_id))

                        modifier_subset_tracker[modifier.type].total_added = modifier_subset_tracker[modifier.type].total_added + 1
                        modifier_subset_tracker[modifier.type].last_added = modifier
                    end

                    modifier_subset_tracker[modifier.type].last_seen = modifier
                end
            end
        end

        -- Make sure the last modifier of each type was included.
        for _, modifier_subset_info in pairs(modifier_subset_tracker) do
            if modifier_subset_info.last_seen.start_time > modifier_subset_info.last_added.start_time then
                -- the modifier that was last added was not the last seen.
                -- Add in the last seen modifier so that we the bookends of this modifier list.
                table.insert(modifier_packet_parts, modifier_to_packet_part(modifier_subset_info.last_seen, instruction.start_time, instruction_modifier_list_id))
            end
        end
    end
    return {instruction_part_and_start = instruction_packet_part_and_start, modifier_parts_and_starts = modifier_packet_parts}
end

--- The big one that loops through all instructions, and their modifiers, and creates a series of packets.
---@see song_to_packets
---@param processed_song ProcessedSong
---@param transfered_song_id_vlq Byte[]?    -- If nil, then transferSong ID will not be added to to the packet
---@return SongPacket[] data_packets        Fully formed packets, ready to be packed and shipped.
---@return integer buffer_delay_in_milis
local function build_data_packets(processed_song, transfered_song_id_vlq)
    if not transfered_song_id_vlq then transfered_song_id_vlq = {} end

    --- A counter that lets us generate unique IDs for any note that has a modifier

    local modifiers_tracker = {
        id_counter = 0, ---@type integer A counter that lets us have a unique ID for every note that has a modifier in this song.
        total_number_of_unrecognized_modifier_types_by_type = {}  ---@type table<string, integer>
    }

    ---@type SongPacket[]
    local data_packets = {}
    local required_buffer_delay_in_milis = 0

    local current_packet_builder = {}
    ---@type {start_time: number, packet_part: DataPacketPart}[]
    local unhandled_modifiers_start_part_pairs = {}
    union_tables(current_packet_builder, int_to_vlq(packet_ids.data))
    union_tables(current_packet_builder, transfered_song_id_vlq)
    local packet_start_time = processed_song.instructions[1].start_time
    union_tables(current_packet_builder, int_to_vlq(math.floor(packet_start_time)))

    --- Checks if there is room for the proposed DataPacketPart to be included in the current Packet
    ---
    --- Also runs the bulk of the buffer time calculations
    ---@param proposed_packet_start_part_pair {start_time: number, packet_part: DataPacketPart}
    ---@param new_start_time number     The start time of the next packet, if one needs to be created.
    ---@return boolean instruction_packet_should_be_rebuilt
    local function check_and_make_room(proposed_packet_start_part_pair, new_start_time)
        local instruction_packet_should_be_rebuilt = false
        if #current_packet_builder + #proposed_packet_start_part_pair.packet_part >= max_packet_length then
            -- This next packet part would be too large for this data packet. Save and reset the packet builder before adding this packet
            table.insert(data_packets, current_packet_builder)

            packet_start_time = nil
            current_packet_builder = nil
            current_packet_builder = {}
            union_tables(current_packet_builder, int_to_vlq(packet_ids.data))
            union_tables(current_packet_builder, transfered_song_id_vlq)
            packet_start_time = new_start_time
            union_tables(current_packet_builder, int_to_vlq(math.floor(new_start_time)))

            if ((#data_packets) * target_milis_between_packets) - required_buffer_delay_in_milis > proposed_packet_start_part_pair.start_time then
                -- Too much time has passed for us to play this instruction on time.
                -- Bump required_buffer_delay_in_milis so that the song starts later, giving us more time to send packets.
                required_buffer_delay_in_milis = ((#data_packets) * target_milis_between_packets) - proposed_packet_start_part_pair.start_time
                print_debug("buffer time changed:", required_buffer_delay_in_milis / 1000)
            end

            instruction_packet_should_be_rebuilt = true
        end
        return instruction_packet_should_be_rebuilt
    end

    for _, instruction in ipairs(processed_song.instructions) do
        local instruction_and_modifier_packet_parts = song_instruction_to_packet_parts(instruction, packet_start_time, modifiers_tracker)
        local instruction_packet_part_with_start_time = instruction_and_modifier_packet_parts.instruction_part_and_start
        local modifier_start_part_pairs_from_this_instrucion = instruction_and_modifier_packet_parts.modifier_parts_and_starts

        -- insert any modifiers that go before this instruction

        local previously_unhandled_modifiers_indexes_to_remove = {}
        for index, unhandled_modifier_start_part_pair in pairs(unhandled_modifiers_start_part_pairs) do
            if unhandled_modifier_start_part_pair.start_time <= instruction.start_time then
                -- This modifier comes before the current instruction. Add it first
                table.insert(previously_unhandled_modifiers_indexes_to_remove, index)

                local should_use_the_new_packet_start_time =
                    check_and_make_room(unhandled_modifier_start_part_pair, instruction.start_time)
                if should_use_the_new_packet_start_time then
                    instruction_and_modifier_packet_parts = song_instruction_to_packet_parts(instruction, packet_start_time, modifiers_tracker)
                    instruction_packet_part_with_start_time = instruction_and_modifier_packet_parts.instruction_part_and_start
                    modifier_start_part_pairs_from_this_instrucion = instruction_and_modifier_packet_parts.modifier_parts_and_starts
                end
                union_tables(current_packet_builder, unhandled_modifier_start_part_pair.packet_part)

            else
                break
            end
        end

        for _, index_to_remove in ipairs(previously_unhandled_modifiers_indexes_to_remove) do
            unhandled_modifiers_start_part_pairs[index_to_remove] = nil
        end

        -- Actualy add the current instruction

        local should_rebuild = check_and_make_room(instruction_packet_part_with_start_time, instruction.start_time)
        if should_rebuild then
            instruction_and_modifier_packet_parts = song_instruction_to_packet_parts(instruction, packet_start_time, modifiers_tracker)
            instruction_packet_part_with_start_time = instruction_and_modifier_packet_parts.instruction_part_and_start
            modifier_start_part_pairs_from_this_instrucion = instruction_and_modifier_packet_parts.modifier_parts_and_starts
        end
        union_tables(current_packet_builder, instruction_packet_part_with_start_time.packet_part)

        -- Add modifiers for current instruction to the unhandled list. They will be handeled in the next loop

        union_tables(unhandled_modifiers_start_part_pairs, modifier_start_part_pairs_from_this_instrucion)

        -- clean up / resort unhandled modifiers table.

        local unhandeld_modifiers_list_requires_resort = (
            #previously_unhandled_modifiers_indexes_to_remove > 0
            or #modifier_start_part_pairs_from_this_instrucion > 0
        )
        if unhandeld_modifiers_list_requires_resort and #unhandled_modifiers_start_part_pairs > 1 then
            table.sort(unhandled_modifiers_start_part_pairs, function (a, b)
                if a and b then return a.start_time < b.start_time end
                return (a and true or false)
            end)
        end
    end

    -- we exited the loop. There may be unhandled modifiers, and the current packet builder needs to be added to the data_packets_list

    for _, unhandled_modifier_start_part_pair in pairs(unhandled_modifiers_start_part_pairs) do
        check_and_make_room(unhandled_modifier_start_part_pair, unhandled_modifier_start_part_pair.start_time)
        union_tables(current_packet_builder, unhandled_modifier_start_part_pair.packet_part)
    end
    table.insert(data_packets, current_packet_builder)

    -- debug to notice unhandled modifier types
    if next(modifiers_tracker.total_number_of_unrecognized_modifier_types_by_type) then
        print_debug("build_data_packets found some unrecognized note modifiers")
        for modifier_name, ammount in pairs(modifiers_tracker.total_number_of_unrecognized_modifier_types_by_type) do
            print_debug("  found "..tostring(ammount).." instances of the `"..modifier_name.."` modifier")
        end
    end

    return data_packets, required_buffer_delay_in_milis + (1 * target_milis_between_packets)
end

---Immediatly converts an entire ProcessedSong and any config data into a list of packets
---@param processed_song ProcessedSong
---@param player_config SongPlayerConfig
---@param for_local_use boolean?
---@return PackedSongPacket[]
---@return integer transfered_song_id       Unique ID to address these packets (and player_data) on both the host and any clients.
local function song_to_packets(processed_song, player_config, for_local_use)
    local header_packet_body = build_header_packet_without_buffer_delay(processed_song)


    local header_packet_head = {}
    union_tables(header_packet_head, int_to_vlq(packet_ids.header))  -- First element is allways packet ID


    songs_turned_into_packets_so_far = songs_turned_into_packets_so_far +1
    ---A unique ID for each song since the avatar loaded.
    local transfered_song_id = songs_turned_into_packets_so_far
    local transfered_song_id_vlq = int_to_vlq(transfered_song_id)
    union_tables(header_packet_head, transfered_song_id_vlq)             -- 2nd element is allways the song transfer ID

    local config_packet_body = build_config_packet_body(player_config)
    local all_data_packets, buffer_delay = build_data_packets(processed_song, transfered_song_id_vlq)

    local header_packet = {}

    ---@type SongPacket[]
    local final_packet_list = {}
    local there_is_enough_space_to_combine_the_header_and_config_packets =
        (#header_packet_head + #header_packet_body + #int_to_vlq(buffer_delay) + #config_packet_body)
        < max_packet_length
    if there_is_enough_space_to_combine_the_header_and_config_packets then
        -- @e can join the header packet and the initial config packet

        union_tables(header_packet_body, int_to_vlq(buffer_delay))

        union_tables(header_packet, header_packet_head)
        union_tables(header_packet, header_packet_body)
        union_tables(header_packet, config_packet_body)
        table.insert(final_packet_list, header_packet)
    else
        -- We need to send the config packet as its own packet

        union_tables(header_packet_body, int_to_vlq(buffer_delay + target_milis_between_packets))  -- buffer needs to be one packet longer.
        union_tables(header_packet, header_packet_head)
        union_tables(header_packet, header_packet_body)

        table.insert(final_packet_list, header_packet)

        local config_packet = {}
        union_tables(config_packet, int_to_vlq(packet_ids.config))
        union_tables(config_packet, transfered_song_id_vlq)
        union_tables(config_packet, config_packet_body)
        table.insert(final_packet_list, config_packet)
    end

    for _, data_packet in ipairs(all_data_packets) do
        table.insert(final_packet_list, data_packet)
    end

    local final_packed_packet_list = {}
    for _, unpacked_packet in ipairs(final_packet_list) do
        table.insert(final_packed_packet_list, pack_packet(unpacked_packet))
    end

    return final_packed_packet_list, transfered_song_id
end

---@enum ControlPacketCode
local control_packet_codes = {
    stop = 0,       -- Stop a song by it's transfered ID
    start = 1,      -- Play a song by it's transfered ID
    remove = 2,     -- Delete a song from the transfered song list
}


-- The colection of songs received from the Host (or whatever called add_packet_to_song).
-- These are indexed by a host-controlled integer, and are uniquely identifiable in this way.
---@type table<integer, {song: ProcessedSong, instructions_with_modifier_ids: table<integer, Instruction>, player: PlayingSongController}>
local collected_incomming_songs = {}

-- list of transfer IDs that we must have missed
---@type table<integer, boolean>
local missed_incomming_songs = {}

---@param transfered_song_id integer
---@param control_code ControlPacketCode
---@return PackedSongPacket
local function make_control_packet(transfered_song_id, control_code)
    local control_packet = {}
    union_tables(control_packet, int_to_vlq(packet_ids.control))
    union_tables(control_packet, int_to_vlq(transfered_song_id))
    union_tables(control_packet, int_to_vlq(control_code))
    return pack_packet(control_packet)
end






---@type table<integer, string>
local modifier_number_to_type_lookup = {}
for name, id in pairs(modifier_type_to_number_lookup) do
    modifier_number_to_type_lookup[id] = name
end

---Reads a data packet out of a Reader.
---@param reader PacketReader           Where the packet id and transfer song ID have already been read
---@param transfered_song_id integer    Index into collected_incomming_songs
local function receive_data_packet(reader, transfered_song_id)
    if not collected_incomming_songs[transfered_song_id] then
        if not missed_incomming_songs[transfered_song_id] then
            print_debug("Received a data packet for song with transfer ID `"..tostring(transfered_song_id).."` before receiving a header packet for the song. Future lost data packets for this song will be ignored.")
            missed_incomming_songs[transfered_song_id] = true
        end
        return
    end
    local song = collected_incomming_songs[transfered_song_id].song
    local modifiable_instructions = collected_incomming_songs[transfered_song_id].instructions_with_modifier_ids
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

            local modifier_type = modifier_number_to_type_lookup[modifier_type_id]

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
---Returns nothing, but modifies collected_incomming_songs[transfered_song_id]
---@param reader PacketReader           Where the packet id and transfer song ID have already been read
---@param transfered_song_id integer    Index into collected_incomming_songs
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

    if not collected_incomming_songs[transfered_song_id].player then
        -- This config packet must be inside of a header packet. It is our job to create the player.

        ---@type SongPlayerAPI
        local player_api = require("./player")
        collected_incomming_songs[transfered_song_id].player =
            player_api.new_player(collected_incomming_songs[transfered_song_id].song, config_data)
    else
        collected_incomming_songs[transfered_song_id].player.set_new_config(config_data)
    end
end

---Parces a header packet out of a Reader. Packet type and transfered_song_id have already been received since they start every packet.
---@param reader PacketReader           Where the packet id and transfer song ID have already been read
---@param transfered_song_id integer    Index into collected_incomming_songs
---@return ProcessedSong        A processed song that likely has no instructions
local function receive_header_packet(reader, transfered_song_id)
    -- This is a header packet. Even if the song with this ID already exists, the host is clearly sending a new one. Purge this data.
    -- The host should never send a 2nd song with the same ID, but it might happen if the host has reloaded their script.
    -- Purging this data means we loose controll over it, but the host must have already lost control, so it's kinda OK actualy.
    collected_incomming_songs[transfered_song_id] = {}

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

    ---@type ProcessedSong
    local incomming_processed_song = {
        name = name,
        duration = duration,
        tracks = tracks,
        instructions = {},
        buffer_delay = buffer_delay,
        buffer_start_time = client:getSystemTime()
    }

    collected_incomming_songs[transfered_song_id] = {
        song = incomming_processed_song,
        instructions_with_modifier_ids = {},
        player = nil
    }

    if reader.index <= #reader.bytes then -- There is still data in the reader, the rest is config data.
        receive_config_packet(reader, transfered_song_id)
    else
        -- there is no config data, let's initilize a blank player

        ---@type SongPlayerAPI
        local player_api = require("./player")
        collected_incomming_songs[transfered_song_id].player =
            player_api.new_player(collected_incomming_songs[transfered_song_id].song, nil)
    end

    return incomming_processed_song
end

---@type table<ControlPacketCode, fun(transfered_song_id:integer)>
local control_packet_handelers = {
    [control_packet_codes.start] = function(transfered_song_id)
        if collected_incomming_songs[transfered_song_id] then
            collected_incomming_songs[transfered_song_id].player:play()
        end
    end,
    [control_packet_codes.stop] = function(transfered_song_id)
        if collected_incomming_songs[transfered_song_id] then
            collected_incomming_songs[transfered_song_id].player:stop()
        end
    end,
    [control_packet_codes.remove] = function(transfered_song_id)
        if collected_incomming_songs[transfered_song_id] then
            collected_incomming_songs[transfered_song_id] = nil
        end
    end,
}


---@param reader PacketReader           Where the packet id and transfer song ID have already been read
---@param transfered_song_id integer    Index into collected_incomming_songs
local function receive_control_packet(reader, transfered_song_id)
    local control_code = vlq_to_int_from_reader(reader)
    if control_packet_handelers[control_code] then
        control_packet_handelers[control_code](transfered_song_id)
    else
        print_debug("unrecognized controll code `"..tostring(control_code).."` for transfered song #"..tostring(transfered_song_id))
    end
end

-- function lookup table for packet receiver
---@type table<SongPacketTypeIDs, fun(reader: PacketReader, transfered_song_id: integer)>
local packet_receiving_functions = {
    [packet_ids.control] = receive_control_packet,
    [packet_ids.header] = receive_header_packet,
    [packet_ids.data] = receive_data_packet,
    [packet_ids.config] = receive_config_packet,
}


local local_receive_packet_loop_is_running = false
local incoming_packed_packets = {}  ---@type PackedSongPacket[]

--- Primary function to receive packets. Distributes packets to the correct receiving functions.
---
--- There seems to be a rare chance that two pings may be bundled and processed in the same tick.
--- By running in a tick event, we ensure that, on the off chance we receive two pings on the same tick, that we process them on diffrent ticks.
---@see local_receive_packet
local function local_receive_packet_loop()
    local packed_packet_data = table.remove(incoming_packed_packets, 1)   -- table.remove is usualy inneficient when popping from the front. But we shouldn't have more than like 2 packets in here at a time, so should be fine.

    local packet_data = unpack_packet(packed_packet_data)
    local reader = new_packet_reader(packet_data)
    local packet_id = vlq_to_int_from_reader(reader)
    local transfered_song_id = vlq_to_int_from_reader(reader)
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
---
---@param packed_packet_data PackedSongPacket
local function local_receive_packet(packed_packet_data)
    table.insert(incoming_packed_packets, packed_packet_data)
    if not local_receive_packet_loop_is_running then
        local_receive_packet_loop_is_running = true
        events.TICK:register(local_receive_packet_loop)

    -- else
    --     print("We already have a ping to process this tick")

    end
end

---For use with outgoing_packet_queue and others to get the transfer ID out of a packet, without needing to trust whoever is giveing us the packets.
---@param packed_packet_data PackedSongPacket
---@return integer transfered_song_id
local function get_transfer_id_from_packed_packet_data(packed_packet_data)
    local packet_data = unpack_packet(packed_packet_data)
    local reader = new_packet_reader(packet_data)
    local packet_id = vlq_to_int_from_reader(reader)
    local transfered_song_id = vlq_to_int_from_reader(reader)
    return transfered_song_id
end

--- primary ping function. It receives a packet and sends it off for processing
--- On the off chance that pings need to be unique (idk at the moment): `TL_FMP` → Tanner Limes Figura Mucic Player
---@param incomming_packet PackedSongPacket
function pings.TL_FMP_receive_packet(incomming_packet)
    local_receive_packet(incomming_packet)
end

local function ping_packet_immediatly(outgoing_packed_packet)
    pings.TL_FMP_receive_packet(outgoing_packed_packet)
end

---@alias PacketQueue {transfered_song_id: integer, packet: PackedSongPacket}[]

local outgoing_packet_queue_index = 1   ---@type integer        Index into outgoing_packet_queue. Using an index so that we don't have to remove items from the list.
local outgoing_packet_queue = {}        ---@type PacketQueue

local ping_loop_start_time

local ping_loop_identifier = "TL_FMP_song_data_ping_loop"

local function stop_and_cleanup_packet_ping_loop()
    outgoing_packet_queue = {}
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
        #outgoing_packet_queue
    do
        local should_delete_packet = outgoing_packet_queue[search_index].transfered_song_id == transfered_song_id_to_cancel
        if not should_delete_packet then
            if (size_of_hole > 0) then
                -- We want to keep this value, but there's a hole in the list. Slide the value so that we fill the hole.
                outgoing_packet_queue[search_index - size_of_hole] = outgoing_packet_queue[search_index]
                outgoing_packet_queue[search_index] = nil
            end
        else
            if outgoing_packet_queue_index == search_index then
                -- In this situation, we can just skip the packet instead of modifying the table
                outgoing_packet_queue_index = outgoing_packet_queue_index + 1
            else
                outgoing_packet_queue[search_index] = nil
                size_of_hole = size_of_hole + 1
            end
        end
    end

    -- Any nils we created should have propigated to the end of the queue by now.
    -- But since lua considers the length to the index of the last non-nil value,
    -- it effectively means the list has shrunk, so #outgoing_packet_queue sould
    -- accuratly represent the new size.
    if outgoing_packet_queue_index > #outgoing_packet_queue then stop_and_cleanup_packet_ping_loop() end
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
    local new_outgoing_packet_queue = table.pack(table.unpack(outgoing_packet_queue, outgoing_packet_queue_index))
    new_outgoing_packet_queue.n = nil   -- table.pack adds an `n` field that we don't want.
    outgoing_packet_queue = new_outgoing_packet_queue   ---@type PacketQueue

    outgoing_packet_queue_index = 1
    if outgoing_packet_queue_index > #outgoing_packet_queue then stop_and_cleanup_packet_ping_loop() end
end

--- Host-side event loop to emit pings from the ping queue
local function ping_loop()
    if ping_loop_start_time + (target_milis_between_packets * (outgoing_packet_queue_index -1)) < client:getSystemTime() then
        -- we can emit another packet
        -- Note that this condition may be true in situations where the time between
        -- two packets is slightly _less_ than target_milis_between_packets.
        -- It will still be the average, but enabling us to send a packet slightly
        -- early will avoid the "slip" caused from missing the perfect time to emmit a packet.

        print_debug("pinging packet #"..tostring(outgoing_packet_queue_index).."/"..tostring(#outgoing_packet_queue).."…")

        pings.TL_FMP_receive_packet(outgoing_packet_queue[outgoing_packet_queue_index].packet)

        outgoing_packet_queue_index = outgoing_packet_queue_index + 1

        -- check if list is empty
        if outgoing_packet_queue_index > #outgoing_packet_queue then print_host("All pings sent."); stop_and_cleanup_packet_ping_loop() end
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
---@param outgoing_packed_packet PackedSongPacket
local function ping_packet(outgoing_packed_packet)
    table.insert(outgoing_packet_queue, {transfered_song_id = get_transfer_id_from_packed_packet_data(outgoing_packed_packet), packet = outgoing_packed_packet})
    check_or_start_ping_loop()
end

---Add several packets to the packet queue
---@param outgoing_packed_packets PackedSongPacket[]
local function ping_packets(outgoing_packed_packets)
    for _, packet in ipairs(outgoing_packed_packets) do
        table.insert(outgoing_packet_queue, {transfered_song_id = get_transfer_id_from_packed_packet_data(packet), packet = packet})
    end
    check_or_start_ping_loop()
end

---@return number
local function outgoing_packet_queue_progress()
    if #outgoing_packet_queue == 0 then return 1 end
    return outgoing_packet_queue_index / #outgoing_packet_queue
end

---@class SongNetworkingApi
---@field song_to_packets       fun(processed_song:ProcessedSong, player_config:SongPlayerConfig, for_local_use:boolean?):PackedSongPacket[], integer
---@field local_receive_packet  fun(packed_packet_data:PackedSongPacket, for_local_use:boolean?)
---@field ping_packets          fun(outgoing_packed_packets:PackedSongPacket[])
---@field outgoing_packet_queue_progress    fun():number
---@field play_transfered_song  fun(transfered_song_id:integer)         Sends a controll packet to play the selected song.
---@field stop_transfered_song  fun(transfered_song_id:integer)         Sends a controll packet to stop the selected song, and removes any remaining queued packets for the song.
---@field remove_transfered_song  fun(transfered_song_id:integer)       Sends a controll packet to delete the selected song. This simply removes the song from the transfered_songs list. A player playing this song may still hold onto it.
---@field cancel_all_pings fun()        Deletes all pings in the queued pings list and stops the update loop.
---@field get_player_for_transfered_song fun(transfered_song_id:integer):PlayingSongController  Treat this as read-only. Edits to this player will only be seen by the host.
---@field get_target_milis_between_packets fun():integer                Returns `target_milis_between_packets`, so that we can make time-estemations from packet rate.
return {
    song_to_packets = song_to_packets,
    local_receive_packet = local_receive_packet,    -- adds a packet to it's targeted song.
    ping_packets = ping_packets,
    outgoing_packet_queue_progress = outgoing_packet_queue_progress,
    play_transfered_song = function(transfered_song_id)
        ping_packet_immediatly(make_control_packet(transfered_song_id, control_packet_codes.start))
    end,
    stop_transfered_song = function(transfered_song_id)
        ping_packet_immediatly(make_control_packet(transfered_song_id, control_packet_codes.stop))
        remove_packets_from_outgoing_queue_by_transfer_id(transfered_song_id) -- Does not cancel the above packet, since ping_packet_immediatly bypasses the packet queue
    end,
    remove_transfered_song = function(transfered_song_id) ping_packet_immediatly(make_control_packet(transfered_song_id, control_packet_codes.remove)) end,
    cancel_all_pings       = function() stop_and_cleanup_packet_ping_loop() end,
    get_player_for_transfered_song = function(transfered_song_id) return collected_incomming_songs[transfered_song_id] and collected_incomming_songs[transfered_song_id].player or nil end,
    get_target_milis_between_packets = function() return target_milis_between_packets end,
}
