
-- A set of functions that build packet data out of songs, headers, and config info.



local packet_enums_api = require("./packet_enums") ---@type PacketEnumsAPI

-- Packets are used both for pings and local song storage.
-- "Local" meaning bundled with the avatar upload.
--
-- Packets must be small enough to
--  1. Fit into the ping requirements
--  2. Be processable by the lowest supported permission level (more + small > few + big)
--  3. Not monopolize the ping budget from the rest of the avatar
--  4. Dodge Figura's ping "batching"
--     If figura has many pings to send at once, it might batch them and send many at one time.
--     Annoyingly, as far as the ping limits are concerned, this counts as one big ping.
--     So our pings need to be small enough and infrequent enough to also avoid stacking up

-- Ping limits (see https://figura-wiki.pages.dev/tutorials/Pings#ping-rate-limiting )
-- Fewer than 32 pings in one second (~32 milis between packets min)
-- Fewer than 1024 bytes per second (~1 byte/mili)

local pings_per_second = 6
local bytes_per_second = 400

-- In bytes. (-2 because storing data as a string adds 2 bytes to encode the string's length)
local max_packet_length = math.floor(bytes_per_second / pings_per_second) - 2
-- How long the ping system should try to wait before sending another packet.
-- (Tick event adds 50 milis (1/20th of a second) of possible drift to account for.)
local target_milis_between_packets = math.ceil(1000 / pings_per_second)


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

--- Effectively converts {true, false, true} → `101` → 5
---@param bools boolean[]
---@return integer
local function bool_list_to_number(bools)
    local bits = {}
    for index, bool in ipairs(bools) do bits[index] = (bool and 1 or 0) end
    return tonumber(table.concat(bits), 2)
end

--- Effectively converts {1, 0, 1} → `101` → 5
---@param bits (1|0)[]
---@return integer
local function bit_list_to_number(bits)
    return tonumber(table.concat(bits), 2)
end




---Converts a table of bytes (ints from 0 to 255) into a string
---@param data_bytes PacketDataBytes
---@return PacketDataString
local function packet_data_bytes_to_string(data_bytes)
    local data_string = string.char(table.unpack(data_bytes))
    return data_string
end

--- Builds a config packet out of a SongPlayerConfig table.
---
--- This can be used at any time to update a remote song's configuration.
---@param player_config SongPlayerConfig
---@return PacketDataString
local function build_config_packet(player_config)

    local config_packet_body = {}   ---@type PacketDataBytes[]

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

    -- local boolean_configs = {
    --     (player_config.play_immediately and true or false),
    -- }
    -- union_tables(config_packet_body, int_to_vlq(bool_list_to_number(boolean_configs)))

    return packet_data_bytes_to_string(config_packet_body)
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
---@param song Song
---@param buffer_delay integer
---@return PacketDataString
local function build_header_packets(song, buffer_delay)
    local packet = {}
    union_tables(packet, string_to_bytes_with_len(song.name))

    union_tables(packet, int_to_vlq(
        math.ceil(song.duration) -- At 144FPS, the player can only update every 5ms. math.ceil to drop sub-milisecond precission.
    ))

    local track_type_bits = {}
    for _, track in ipairs(song.tracks) do
        table.insert(track_type_bits, track.instrument_type_id)
    end
    union_tables(packet, int_to_vlq(#track_type_bits))
    union_tables(packet, int_to_vlq(bit_list_to_number(track_type_bits)))

    union_tables(packet, int_to_vlq(buffer_delay))

    return packet_data_bytes_to_string(packet)
end

--- For use with song_instruction_to_packet_parts()
---
--- A simple wraper so that I can reuse the "add modifier" code
---@param modifier InstructionModifier                 The modifier to add
---@param instruction_modifier_list_id integer  The note ID to add this modifier to.
---@return {start_time: number, packet_part: PartialPacketDataBytes}
local function modifier_to_packet_part(modifier, instruction_start_time, instruction_modifier_list_id)
    ---@type PartialPacketDataBytes
    local modifier_packet_part = {}
    union_tables(modifier_packet_part, int_to_vlq(math.floor(modifier.start_time - instruction_start_time)))
    union_tables(modifier_packet_part, int_to_vlq(nil))
        -- nil signals that this is a modifier for an instruction we've (probably) already sent
        -- meta tracks in the song itself use track_id == 0, so we're safe to use nil
    union_tables(modifier_packet_part, int_to_vlq(instruction_modifier_list_id))
    union_tables(modifier_packet_part, int_to_vlq(packet_enums_api.modifier_key_to_number[modifier.type]))
    union_tables(modifier_packet_part, int_to_vlq(modifier.value))
    return {start_time = modifier.start_time, packet_part = modifier_packet_part}
end



--- Encodes a song instruction into PartialPacketDataBytes.
---
--- It also splits any recognized modifiers into their own list of PartialPacketDataBytes, and makes sure their IDs are synced to the root instruction
---@param instruction Instruction
---@param packet_start_time number      The start time of the current packet. Used to calculate the delta for this instruction.
---@param modifiers_tracker table
---@return {instruction_part_and_start: {start_time: number, packet_part: PartialPacketDataBytes}, modifier_parts_and_starts: {start_time: number, packet_part: PartialPacketDataBytes}[] }
local function song_instruction_to_packet_parts(instruction, packet_start_time, modifiers_tracker)
    local modifier_packet_parts = {}

    local instruction_packet_part_and_start = {start_time = instruction.start_time, packet_part = {}}

    union_tables(instruction_packet_part_and_start.packet_part, int_to_vlq(math.floor(instruction.start_time - packet_start_time)))
    union_tables(instruction_packet_part_and_start.packet_part, int_to_vlq(instruction.track_index))
    union_tables(instruction_packet_part_and_start.packet_part, int_to_vlq(math.floor(instruction.duration)))
    union_tables(instruction_packet_part_and_start.packet_part, int_to_vlq(instruction.note))
    union_tables(instruction_packet_part_and_start.packet_part, int_to_vlq(instruction.start_velocity)) -- This is a normal instruction.

    if not (instruction.modifiers and next(instruction.modifiers)) then -- This instruction has no modifiers.
        union_tables(instruction_packet_part_and_start.packet_part, int_to_vlq(nil))
    else    -- this instruction has modifiers.
        -- Assign a unique note modifier tracker ID

        local instruction_modifier_list_id = modifiers_tracker.id_counter
        modifiers_tracker.id_counter = modifiers_tracker.id_counter + 1
        union_tables(instruction_packet_part_and_start.packet_part, int_to_vlq(instruction_modifier_list_id))


        -- Stores some modifiers sorted by type. Used to drop some modifiers and reduce temporal resolution
        ---@type table<string, {first_start_time: integer, total_added: integer, last_added: InstructionModifier?, last_seen: InstructionModifier}>
        local modifier_subset_tracker = {}

        -- make new packet parts for each modifier
        for _, modifier in ipairs(instruction.modifiers) do
            if not packet_enums_api.modifier_key_to_number[modifier.type] then
                if not modifiers_tracker.total_number_of_unrecognized_modifier_types_by_type[modifier.type] then
                    modifiers_tracker.total_number_of_unrecognized_modifier_types_by_type[modifier.type] = 1
                    print_debug(
                        "song_instruction_to_packet_parts: unrecognized modifier type: `"
                            ..tostring(modifier.type)
                            .."`.\ninstruction.start_time: "
                            ..tostring(instruction.start_time)
                            ..", instruction.note: "
                            ..tostring(instruction.note)
                            .."`.\n This warning will be suppressed for the rest of this song."
                        , true
                    )
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

    if instruction.track_index == 0 then -- This instruction is a song-level meta event
        -- we'll need to add in any extra data from instruction.meta_event_data
        local count = 0
        for _, _ in pairs(instruction.meta_event_data) do
            count = count + 1
        end
        union_tables(instruction_packet_part_and_start.packet_part, int_to_vlq(count))

        for key, val in pairs(instruction.meta_event_data) do
            union_tables(instruction_packet_part_and_start.packet_part, string_to_bytes_with_len(key))
            union_tables(instruction_packet_part_and_start.packet_part, int_to_vlq(val))
        end
    end

    return {instruction_part_and_start = instruction_packet_part_and_start, modifier_parts_and_starts = modifier_packet_parts}
end

--- The big one that loops through all instructions, and their modifiers, and creates a series of packets.
---@see song_to_packets
---@param song Song
---@return PacketDataString[] data_packets        -- Fully formed packets ready to be bundled and shipped.
---@return integer buffer_delay_in_milis
local function build_data_packets_and_buffer_time(song)

    --- A counter that lets us generate unique IDs for any note that has a modifier

    local modifiers_tracker = {
        id_counter = 0, ---@type integer A counter that lets us have a unique ID for every note that has a modifier in this song.
        total_number_of_unrecognized_modifier_types_by_type = {}  ---@type table<string, integer>
    }

    ---@type PacketDataBytes[]
    local data_packets = {}
    local required_buffer_delay_in_milis = 0

    local current_packet_builder = {}
    ---@type {start_time: number, packet_part: PartialPacketDataBytes}[]
    local unhandled_modifiers_start_part_pairs = {}
    local packet_start_time = song.instructions[1].start_time
    union_tables(current_packet_builder, int_to_vlq(math.floor(packet_start_time)))

    --- Checks if there is room for the proposed DataPacketPart to be included in the current Packet
    ---
    --- Also runs the bulk of the buffer time calculations
    ---@param proposed_packet_start_part_pair {start_time: number, packet_part: PartialPacketDataBytes}
    ---@param new_start_time number     The start time of the next packet, if one needs to be created.
    ---@return boolean instruction_packet_should_be_rebuilt
    local function check_and_make_room(proposed_packet_start_part_pair, new_start_time)
        local instruction_packet_should_be_rebuilt = false
        if #current_packet_builder + #proposed_packet_start_part_pair.packet_part >= max_packet_length then
            -- This next packet part would be too large for this data packet. Save and reset the packet builder before adding this packet
            table.insert(data_packets, current_packet_builder)

            packet_start_time = new_start_time
            current_packet_builder = {}
            union_tables(current_packet_builder, int_to_vlq(math.floor(new_start_time)))

            if ((#data_packets) * target_milis_between_packets) - required_buffer_delay_in_milis > proposed_packet_start_part_pair.start_time then
                -- Too much time has passed for us to play this instruction on time.
                -- Bump required_buffer_delay_in_milis so that the song starts later, giving us more time to send packets.
                required_buffer_delay_in_milis = ((#data_packets) * target_milis_between_packets) - proposed_packet_start_part_pair.start_time
                print_debug("buffer time changed: "..tostring(required_buffer_delay_in_milis / 1000).."s")
            end

            instruction_packet_should_be_rebuilt = true
        end
        return instruction_packet_should_be_rebuilt
    end

    for _, instruction in ipairs(song.instructions) do
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
        print_debug("build_data_packets found some unrecognized note modifiers", true)
        for modifier_name, ammount in pairs(modifiers_tracker.total_number_of_unrecognized_modifier_types_by_type) do
            print_debug("  found "..tostring(ammount).." instances of the `"..modifier_name.."` modifier")
        end
    end

    local data_packets_as_strings = {}  ---@type PacketDataString[]
    for _, data_packet_in_bytes in ipairs(data_packets) do
        table.insert(data_packets_as_strings, packet_data_bytes_to_string(data_packet_in_bytes))
    end

    return data_packets_as_strings, required_buffer_delay_in_milis + (1 * target_milis_between_packets)
end

---@param control_code ControlPacketCode
---@return PacketDataString
local function make_control_packet(control_code)
    return packet_data_bytes_to_string( int_to_vlq(control_code) )
end








---@class PacketEncoderApi
local packet_builder_api = {
    build_header_packets  = build_header_packets,
    build_config_packet   = build_config_packet,
    build_data_packets_and_buffer_time = build_data_packets_and_buffer_time,
    make_control_packet             = make_control_packet,

    get_pings_per_second             = function() return pings_per_second end,
    get_bytes_per_second             = function() return bytes_per_second end,
    get_max_packet_length            = function() return max_packet_length end,
    get_target_milis_between_packets = function() return target_milis_between_packets end,
}

return packet_builder_api
