
-- Packets are used both for pings and local song storage.
-- "Local" meaning bundled with the avatar upload.
-- Packets must be small enough to
--  1. Fit into the ping requirements
--  2. Be processable but the lowest supported permission level.

-- Ping limits:
-- Fewer than 32 pings in one second (~32 milis between packets min)
-- Fewer than 1024 bytes per second (~1 byte/mili)

local max_packet_length = 75-2            -- In bytes. (-2 because storing packets as a string adds 2 bytes to encode the packet string's length)
local target_milis_between_packets = 150   -- How long the ping system should try to wait before sending another packet. (Tick event adds 50 milis of possible drift to account for.)
-- ~6.6 packets/second, 75 bytes per packet, ~500 bytes per second. Roughly half of avatar's total ping quota.


local packet_builder_api = {
    song_header_to_packets    = function() end,
    song_config_to_packets    = function() end,
    instructions_to_packets   = function() end,
}

return packet_builder_api
