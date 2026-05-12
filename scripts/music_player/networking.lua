
-- The flagship feature of this script is the network_song_player. It is essentialy a wrapper arround SongPlayer,
-- but it ensures all controll functions are synced over pings to viewers and the host.
--
-- Not all things are synced. notably the register/remove callback functions are not synced, you'll need to put
-- your own ping logic inside of the callbacks if you want to do something like that.


local packet_decoder_api = require("./packet_decoder")  ---@type PacketDecoderApi
local packet_encoder_api = require("./packet_encoder")  ---@type PacketEncoderApi
local packet_enums_api   = require("./packet_enums")    ---@type PacketEnumsAPI
-- Also requires player.lua

local do_debug_prints = false
--- Logs a message to the console. But if do_debug_prints is true, it also logs to chat. Use do_debug_prints=true to debug viewers.
---@param message string
---@param is_warning boolean?
---@param allways_log boolean?
local function print_debug(message, is_warning, allways_log)
    if do_debug_prints then print(message) end
    if do_debug_prints or allways_log then
        if is_warning then
            host:warnToLog(message)
        else
            host:writeToLog(message)
        end
    end
end
local function printTable_debug(...) if do_debug_prints then printTable(...) end end
local function print_host(...) if host:isHost() or do_debug_prints then print(...) end end


local songs_turned_into_packets_so_far = 0  -- used to build a unique ID number for each transfered song


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

-- A set of functions to call if we receive a header packet.
--
-- Allows us to do some host-only initilization. Technicaly a viewer script may also try to call these, but it's intended to just finish some inits for host-side network player
--
-- Indexed by transfer ID.
local on_header_received_functions = {}    ---@type table<integer, fun(new_song_controller:SongPlayerController)>

--- Creates and stores a new song and player in collected_incoming_songs.
--- Will discard old songs if the same transfer_id is used multiple times.
---@param transfered_song_id integer
---@param packet_data_string PacketDataString
local function receive_header_packet(transfered_song_id, packet_data_string)
    -- This is a header packet. Even if the song with this ID already exists, the host is clearly sending a new one. Purge this data.
    collected_incoming_songs[transfered_song_id] = {}
    local new_song = packet_decoder_api.new_song_from_header_packet(packet_data_string)

    local player_api = require("./song_player")  ---@type SongPlayerAPI
    local new_player_controller = player_api.new_player(new_song, nil)
    collected_incoming_songs[transfered_song_id] = {
        song   = new_song,
        player = new_player_controller
    }
    local callback = on_header_received_functions[transfered_song_id]
    if callback then
        callback(new_player_controller)
        on_header_received_functions[transfered_song_id] = nil
    end
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

--- Just like local_receive_packet, but skips the processor loop.
---
--- Should be host-only. The processor loop in important to make sure we're not overrunning resource limits on the viewer
---@param transfer_id integer
---@param packet_type PacketTypeIDs
---@param packet_data_string PacketDataString
local function local_receive_packet_immediately(transfer_id, packet_type, packet_data_string)
    packet_receiving_functions[packet_type](transfer_id, packet_data_string)
end

--- primary ping function. It receives a packet and sends it off for processing
--- On the off chance that pings need to be unique (idk at the moment): `TL_FMP` → Tanner Limes Figura Mucic Player
---
--- if skip_queue is true, then skip the packet processing queue and processes the packet immediatly. Will use the unlisted PING event.
--- Because packets are sometimes merged, actual instruction cost is unpredictable. Use spareingly, prefer tick events where possible.
---@param transfer_id integer
---@param packet_type PacketTypeIDs
---@param incoming_packet PacketDataString
---@param skip_queue boolean?
function pings.TL_FMP_receive_packet(transfer_id, packet_type, incoming_packet, skip_queue)
    if skip_queue then
        local_receive_packet_immediately(transfer_id, packet_type, incoming_packet)
    else
        local_receive_packet(transfer_id, packet_type, incoming_packet)
    end
end

--- Essentialy a wrapper for pings.TL_FMP_receive_packet
---
--- Bypasses the outbound backet queue. Good for control codes, bad for bulk data.
---
---@param transfer_id integer
---@param packet_type PacketTypeIDs
---@param outgoing_packed_packet PacketDataString
---@param skip_queue boolean?   -- Skip the viewer-side dequeue process and ensures it's processed immediatly by the viewer. Typicaly not ideal.
local function ping_packet_immediatly(transfer_id, packet_type, outgoing_packed_packet, skip_queue)
    pings.TL_FMP_receive_packet(transfer_id, packet_type, outgoing_packed_packet, skip_queue)
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
                ping_loop_start_time = ping_loop_start_time + packet_encoder_api.get_target_milis_between_packets() -- advance ping_loop_start_time to account for moved index
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

    -- upgrade ping_loop_start_time to account for change in index (we're setting index to 1 immediatly after)
    ping_loop_start_time = ping_loop_start_time + (packet_encoder_api.get_target_milis_between_packets() * (outgoing_packet_queue_index -1))
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
---@param outbound_song Song
---@param outbound_player_config SongPlayerConfig
---@return SongPlayerController
local function new_network_song_player(outbound_song, outbound_player_config)
    if not host:isHost() then -- The caller is a viewer.
        -- To avoid double-playback issues (where host makes a player, and also the viewer happens to make a player), this function will throw our own error
        error("new_network_song_player was called, but caller is not Host. Use the normal song_player instead to let the viewer play songs.")
    end

    local transfered_song_id = songs_turned_into_packets_so_far
    songs_turned_into_packets_so_far = songs_turned_into_packets_so_far +1

    -- Gather the data

    local song_data_packets, buffer_time = packet_encoder_api.build_data_packets_and_buffer_time(outbound_song)
    local header_packet_data = packet_encoder_api.build_header_packets(outbound_song, buffer_time)
    local config_packet_data = packet_encoder_api.build_config_packet(outbound_player_config)

    local bundled_song_data_packets = {}    ---@type BundledPacket[]
    for _, song_data_packet in ipairs(song_data_packets) do
        ---@type BundledPacket
        local bundled_packet = {
            packet_data_string = song_data_packet,
            packet_type = packet_enums_api.packet_type_ids.data,
            transfered_song_id = transfered_song_id
        }
        table.insert(bundled_song_data_packets, bundled_packet)
    end

    -- Initilize remote player on host so the controller can be initilized.
    -- We don't need to initilize this on the viewers just yet because we'll allways reset it on :play() anyways.

    local_receive_packet_immediately(
        transfered_song_id,
        packet_enums_api.packet_type_ids.header,
        header_packet_data
    )
    local_receive_packet_immediately(
        transfered_song_id,
        packet_enums_api.packet_type_ids.config,
        config_packet_data
    )

    local time_play_last_called = nil  ---@type number?    For use with is_playing. Hides some of the delay cause by going through ping
    local time_stop_last_called = nil  ---@type number?    For use with is_playing. Hides some of the delay cause by going through ping
    local durration_to_wait_before_assumeing_play_or_stop_failed = math.min(
        outbound_song.duration,
        math.max(
            outbound_song.duration / 4,
            10 * 1000
        )
    )

    local update_callbacks = {}     ---@type fun()[]
    local meta_callbacks = {}       ---@type fun(event_code:integer, meta_event_data:table<string, integer>)[]
    local stop_callbacks = {}       ---@type fun(stop_reason:SongPlayerStopReason)[]

    ---@param stop_reason SongPlayerStopReason
    local function call_stop_callbacks(stop_reason)
        for _, stop_callback in ipairs(stop_callbacks) do stop_callback(stop_reason) end
    end

    local function call_update_callbacks()
        for _, update_callback in ipairs(update_callbacks) do update_callback() end
    end

    ---@param event_code integer
    ---@param meta_event_data table<string, integer>
    local function call_meta_callbacks(event_code, meta_event_data)
        for _, meta_callback in ipairs(meta_callbacks) do meta_callback(event_code, meta_event_data) end
    end

    ---@type SongPlayerController
    local custom_song_controller
    custom_song_controller = {
        play = function()
            if custom_song_controller.is_playing() then return end

            if #outgoing_bundled_packets_queue > 0 then
                print_debug("The outgoing packet queue is already bussy. Playback might be delayed.")
            end

            -- We have to re-initilize the song in case someone new has loaded us for the first time.
            ping_packet_immediatly(
                transfered_song_id,
                packet_enums_api.packet_type_ids.header,
                header_packet_data,
                true
            )

            -- This header packet won't arrive for a tick or two (even on host, so long as it goes through the ping layer.)
            -- queue up some last-remaining init things.

            on_header_received_functions[transfered_song_id] = function (new_song_controller)
                new_song_controller.register_stop_callback(call_stop_callbacks)
                new_song_controller.register_meta_event_callback(call_meta_callbacks)
                new_song_controller.register_update_callback(call_update_callbacks)
            end

            -- Send the start signal. Buffer time is now based on when we receive the first data packet, so it's safe to start now, and send data later.

            ping_packet_immediatly(
                transfered_song_id,
                packet_enums_api.packet_type_ids.control,
                packet_encoder_api.make_control_packet(packet_enums_api.control_packet_codes.start),
                true
            )

            ping_packet_immediatly(
                transfered_song_id,
                packet_enums_api.packet_type_ids.config,
                config_packet_data
            )

            ping_packets(bundled_song_data_packets)

            time_stop_last_called = nil
            time_play_last_called = client:getSystemTime()
        end,

        stop = function()
            ping_packet_immediatly(
                transfered_song_id,
                packet_enums_api.packet_type_ids.control,
                packet_encoder_api.make_control_packet(packet_enums_api.control_packet_codes.stop),
                true
            )

            -- Stop pinging new packets (we'll reset and restart with play)
            remove_packets_from_outgoing_queue_by_transfer_id(transfered_song_id)

            time_play_last_called = nil
            time_stop_last_called = client:getSystemTime()
        end,

        set_new_config = function(new_config)
            config_packet_data = packet_encoder_api.build_config_packet(new_config)
            ping_packet_immediatly(
                transfered_song_id,
                packet_enums_api.packet_type_ids.config,
                config_packet_data
            )
        end,

        is_playing = function()
            local local_player_is_playing = collected_incoming_songs[transfered_song_id].player.is_playing()
            if local_player_is_playing then -- Local player is playing. Double check that we didn't just send a stop command.
                local we_stopped_playing_recently = time_stop_last_called and (time_stop_last_called + durration_to_wait_before_assumeing_play_or_stop_failed > client:getSystemTime())
                if we_stopped_playing_recently then return false end
            else    -- local player is not playing, but maybe we sent the play command recently and it hasn't made it through.
                local we_started_playing_recently = time_play_last_called and (time_play_last_called + durration_to_wait_before_assumeing_play_or_stop_failed > client:getSystemTime())
                if we_started_playing_recently then return true end
            end

            return local_player_is_playing
        end,


        ---@type fun(callback: fun()))
        register_update_callback = function(callback)
            table.insert(update_callbacks, callback)
        end,

        ---@type fun(callback: fun(event_code:integer, meta_event_data:table<string, integer>)))
        register_meta_event_callback = function(callback)
            table.insert(meta_callbacks, callback)
        end,

        ---@type fun(callback: fun(stop_reason:SongPlayerStopReason))
        register_stop_callback = function(callback)
            table.insert(stop_callbacks, callback)
        end,

        ---@type fun(callback: fun()))
        remove_update_callback = function(callback_to_remove)
            for k, fn in pairs(update_callbacks) do
                if fn == callback_to_remove then
                    table.remove(update_callbacks, k)
                    return
                end
            end
        end,

        ---@type fun(callback: fun(event_code:integer, meta_event_data:table<string, integer>)))
        remove_meta_event_callback = function(callback_to_remove)
            for k, fn in pairs(meta_callbacks) do
                if fn == callback_to_remove then
                    table.remove(meta_callbacks, k)
                    return
                end
            end
        end,

        ---@type fun(callback: fun(stop_reason:SongPlayerStopReason))
        remove_stop_callback = function(callback_to_remove)
            for k, fn in pairs(stop_callbacks) do
                if fn == callback_to_remove then
                    table.remove(stop_callbacks, k)
                    return
                end
            end
        end,
    }
    for k, v in pairs(collected_incoming_songs[transfered_song_id].player) do -- loop through the functions of a known player. At this stage, this player will be the wrong player. But it holds the keys we need.
        if not custom_song_controller[k] then -- there's a function we haven't implemented yet
            print_debug("Key `"..tostring(k).."` is not implemented in networked_song_player's controller.")
            if type(v) == "function" then
                custom_song_controller[k] = function(...)
                    -- forwards controll to the current local player
                    return collected_incoming_songs[transfered_song_id].player[k](...)
                end
            end
        end
    end

    return custom_song_controller
end

---@class SongNetworkingApi
local api = {
    new_network_player = new_network_song_player,
    local_receive_packet = local_receive_packet,    -- adds a packet to it's targeted song.
    ping_packets = ping_packets,
    outgoing_packet_queue_progress = outgoing_packet_queue_progress,

    ---@param transfered_song_id integer
    play_transfered_song = function(transfered_song_id)
        ping_packet_immediatly(
            transfered_song_id,
            packet_enums_api.packet_type_ids.control,
            packet_encoder_api.make_control_packet(control_packet_codes.start)
        )
    end,

    ---@param transfered_song_id integer
    stop_transfered_song = function(transfered_song_id)
        ping_packet_immediatly(
            transfered_song_id,
            packet_enums_api.packet_type_ids.control,
            packet_encoder_api.make_control_packet(control_packet_codes.stop)
        )
        remove_packets_from_outgoing_queue_by_transfer_id(transfered_song_id) -- Does not cancel the above packet, since ping_packet_immediatly bypasses the outgoing packet queue
    end,

    --- Efectively deletes a transfered song on all viewers.
    ---
    --- To reuse this song, a new header packet will need to be sent.
    ---@param transfered_song_id integer
    remove_transfered_song = function(transfered_song_id)
        ping_packet_immediatly(
            transfered_song_id,
            packet_enums_api.packet_type_ids.control,
            packet_encoder_api.make_control_packet(control_packet_codes.remove)
        )
        remove_packets_from_outgoing_queue_by_transfer_id(transfered_song_id)
    end,

    cancel_all_outgoing_pings       = function() stop_and_cleanup_packet_ping_loop() end,

    --- Header packets create SongPlayers. This function can be used to get that player's controller for a given transfer ID.
    ---
    --- This is a local song player, so changes to it will not sync with viewers
    ---
    --- You might want to check out new_network_player() to create a syncing player to begin with.
    ---@param transfered_song_id integer
    ---@return SongPlayerController?
    get_player_for_transfered_song = function(transfered_song_id) return collected_incoming_songs[transfered_song_id] and collected_incoming_songs[transfered_song_id].player or nil end,

    ---@return number get_target_milis_between_packets
    get_target_milis_between_packets = function() return packet_encoder_api.get_target_milis_between_packets() end,
}

return api
