
-- Shared constants, enums, lookups, etc for the various packet functions.

---@enum ControlPacketCode
local control_packet_codes = {
    stop = 0,       -- Stop a song by it's transfered ID
    start = 1,      -- Play a song by it's transfered ID
    remove = 2,     -- Delete a song from the transfered song list
}



local packet_schema = {
    {data_type = "integer", source = nil, name = "Delta since start of song"},
    {data_type = "table", source = {
        {--[[ start_time ]]},
        {--[[ instruction or modifier part. Is this a table part? ]]},
        {--[[ idk ]]}
    }, name = "instructions and modifiers"}

}





---@class PacketSchemaAPI
local packet_schema_api = {
    control_packet_codes = control_packet_codes
}

return packet_schema_api
