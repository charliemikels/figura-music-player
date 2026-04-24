
-- Packets are used both for pings and local song storage.
-- "Local" meaning bundled with the avatar upload.
-- Packets must be small enough to
--  1. Fit into the ping requirements
--  2. Be processable but the lowest supported permission level.

-- Ping limits:
-- Fewer than 32 pings in one second (~32 milis between packets min)
-- Fewer than 1024 bytes per second (~1 byte/mili)

local packets_per_second = 6
local bytes_per_second = 500

-- In bytes. (-2 because storing packets as a string adds 2 bytes to encode the packet string's length)
local max_packet_length = math.floor(bytes_per_second / packets_per_second) - 2
-- How long the ping system should try to wait before sending another packet.
-- (Tick event adds 50 milis (1/20th of a second) of possible drift to account for.)
local target_milis_between_packets = math.ceil(1000 / packets_per_second)


---@class PacketEncoderApi
local packet_builder_api = {
    song_header_to_packets    = function() end,     -- TODO: since I'm thinking about it: buffer time should start counting _after_ the first instruction packet is received. (That is, buffer time excludes config and header packet time). This means we won't have to recalculate buffer time if we set a bunch of instruments. (new state?: "applying configuration")
    song_config_to_packets    = function() end,
    instructions_to_packets   = function() end,

    get_packets_per_second    = function() return packets_per_second end,
    get_bytes_per_second      = function() return bytes_per_second   end,
    get_max_packet_length     = function() return max_packet_length  end,
    get_target_milis_between_packets = function() return target_milis_between_packets end,
}

return packet_builder_api
