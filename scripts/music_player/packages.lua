
local max_packet_length = 800   -- in bytes
local max_packet_per_sec = 1.2



local songs_turned_into_packets_so_far = 1  -- used to get the ID of the current song.


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
local function vlq_to_int_from_packet(packet_reader)
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
    local len_string = vlq_to_int_from_packet(reader)
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
    header = 1, -- Includeds initial like name, durration, track_types
    data = 2,   -- Bulk of the packet stream
    config = 3, -- A packet that might appear to update a song's configuration
}

--- Builds a config packet out of a SongPlayerConfig table.
---
--- This can be used at any time to update a remote song's configuration.
---@param player_config SongPlayerConfig
---@return SongPacket
local function build_config_packet(player_config)

    local config_packet_body = {}

    local source_table = {}
    do
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
    end
    union_tables(config_packet_body, source_table)



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
local function build_header_packet_without_buffer(processed_song)
    local packet = {}
    union_tables(packet, string_to_bytes_with_len(processed_song.name))

    union_tables(packet, int_to_vlq(
        math.ceil(processed_song.durration) -- At 144FPS, the player can only update every 5ms ceil to drop sub-milisecond precission.
    ))

    local track_type_bits = {}
    for _, track in ipairs(processed_song.tracks) do
        table.insert(track_type_bits, track.instrument_type_id)
    end
    union_tables(packet, int_to_vlq(#track_type_bits))
    union_tables(packet, int_to_vlq(bit_list_to_number(track_type_bits)))
    return packet
end

---Immediatly converts an entire ProcessedSong and any config data into a list of packets
---@param processed_song ProcessedSong
---@param player_config SongPlayerConfig
---@return PackedSongPacket[]
local function song_to_packets(processed_song, player_config)
    local header_packet_body = build_header_packet_without_buffer(processed_song)
    local config_packet_body = build_config_packet(player_config)
    local complete_data_packets = {}



    local header_packet_head = {}
    union_tables(header_packet_head, int_to_vlq(packet_ids.header))  -- First element is allways packet ID

    ---A unique ID for each song since the avatar loaded.
    local transfered_song_id = int_to_vlq(songs_turned_into_packets_so_far)
    songs_turned_into_packets_so_far = songs_turned_into_packets_so_far +1
    union_tables(header_packet_head, transfered_song_id)             -- 2nd element is allways the song transfer ID


    local there_is_enough_space_to_combine_the_header_and_config_packets = true -- TODO
    if there_is_enough_space_to_combine_the_header_and_config_packets then
        union_tables(header_packet_body, config_packet_body)
    end

    -- TODO: append a buffer time to the end of header_packet
    local header_packet_final = union_tables(header_packet_head, header_packet_body)
    printTable(header_packet_final)
    local packed_header_packet_final = pack_packet(header_packet_final)

    return { packed_header_packet_final }
end




-- == Receiving functions == --



-- The colection of songs received from the Host (or whatever called add_packet_to_song).
-- These are indexed by a host-controlled integer, and are uniquely identifiable in this way.
---@type table<integer, {song: ProcessedSong, player: PlayingSongController}>
local collected_incomming_songs = {}

---Reads a config packet out of a Reader.
---Returns nothing, but modifies collected_incomming_songs[transfered_song_id]
---@param reader PacketReader           Where the packet id and transfer song ID have already been read
---@param transfered_song_id integer    Index into collected_incomming_songs
local function receive_config_packet(reader, transfered_song_id)
    ---@type SongPlayerConfig
    local config_data = {}

    do -- source position / entity
        local bool_list_int = vlq_to_int_from_packet(reader)
        if bool_list_int == nil then
            -- The boolean list used to flag info about the source is missing. Source info was not provided.
        else
            local bool_list = int_to_bool_list(bool_list_int, 7)
            local source_is_entity = bool_list[1]
            if source_is_entity then
                local flip_uuid_int_1 = bool_list[4]
                local flip_uuid_int_2 = bool_list[5]
                local flip_uuid_int_3 = bool_list[6]
                local flip_uuid_int_4 = bool_list[7]

                local uuid_part_1 = vlq_to_int_from_packet(reader) * (flip_uuid_int_1 and -1 or 1)
                local uuid_part_2 = vlq_to_int_from_packet(reader) * (flip_uuid_int_2 and -1 or 1)
                local uuid_part_3 = vlq_to_int_from_packet(reader) * (flip_uuid_int_3 and -1 or 1)
                local uuid_part_4 = vlq_to_int_from_packet(reader) * (flip_uuid_int_4 and -1 or 1)

                local uuid_string = client.intUUIDToString(uuid_part_1, uuid_part_2, uuid_part_3, uuid_part_4)

                local success, possible_entity = pcall(world.getEntity, uuid_string)
                if success and possible_entity then
                    config_data.source_entity = possible_entity
                else
                    print("There was an error getting the entity with uuid:", uuid_string)
                    if not success
                        then print("world.getEntity returned this error:", possible_entity)
                        else print("world.getEntity returned nil (Entity not loaded).")
                    end
                end

            else
                local flip_x = bool_list[2]
                local flip_y = bool_list[3]
                local flip_z = bool_list[4]
                local add_half_x = bool_list[5]
                local add_half_y = bool_list[6]
                local add_half_z = bool_list[7]

                local abs_floor_x = vlq_to_int_from_packet(reader)
                local abs_floor_y = vlq_to_int_from_packet(reader)
                local abs_floor_z = vlq_to_int_from_packet(reader)

                local source_x_pos = (abs_floor_x + (add_half_x and 0.5 or 0)) * (flip_x and -1 or 1)
                local source_y_pos = (abs_floor_y + (add_half_y and 0.5 or 0)) * (flip_y and -1 or 1)
                local source_z_pos = (abs_floor_z + (add_half_z and 0.5 or 0)) * (flip_z and -1 or 1)

                config_data.source_pos = vec(source_x_pos, source_y_pos, source_z_pos)
                print(config_data.source_pos)
            end
        end
    end



    if not collected_incomming_songs[transfered_song_id].player then
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
    collected_incomming_songs[transfered_song_id] = {}

    local name = bytes_with_len_to_string_from_reader(reader)
    local durration = vlq_to_int_from_packet(reader)

    local num_tracks = vlq_to_int_from_packet(reader)
    local track_type_id_flags = int_to_bit_list(vlq_to_int_from_packet(reader), num_tracks)
    ---@type Track[]
    local tracks = {}
    for i, type in ipairs(track_type_id_flags) do
        tracks[i] = {instrument_type_id = type}
    end

    ---@type ProcessedSong
    local incomming_processed_song = {
        name = name,
        durration = durration,
        tracks = tracks,
        instructions = {},
        buffer_delay = 0,
        buffer_start_time = client:getSystemTime()
    }

    collected_incomming_songs[transfered_song_id] = { song = incomming_processed_song, player = nil }

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

-- function lookup table for packet receiver
---@type table<string, fun(reader: PacketReader, transfered_song_id: integer)>
local packet_receiving_functions = {
    [packet_ids.header] = receive_header_packet,
    [packet_ids.config] = receive_config_packet,
    [packet_ids.data] = function () end,
}

---Primary function to receive packets. Distributes packets to the correct receiving functions.
---@param packed_packet_data PackedSongPacket
local function add_packet_to_song(packed_packet_data)
    local packet_data = unpack_packet(packed_packet_data)
    local reader = new_packet_reader(packet_data)
    local packet_id = vlq_to_int_from_packet(reader)
    local transfered_song_id = vlq_to_int_from_packet(reader)
    packet_receiving_functions[packet_id](reader, transfered_song_id)
end

return {
    song_to_packets = song_to_packets,
    add_packet_to_song = add_packet_to_song,
    list_transfered_songs = function() return collected_incomming_songs end
}
