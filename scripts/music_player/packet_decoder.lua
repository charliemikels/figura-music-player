
-- decoder creates processed songs and configs for those songs.

-- There should be no ping functions here. This entire file must be runable on the viewer.

---@class PacketDecoderInfo -- Stored inside a Song so that we can have information about any ongoing decoding processes
---@field instructions_with_modifier_ids table<integer, Instruction>

---@class PacketDecoderApi
local packet_receiver_api = {

    ---@type fun(packet_data:BundledPacket):Song
    new_song_from_header_packet  = function(packet_data)

        return {}
    end,

    ---@type fun(partial_song:Song, packet_data:BundledPacket):Song
    add_config_to_song_from_packet  = function(partial_song, packet_data) return {} end,

    ---@type fun(partial_song:Song, packet_data:BundledPacket):Song
    add_instructions_to_song_from_packet = function(partial_song, packet_data)

        return {}
    end,

    ---@type fun(controller:SongPlayerController, packet_data:BundledPacket):SongPlayerController
    controll_player_from_packet = function(controller, packet_data) return {} end,
}

return packet_receiver_api
