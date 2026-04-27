
-- decoder creates processed songs and configs for those songs.

-- There should be no ping functions here. This entire file must be runable on the viewer.

-- who should be in charge of knowing what song a packet belongs to? (Who tracks the transfer id?)

-- IDEA: two types of functions here. Receivers, and converters.
--      Converters just transform the data from packets to tables
--      Receivers actualy keep track of trasfer IDs and ongoing assembly.

---@class PacketDecoderApi
local packet_receiver_api = {
    receive_packet            = function() end,
    receive_local_packet      = function() end,

    ---@type fun(packet_data:BundledPacket):Song
    song_header_from_packets  = function(packet_data) end,

    ---@type fun(partial_song:Song, packet_data:BundledPacket):Song
    song_config_from_packets  = function(partial_song, packet_data) end,

    ---@type fun(partial_song:Song, packet_data:BundledPacket):Song
    instructions_from_packets = function(partial_song, packet_data) end,
}

return packet_receiver_api
