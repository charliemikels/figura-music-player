



local packet_receiver_api = {
    receive_packet            = function() end,
    receive_local_packet      = function() end,
    song_header_from_packets  = function() end,
    song_config_from_packets  = function() end,
    instructions_from_packets = function() end,
}

return packet_receiver_api
