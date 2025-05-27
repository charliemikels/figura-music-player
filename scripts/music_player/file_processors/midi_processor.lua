---@module "../core"

-- see: http://www.music.mcgill.ca/~ich/classes/mumt306/StandardMIDIfileformat.html



-- Defaults and limits

---Limits to keep to reduce lag when processing large files.
local max_read_steps_per_event    = 100000
local max_process_steps_per_event = 1000

local instructions_api = require("../instructions")

---@enum MidiChunkTypes
local midi_chunk_types = {
    header = "MThd",
    track = "MTrk"
}



---Converts a number into a string with both Dec and Hex values. Primaraly for debug
---@param number number
---@return string
local function number_to_dec_and_hex(number)
    return string.format("Dec: %.0f | Hex: %x", number, number)
end

---Converts a number into a string with that number's Hex value. Primaraly for debug
---@param number number
---@return string
local function number_to_hex(number)
    return string.format("%x", number)
end

---converts a set of bytes to a number.
---@param bytes integer[]
---@return number
local function bytes_to_number(bytes)
    local result = 0
    for i, v in ipairs(bytes) do
        result = result + bit32.lshift(v, ((#bytes - i) * 8))
    end
    return result
end

---Similar to bytes_to_number, but ensures incomming numebrs are 7 bits long.
---Use with variable-length quantities
---TODO: if only used with variable length quantities, move into that function.
---@param bytes integer[]
---@return number
local function combine_seven_bit_numbers(bytes)
    local everything_but_first_bit = tonumber("01111111", 2)
    local result = 0
    for _, next_7byte in ipairs(bytes) do
        result = bit32.bor( -- lshift fills space it makes with 0s. use or to "paste" data into space created.
            bit32.lshift( result, 7 ), -- make space for next byte
            bit32.band(next_7byte, everything_but_first_bit) -- ensure value is only 7 bits. (might break if input is larget than 8 bits? idk)
        )
    end
    return result
end

---Grabs the next byte from raw_data, and keeps track of progress through the raw data and current chunk.
---@param state MidiProcessorState
---@return number
---@see undo_byte_read
local function read_next_file_byte(state)
    if state.reader.current_chunk_length_counter then
        state.reader.current_chunk_length_counter = state.reader.current_chunk_length_counter - 1
    end
    return state.reader.file_stream:read()
end

---Like read_next_file_byte, returns the next byte from the data list, and auto incriments chunk.data_index
---@param chunk MidiChunk
local function read_next_chunk_byte(chunk)
    local return_byte = chunk.data[chunk.data_index]
    chunk.data_index = chunk.data_index + 1
    return return_byte
end

---comment
---@param track MidiChunk
---@return number
local function read_variable_length_quantity(track)
    -- Some values in midi are stored as "variable-length quantities."
    -- These are numbers that can be 1 byte long, or up to 4 bytes long. "Theoreticaly," could go longer.
    --
    -- Bit 7 (the first bit, where the last is bit 0) for each number is actualy the flag that tells us
    -- whether to continue reading or if we've reached the end. The last byte in the sequence has a 0 at
    -- bit 7, and every byte before will have a 1. Bits 6-0 hold the actual number.
    --
    -- Examples:
    -- midi file → real value
    -- 00000000 → 00000000  |  00 → 00 00 00 00
    -- 01000000 → 01000000  |  40 → 00 00 00 40
    -- 10000001 00000000 → 10000000
    -- 11000000 00000000 → 00100000 00000000
    -- 10000001 10000000 00000000 → 01000000 00000000
    -- 11111111 11111111 11111111 01111111 → 00001111 11111111 11111111 11111111  | FF FF FF 7F → 0F FF FF FF
    --
    -- largest midi value: FF FF FF 7F → resulting in 0FFFFFFF. Although, theoreticaly, it could go higher.

    local continue_bit_mask = tonumber("10000000", 2)
    local number_data_mask = bit32.bnot(continue_bit_mask)

    -- gather relevent bytes
    local bytes = {}
    repeat
        local current_byte = read_next_chunk_byte(track)
        table.insert(bytes, bit32.band(current_byte, number_data_mask))
    until not bit32.btest(current_byte, continue_bit_mask)

    return combine_seven_bit_numbers(bytes)
end

---Collection of functions to read midi meta events, indexed by their event ID byte.
---
---These are used during the read stage. Called from midi_message_functions[11111111]. Fills in message.data
---
---@see MidiMessage
---
---It is technicaly safe to implement an empty function to ignore a meta event.
---The function that calls these functions has already read in the data.
---
---@type table<integer, fun(state: MidiProcessorState, track: MidiChunk, data: integer[], channel: integer?)>
local midi_meta_event_functions = {

    ---sequence_number
    ---
    ---Optional. Format 0 and 1 have only one sequence, But format 2 might have multiple. Sequence_number is used to keep sequences in order.
    ---Must come before non-zero delta times, and before all transmitable midi events.
    -- [0x00] = function(state, track, data, channel)
    --     message.data.sequence_number = message.event_raw_data[1]
    -- end,

    ---text_event
    ---
    ---Generic text event. Provides notes about the song, or about a part of it. Events 0x01 - 0x0F are all text events of some sort.
    [0x01] = function(state, track, data, channel)
        -- we have no system to display generic text.
        -- local text = string.char(table.unpack(data))
    end,

    ---copyright_notice
    ---
    ---Text event with copyright info.
    [0x02] = function(state, track, data, channel)
        -- Revisit. right now there's no planned system to display copyright info for a song.
        -- local copyright_notice = string.char(table.unpack(data))
    end,

    ---sequence_or_track_name
    ---
    ---Text event. If in format 0, or first track in format 1, then this is the name of the sequence. (the whole song.)
    ---Else, it's the name of this specific track.
    [0x03] = function(state, track, data, channel)
        if track.index > 1 then
            -- Not the very first track, data is the name of this specific track.
            local track_name = string.char(table.unpack(data))
            error("Figure out how we convert MidiChunk tracks to ProcessedSong tracks to correctly store the name of the track. "
                .."This is something we'll want to display."
            )
        end
    end,

    ---instrument_name
    ---
    ---Text event. Description or type of instrument to use for this track. See also Midi channel prefix
    -- [0x04] = function(state, track, data, channel)
    --     message.data.instrument_name = string.char(table.unpack(message.event_raw_data))
    -- end,

    ---lyric
    ---
    ---Text event. defines the lyric to sing at a speciffic time. Typicaly, lyric events are stored per-sylable
    -- [0x05] = function(state, track, data, channel)
    --     message.data.lyric = string.char(table.unpack(message.event_raw_data))
    -- end,

    ---marker
    ---
    ---a text marker to name parts of the song. ("Verse 1", "chorus", etc.) usualy only if first track.
    -- [0x06] = function(state, track, data, channel)
    --     message.data.marker = string.char(table.unpack(message.event_raw_data))
    -- end,

    ---cue_point
    ---
    ---With film, a description of what happens on screen.
    -- [0x07] = function(state, track, data, channel)
    --     message.data.cue_point = string.char(table.unpack(message.event_raw_data))
    -- end,

    ---midi_channel_prefix
    ---
    ---Sets a prefix for the channel. (0-15 (?)). Ties any following events (eg sysex events) to selected channel, until
    ---next event that defines a channel, or next channel_prefix meta event.
    -- [0x20] = function(state, track, data, channel)
    --     message.data.sequence_number = message.event_raw_data[1]

    -- end,

    ---end_of_track
    ---
    ---**Required.** Marker for a cannonical end of a track.
    ---(Unlike in ABC, MIDI songs end when this event is hit. In ABC, it ends whenever the last note is done.)
    -- [0x2F] = function(state, track, data, channel)
    --     -- TODO: Save "end of song point"
    --     -- Clean up/save remaining data in current track.

    --     -- Some tracks may not have saved any note data. We may want throw a flag in the track data so that we don't have to display it in the UI.
    --     -- EG: `Wii Sports - Theme.mid`: The first track only time signature and some other meta data, then closes.

    --     -- Resetting for next track happens at the end of the midi-chunk loop

    --     message.data.end_of_track = true
    --     if state.reader.current_chunk_length_counter > 0 then
    --         error("End of track event found, but chunk counter is still greater than 0")
    --     end
    -- end,

    ---set_tempo
    ---
    ---Sets tempo in "microseconds per MIDI quarter-note" (aka: "24ths of a microsecond per MIDI clock")
    ---Note this is in time-per beat, not the traditional beat-per-time.
    -- [0x51] = function(state, track, data, channel)
    --     local microseconds_per_midi_quarter_note = bytes_to_number(message.event_raw_data)
    --     message.data.tempo = microseconds_per_midi_quarter_note
    --     message.data.bpm = 60000000 / microseconds_per_midi_quarter_note    -- BPM may be easier for libraries to understand. keep arround as an option?
    -- end,

    ---smpte_offset
    ---
    ---Part of Format 2. Marks the timestamp when this track is supposed to start. Default to
    -- [0x54] = function(state, track, data, channel) end,

    ---time_signature
    ---
    ---Does not actualy impact playback of a midi file. But used for accurate score info and display.
    ---We will keep parts of it arround for posibly syncing animations.
    ---
    ---Should default to 4/4
    [0x58] = function(state, _, data, _)
        local numerator = data[1]
        local denominator = 2^(data[2]) -- denominator is stored as "a negative power of two". (2→4, 3→8 …)
        -- local number_of_midi_clocks_in_a_metronome_click = data[3]
        -- local number_of_notated_32nd_notes_per_beat = data[4]

        ---@type Instruction
        local instruction = {
            track_index = 0,
            duration = 0,
            start_time = error("set start time freom current state"),
            note = 0x58,
            modifiers = { numerator = numerator, denominator = denominator }
        }
        table.insert(state.complete_instructions, instruction)
    end,

    ---key_signature.
    --- - <numb of sharps / flats (negative == flat, positive == sharps. 0 == C)>
    --- - <0 == major, 1 == minor>
    -- [0x59] = function(state, track, data, channel)
    --     local unsigned_sharps_or_flats = message.event_raw_data[1]
    --     message.data.key_signature = {
    --         sharps_or_flats = (unsigned_sharps_or_flats >= 128 and unsigned_sharps_or_flats - 256 or unsigned_sharps_or_flats),
    --         major_or_minor = message.event_raw_data[2]
    --     }
    -- end,

    ---sequencer_specific_meta_event
    ---
    ---Instructions for speciffic sequencers. There may be common ones we'll want to implement later. Take note of instances where this appears.
    -- [0x7F] = function(state, track, data, channel)
    --     message.data.sequencer_specific_meta_event_data = message.event_raw_data
    -- end
}


---Collection of functions to process midi message events from a Midi Tracks, indexed by their event ID byte.
---
---When these functions return, track.data_index should be ready to index the delta of the next event
---
---These are ran during the `process` stage to turn data bytes into .
---@type table<integer, fun(state: MidiProcessorState, track: MidiChunk, channel: integer?)>
local midi_message_functions = {
    -- ↓ Functions 10000000 through 11100000 (aka 11101111) include a channel ID. This is pre-parsed and passed as a paramiter.

    ---Note Off event
    -- [tonumber("10000000", 2)] = function(state, track, channel)
    --     message.data.note = read_next_file_byte(state)
    --     message.data.velocity = read_next_file_byte(state)  -- Note off velocity is frequently ignored by all but the fancy synths.
    --     message.data.note_enabled = false
    -- end,

    ---Note On event
    ---Special case: if velocity is 0, treat as a note off event. Stacks well with running status.
    -- [tonumber("10010000", 2)] = function(state, track, channel)
    --     message.data.note = read_next_file_byte(state)
    --     message.data.velocity = read_next_file_byte(state)
    --     message.data.note_enabled = (message.data.velocity ~= 0)
    --     -- I know this ↑ looks like parcing, but if we're gonna do `note_enabled` for Note Off, then we should set it correctly here.
    --     -- Note On events with velocity of `0` are treated like a Note Off events.
    -- end,

    ---Polyphonic Key Pressure (Aftertouch)
    -- [tonumber("10100000", 2)] = function(state, track, channel)
    --     message.data.note = read_next_file_byte(state)
    --     message.data.note_after_touch = read_next_file_byte(state)
    -- end,

    ---Control Change / Channel Mode Messages
    ---
    ---Some controller numbers are reserved. See "Channel Mode Messages"
    -- [tonumber("10110000", 2)] = function(state, track, channel)
    --     -- These are two sepperate event types. Be sure to handle each depending on the state.
    --     message.data.controller_number = read_next_file_byte(state)
    --     message.data.controller_value = read_next_file_byte(state)
    -- end,

    ---Program change
    -- [tonumber("11000000", 2)] = function(state, track, channel)
    --     message.data.patch_number = read_next_file_byte(state)
    -- end,

    ---Channel Presure (Channel Aftertouch)
    -- [tonumber("11010000", 2)] = function(state, track, channel)
    --     message.data.channel_after_touch = read_next_file_byte(state)
    -- end,

    ---Pitch Wheel Change
    ---
    ---The pitch wheel is measured by a fourteen bit value. Where 3FFF is the maximum value.
    ---
    ---Center (no pitch change) is Hex = 2000, Dec = 8192.
    ---
    ---"Sensitivity is a function of the transmitter." Usualy this is ±2 semitones. Midi by default doesn't encode the range,
    ---but some use a `RPN` (Registered Parameter Number) to encode this message in the control codes.
    -- [tonumber("11100000", 2)] = function(state, track, channel)
    --     message.data.pitch_wheel = combine_seven_bit_numbers({ read_next_file_byte(state), read_next_file_byte(state) })
    -- end,

    -- ↑ Has channel ID
    -- ↓ No channel ID. Channel is not used.

    ---System Exclusive
    ---
    ---Each data byte in the system Exclusive message starts with a 0. Only real-time messages can inturrupt a system exclusive message.
    -- [tonumber("11110000", 2)] = function(state, track, channel)
    --     -- sysex events are messages for "the system." I don't think we need to worry about this type.
    --     -- sysex events are sometimes stored as packets within the midi file.
    --     -- normal one-message sysex = `F0 <variable-length quantity> <bytes>`, where final byte is `F7`
    --     -- Start of message chain   = `F0 <variable-length quantity> <bytes>`, where final byte is not `F7`
    --     -- Continuation of message  = `F7 <variable-length quantity> <bytes>`, where final byte is not `F7`
    --     -- end of message chain     = `F7 <variable-length quantity> <bytes>`, where final byte is `F7`.
    --     -- A final `F7` indicates that the message is done. But we shouldn't need to worry about
    --     -- system messages like these at all. If we encounter an event starting with `F0` or `F7`,
    --     -- we can just skip the entire length of bytes.

    --     local sysex_event_length = read_variable_length_quantity(state)
    --     for _ = 1, sysex_event_length do
    --         local byte = read_next_file_byte(state)
    --         table.insert(message.event_raw_data, byte)
    --         table.insert(message.data, byte)
    --     end
    -- end,

    ---Undefined
    [tonumber("11110001", 2)] = function(state, track, channel)
        error("Undefined midi message")
    end,

    ---Song Position Pointer
    -- [tonumber("11110010", 2)] = function(state, track, channel) end,

    ---Song Select
    ---
    ---Used to select what sequence/song to play.
    -- [tonumber("11110011", 2)] = function(state, track, channel) end,

    ---Undefined
    [tonumber("11110100", 2)] = function(state, track, channel)
        error("Undefined midi message")
    end,

    ---Undefined
    [tonumber("11110101", 2)] = function(state, track, channel)
        error("Undefined midi message")
    end,

    ---Tune request
    ---
    ---Request all analogue systems to tune themselves.
    [tonumber("11110110", 2)] = function(state, track, channel)
        -- no data, nothing to tune, safely ignore.
    end,

    ---System exclusive message
    -- [tonumber("11110111", 2)] = function(state, track, channel)
    --     -- There are two System Exclusive messages. See event ID `11110000` (F0) for more detail
    --     local sysex_event_length = read_variable_length_quantity(state)
    --     for _ = 1, sysex_event_length do
    --         local byte = read_next_file_byte(state)
    --         table.insert(message.event_raw_data, byte)
    --         table.insert(message.data, byte)
    --     end
    -- end,

    -- ↓ System "Real-time" messages.
    -- We can probably ignore just about all of these.

    ---Timing Clock
    ---
    ---Sent 24 times per quarter note when synchronisation is required
    [tonumber("11111000", 2)] = function(state, track, channel)
        -- no data, no devices to syncronize, safely ignore.
    end,

    ---Undefined
    [tonumber("11111001", 2)] = function(state, track, channel)
        error("Undefined midi message")
    end,

    ---Start
    ---
    ---Start the current sequence playing
    [tonumber("11111010", 2)] = function(state, track, channel)
        -- No data, controlls playback devices in realtime situations. We are not realtime, Safely ignore?
    end,

    ---Continue
    ---
    ---Continue at the point the sequence was stopped
    [tonumber("11111011", 2)] = function(state, track, channel)
        -- No data, controlls playback devices in realtime situations. We are not realtime, Safely ignore?
    end,

    ---Stop
    ---
    ---Stop the current sequence
    [tonumber("11111100", 2)] = function(state, track, channel)
        -- No data, controlls playback devices in realtime situations. We are not realtime, Safely ignore?
    end,

    ---Undefined
    [tonumber("11111101", 2)] = function(state, track, channel)
        error("Undefined midi message")
    end,

    ---Active Sensing
    ---
    ---Optional message. Receivers that get this message will expect another Active Sensing message within 300ms.
    ---Or it will assume the conection has terminated. When it's terminated, receiver will turn off all voices and
    ---return to normal, non active sensing opperation.
    [tonumber("11111110", 2)] = function(state, track, channel)
        -- no data, realtime situations only to make sure everything stays online. Safely ignore.
    end,

    ---Meta event
    ---
    ---Meta events have their own sub IDs and functions assosiated with them.
    ---
    ---@see midi_meta_event_functions
    [tonumber("11111111", 2)] = function(state, track, channel)
        local meta_event_id = read_next_chunk_byte(track)
        local meta_event_length = read_variable_length_quantity(track)
        local meta_event_data = {}
        for _ = 1, meta_event_length do
            table.insert(meta_event_data, read_next_chunk_byte(track))
        end

        if midi_meta_event_functions[meta_event_id] then
            print("meta ID = "..number_to_dec_and_hex(meta_event_id))
            midi_meta_event_functions[meta_event_id](state, track, meta_event_data, channel)
        else
            error("Unimplemented meta event: "..number_to_dec_and_hex(meta_event_id))
        end
    end
}


---@alias midi_processor_stage
---| '"init"'
---| '"read"'
---| '"process"'
---| '"done"'

---@type table<midi_processor_stage, fun(song: Song, state: MidiProcessorState)>
local midi_processor_loop_stage_functions = {
    init = function(song, state)
        -- Ensure everything is ready to go for reading and organizing

        -- Set up input stream for read step, or skip read if not needed

        -- TODO: remove song.data_source entirely? Because we could bundle our own native file format,
        -- we probably don't want to bundle midi files. IE: this function will only be called with filesAPI.
        -- It is worth while to keep track of songs that have host-only data (needs pings) vs songs that are
        -- bundled with the avatar. (Don't need pings for data, just start/stop.) But for the midi parcer
        -- itself, this distinction is not exactly nessesary.
        if song.source.type == "files" then
            state.reader.file_stream = file:openReadStream(song.source.full_path)
            state.stage = "read"
        else
            error("song.source.type is not `files`. Non files API sources are not supported yet.")
        end
        print("init done")
    end,

    read = function(song, state)
        -- read in data, a few bytes at a time, so that we don't freeze the game reading a hughe file.
        for i = 1, max_read_steps_per_event, 1 do
            if
                not state.reader.file_stream:available()
                or state.reader.file_stream:available() <= 0
            then
                break
            else
                -- Midi files split into chunks like head and track.
                -- We'll want to process the head first, but then process the tracks together.
                -- (Tracks just organize messages. The 16 midi channels are the real stars as far as playback is concerned.)
                -- As we read, organize data by chunk.
                if  not state.reader.current_chunk then
                    -- Must be at the start of a new chunk.

                    ---Stores the raw data for a single chunk in a midi file.
                    ---@class MidiChunk
                    local new_chunk = {

                        --Chunk types start with a 4 char type, then a 32 bit length
                        ---@type MidiChunkTypes
                        type = string.char(
                            read_next_file_byte(state),
                            read_next_file_byte(state),
                            read_next_file_byte(state),
                            read_next_file_byte(state)
                        ),

                        --32-bit unsigned int, represents how many bytes in the entire chunk.
                        length = bytes_to_number({
                            read_next_file_byte(state),
                            read_next_file_byte(state),
                            read_next_file_byte(state),
                            read_next_file_byte(state)
                        }),

                        --Raw data from file for this chunk
                        ---@type integer[]
                        data = {},

                        -- Keeps track of our progress through the data table.
                        -- See read_next_chunk_data_byte(chunk)
                        ---@type integer
                        data_index = 1,

                        ---Durring the process stage, we need to read track messages in chronological order.
                        ---Use this to track the absolute time passed for a track to compare with the next message's delta time.
                        ---@type number
                        sum_delta = 0,

                        ---Holds the delta of the next event.
                        ---Used to compare this track against every other track, without doing var-length calculations every loop
                        ---@type integer
                        next_event_delta = 1,

                        ---For tracks, stores the index of this track. Sometimes, a meta event needs to know if it's in the
                        ---first track in a file (eg, `0x03` == sequence_or_track_name)
                        ---@type integer?
                        index = nil,
                    }

                    state.reader.current_chunk = new_chunk
                    state.reader.current_chunk_length_counter = new_chunk.length

                    if new_chunk.type == midi_chunk_types.track then
                        table.insert(state.chunks.tracks, new_chunk)
                        -- print("Found new track")

                    elseif new_chunk.type == midi_chunk_types.header then
                        -- header chunks are usualy very small (6 bytes). It's worth while to just process it now.

                        if state.chunks.header then error("Tried to process the header chunk, but state.chunks.header is not empty.") end

                        -- All midi headers should be 6 bytes, with 3 2-byte (16-bit) words.
                        -- state.midi_header_info = {}
                        local header_chunk = new_chunk

                        local expected_header_chunk_length = 6

                        for _ = 1, header_chunk.length do
                            table.insert(header_chunk.data, read_next_file_byte(state))
                        end

                        if header_chunk.length > expected_header_chunk_length then
                            print("Header chunk is larger than expected. Got " .. tostring(header_chunk.length)
                                .. " instead of " .. tostring(expected_header_chunk_length)
                            )
                        end

                        -- format: 0, 1, or 2.
                        --
                        -- * 0 = one track in the entire file
                        -- * 1 = multiple tracks, each track listed one after the other. { full_track_1, full_track_2 }
                        -- * 2 = multiple tracks woven through each other. { partial_track_1, partial_track_2, partial_track_1, partial_track_2, … }
                        state.midi_header_info.format = bytes_to_number({ header_chunk.data[1], header_chunk.data[2] })

                        if state.midi_header_info.format == "2" then
                            error("MIDI format 2 not yet supported."
                                .." Send this MIDI file (".. song.name ..") to the script author for testing.")
                        end

                        -- Number of tracks
                        state.midi_header_info.number_of_tracks = bytes_to_number({header_chunk.data[3],header_chunk.data[4]})

                        -- division / timing data
                        -- bit 15 = format type: 0 == ticks per quarter-note. 1 == timecode system
                        local first_bit_mask = tonumber("10000000", 2)
                        local everything_but_first_bit_mask = bit32.bnot(first_bit_mask)
                        local first_byte_of_timing_data = header_chunk.data[5]
                        local second_byte_of_timing_data = header_chunk.data[6]

                        if bit32.btest(first_byte_of_timing_data, first_bit_mask) then
                            --first bit of first byte of timing data is 1. Use time-code-based method

                            -- bit 15 = time type. Already checked
                            state.midi_header_info.timing_method = 1
                            -- bit 14-8 = one of 4 values: -24, -25, -29, or -30. Stored in two's compliment
                            -- "…corresponding to the four standard SMPTE and MIDI Time Code formats
                            --      (-29 corresponds to 30 drop frame), and represents the number of frames per second."
                            --
                            -- TODO

                            -- bit 7-0 = resolution within a frame
                            -- TODO

                            error("MIDI time division type 1 (SMPTE / time codes / whatever) is not implemented."
                                .." Send this MIDI file (".. song.name ..") to the script author for testing.")
                        else
                            --first bit of first byte of timing data is 0. Use normal ticks-per-quarter-note method
                            local ticks_per_quarter_note_fist_byte = bit32.band(first_byte_of_timing_data, everything_but_first_bit_mask)
                            local ticks_per_quarter_note = bytes_to_number({ticks_per_quarter_note_fist_byte, second_byte_of_timing_data})
                            state.midi_header_info.timing_method = 0
                            state.midi_header_info.ticks_pre_quarter_note = ticks_per_quarter_note
                        end

                        state.chunks.header = header_chunk

                        state.reader.current_chunk = nil
                        state.reader.current_chunk_length_counter = 0

                    else
                        table.insert(state.chunks.unknown_chunks, new_chunk)
                        print("Found a chunk with an unknown type.")
                    end

                else -- We've inside of a chunk. Read file data into the current chunk.
                    table.insert(state.reader.current_chunk.data, read_next_file_byte(state))
                    if state.reader.current_chunk_length_counter <= 0 then
                        -- End of chunk. Clear it so that next loop we get a new chunk.
                        state.reader.current_chunk = nil
                    end
                end
            end
        end

        if state.reader.file_stream:available() <= 0 then
            -- Last loop had last item. Do Final cleanup and move on.
            -- song.raw_data = state.raw_data
            state.raw_data = nil
            state.reader.file_stream:close()
            state.reader.file_stream = nil

            state.reader.current_chunk = nil
            state.reader.current_chunk_length_counter = nil
            state.reader = nil

            for track_index, track in pairs(state.chunks.tracks) do
                -- Jumpstart process phase by pre-calculating the delta of the first event in each track.
                -- For most tracks, this will probably just be 0
                track.index = track_index
                track.next_event_delta = read_variable_length_quantity(track)
            end

            state.stage = "process"
            print("read done")
            return
        end
    end,

    process = function(song, state)
        -- Midi files store midi events `<delta_time><event_id><event_data>`
        -- In order to not calculate delta_time every time to figure out the next chronological event,
        -- We will calculate it ahead of time during the end of Read, and update it for the current track at the end of this loop.
        -- So effectively, we will read the data like this: `<event_id><event_data><next_event_delta_time>`

        for i = 1, max_process_steps_per_event, 1 do

            -- Get next message to process

            local soonest_time = math.huge
            local soonest_track
            local soonest_track_index

            for track_index, track in ipairs(state.chunks.tracks) do
                if #track.data >= track.data_index then
                    local time_of_next_message = track.sum_delta + track.next_event_delta
                    if time_of_next_message < soonest_time then
                        soonest_time = time_of_next_message
                        soonest_track = track
                        soonest_track_index = track_index
                    end
                end
            end
            if not soonest_track then
                -- No soonest message was set. → There are no more messages. → Done processing.
                print("process done")
                state.stage = "done"
                return
            end

            -- Running Status:
            -- Messages may ommit their status ID if they have the same ID as the status before it. ("Running status")
            -- Check next byte. If it's a data byte, backtrack reader and use previous status ID

            local first_bit_mask = tonumber("10000000", 2)
            local event_id_byte = read_next_chunk_byte(soonest_track)
            if event_id_byte < first_bit_mask then
                -- This isn't a standard midi event, This is the data for running status.
                -- Backtrack, and use the previous event ID
                soonest_track.data_index = soonest_track.data_index -1
                event_id_byte = state.reader.running_status_id
            else
                state.processor.running_status_id = event_id_byte
            end

            -- Midi Messages < `0x11110000` use the last 4 bits to represent a channel ID
            local first_half_mask = tonumber("11110000", 2)
            local midi_channel = (
                (event_id_byte < first_half_mask)
                and bit32.band(event_id_byte, bit32.bnot(first_half_mask))
                or nil
            )
            local event_id_without_channel = (
                (event_id_byte < first_half_mask)
                and bit32.band(event_id_byte, first_half_mask)
                or event_id_byte
            )

            if midi_message_functions[event_id_without_channel] then
                print("processing event:", event_id_without_channel, "track:", soonest_track_index, "time:", soonest_time)
                midi_message_functions[event_id_without_channel](state, soonest_track, midi_channel)
            else
                error("Unimplemented Event ID: "..number_to_dec_and_hex(event_id_without_channel))
            end

            -- see state.processed_song_data for output?

            soonest_track.sum_delta = soonest_track.sum_delta + soonest_track.next_event_delta
            if soonest_track.data_index >= soonest_track.length then
                print("end of track", soonest_track_index, #soonest_track.messages, soonest_track.sum_delta)
            else
                soonest_track.next_event_delta = read_variable_length_quantity(soonest_track)
            end
        end
    end,

    done = function(song, stage)
        error("reached new done. Clean up should be handled by state.is_done check.")
    end
}


---Convert a song with midi data into a processed song.
---@param song Song
---@return TL_Future
local function midi_processor(song)
    -- if not host:isHost() then
    --     error("Viewer tried to process a song.")
    -- end

    ---@class MidiProcessorState
    song.data_processor_state = {
        is_done = false,

        ---@type midi_processor_stage
        stage = "init",

        -- stores the raw midi data, organized by chunk
        -- organized during the read stage.
        chunks = {
            ---@type MidiChunk[]
            unknown_chunks = {},

            ---@type MidiChunk?
            header = nil,

            ---@type MidiChunk[]
            tracks = {},
        },

        -- Stores temporary info ab50out notes.
        ---@type table<integer, table<integer, Instruction>>
        instruction_builder = {
            -- channel_index { note_index = { instruction } }
        },
        ---@type Instruction[]
        complete_instructions = {},

        reader = {
            file_stream = nil, ---@type InputStream|nil
            current_chunk_length_counter = 0,   ---@type integer
        },
        processor = {
            ---Message IDs can be omitted if the current ID is identical to the previous ID.
            ---Store the most resent ID here
            ---@type integer?
            running_status_id = nil,
        },
        data_index = 1,
        midi_header_info = {
            default_time_signature = {numerator = 4, denominator = 4},
            default_tempo = 500000, -- 120 BPM in microseconds per beat.
            default_bpm = 120,      -- Calculated number. Midi stores temp in microseconds per beat. ↑
            initial_time_signature = nil,   -- initial should be set by the time signature and tempo midi events in the first track. (format 0 and 1)
            initial_tempo = nil,            --      in format 2, they should be at the start of every temporaly independant track.
            initial_bpm = nil,
        },
        -- current_chunk = nil  →
    }

    local state = song.data_processor_state

    ---@type TL_FutureController, TL_Future
    local future_controller, return_future = require("./../futures").new_future("Song")

    local function processor_loop()
        if state.is_done then
            -- this has a chance to run _after_ the future says it's done
            print("processor all done. Cleaning up.")
            events.WORLD_RENDER:remove(processor_loop)
        elseif midi_processor_loop_stage_functions[state.stage] then
            local success, value = pcall(function() midi_processor_loop_stage_functions[state.stage](song, state) end)
            if not success then
                future_controller:set_done_with_error(value)
                state.is_done = true
                events.WORLD_RENDER:remove(processor_loop)
            end
        end
    end

    -- leveraging the event loop to preform async-like code.
    -- The tick event wouldn't be ideal here because if the function takes
    -- longer than 1 tick's worth of time, the game will freeze as it tries
    -- to catch all the tick events
    -- Using the render loop is better, because the game does not try to
    -- catch up lost frames, and instead the framerate just drops.
    -- Using world_render is even better, because it is allways called, but
    -- the default limit is really low unless the host is on max perms.
    -- It's safe to assume the HOST is allways at max perms. So ultimately,
    -- it's fine.
    events.WORLD_RENDER:register(processor_loop)

    return return_future
end

---@type FileProcessor
local midi_processor_api = {

    song_list_from_paths = function(self, display_and_full_paths)
        -- All the midi files we care about are self contained. Each file is a single song.
        -- This is different from ABC files, where song tracks are sometimes split between files.
        -- But for midi, we just need to see if the file is a midi file, and wrap it in a song table.

        local supported_extensions = {"mid", "midi"}
        local midi_songs = {}
        for i, file_paths in ipairs(display_and_full_paths) do
            local file_ext = file_paths.full_path:match("%.([^%.]+)$"):lower()
            for _, supported_file_ext in pairs(supported_extensions) do
                if supported_file_ext == file_ext then
                    ---@type Song
                    local new_song = {
                        id = file_paths.full_path,
                        name = file_paths.short_path,
                        short_name = file_paths.short_path:match("([^/]*)%."),
                        source = {type = "files", full_path = file_paths.full_path},
                        start_data_processor = self.process_song
                    }
                    table.insert(midi_songs, new_song)
                    break
                end
            end
        end
        return midi_songs
    end,

    process_song = midi_processor
}

return midi_processor_api
