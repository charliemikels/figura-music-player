local packet_decoder_api = require("./packet_decoder")  ---@type PacketDecoderApi
local packet_encoder_api = require("./packet_encoder")  ---@type PacketEncoderApi
local packet_enums_api   = require("./packet_enums")    ---@type PacketEnumsAPI


local do_debug_prints = false
local function print_debug(...) if do_debug_prints then print(...) end end
local function printTable_debug(...) if do_debug_prints then printTable(...) end end
local function print_host(...) if host:isHost() or do_debug_prints then print(...) end end


local songs_turned_into_packets_so_far = 0  -- used to build a unique ID number for each transfered song





---Immediatly converts an entire ProcessedSong and any config data into a list of packets
---@param processed_song Song
---@param player_config SongPlayerConfig
---@return BundledPacket[]
local function song_to_packets(processed_song, player_config)
    ---A unique ID for each song since the avatar loaded.
    local transfered_song_id = songs_turned_into_packets_so_far
    songs_turned_into_packets_so_far = songs_turned_into_packets_so_far +1

    local all_data_packets, buffer_delay =  packet_encoder_api.build_data_packets_and_buffer_time(processed_song)
    local header_packet = packet_encoder_api.build_header_packets(processed_song, buffer_delay)
    local config_packet = packet_encoder_api.build_config_packet(player_config)

    ---@type BundledPacket[]
    local final_packet_list = {}

    table.insert(final_packet_list, {
        transfered_song_id = transfered_song_id,
        packet_type = packet_enums_api.packet_type_ids.header,
        packet_data_string = header_packet
    })
    table.insert(final_packet_list, {
        transfered_song_id = transfered_song_id,
        packet_type = packet_enums_api.packet_type_ids.config,
        packet_data_string = config_packet
    })

    for _, data_packet in ipairs(all_data_packets) do
        table.insert(final_packet_list, {
            transfered_song_id = transfered_song_id,
            packet_type = packet_enums_api.packet_type_ids.data,
            packet_data_string = data_packet
        })
    end

    return final_packet_list
end

local control_packet_codes = packet_enums_api.control_packet_codes

-- The colection of songs received from the Host (or whatever called add_packet_to_song).
-- These are indexed by a host-controlled integer, and are uniquely identifiable in this way.
---@type table<integer, {song: Song, player: SongPlayerController}>
local collected_incoming_songs = {}

-- list of transfer IDs that we must have missed
--
-- Allows us to throw a warning the first time, and ignore followup missing songs.
---@type table<integer, boolean>
local missed_incoming_songs = {}



---@param transfered_song_id integer
---@param packet_data_string PacketDataString
local function receive_data_packet(transfered_song_id, packet_data_string)
    if not collected_incoming_songs[transfered_song_id] then
        if not missed_incoming_songs[transfered_song_id] then
            print_debug("Received a data packet for song with transfer ID `"..tostring(transfered_song_id).."` before receiving a header packet for the song. Future lost packets for this song will be ignored.")
            missed_incoming_songs[transfered_song_id] = true
        end
        return
    end

    packet_decoder_api.add_instructions_to_song_from_packet(
        collected_incoming_songs[transfered_song_id].song,
        packet_data_string
    )
end


---@param transfered_song_id integer
---@param packet_data_string PacketDataString
local function receive_config_packet(transfered_song_id, packet_data_string)
    if not collected_incoming_songs[transfered_song_id] then
        if not missed_incoming_songs[transfered_song_id] then
            print_debug("Received a config packet for song with transfer ID `"..tostring(transfered_song_id).."` before receiving a header packet for the song. Future lost packets for this song will be ignored.")
            missed_incoming_songs[transfered_song_id] = true
        end
        return
    end

    local new_config = packet_decoder_api.new_config_from_packet(packet_data_string)
    collected_incoming_songs[transfered_song_id].player.set_new_config(new_config)
end

---@param transfered_song_id integer
---@param packet_data_string PacketDataString
local function receive_header_packet(transfered_song_id, packet_data_string)
    -- This is a header packet. Even if the song with this ID already exists, the host is clearly sending a new one. Purge this data.
    collected_incoming_songs[transfered_song_id] = {}

    local new_song = packet_decoder_api.new_song_from_header_packet(packet_data_string)

    ---@type SongPlayerAPI
    local player_api = require("./player")

    collected_incoming_songs[transfered_song_id] = {
        song = new_song,
        player = player_api.new_player(new_song, nil)
    }
    return new_song
end


---@param transfered_song_id integer
---@param packet_data_string PacketDataString
local function receive_control_packet(transfered_song_id, packet_data_string)
    if not collected_incoming_songs[transfered_song_id] then
        if not missed_incoming_songs[transfered_song_id] then
            print_debug("Received a control packet for song with transfer ID `"..tostring(transfered_song_id).."` before receiving a header packet for the song. Future lost packets for this song will be ignored.")
            missed_incoming_songs[transfered_song_id] = true
        end
        return
    end

    packet_decoder_api.controll_player_from_packet(
        collected_incoming_songs[transfered_song_id].player,
        packet_data_string
    )
end

-- function lookup table for packet receiver
---@type table<PacketTypeIDs, fun(transfered_song_id: integer, packet_data_string:PacketDataString)>
local packet_receiving_functions = {
    [packet_enums_api.packet_type_ids.control] = receive_control_packet,
    [packet_enums_api.packet_type_ids.header] = receive_header_packet,
    [packet_enums_api.packet_type_ids.data] = receive_data_packet,
    [packet_enums_api.packet_type_ids.config] = receive_config_packet,
}


local local_receive_packet_loop_is_running = false
local incoming_packed_packets = {}  ---@type BundledPacket[]

--- Primary function to receive packets. Distributes packets to the correct receiving functions.
---
--- There seems to be a rare chance that two pings may be bundled and processed in the same tick.
--- By running in a tick event, we ensure that, on the off chance we receive two pings on the same tick, that we process them on diffrent ticks.
---@see local_receive_packet
local function local_receive_packet_loop()
    ---@type BundledPacket
    local incomming_bundled_packet = table.remove(incoming_packed_packets, 1)   -- table.remove is usualy inneficient when popping from the front. But we shouldn't have more than like 2 packets in here at a time, so should be fine.
    packet_receiving_functions[incomming_bundled_packet.packet_type](incomming_bundled_packet.transfered_song_id, incomming_bundled_packet.packet_data_string)

    if #incoming_packed_packets == 0 then
        events.TICK:remove(local_receive_packet_loop)
        local_receive_packet_loop_is_running = false
    end
end

--- Receives a packet and passes it to the TICK event loop.
---
--- Pings appear to have their own instruction limits sepperate from TICK or RENDER or whatever, but this limit isn't displayed anywhere.
--- Furehtermore, if we send pings too quickly, it seems that pings may get bundled and processed on the same tick, meaning the instruction
--- cost of pings can occasionaly double without warning.
---
--- Dispatch to our own TICK loop, so that we can control when we process these pings, and prevent doubleing up.
---
--- @see avatar:getCurrentInstructions
---
--- That said, if my assumption is correct, then the ping "event" gives us free instructions to work with. It may be worth while
--- to find a new way to process pings so that we don't share TICK instructions with the rest of the avatar.
---
---@see local_receive_packet_loop
---@param transfered_song_id integer
---@param packet_type PacketTypeIDs
---@param packet_data_string PacketDataString
local function local_receive_packet(transfered_song_id, packet_type, packet_data_string)
    ---@type BundledPacket
    local bundled_packet = {
        transfered_song_id = transfered_song_id,
        packet_type = packet_type,
        packet_data_string = packet_data_string,
    }

    table.insert(incoming_packed_packets, bundled_packet)
    if not local_receive_packet_loop_is_running then
        local_receive_packet_loop_is_running = true
        events.TICK:register(local_receive_packet_loop)

    end
end

--- primary ping function. It receives a packet and sends it off for processing
--- On the off chance that pings need to be unique (idk at the moment): `TL_FMP` → Tanner Limes Figura Mucic Player
---@param transfer_id integer
---@param packet_type PacketTypeIDs
---@param incoming_packet PacketDataString
function pings.TL_FMP_receive_packet(transfer_id, packet_type, incoming_packet)
    local_receive_packet(transfer_id, packet_type, incoming_packet)
end

---@param transfer_id integer
---@param packet_type PacketTypeIDs
---@param outgoing_packed_packet PacketDataString
local function ping_packet_immediatly(transfer_id, packet_type, outgoing_packed_packet)
    pings.TL_FMP_receive_packet(transfer_id, packet_type, outgoing_packed_packet)
end

---@alias BundledPacket {transfered_song_id: integer, packet_type: PacketTypeIDs, packet_data_string: PacketDataString}    -- a light weight way to keep a packet tied to it's packet ID and transfer ID.

---@alias PacketQueue BundledPacket[]

local outgoing_packet_queue_index = 1   ---@type integer        Index into outgoing_packet_queue. Using an index so that we don't have to remove items from the list.
local outgoing_bundled_packets_queue = {}        ---@type PacketQueue

local ping_loop_start_time

local ping_loop_identifier = "TL_FMP_song_data_ping_loop"

local function stop_and_cleanup_packet_ping_loop()
    outgoing_bundled_packets_queue = {}
    outgoing_packet_queue_index = 1
    ping_loop_start_time = nil
    events.WORLD_TICK:remove(ping_loop_identifier)
end

--- Searches upcoming packets in outgoing_packet_queue and skips/removes any that match transfered_song_id_to_cancel
---
--- Only really useful if there are multiple songs in the queue, which should never happen if the HOST is only useing ui.lua.
--- But if the host is doing something clever with multiple players, or multiple UIs, this fn is nessesary.
---
--- Item removal logic based on https://stackoverflow.com/a/53038524
---@see stop_and_cleanup_packet_ping_loop
---@param transfered_song_id_to_cancel integer
local function remove_packets_from_outgoing_queue_by_transfer_id(transfered_song_id_to_cancel)
    local size_of_hole = 0

    for search_index =
        outgoing_packet_queue_index, -- we can ignore packets that we've already sent.
        #outgoing_bundled_packets_queue
    do
        local should_delete_packet = outgoing_bundled_packets_queue[search_index].transfered_song_id == transfered_song_id_to_cancel
        if not should_delete_packet then
            if (size_of_hole > 0) then
                -- We want to keep this value, but there's a hole in the list. Slide the value so that we fill the hole.
                outgoing_bundled_packets_queue[search_index - size_of_hole] = outgoing_bundled_packets_queue[search_index]
                outgoing_bundled_packets_queue[search_index] = nil
            end
        else
            if outgoing_packet_queue_index == search_index then
                -- In this situation, we can just skip the packet instead of modifying the table
                outgoing_packet_queue_index = outgoing_packet_queue_index + 1
            else
                outgoing_bundled_packets_queue[search_index] = nil
                size_of_hole = size_of_hole + 1
            end
        end
    end

    -- Any nils we created should have propigated to the end of the queue by now.
    -- But since lua considers the length to the index of the last non-nil value,
    -- it effectively means the list has shrunk, so #outgoing_packet_queue sould
    -- accuratly represent the new size.
    if outgoing_packet_queue_index > #outgoing_bundled_packets_queue then stop_and_cleanup_packet_ping_loop() end
end

--- outgoing_packet_queue needs to stay in order, so it's simpler to keep an index
--- (outgoing_packet_queue_index) rather than to actualy remove packets from the list.
--- But this does mean that outgoing_packet_queue will constantly grow since no items
--- are removed.
---
--- Typicaly this isn't really a problem, because the queue gets reset  whenever we
--- reach the end, but if some power user is constantly dumping stuff into the network,
--- we might not reach it.
---
--- It's at least nice to have this function around
local function remove_already_sent_packets_from_outgoing_packet_queue()
    if outgoing_packet_queue_index == 1 then
        -- outgoing_packet_queue has no sent packets
        return
    end

    -- table.move() isn't available in Lua 5.2, but combineing pack and unpack should get us close enough
    local new_outgoing_packet_queue = table.pack(table.unpack(outgoing_bundled_packets_queue, outgoing_packet_queue_index))
    new_outgoing_packet_queue.n = nil   -- table.pack adds an `n` field that we don't want.
    outgoing_bundled_packets_queue = new_outgoing_packet_queue   ---@type PacketQueue

    outgoing_packet_queue_index = 1
    if outgoing_packet_queue_index > #outgoing_bundled_packets_queue then stop_and_cleanup_packet_ping_loop() end
end

--- Host-side event loop to emit pings from the ping queue
local function ping_loop()
    if ping_loop_start_time + (packet_encoder_api.get_target_milis_between_packets() * (outgoing_packet_queue_index -1)) < client:getSystemTime() then
        -- we can emit another packet
        -- Note that this condition may be true in situations where the time between
        -- two packets is slightly _less_ than target_milis_between_packets.
        -- It will still be the average, but enabling us to send a packet slightly
        -- early will avoid the "slip" caused from missing the perfect time to emmit a packet.

        print_debug("pinging packet #"..tostring(outgoing_packet_queue_index).."/"..tostring(#outgoing_bundled_packets_queue).."…")

        pings.TL_FMP_receive_packet(
            outgoing_bundled_packets_queue[outgoing_packet_queue_index].transfered_song_id,
            outgoing_bundled_packets_queue[outgoing_packet_queue_index].packet_type,
            outgoing_bundled_packets_queue[outgoing_packet_queue_index].packet_data_string
        )

        outgoing_packet_queue_index = outgoing_packet_queue_index + 1

        -- check if list is empty
        if outgoing_packet_queue_index > #outgoing_bundled_packets_queue then print_host("All pings sent."); stop_and_cleanup_packet_ping_loop() end
    end
end

--- Reusable start-the-ping-loop function. Does not start the loop if it's already running
local function check_or_start_ping_loop()
    if ping_loop_start_time then
        return
    else
        print_debug("Starting ping loop")
        events.WORLD_TICK:register(ping_loop, ping_loop_identifier)
        ping_loop_start_time = client:getSystemTime()
    end
end

---Adds a single packet to the packet queue.
---
--- Probably unnessesary. most of the time that we want to ping something,
--- we either want to ping it ASAP, or we're pinging bulk data.
---@param outgoing_bundled_packet BundledPacket
local function ping_packet(outgoing_bundled_packet)
    table.insert(outgoing_bundled_packets_queue, outgoing_bundled_packet)
    check_or_start_ping_loop()
end

---Add several packets to the packet queue
---@param outgoing_bundled_packets BundledPacket[]
local function ping_packets(outgoing_bundled_packets)
    for _, bundled_packet in ipairs(outgoing_bundled_packets) do
        table.insert(outgoing_bundled_packets_queue, bundled_packet)
    end
    check_or_start_ping_loop()
end

---@return number
local function outgoing_packet_queue_progress()
    if #outgoing_bundled_packets_queue == 0 then return 1 end
    return outgoing_packet_queue_index / #outgoing_bundled_packets_queue
end

--- A SongPlayer wrapper that plays the a song on all clients (viewers and host).
---
--- Use this instead of manualy working with the networking / packet building process.
---
--- Host Only. May turn a song into packets (expensive) and call ping functions.
---@param processed_song Song
---@param player_config SongPlayerConfig
---@return SongPlayerController
local function new_network_song_player(processed_song, player_config)
    local song_player_api = require("./player")      ---@type SongPlayerAPI
    if not host:isHost() then -- The caller is a viewer. They will not be able to do any syncronization with other clients, so just give them a normal player.
        return song_player_api.new_player(processed_song, player_config)
    end

    -- local our_song_player_controller = song_player_api.new_player(processed_song, player_config)
    -- ---@class SongPlayerController
    -- net_player = {}
    -- for k,fn in pairs(our_song_player_controller) do net_player[k] = fn end

    -- if processed_song.is_local then -- The song is local. We won't need to ping data.
    --     error("Implement new_network_song_player's `processed_song.is_local` logic")    -- TODO
    -- else -- The song is not local. We need to turn the song into packets and send that over
    -- end

    -- TODO: Set up the remote player. Immediatly ping the song's header packets (Or whatever method we need to do for local songs).
    --       This will be enough to create a remote/transfered player with an empty config.


    -- TODO: Get the remote player build a controller arround it. For most set functions, we'll need to ping data over. But we can also look at ourself for most other actions.


    -- TODO: Figure out how we want to represent local songs with a newtwork relationship.



    -- TODO: Remove play_immediatly as a config paramiter. We don't need to do magic to get things to play if we can just talk to the remote player with control codes.

    -- This wraper needs to
    --  - [ ] Know if a song will processable/accessable to client already. (If it's a local song)
    --      - [ ] Allways assume the client will need to build the data. (otherwise, caller could just use a normal player).
    --      - [ ] If song is non-local, convert the song into packets and know how to ping them.
    --      - [ ]
    --  - [ ] TODO: should we have sepparate host/client players? Honestly probably not. We can re-use the transfer-song ideas and only deal with the "remote" player. This wrapper will make it feel host-ish to the caller.




    -- ---@class NetworkedSongPlayer




    return {}
end

---@class SongNetworkingApi
---@field new_network_song_player fun(processed_song:Song, player_config:SongPlayerConfig):SongPlayerController
---@field song_to_packets       fun(processed_song:Song, player_config:SongPlayerConfig):BundledPacket[]
---@field local_receive_packet  fun(packed_packet_data:PacketDataString)
---@field ping_packets          fun(outgoing_packed_packets:PacketDataString[])
---@field outgoing_packet_queue_progress    fun():number
---@field play_transfered_song  fun(transfered_song_id:integer)         Sends a controll packet to play the selected song.
---@field stop_transfered_song  fun(transfered_song_id:integer)         Sends a controll packet to stop the selected song, and removes any remaining queued packets for the song.
---@field remove_transfered_song  fun(transfered_song_id:integer)       Sends a controll packet to delete the selected song. This simply removes the song from the transfered_songs list. A player playing this song may still hold onto it.
---@field cancel_all_pings fun()        Deletes all pings in the queued pings list and stops the update loop.
---@field get_player_for_transfered_song fun(transfered_song_id:integer):SongPlayerController  Treat this as read-only. Edits to this player will only be seen by the host.
---@field get_target_milis_between_packets fun():integer                Returns `target_milis_between_packets`, so that we can make time-estemations from packet rate.
return {
    new_network_song_player = new_network_song_player,
    song_to_packets = song_to_packets,
    local_receive_packet = local_receive_packet,    -- adds a packet to it's targeted song.
    ping_packets = ping_packets,
    outgoing_packet_queue_progress = outgoing_packet_queue_progress,
    play_transfered_song = function(transfered_song_id)
        ping_packet_immediatly(
            transfered_song_id,
            packet_enums_api.packet_type_ids.control,
            packet_encoder_api.make_control_packet(control_packet_codes.start)
        )
    end,
    stop_transfered_song = function(transfered_song_id)
        ping_packet_immediatly(
            transfered_song_id,
            packet_enums_api.packet_type_ids.control,
            packet_encoder_api.make_control_packet(control_packet_codes.stop)
        )
        remove_packets_from_outgoing_queue_by_transfer_id(transfered_song_id) -- Does not cancel the above packet, since ping_packet_immediatly bypasses the packet queue
    end,
    remove_transfered_song = function(transfered_song_id)
        ping_packet_immediatly(
            transfered_song_id,
            packet_enums_api.packet_type_ids.control,
            packet_encoder_api.make_control_packet(control_packet_codes.remove)
        )
        -- TODO: keep?
    end,
    cancel_all_pings       = function() stop_and_cleanup_packet_ping_loop() end,
    get_player_for_transfered_song = function(transfered_song_id) return collected_incoming_songs[transfered_song_id] and collected_incoming_songs[transfered_song_id].player or nil end,
    get_target_milis_between_packets = function() return packet_encoder_api.get_target_milis_between_packets() end,
}
