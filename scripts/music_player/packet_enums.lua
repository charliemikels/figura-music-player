
-- Shared enums and type definitions between the various packet-processing scripts.



---@alias Byte integer  -- Should be between 0x00 and 0xFF

---@alias PartialPacketDataBytes Byte[] Can represent an instruction, or a modifier for an earlier instruction

---@alias PacketDataBytes Byte[]

--- When sending raw data through pings, Strings are far more efficient than tables.
---
--- The final size will be the length of the SongPacket table + 2 bytes for the string's length info.
---@alias PacketDataString string

---@enum PacketTypeIDs
local packet_type_ids = {
    control = 0,    -- A very tiny packet to send a few simple control codes.
    header = 1,     -- Includeds initial like name, duration, track_types
    data = 2,       -- Bulk of the packet stream
    config = 3,     -- A packet that might appear to update a song's configuration
}

---@enum ControlPacketCode
local control_packet_codes = {
    stop = 0,       -- Stop a song by it's transfered ID
    start = 1,      -- Play a song by it's transfered ID
    remove = 2,     -- Delete a song from the transfered song list
}

---@enum ModifierTypeCodes
local modifier_key_to_number = {
    volume = 1,
    pitch_wheel = 2,
    -- pan = 3,
}

--- Reverse of modifier_type_codes for reverse lookups
---@type table<ModifierTypeCodes, string>
local modifier_number_to_key = {}
for name, id in pairs(modifier_key_to_number) do
    modifier_number_to_key[id] = name
end


---@class PacketEnumsAPI
local packet_enums_api = {
    packet_type_ids = packet_type_ids,
    control_packet_codes = control_packet_codes,
    modifier_key_to_number = modifier_key_to_number,
    modifier_number_to_key = modifier_number_to_key,
}

return packet_enums_api
