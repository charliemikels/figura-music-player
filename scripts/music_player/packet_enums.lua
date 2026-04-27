
-- Shared enums and type definitions between the various packet-processing scripts.

---@alias PartialPacketDataBytes Byte[] Can represent an instruction, or a modifier for an earlier instruction


---@enum SongPacketTypeIDs
local packet_type_ids = {
    control = 0,   -- A very tiny packet to send a few simple control codes.
    header = 1, -- Includeds initial like name, duration, track_types
    data = 2,   -- Bulk of the packet stream
    config = 3, -- A packet that might appear to update a song's configuration
}

---@enum ControlPacketCode
local control_packet_codes = {
    stop = 0,       -- Stop a song by it's transfered ID
    start = 1,      -- Play a song by it's transfered ID
    remove = 2,     -- Delete a song from the transfered song list
}


---@class PacketEnumsAPI
local packet_enums_api = {
    packet_type_ids = packet_type_ids,
    control_packet_codes = control_packet_codes,
}

return packet_enums_api
