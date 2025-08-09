
local max_packet_length = 800   -- in bytes
local max_packet_per_sec = 1.2



local songs_turned_into_packets_so_far = 0  -- used to get the ID of the current song.


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

---Convert an integer into a variable-length-quantity byte list
---@param integer integer
---@return Byte[]
local function int_to_vlq(integer)
    local bytes = { integer % 128 }
    integer = math.floor(integer / 128)
    while integer > 0 do
        table.insert(bytes, 1, 0x80 + (integer % 128))
        integer = math.floor(integer / 128)
    end
    return bytes
end

---Convert a variable-length-quantity into an integer and advances PacketReader's index.
---@param packet_reader PacketReader
---@return integer
local function vlq_to_int_from_packet(packet_reader)
    local bytes = packet_reader.bytes
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
---@param str string
---@return Byte[]
local function string_to_bytes_with_len(str)
    local tableized_string = table.pack( string.byte(str, 1, -1) )
    local tableized_length = int_to_vlq(tableized_string.n)
    tableized_string.n = nil
    return union_tables(tableized_length, tableized_string)
end

---Reads a string (including the length at the beginning) out of a PacketReader's bytes
---@param reader PacketReader
---@return string
local function bytes_to_string_with_len_from_reader(reader)
    local len_string = vlq_to_int_from_packet(reader)
    local str = string.char(table.unpack( reader.bytes, reader.index, reader.index+len_string-1 ))
    reader.index = reader.index + len_string
    return str
end

--- Effectively converts 5 → `101` → {1, 0, 1}.
--- If expected_len > results_list, append false to left side (`101` → `00101`)
--- Used to assign percussion tracks to incomming songs
local function int_to_bit_list(int, length)
    local bits = {}
    for bit_index = length, 1, -1 do
        local bit = math.fmod(int, 2)
        bits[bit_index] = bit
        int = math.floor((int - bit) / 2)
    end
    return bits
end

--- Effectively converts {true, false, true} → `101` → 5
local function bit_list_to_number(bits)
    return tonumber(table.concat(bits), 2)
end


---@alias SongDataPacket Byte[]
---@alias SongHeaderPacket Byte[]
---@alias SongPacket SongDataPacket|SongHeaderPacket

---A helper that wraps a list of bytes with an index,
---@param bytes SongDataPacket
---@return PacketReader
local function new_packet_reader(bytes)
    ---@class PacketReader
    local reader = {
        bytes = bytes,  ---@type SongDataPacket
        index = 1,      ---@type integer
    }
    return reader
end

local packet_ids = {
    header = 1, -- Includeds initial like name, durration, track_types
    data = 2,   -- Bulk of the packet stream
    config = 3, -- A packet that might appear to update a song's configuration.
}

---comment
---@param processed_song ProcessedSong
---@param player_config SongPlayerConfig
---@return SongPacket[]
local function song_to_packets(processed_song, player_config)
    printTable(processed_song)

    local header_packet = {}

    ---A unique ID for each song since the avatar loaded.
    local transfered_song_id = int_to_vlq(songs_turned_into_packets_so_far)
    songs_turned_into_packets_so_far = songs_turned_into_packets_so_far +1
    union_tables(header_packet, transfered_song_id)

    union_tables(header_packet, int_to_vlq(packet_ids.header))

    union_tables(header_packet, string_to_bytes_with_len(processed_song.name))

    union_tables(header_packet, int_to_vlq(
        math.ceil(processed_song.durration) -- At 144FPS, the player can only update every 5ms ceil to drop sub-milisecond precission.
    ))

    local track_type_bits = {}
    for _, track in ipairs(processed_song.tracks) do
        table.insert(track_type_bits, track.instrument_type_id)
    end
    union_tables(header_packet, int_to_vlq(#track_type_bits))
    union_tables(header_packet, int_to_vlq(bit_list_to_number(track_type_bits)))


    -- TODO: append a buffer time to the end of header_packet
    return { header_packet }
end

---comment
---@param packet_data SongPacket
local function add_packet_to_song(packet_data)
    local reader = new_packet_reader(packet_data)
    local transfered_song_id = vlq_to_int_from_packet(reader)
    print("transfered_song_id", transfered_song_id)

    local packet_id = vlq_to_int_from_packet(reader)

    if packet_id == packet_ids.header then
        local name = bytes_to_string_with_len_from_reader(reader)
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

        printTable(incomming_processed_song)
    end

end

return {
    song_to_packets = song_to_packets,
    add_packet_to_song = add_packet_to_song,
}
