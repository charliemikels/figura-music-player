
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
    song_header_from_packets  = function(partial_song, packet_data) end,
    song_config_from_packets  = function(partial_song, packet_data) end,
    instructions_from_packets = function(partial_song, packet_data) end,
}

return packet_receiver_api
