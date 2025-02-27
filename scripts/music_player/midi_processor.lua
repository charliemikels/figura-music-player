---@module "scripts.music_player.music_player"

-- see: http://www.music.mcgill.ca/~ich/classes/mumt306/StandardMIDIfileformat.html


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



---@enum midi_event_types
local midi_event_types = {
    meta = 0xFF,
    system_exclusive_message = 0xF0,
    continued_system_exclusive_message = 0xF7,
}

---Collection of functions to process midi meta events, indexed by their event ID byte.
---
---The function that calls these functions should have already read the data needed for these functions.
---So if an unrecognized event happens, we can safely ignore it.
---@type table<integer, fun(state: MidiProcessorState, length: integer, bytes: integer[])>
local midi_meta_event_functions = {

    ---sequence_number
    ---
    ---Optional. Format 0 and 1 have only one sequence, But format 2 might have multiple. Sequence_number is used to keep sequences in order.
    -- [0x00] = function(state, length, bytes) end,

    ---text_event
    ---
    ---Generic text event. Provides notes about the song, or about a part of it. Events 0x01 - 0x0F are all text events of some sort.
    -- [0x01] = function(state, length, bytes) end,

    ---copyright_notice
    ---
    ---Text event with copyright info.
    [0x02] = function(state, length, bytes)
        state.processed_song_metadata.copyright_notice = string.char(table.unpack(bytes))
    end,

    ---sequence_or_track_name
    ---
    ---Text event. If in format 0, or first track in format 1, then this is the name of the sequence. (the whole song.) Else, it's the name of the track
    [0x03] = function(state, length, bytes)
        state.current_chunk.track_name = string.char(table.unpack(bytes))
    end,

    ---instrument_name
    ---
    ---Text event. Description or type of instrument to use for this track. See also Midi channel prefix
    -- [0x04] = function(state, length, bytes) end,

    ---lyric
    ---
    ---Text event. defines the lyric to sing at a speciffic time. Typicaly, lyric events are stored per-sylable
    -- [0x05] = function(state, length, bytes) end,

    ---marker
    ---
    ---a text marker to name parts of the song. ("Verse 1", "chorus", etc.) usualy only if first track.
    -- [0x06] = function(state, length, bytes) end,

    ---cue_point
    ---
    ---With film, a description of what happens on screen.
    -- [0x07] = function(state, length, bytes) end,

    ---midi_channel_prefix
    ---
    ---Sets a prefix for the channel. (0-15 (?)). Used to assosiate this channel with any following events.
    -- [0x20] = function(state, length, bytes) end,

    ---end_of_track
    ---
    ---**Required.** Marker for a cannonical end of a track.
    ---(Unlike in ABC, MIDI songs end when this event is hit. In ABC, it ends whenever the last note is done.)
    [0x2F] = function(state, length, bytes)
        -- TODO: Save "end of song point"
        -- Clean up/save remaining data in current track.

        -- Some tracks may not have saved any note data. We may want throw a flag in the track data so that we don't have to display it in the UI.
        -- EG: `Wii Sports - Theme.mid`: The first track only time signature and some other meta data, then closes.

        -- Resetting for next track happens at the end of the midi-chunk loop


        -- tmp
        if End_Of_Track_Event_Not_First_Time then
            -- dev
            error("TODO: Finish End of track Meta Event: 0x2F")
        end
        End_Of_Track_Event_Not_First_Time = true
        print("")
        print("TODO: Finish End of track Meta Event: 0x2F")
        print("")
    end,

    ---set_tempo
    ---
    ---Sets tempo in "microseconds per MIDI quarter-note" (aka: "24ths of a microsecond per MIDI clock")
    ---Note this is in time-per beat, not the traditional beat-per-time.
    [0x51] = function(state, length, bytes)
        local microseconds_per_midi_quarter_note = bytes_to_number(bytes)

        state.current_chunk.tempo = microseconds_per_midi_quarter_note
        state.current_chunk.bpm = 60000000 / microseconds_per_midi_quarter_note

        if not state.midi_header_info.initial_tempo then
            state.midi_header_info.initial_tempo = state.current_chunk.tempo
            state.midi_header_info.initial_bpm = state.current_chunk.bpm
        end
    end,

    ---smpte_offset
    ---
    ---Part of Format 2. Marks when this track is supposed to start.
    -- [0x54] = function(state, length, bytes) end,

    ---time_signature
    --- - <numerator: int>
    --- - <denominator: negative-power-of-two>.
    --- - the 3rd and 4th bytes are metronome data.
    [0x58] = function(state, length, bytes)
        local numerator = bytes[1]
        local denominator = 2^(bytes[2]) -- denominator is stored as "a negative power of two". (2→4, 3→8 …)
        -- local number_of_midi_clocks_in_a_metronome_click = bytes[3]
        -- local number_of_notated_32nd_notes_in_a_midi_quarter_note = bytes[4]

        state.current_chunk.time_signature = { numerator = numerator, denominator = denominator }

        if not state.midi_header_info.initial_time_signature then
            state.midi_header_info.initial_time_signature = { numerator = numerator, denominator = denominator }
        end

        print("TODO: time_signature meta event: Double check meaning of 'a negative power of two' for the denominator.")
    end,

    ---key_signature.
    --- - <numb of sharps and flats (negative == flat, positive == sharps. 0 == C)>
    --- - <0 == major, 1 == minor>
    -- [0x59] = function(state, length, bytes) end,

    ---sequencer_specific_meta_event
    ---
    ---Instructions for speciffic sequencers. There may be common ones we'll want to implement later. Take note of instances where this appears.
    -- [0x7F] = function(state, length, bytes) end
}


---Collection of functions to process midi message events, indexed by their event ID byte.
---
---These functions are responcible for reading their own data. All events must be handeled in some way.
---@type table<integer, fun(state: MidiProcessorState, delta: number, channel: number?)>
local midi_message_functions = {
    -- ↓ Functions 10000000 through 11100000 (aka 11101111) include a channel ID. This is pre-parsed and passed as a paramiter.

    ---Note Off event
    -- [tonumber("10000000", 2)] = function(state, delta, channel) end,

    ---Note On event
    -- [tonumber("10010000", 2)] = function(state, delta, channel) end,

    ---Polyphonic Key Pressure (Aftertouch)
    -- [tonumber("10100000", 2)] = function(state, delta, channel) end,

    ---Control Change / Channel Mode Messages
    ---
    ---Some Controller numbers are reserved. See "Channel Mode Messages"
    -- [tonumber("10110000", 2)] = function(state, delta, channel) end,

    ---Program change
    -- [tonumber("11000000", 2)] = function(state, delta, channel) end,

    ---Channel Presure
    -- [tonumber("11010000", 2)] = function(state, delta, channel) end,

    ---Pitch Wheel Change
    -- [tonumber("11100000", 2)] = function(state, delta, channel) end,

    -- ↑ Has channel ID
    -- ↓ No channel ID. Channel is not used.

    ---System Exclusive
    ---
    ---Each data byte in the system Exclusive message starts with a 0. Only real-time messages can inturrupt a system exclusive message.
    ---
    ---This is the same code as the system_exclusive_message type that we're already handeling. We shouldn't encounter this message at this stage.
    [tonumber("11110000", 2)] = function(state, delta, channel)
        error("System Exclusive Message tried to be processed as a normal midi message.")
    end,

    ---Undefined
    [tonumber("11110001", 2)] = function(state, delta, channel)
        error("Undefined midi message")
    end,

    ---Song Position Pointer
    -- [tonumber("11110010", 2)] = function(state, delta, channel) end,

    ---Song Select
    ---
    ---Used to select what sequence/song to play.
    -- [tonumber("11110011", 2)] = function(state, delta, channel) end,

    ---Undefined
    [tonumber("11110100", 2)] = function(state, delta, channel)
        error("Undefined midi message")
    end,

    ---Undefined
    [tonumber("11110101", 2)] = function(state, delta, channel)
        error("Undefined midi message")
    end,

    ---Tune request
    ---
    ---Request all analogue systems to tune themselves.
    -- [tonumber("11110110", 2)] = function(state, delta, channel) end,

    ---End of system exclusive dump.
    ---
    ---The System Exclusive message handeler will usualy take care of this.
    [tonumber("11110111", 2)] = function(state, delta, channel)
        error("End of a System Exclusive Message tried to be processed as a normal midi message.")
    end,

    -- ↓ System "Real-time" messages.
    -- We can probably ignore just about all of these.

    ---Timing Clock
    ---
    ---Sent 24 times per quarter note when synchronisation is required
    -- [tonumber("11111000", 2)] = function(state, delta, channel) end,

    ---Undefined
    [tonumber("11111001", 2)] = function(state, delta, channel)
        error("Undefined midi message")
    end,

    ---Start
    ---
    ---Start the current sequence playing
    -- [tonumber("11111010", 2)] = function(state, delta, channel) end,

    ---Continue
    ---
    ---Continue at the point the sequence was stopped
    -- [tonumber("11111011", 2)] = function(state, delta, channel) end,

    ---Stop
    ---
    ---Stop the current sequence
    -- [tonumber("11111100", 2)] = function(state, delta, channel) end,

    ---Undefined
    [tonumber("11111101", 2)] = function(state, delta, channel)
        error("Undefined midi message")
    end,

    ---Active Sensing
    ---
    ---Optional message. Receivers that get this message will expect another Active Sensing message within 300ms.
    ---Or it will assume the conection has terminated. When it's terminated, receiver will turn off all voices and
    ---return to normal, non active sensing opperation.
    [tonumber("11111110", 2)] = function(state, delta, channel) end,

    ---Reset
    ---
    ---Reset all receivers to the system power-up status.
    ---
    ---For us, this should never happen since code `11111111` is a meta event.
    [tonumber("11111111", 2)] = function(state, delta, channel)
        error("Meta event tried to be processed as a normal midi message.")
    end
}


---Convert a song with midi data into a processed song.
---@param song Song
---@return Future
local function midi_processor(song)
    -- if not host:isHost() then
    --     error("Viewer tried to process a song.")
    -- end

    ---@class MidiProcessorState
    song.data_processor_state = {
        is_done = false,
        stage = "init",
        raw_data = {},
        processed_song_metadata = {},
        incomplete_instructions = {
            -- .track = {
            --      .channel = { instruction }
            -- }
            -- ??
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
        current_chunk = nil
    }

    ---Limits to keep to reduce lag when processing large files.
    local max_read_steps_per_event    = 100000  -- This stage has very few instructions, so it's max count can be very high.
    local max_process_steps_per_event = 1000    -- This stage is far more expensive than max_read_steps.

    local state = song.data_processor_state

    ---Grabs the next byte from raw_data, and keeps track of progress through the raw data and current chunk.
    ---@param self self
    ---@return number
    function state:raw_data_next_byte()
        local return_data = song.raw_data[self.data_index]
        self.data_index = self.data_index + 1
        if self.current_chunk and self.current_chunk.data_index then
            self.current_chunk.data_index = self.current_chunk.data_index +1
        end
        return return_data
    end

    ---Assumes current index is the start of a variable-length-quantity, and attempts to read it as a number.
    ---Uses state:raw_data_next_byte() under the hood, so the data_index is advanced when ran.
    ---@param self self
    ---@return number
    function state:read_variable_length_quantity()
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
            local current_byte = self:raw_data_next_byte()
            table.insert(bytes, bit32.band(current_byte, number_data_mask))
        until not bit32.btest(current_byte, continue_bit_mask)

        return combine_seven_bit_numbers(bytes)
    end

    local function processor_loop()
        if state.stage == "init" then
            -- Ensure everything is ready to go for reading and organizing

            -- Set up input stream for read step, or skip read if not needed
            if song.data_source == "files" and (song.raw_data == nil or song.raw_data == {}) then
                state.file_stream = file:openReadStream(song.truepath)
                state.stage = "read"
            else
                state.stage = "process"
            end
            print("init done")

        elseif state.stage == "read" then
            -- read in data, one byte at a time,
            for i = 1, max_read_steps_per_event, 1 do
                if
                    state.file_stream:available()
                    and state.file_stream:available() > 0
                then
                    table.insert(state.raw_data, state.file_stream:read())
                else
                    break
                end
            end

            if state.file_stream:available() <= 0 then
                -- Last loop had last item. move on
                song.raw_data = state.raw_data
                state.raw_data = nil
                state.file_stream:close()
                state.file_stream = nil
                state.stage = "process"

                print("read done")
            end

        elseif state.stage == "process" then
            if state.data_index >= #song.raw_data then
                state.stage = "done"
                state.is_done = true
                print("process done")
            else
                for i = 1, max_process_steps_per_event, 1 do
                    if state.current_chunk == nil then
                        -- no chunk data. Let's set that up

                        --Midi chunks always start with 4 Chars to ID the chunk,
                        -- then a 32-bit length (4 bytes) to indicate how many bytes are in the chunk.
                        state.current_chunk = {}

                        --Chunk type: string with 4 chars.
                        --"MThd" == midi header. "MTrk" == track. Any unrecognized are probably ignorable.
                        state.current_chunk.type = string.char(
                            state:raw_data_next_byte(),
                            state:raw_data_next_byte(),
                            state:raw_data_next_byte(),
                            state:raw_data_next_byte()
                        )

                        --32-bit unsigned int, represents how many bytes in the entire chunk.
                        state.current_chunk.length = bytes_to_number({
                            state:raw_data_next_byte(),
                            state:raw_data_next_byte(),
                            state:raw_data_next_byte(),
                            state:raw_data_next_byte()
                        })
                        state.current_chunk.data_index = 1


                        -- Transfer meta info that transfers between tracks.
                        state.current_chunk.tempo = state.midi_header_info.initial_tempo or state.midi_header_info.default_tempo
                        state.current_chunk.bpm = state.midi_header_info.initial_bpm or state.midi_header_info.default_bpm
                        state.current_chunk.time_signature = (
                            state.midi_header_info.initial_time_signature
                            and {   numerator   = state.midi_header_info.initial_time_signature.numerator,
                                    denominator = state.midi_header_info.initial_time_signature.denominator }
                            or  {   numerator   = state.midi_header_info.default_time_signature.numerator,
                                    denominator = state.midi_header_info.default_time_signature.denominator }
                        )

                        break

                    elseif state.current_chunk.data_index > state.current_chunk.length then
                        -- at end of chunk
                        -- (if instead chunk.data_index == chunk.length, then we would still need to grab the last state:raw_data_next_byte())

                        state.current_chunk = nil

                    elseif state.current_chunk.type == "MThd" then  -- MIDI header. should be first chunk in file
                        -- All midi headers should be 6 bytes, with 3 2-byte (16-bit) words.
                        -- state.midi_header_info = {}

                        -- format: 0, 1, or 2.
                        --
                        -- * 0 = one track in the entire file
                        -- * 1 = multiple tracks, each track listed one after the other. { full_track_1, full_track_2 }
                        -- * 2 = multiple tracks woven through each other. { partial_track_1, partial_track_2, partial_track_1, partial_track_2, … }
                        state.midi_header_info.format = bytes_to_number({state:raw_data_next_byte(), state:raw_data_next_byte()})

                        if state.midi_header_info.format == "2" then
                            error("MIDI format 2 not yet supported."
                                .." Send this MIDI file (".. song.name ..") to the script author for testing.")
                        end

                        -- Number of tracks
                        state.midi_header_info.number_of_tracks = bytes_to_number({state:raw_data_next_byte(),state:raw_data_next_byte()})

                        -- division / timing data
                        -- bit 15 = format type: 0 == ticks per quarter-note. 1 == timecode system
                        local first_bit_mask = tonumber("10000000", 2)
                        local everything_but_first_bit_mask = bit32.bnot(first_bit_mask)
                        local first_byte_of_timing_data = state:raw_data_next_byte()
                        local second_byte_of_timing_data = state:raw_data_next_byte()

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

                        if state.current_chunk.data_index <= state.current_chunk.length then
                            print("Header chunk is larger than expected. Skipping to next chunk.")
                            state.data_index = state.data_index + (state.current_chunk.length - 6)
                        end

                        -- Done processing the header chunk
                        state.current_chunk = nil

                    elseif state.current_chunk.type == "MTrk" then
                        -- We've already checked if the current chunk has ended. So we should have some midi event before us

                        -- Track chunks are repeating (delta-times, and events). delta-times are a variable-lenght quantity.
                        -- The start of a track is likely a delta 0 and some meta events.

                        -- Some meta events are expected at the start of the first track.

                        local event_delta = state:read_variable_length_quantity()
                        local event_code = state:raw_data_next_byte()
                        print("event_code:", number_to_dec_and_hex(event_code))

                        -- events have a few flavors: midi event, sysex events, and meta events.
                        if event_code == midi_event_types.meta then
                            -- meta events all start with `FF`. They have this format: `FF <type> <length> <bytes>`
                            -- where `type` is a byte less that `128`, `length` is a variable-length quantity, and
                            -- the rest is just data. There are a few meta events that we care about. But many we
                            -- may not recognize.

                            local meta_event_type = state:raw_data_next_byte()
                            local meta_event_length = state:read_variable_length_quantity()
                            local meta_event_bytes = {}
                            for _ = 1, meta_event_length do
                                table.insert(meta_event_bytes, state:raw_data_next_byte())
                            end

                            -- process specific meta events.
                            if midi_meta_event_functions[meta_event_type] then
                                midi_meta_event_functions[meta_event_type](state, meta_event_length, meta_event_bytes)
                            else
                                print("Unrecognized meta event:", number_to_hex(meta_event_type))
                            end

                        elseif event_code == midi_event_types.system_exclusive_message
                            or event_code == midi_event_types.continued_system_exclusive_message
                        then
                            -- sysex events are messages for "the system." I don't think we need to worry about this type.
                            -- sysex events is sometimes stored as packets within the midi file.
                            -- normal one-message sysex = `F0 <variable-length quantity> <bytes>`, where final byte is `F7`
                            -- Start of message chain   = `F0 <variable-length quantity> <bytes>`, where final byte is not `F7`
                            -- Continuation of message  = `F7 <variable-length quantity> <bytes>`, where final byte is not `F7`
                            -- end of message chain     = `F7 <variable-length quantity> <bytes>`, where final byte is `F7`.
                            -- A final `F7` indicates that the message is done. But we shouldn't need to worry about
                            -- system messages like these at all. If we encounter an event starting with `F0` or `F7`,
                            -- we can just skip the entire length of bytes.

                            local sysex_event_length = state:read_variable_length_quantity()
                            local sysex_event_bytes = {}
                            for _ = 1, sysex_event_length do
                                table.insert(sysex_event_bytes, state:raw_data_next_byte())
                            end

                            log("skipping sysex event:", table.unpack(sysex_event_bytes))

                            -- error("TODO: sysex events")
                        else
                            -- Standard midi message. Refer to lookup table.

                            -- by the time we get here, we should have already seen the tempo and key signature meta events.


                            -- Midi Messenge < `11110000` use the last 4 bits to represent a channel ID
                            local first_half_mask = tonumber("11110000", 2)
                            local midi_channel = (
                                (event_code < first_half_mask)
                                and bit32.band(event_code, bit32.bnot(first_half_mask))
                                or nil
                            )
                            local midi_message_id = (
                                (event_code < first_half_mask)
                                and bit32.band(event_code, first_half_mask)
                                or event_code
                            )

                            print("Midi message:", number_to_hex(midi_message_id), "|", "Channel:", number_to_hex(midi_channel))

                            if midi_message_functions[midi_message_id] then
                                midi_message_functions[midi_message_id](state, event_delta, midi_channel)
                            else
                                error("Unknown midi message: " .. number_to_hex(event_code))
                            end


                            -- error("TODO: standard midi events")
                        end


                        -- DEV: end early
                        -- state.data_index = #song.raw_data +1
                        break

                    end

                end
            end

        elseif state.is_done then
            -- this has a chance to run _after_ the future says it's done
            print("processor all done. Cleaning up.")
            events.WORLD_RENDER:remove(processor_loop)
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

    local future = {}
    ---@type Future
    future = {
        isDone = function()
            if state.is_done then return true end
        end,
        hasError = function()
            error("TODO: Implement Future.hasError.")
            if true then
                return true
            end
            return false
        end,
        throwError = function()
            error("TODO: Implement Future.throwError.")
            return nil
        end,
        getValue = function()
            if not future.isDone() then
                error("Future is has not finished. Check with future.isDone() before calling getValue.")
            elseif future.hasError() then
                return nil
            end
            error("TODO: Future.getValue not implemented.")
        end,
        getOrError = function()
            if future.hasError() then
                future.throwError()
            elseif not future.isDone() then
                error("Future.getOrError() was called before the future was done. use Future.isDone() to check if the future is done.")
            else
                return future.getValue()
            end
        end,
    }

    return future
end

return midi_processor
