
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
--
--     This is by far the most common reason you'll see the "packet is too big" toast
--     -- TODO: If figura is miscounting ping information, could this be a bug in Figura?

-- Ping limits (see https://figura-wiki.pages.dev/tutorials/Pings#ping-rate-limiting )
-- Fewer than 32 pings in one second (~32ms between packets min)
-- Fewer than 1024 bytes per second (~1 byte/milli)

local pings_per_second = 6    -- Keep between, 4 and 18. Too low: packets are too big to process. Too big, viewer might lag behind. (viewer can't process more than one ping per TICK (20 per second).)
local bytes_per_second = 400    -- 400 is about as high as you can get without dropping too many packets. If it's a good day, you can get away with something much higher, but 400 is a safe default.


local discard_track_instructions = false      -- Disables all instruction modifiers. Things like volume control and pitch bending. These can take up a lot of space, so disabling them can significantly improve buffer times (at cost of worse quality)

--- Baseline temporal resolution for modifiers.
---
--- At high FPS like 144, we can only update a SongPlayer about once every 7 milliseconds.
--- At 60 FPS, our maximum resolution is about 16ms
---
--- Midi modifiers are typically at a very high temporal resolution. We can safely drop a
--- few modifiers to significantly improve buffer times.
---@type integer
local target_modifier_temporal_resolution = 35

local do_debug_prints = false



-- In bytes. (-2 because storing data as a string adds 2 bytes to encode the string's length)
local max_packet_length = math.floor(bytes_per_second / pings_per_second) - 2
-- How long the ping system should try to wait before sending another packet.
-- (Tick event adds 50ms (1/20th of a second) of possible drift to account for.)
local target_milliseconds_between_packets = math.ceil(1000 / pings_per_second)

--- Logs a message to the console. But if do_debug_prints is true, it also logs to chat. Use do_debug_prints=true to debug viewers.
---@param message string
---@param is_warning boolean?
---@param always_log boolean?
local function print_debug(message, is_warning, always_log)
    if do_debug_prints then print(message) end
    if do_debug_prints or always_log then
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

---Lets us save negative numbers as positive numbers.
---@param signed_integer integer
---@return integer zigzag_unsigned_integer
local function zigzag_encode(signed_integer)
    -- double number, take absolute value, then subtract 1 if original number was negative.
    -- negative numbers become odd numbers, and positive numbers become even.
    if signed_integer < 0 then return (-signed_integer * 2) - 1 else return signed_integer * 2 end
end

---Convert an integer (or nil) into a variable-length-quantity byte list
---@param integer integer?
---@return Byte[]
local function uint_to_bytes(integer)
    if integer == nil then
        -- 0x80 (10000000) is not a valid first byte in the sequence.
        -- The first byte will either be `0x00`, or have a `1` somewhere in the data to start the number.
        -- 0x80 is legal in the middle of the sequence, but never as the initial.
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


---Shifts the decimal point in a number so that `0.123` becomes `123`
---@param number number must be between [0, 1)
---@return integer
local function promote_decimal_places_to_int(number)
    if (number >= 1) or (number < 0) then error("promote_decimal_places_to_int must take a number between [0, 1), but we got `"..tostring(number).."`") end

    local max_vlq_len = 2
    -- by default, lua prints numbers with up to 5 decimal points (though it actually stores at a higher resolution). max_vlq_len = 2 is enough to get all 5, max_vlq_len = 3 gets us up to 7

    -- generates the maximum value that can be stored in a VLQ and stay under max_vlq_len
    -- Each byte in the VLQ holds 7 bits of info.
    local max_vlq_value = tonumber(string.rep(string.rep("1", 7), max_vlq_len), 2)

    local shifted_number = number
    local previous_shift = number

    local tolerance = 1e-5 -- end early if the shifted_number is within range of floor(shifted_number), meaning they're basically the same number, don't add padding 0s

    while
        math.floor(shifted_number) < max_vlq_value
        and math.abs(previous_shift - math.floor(previous_shift)) > tolerance
    do
        previous_shift = shifted_number
        shifted_number = shifted_number * 10
        -- using base ten ensures the viewer is able to slap a `0.` to the front using string functions and quickly get a result.
        -- if instead we used `* 2` (effectively a left shift), it would better maximize precision, but undoing it, I think requires a loop of some sort on the viewer
    end
    -- shifted_number is now out of range, but previous number should be fine.

    return math.floor(previous_shift)
end

---converts a number into two VLQ ints
---
---Unlike the int functions, number may be positive or negative and can be a float. But may be a lossy conversion.
---@param float number?
---@return Byte[]
local function number_to_bytes(float)
    if not float then return uint_to_bytes(nil) end

    local mantissa, exponent = math.frexp(float)    -- mantissa will always be between [0.5, 1). exponent is a signed int

    local mantissa_as_an_int = promote_decimal_places_to_int(mantissa)
    local zigzag_exponent = zigzag_encode(exponent)

    return union_tables(uint_to_bytes(mantissa_as_an_int), uint_to_bytes(zigzag_exponent))
end


---Converts a string into a table of bytes, where the length is placed just before the string.
---@param str string?
---@return Byte[]
local function string_to_bytes(str)
    if str == nil then return uint_to_bytes(nil) end
    local tabulated_string = table.pack( string.byte(str, 1, -1) )
    local tabulated_length = uint_to_bytes(tabulated_string.n)
    tabulated_string.n = nil
    return union_tables(tabulated_length, tabulated_string)
end

--- Effectively converts {true, false, true} → `101` → 5
---@param bools boolean[]
---@return integer
local function bool_list_to_int(bools)
    local bits = {}
    for index, bool in ipairs(bools) do bits[index] = (bool and 1 or 0) end
    return tonumber(table.concat(bits), 2)
end

--- Effectively converts {1, 0, 1} → `101` → 5
---@param bits (1|0)[]
---@return integer
local function bit_list_to_int(bits)
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

            union_tables(source_table, uint_to_bytes(bool_list_to_int(truth_table)))
            union_tables(source_table, uint_to_bytes(math.floor(math.abs(uuid_int_1))))
            union_tables(source_table, uint_to_bytes(math.floor(math.abs(uuid_int_2))))
            union_tables(source_table, uint_to_bytes(math.floor(math.abs(uuid_int_3))))
            union_tables(source_table, uint_to_bytes(math.floor(math.abs(uuid_int_4))))

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
            union_tables(source_table, uint_to_bytes(bool_list_to_int(truth_table)))
            union_tables(source_table, uint_to_bytes(abs_floor_x))
            union_tables(source_table, uint_to_bytes(abs_floor_y))
            union_tables(source_table, uint_to_bytes(abs_floor_z))
        else
            -- no source data given at data at all send nil.
            union_tables(source_table, uint_to_bytes( nil ))
        end

        union_tables(config_packet_body, source_table)
    end

    -- Default instruments
    union_tables(config_packet_body, string_to_bytes(
        player_config.default_normal_instrument
        and player_config.default_normal_instrument.name
        or nil
    ))
    union_tables(config_packet_body, string_to_bytes(
        player_config.default_percussion_instrument
        and player_config.default_percussion_instrument.name
        or nil
    ))
    -- TODO: serialize instrument params

    local instrument_selections = {}
    local configured_track_count = 0
    for track_id, selected_instrument in pairs(player_config.instrument_selections or {}) do
        configured_track_count = configured_track_count + 1
        union_tables(instrument_selections, uint_to_bytes(track_id))
        union_tables(instrument_selections, string_to_bytes(selected_instrument.name))
        -- TODO: serialize instrument params
    end
    union_tables(config_packet_body, uint_to_bytes(configured_track_count))
    union_tables(config_packet_body, instrument_selections)

    -- events
    union_tables(config_packet_body, string_to_bytes(player_config.primary_update_event_key))
    union_tables(config_packet_body, string_to_bytes(player_config.fallback_update_event_key))

    -- boolean-based-configs

    local boolean_configs = {
        (player_config.hide_in_world_info and true or false),
    }
    union_tables(config_packet_body, uint_to_bytes(bool_list_to_int(boolean_configs)))

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
    union_tables(packet, string_to_bytes(song.name))

    union_tables(packet, uint_to_bytes(
        math.ceil(song.duration) -- Even if the render event is running at 144FPS, the player only update every 5ms. Drop sub-millisecond precision.
    ))

    local track_type_bits = {}
    for _, track in ipairs(song.tracks) do
        table.insert(track_type_bits, track.instrument_type_id)
    end
    union_tables(packet, uint_to_bytes(#track_type_bits))
    union_tables(packet, uint_to_bytes(bit_list_to_int(track_type_bits)))

    union_tables(packet, uint_to_bytes(buffer_delay))

    return packet_data_bytes_to_string(packet)
end

--- When deciding if a TrackInstruction should be included, always include if there are no TrackInstructions within this time window.
---@type integer
local modifier_gap_threshold = math.floor(target_modifier_temporal_resolution * 1.25)

--- Encodes a song instruction into PartialPacketDataBytes.
---@param instruction AnyInstruction
---@param packet_start_time number?      The start time of the current packet. Used to calculate the delta for this instruction. Nil is a special case for context instructions. Basically, "Copy this packet's start time"
---@return PartialPacketDataBytes
local function song_instruction_to_packet_parts(instruction, packet_start_time)
    local instruction_packet_part = {}  ---@type PartialPacketDataBytes
    local packet_relative_start_time = packet_start_time and math.floor(instruction.start_time - packet_start_time) or nil

    if instruction.is_track_instruction then
        ---@cast instruction TrackInstruction

        union_tables(instruction_packet_part, uint_to_bytes(packet_relative_start_time))    -- start time of this instruction relative to the packet's start time.
        union_tables(instruction_packet_part, uint_to_bytes(nil))   -- typically, this would be a track index in this slot. But set it to nil to know this isn't a normal NoteInstruction.
        union_tables(instruction_packet_part, uint_to_bytes(instruction.track_index))   -- Track-level instructions still need to know what track they belong to.
        union_tables(instruction_packet_part, uint_to_bytes(packet_enums_api.modifier_key_to_number[instruction.type]))
        union_tables(instruction_packet_part, number_to_bytes(instruction.value))

    else
        ---@cast instruction NoteInstruction

        union_tables(instruction_packet_part, uint_to_bytes(packet_relative_start_time))
        union_tables(instruction_packet_part, uint_to_bytes(instruction.track_index))
        if instruction.duration == nil then printTable(instruction) end
        union_tables(instruction_packet_part, uint_to_bytes(math.floor(instruction.duration)))
        union_tables(instruction_packet_part, uint_to_bytes(instruction.note))
        union_tables(instruction_packet_part, uint_to_bytes(instruction.start_velocity))

        if instruction.track_index == 0 then -- This instruction is a song-level meta event     -- TODO: should song-level events become some sort of SongInstruction type?
            -- we'll need to add in any extra data from instruction.meta_event_data
            local count = 0
            for _, _ in pairs(instruction.meta_event_data) do
                count = count + 1
            end
            union_tables(instruction_packet_part, uint_to_bytes(count))

            for key, val in pairs(instruction.meta_event_data) do
                union_tables(instruction_packet_part, string_to_bytes(key))
                union_tables(instruction_packet_part, uint_to_bytes(val))
            end
        end
    end

    return instruction_packet_part
end


--- The big one that loops through all instructions and creates a series of packets.
---@see song_to_packets
---@param song Song
---@return PacketDataString[] data_packets        -- Fully formed packets ready to be bundled and shipped.
---@return integer buffer_delay_in_milliseconds
local function build_data_packets_and_buffer_time(song)

    ---@type PacketDataBytes[]
    local data_packets = {}
    local required_buffer_delay_in_milliseconds = 0

    local current_packet_builder = {}   ---@type PartialPacketDataBytes[]
    local current_packet_builder_sum_cache = 0
    local current_packet_builder_sum_last_len = 0

    ---@return integer
    local function get_current_packet_builder_sum()
        if #current_packet_builder == current_packet_builder_sum_last_len then return current_packet_builder_sum_cache end

        if #current_packet_builder < current_packet_builder_sum_last_len then
            current_packet_builder_sum_cache = 0
            current_packet_builder_sum_last_len = 0
        end

        -- print("loop starting")
        for i = current_packet_builder_sum_last_len+1, #current_packet_builder, 1 do
            -- print(i, current_packet_builder_sum_last_len, #current_packet_builder)
            current_packet_builder_sum_cache = current_packet_builder_sum_cache + #current_packet_builder[i]
        end

        current_packet_builder_sum_last_len = #current_packet_builder

        return current_packet_builder_sum_cache

        -- -- Brute force alternative
        -- local sum = 0
        -- for _, packet_bytes in pairs(current_packet_builder) do
        --     sum = sum + #packet_bytes
        -- end
        -- return sum
    end

    local current_packet_start_time = song.instructions[1].start_time
    local start_time_in_bytes = uint_to_bytes(math.floor(current_packet_start_time))
    table.insert(current_packet_builder, start_time_in_bytes)


    ---@type table<integer, table<string, TrackInstruction>>    -- Always has the last seen modifier. Indexed by [TrackInstruction.track_index][TrackInstruction.type]
    local context_track_instructions = {}
    local next_context_track_index = nil    ---@type integer?   used with a next function to track what modifier to add this packet.
    local next_context_track_type = nil     ---@type string?    used with a next function to track what modifier to add this packet.

    local last_added_track_instructions = {}    ---@type table<integer, table<string, TrackInstruction>>    -- indexed by [TrackInstruction.track_index][TrackInstruction.type]

    --- May update current_packet, data_packets, and required_buffer_delay_in_milliseconds if needed
    ---
    ---@param instruction AnyInstruction
    ---@param instruction_index_in_song integer index into song.instructions for this instruction.
    local function add_instruction_to_final_packet_queue(instruction, instruction_index_in_song)
        local instruction_packet_part = song_instruction_to_packet_parts(instruction, current_packet_start_time)

        local instruction_will_not_fit_in_current_packet = get_current_packet_builder_sum() + #instruction_packet_part >= max_packet_length
        if instruction_will_not_fit_in_current_packet then -- we need to end the current packet and initialize a new one.
            local finished_packet = {}  ---@type PacketDataBytes

            for _, part in ipairs(current_packet_builder) do
                union_tables(finished_packet, part);
            end
            table.insert(data_packets, finished_packet)

            current_packet_builder = {}
            current_packet_builder_sum_cache = 0
            current_packet_builder_sum_last_len = 0

            current_packet_start_time = instruction.start_time
            local current_packet_start_time_in_bytes = uint_to_bytes(math.floor(current_packet_start_time)) -- packet start time.
            table.insert(current_packet_builder, current_packet_start_time_in_bytes)

            if ((#data_packets) * target_milliseconds_between_packets) - required_buffer_delay_in_milliseconds > current_packet_start_time then
                -- Too much time has passed for us to play this instruction on time.
                -- Bump required_buffer_delay_in_milliseconds so that the song starts later, giving us more time to send packets.
                required_buffer_delay_in_milliseconds = ((#data_packets) * target_milliseconds_between_packets) - current_packet_start_time
                print_debug("buffer time changed: "..tostring(required_buffer_delay_in_milliseconds / 1000).."s")
            end

            -- rebuild instruction_packet around new packet_start_time.
            instruction_packet_part = song_instruction_to_packet_parts(instruction, current_packet_start_time)

            local success, matching_context_instruction = pcall(function() -- pcall because I'm lazy and don't want to do all this nil checking.
                return instruction.is_track_instruction and context_track_instructions[instruction.track_index][instruction.type] or nil
            end)

            if success and matching_context_instruction then -- this current instruction should become the new context. Remove the match from the current context. It will be re-added when we insert this TrackInstruction.
                context_track_instructions[instruction.track_index][instruction.type] = nil
            end


            -- Add context / catch-up TrackInstructions after enough time

            if #data_packets % (math.ceil(pings_per_second)) == 0 then -- ~ 1 second should have passed. Let's include a catch-up / context TrackInstruction.

                if (not next_context_track_index) or (not context_track_instructions[next_context_track_index]) then
                    -- we have not selected a next_context_track_index. Select one now, if one exists
                    next_context_track_index = next(context_track_instructions, next_context_track_index)
                end
                if next_context_track_index then    -- we found a track with TrackInstructions

                    if (not next_context_track_type) or (not context_track_instructions[next_context_track_index][next_context_track_type]) then
                        -- we have not selected a next_context_track_type. Select one now, if one exists
                        next_context_track_type = next(context_track_instructions[next_context_track_index], next_context_track_type)
                    end
                    if next_context_track_type then
                        -- both next_context_track_index and _type are set to something. Let's add the matching context TrackInstruction to the start of the packet, then advance the context list
                        local context_instruction = context_track_instructions[next_context_track_index][next_context_track_type]

                        table.insert(current_packet_builder, song_instruction_to_packet_parts(context_instruction, nil))

                        -- see if most recently added instruction was actually a previously ignored instruction.
                        if      last_added_track_instructions[next_context_track_index]
                            and last_added_track_instructions[next_context_track_index][next_context_track_type] -- is truthy
                            and last_added_track_instructions[next_context_track_index][next_context_track_type] ~= context_instruction
                            and last_added_track_instructions[next_context_track_index][next_context_track_type].start_time < context_instruction.start_time
                        then -- this context that we just added was probably a TrackInstruction that we had skipped over. Set it as the new "most recently added"
                            last_added_track_instructions[next_context_track_index][next_context_track_type] = context_instruction
                        end

                        -- advance to next context part.
                        next_context_track_type = next(context_track_instructions[next_context_track_index], next_context_track_type)
                        if not next_context_track_type then -- we've ran out of types for this next_context_track_index. Advance next_context_track_index
                            next_context_track_index = next(context_track_instructions, next_context_track_index) -- may still return nil, but the initializer will take care of it.
                        end
                    end
                end
            end -- end of context TrackInstructions
        end -- end of instruction_will_not_fit

        -- Insert instruction
        if instruction.is_track_instruction then -- we need to decide if we should insert this TrackInstruction right now, or ignore it.
            ---@cast instruction TrackInstruction

            -- always add the instruction to the context. Why not. It'll be a 2nd chance to add this instruction early, tho the chance of that happening are very slim.
            if not context_track_instructions[instruction.track_index] then context_track_instructions[instruction.track_index] = {} end
            context_track_instructions[instruction.track_index][instruction.type] = instruction

            local there_is_enough_time_between_this_track_instruction_and_the_one_before_it = (
                (not last_added_track_instructions[instruction.track_index])    -- no TrackInstructions on this track. We can just add it now.
                or (not last_added_track_instructions[instruction.track_index][instruction.type])   -- no TrackInstructions of this type on this track. We can just add it now.
                or ( -- there must be a last_added instruction. if enough time has passed, we can add this instruction
                    (last_added_track_instructions[instruction.track_index][instruction.type].start_time + target_modifier_temporal_resolution) < instruction.start_time    -- culprit somewhere here???
                )
            )

            local function future_track_instructions_are_too_far_away_or_next_note_is_too_soon()
                -- print("scanning ahead for instruction", instruction)
                for i = instruction_index_in_song +1, #song.instructions, 1 do
                    -- print(i)
                    local test_instruction = song.instructions[i]
                    if test_instruction.start_time > instruction.start_time + modifier_gap_threshold then
                        -- we have not found a "landmark" instruction within range. Go ahead and insert this modifier now.

                        -- print("no landmarks.", true)
                        return true
                    end
                    if test_instruction.track_index == instruction.track_index then -- this instruction is relevant to us right now.
                        if test_instruction.is_track_instruction then
                            if test_instruction.type == instruction.type then -- this track instruction matches our own and is close to us. We don't need to insert right now.
                                -- print("next matching track too soon.", false)
                                return false
                            end
                            -- continue     -- here, test_instruction must be of a different TrackInstruction type. We don't really care about it. Let's continue to the next instruction
                        else
                            -- this is a normal note, and we have not seen a relevant track instruction between us and this note.
                            -- So let's insert ourselves now so that we know that note will be ready to play

                            -- print("normal note too soon.", true)
                            return true
                        end
                    end
                end
            end

            if there_is_enough_time_between_this_track_instruction_and_the_one_before_it or future_track_instructions_are_too_far_away_or_next_note_is_too_soon() then
                -- print("added instruction")
                table.insert(current_packet_builder, instruction_packet_part)
                if not last_added_track_instructions[instruction.track_index] then last_added_track_instructions[instruction.track_index] = {} end
                last_added_track_instructions[instruction.track_index][instruction.type] = instruction
            end

        else
            table.insert(current_packet_builder, instruction_packet_part)
        end
    end

    for instruction_index_in_song, instruction in ipairs(song.instructions) do

        if not (instruction.is_track_instruction and discard_track_instructions) then
            add_instruction_to_final_packet_queue(instruction, instruction_index_in_song)
        end

    end

    -- assemble final packet.

    local final_packet = {}
    for _, part in ipairs(current_packet_builder) do
        union_tables(final_packet, part)
    end
    table.insert(data_packets, final_packet)

    local data_packets_as_strings = {}  ---@type PacketDataString[]
    for _, data_packet_in_bytes in ipairs(data_packets) do
        table.insert(data_packets_as_strings, packet_data_bytes_to_string(data_packet_in_bytes))
    end

    return data_packets_as_strings, required_buffer_delay_in_milliseconds + (1 * target_milliseconds_between_packets)
end

---@param control_code ControlPacketCode
---@return PacketDataString
local function make_control_packet(control_code)
    return packet_data_bytes_to_string( uint_to_bytes(control_code) )
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
    get_target_ms_between_packets = function() return target_milliseconds_between_packets end,
}

return packet_builder_api
