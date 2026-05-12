---@module "../core"
---@module "../song_player"

-- see: https://www.freqsound.com/SIRA/MIDI%20Specification.pdf

local do_debug_prints = false

-- Defaults, enums, and and limits

---Limits to keep to reduce lag when processing large files.
local max_read_steps_per_event    = 100000
local max_process_steps_per_event = 1000

---@enum MidiChunkTypes
local midi_chunk_types = {
    header = "MThd",
    track = "MTrk"
}

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

---For use with state and track chunk initilization.
---@type MidiDeviceName
local default_midi_device_name = ""

---Meta event `0x09` can define new output devices with their own set of channels,
---allowing us to have more than 16 total channels in a file.
---
---Use this function to standardize channel initilization within state.
---
---@param state MidiProcessorState
---@param new_device_name MidiDeviceName
local function add_new_device(state, new_device_name)

    ---@class MidiDeviceChannelState
    ---@field volume integer?
    ---@field pan integer?

    ---@alias MidiDeviceName string
    ---@alias MidiChannelId integer

    if state.known_devices[new_device_name] then
        print_debug("device `"..new_device_name.."` is already known.")
        return
    end
    state.known_devices[new_device_name] = true

    state.instruction_builder[new_device_name] = {}
    state.processed_metadata.channel_data[new_device_name] = {}
    for channel_id = 0, 15 do
        state.instruction_builder[new_device_name][channel_id] = { channel_state = {}, notes = {} }
        ---@class MidiDeviceChannelData
        state.processed_metadata.channel_data[new_device_name][channel_id] = {
            ---@type {id: integer, name: string}[]
            seen_instruments = {}
        }

        local blank_instrument = { id = 0, name = (channel_id == 10-1 and "Percussion"  or "Acoustic Grand Piano") }
        table.insert(state.processed_metadata.channel_data[new_device_name][channel_id].seen_instruments, blank_instrument )
    end
end


-- A helper function to convert between midi device + channels to music player tracks.
--
-- Not to be confused with track chunks in a midi file.
--
-- This version returns nil if the device and channel combo is currently unused
--
---@param state MidiProcessorState
---@param device_name MidiDeviceName
---@param channel_id MidiChannelId
---
--- Program can change in the middle of a song.
--- Because we want out final output to have 1 instrument per track,
--- we need to treat every program change as the start of a new track.
---@param program_id integer
---@return integer?
local function get_track_id(state, device_name, channel_id, program_id)
    if not state.used_track_ids[device_name] then return nil end
    if not state.used_track_ids[device_name][channel_id] then return nil end
    return state.used_track_ids[device_name][channel_id][program_id]
end

-- A helper function to convert between midi device + channels to music player tracks.
--
-- Not to be confused with track chunks in a midi file.
--
---@param state MidiProcessorState
---@param device_name MidiDeviceName
---@param channel_id MidiChannelId
---@return integer
local function get_or_set_and_get_track_id(state, device_name, channel_id, program_id)
    if not state.used_track_ids[device_name] then
        state.used_track_ids[device_name] = {}
    end

    if not state.used_track_ids[device_name][channel_id] then
        state.used_track_ids[device_name][channel_id] = {}
    end

    if not state.used_track_ids[device_name][channel_id][program_id] then
        state.used_track_ids[device_name][channel_id][program_id] = state.next_track_id
        state.next_track_id = state.next_track_id + 1
    end

    return state.used_track_ids[device_name][channel_id][program_id]
end

---Converts a number into a string with both Dec and Hex values. Primaraly for debug
---@param number number
---@return string
local function number_to_dec_and_hex(number)
    return string.format("Dec: %.0f | Hex: %x", number, number)
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


local midi_default_tempo = 500000
---Calculates a multiplier to convert between the file's delta ticks to a duration in miliseconds
---@param division integer      Part of the midi header chunk. Defines delta ticks per quarter note
---@param tempo integer         Set by meta event 0x51 (set_tempo). Defines microseconds (not milis) per midi quarter note.
---@return number multiplier
local function recalculate_ticks_to_milis_multiplier(division, tempo)
    -- state.midi_header_info.ticks_pre_quarter_note
    return (tempo / division) / 1000
end

---List of patch/instrument names for use with message 11000000 "Program change"
---@type table<integer, string >
local patch_name_lookup = {
    [1-1] = "Acoustic Grand Piano",
    [2-1] = "Bright Acoustic Piano",
    [3-1] = "Electric Grand Piano",
    [4-1] = "Honky-tonk Piano",
    [5-1] = "Electric Piano 1 (Rhodes Piano)",
    [6-1] = "Electric Piano 2 (Chorused Piano)",
    [7-1] = "Harpsichord",
    [8-1] = "Clavinet",
    [9-1] = "Celesta",
    [10-1] = "Glockenspiel",
    [11-1] = "Music Box",
    [12-1] = "Vibraphone",
    [13-1] = "Marimba",
    [14-1] = "Xylophone",
    [15-1] = "Tubular Bells",
    [16-1] = "Dulcimer (Santur)",
    [17-1] = "Drawbar Organ (Hammond)",
    [18-1] = "Percussive Organ",
    [19-1] = "Rock Organ",
    [20-1] = "Church Organ",
    [21-1] = "Reed Organ",
    [22-1] = "Accordion (French)",
    [23-1] = "Harmonica",
    [24-1] = "Tango Accordion (Band neon)",
    [25-1] = "Acoustic Guitar (nylon)",
    [26-1] = "Acoustic Guitar (steel)",
    [27-1] = "Electric Guitar (jazz)",
    [28-1] = "Electric Guitar (clean)",
    [29-1] = "Electric Guitar (muted)",
    [30-1] = "Overdriven Guitar",
    [31-1] = "Distortion Guitar",
    [32-1] = "Guitar harmonics",
    [33-1] = "Acoustic Bass",
    [34-1] = "Electric Bass (fingered)",
    [35-1] = "Electric Bass (picked)",
    [36-1] = "Fretless Bass",
    [37-1] = "Slap Bass 1",
    [38-1] = "Slap Bass 2",
    [39-1] = "Synth Bass 1",
    [40-1] = "Synth Bass 2",
    [41-1] = "Violin",
    [42-1] = "Viola",
    [43-1] = "Cello",
    [44-1] = "Contrabass",
    [45-1] = "Tremolo Strings",
    [46-1] = "Pizzicato Strings",
    [47-1] = "Orchestral Harp",
    [48-1] = "Timpani",
    [49-1] = "String Ensemble 1 (strings)",
    [50-1] = "String Ensemble 2 (slow strings)",
    [51-1] = "SynthStrings 1",
    [52-1] = "SynthStrings 2",
    [53-1] = "Choir Aahs",
    [54-1] = "Voice Oohs",
    [55-1] = "Synth Voice",
    [56-1] = "Orchestra Hit",
    [57-1] = "Trumpet",
    [58-1] = "Trombone",
    [59-1] = "Tuba",
    [60-1] = "Muted Trumpet",
    [61-1] = "French Horn",
    [62-1] = "Brass Section",
    [63-1] = "SynthBrass 1",
    [64-1] = "SynthBrass 2",
    [65-1] = "Soprano Sax",
    [66-1] = "Alto Sax",
    [67-1] = "Tenor Sax",
    [68-1] = "Baritone Sax",
    [69-1] = "Oboe",
    [70-1] = "English Horn",
    [71-1] = "Bassoon",
    [72-1] = "Clarinet",
    [73-1] = "Piccolo",
    [74-1] = "Flute",
    [75-1] = "Recorder",
    [76-1] = "Pan Flute",
    [77-1] = "Blown Bottle",
    [78-1] = "Shakuhachi",
    [79-1] = "Whistle",
    [80-1] = "Ocarina",
    [81-1] = "Lead 1 (square wave)",
    [82-1] = "Lead 2 (sawtooth wave)",
    [83-1] = "Lead 3 (calliope)",
    [84-1] = "Lead 4 (chiffer)",
    [85-1] = "Lead 5 (charang)",
    [86-1] = "Lead 6 (voice solo)",
    [87-1] = "Lead 7 (fifths)",
    [88-1] = "Lead 8 (bass + lead)",
    [89-1] = "Pad 1 (new age Fantasia)",
    [90-1] = "Pad 2 (warm)",
    [91-1] = "Pad 3 (polysynth)",
    [92-1] = "Pad 4 (choir space voice)",
    [93-1] = "Pad 5 (bowed glass)",
    [94-1] = "Pad 6 (metallic pro)",
    [95-1] = "Pad 7 (halo)",
    [96-1] = "Pad 8 (sweep)",
    [97-1] = "FX 1 (rain)",
    [98-1] = "FX 2 (soundtrack)",
    [99-1] = "FX 3 (crystal)",
    [100-1] = "FX 4 (atmosphere)",
    [101-1] = "FX 5 (brightness)",
    [102-1] = "FX 6 (goblins)",
    [103-1] = "FX 7 (echoes, drops)",
    [104-1] = "FX 8 (sci-fi, star theme)",
    [105-1] = "Sitar",
    [106-1] = "Banjo",
    [107-1] = "Shamisen",
    [108-1] = "Koto",
    [109-1] = "Kalimba",
    [110-1] = "Bag pipe",
    [111-1] = "Fiddle",
    [112-1] = "Shanai",
    [113-1] = "Tinkle Bell",
    [114-1] = "Agogo",
    [115-1] = "Steel Drums",
    [116-1] = "Woodblock",
    [117-1] = "Taiko Drum",
    [118-1] = "Melodic Tom",
    [119-1] = "Synth Drum",
    [120-1] = "Reverse Cymbal",
    [121-1] = "Guitar Fret Noise",
    [122-1] = "Breath Noise",
    [123-1] = "Seashore",
    [124-1] = "Bird Tweet",
    [125-1] = "Telephone Ring",
    [126-1] = "Helicopter",
    [127-1] = "Applause",
    [128-1] = "Gunshot",
}

---comment
---@param state MidiProcessorState
---@param track MidiChunk
---@param channel MidiChannelId
---@param start_time number
---@param controller_value integer
---@param data_type string
local function update_channel_state_in_currently_playing_notes(state, track, channel, start_time, controller_value, data_type)
    ---@type integer, Instruction
    for _, note_data in pairs(state.instruction_builder[track.current_device][channel].notes) do
        ---@type InstructionModifier
        local new_modifier = { start_time = start_time, type = data_type, value = controller_value }
        table.insert(
            note_data.modifiers,
            new_modifier
        )
    end
end

-- for use with midi event 10110000: Control Change / Channel Mode Messages
--
-- See: https://nickfever.com/music/midi-cc-list
---@type table<MidiControlChangeEventKey, fun(state: MidiProcessorState, track: MidiChunk, channel: MidiChannelId, start_time: number, controller_value: integer)>
local control_change_and_mode_change_functions = {

    -- At this stage, we're reading all notes in chronological order. So we should be able to
    -- ignore start time, so long as we save any relevent data in the note on event

    ---@alias MidiControlChangeEventKey
    --- | 2 breath control
    --- | 7 volume
    --- | 10 pan
    --- | 91 reverb
    --- | 92 tremolo
    --- | 93 chorus
    --- | 94 detuneing
    --- | 95 phazer
    --- | 121 reset controllers

    [2] = function() end,    -- Breath control

    [7] = function(state, track, channel, start_time, controller_value)    -- Volume
        state.instruction_builder[track.current_device][channel].channel_state.volume = (controller_value ~= 100 and controller_value or nil) -- 100 is probably the "most default" setting
        update_channel_state_in_currently_playing_notes(state, track, channel, start_time, controller_value, "volume")
    end,
    [10] = function (state, track, channel, start_time, controller_value)  -- Pan
        -- 0 = hard left, 64 = center, 127 = hard right
        state.instruction_builder[track.current_device][channel].channel_state.pan = (controller_value ~= 64 and controller_value or nil)
        update_channel_state_in_currently_playing_notes(state, track, channel, start_time, controller_value, "pan")
    end,

    [91] = function() end,      -- Reverb. Ignoring.
    [92] = function() end,      -- Tremolo. Ignoring.
    [93] = function() end,      -- Chorus. Ignoring.
    [94] = function() end,      -- Detuning. Ignoring, though this wouldn't be too hard to implement. TODO: revisit.
    [95] = function() end,      -- Phazer. Ignoring.

    [121] = function() end,     -- Reset all controllers.   TODO: Revisit? this may be something simple like "purge all channel modifiers from current channel states"  -- TODO: is this per device, or over the whole file?
}


local midi_meta_event_functions -- pre-declared so that event `0x21` can reuse `0x09`
---Collection of functions to read midi meta events, indexed by their event ID byte.
---
---These are used during the read stage. Called from midi_message_functions[11111111]. Fills in message.data
---
---@see MidiMessage
---
---It is technicaly safe to implement an empty function to ignore a meta event.
---The function that calls these functions has already read in the data.
---
---@type table<MidiMetaEventKey, fun(state: MidiProcessorState, track: MidiChunk, data: integer[], start_time: number)>
midi_meta_event_functions = {

    ---@alias MidiMetaEventKey
    --- | 0   0x00  sequence number
    --- | 1   0x01  text
    --- | 2   0x02  copyright notice
    --- | 3   0x03  sequence or track name
    --- | 4   0x04  instrument name
    --- | 5   0x05  lyric
    --- | 6   0x06  marker
    --- | 7   0x07  cue point
    --- | 8   0x08  program name
    --- | 9   0x09  device name
    --- | 32  0x20  channel prefix
    --- | 33  0x21  midi port
    --- | 47  0x2F  end of track
    --- | 81  0x51  set tempo
    --- | 84  0x54  smpte offset
    --- | 88  0x58  time signature
    --- | 89  0x59  key signature
    --- | 127 0x7F  sequencer specific meta event

    ---sequence_number
    ---
    ---Optional. Format 0 and 1 have only one sequence, But format 2 might have multiple. Sequence_number is used to keep sequences in order.
    ---Must come before non-zero delta times, and before all transmitable midi events.
    -- [0x00] = function(state, track, data, start_time)
    --     message.data.sequence_number = message.event_raw_data[1]
    -- end,

    ---text_event
    ---
    ---Generic text event. Provides notes about the song, or about a part of it. Events 0x01 - 0x0F are all text events of some sort.
    [0x01] = function()
        -- we have no system to display generic text.
        -- local text = string.char(table.unpack(data))
    end,

    ---copyright_notice
    ---
    ---Text event with copyright info.
    [0x02] = function()
        -- TODO: Revisit. right now there's no planned system to display copyright info for a song.
        -- local copyright_notice = string.char(table.unpack(data))
    end,

    ---sequence_or_track_name
    ---
    ---Text event. If in format 0, or first track in format 1, then this is the name of the sequence. (the whole song.)
    ---Else, it's the name of this specific track.
    ---
    ---We may want to care about this, but because we'll probably get the song name from the file name, and because
    ---tracks don't actualy isolate anything (we really only care about the midi channels) then we can probably just
    ---ignore this event entirely.
    ---
    ---See also: midi message 11000000 - Program change. Sets the reccomended instrument for the selected track.
    [0x03] = function()
        -- local track_name = string.char(table.unpack(data))
    end,

    ---instrument_name
    ---
    ---Text event. Description or type of instrument to use for this track. See also Midi channel prefix
    -- [0x04] = function(state, track, data, start_time)
    --     track.meta_state.custom_program_name = string.char(table.unpack(data))   --?? What's the dif between this and `0x08`?
    -- end,

    ---lyric
    ---
    ---Text event. defines the lyric to sing at a speciffic time. Typicaly, lyric events are stored per-sylable
    -- [0x05] = function(state, track, data, start_time)
    --     message.data.lyric = string.char(table.unpack(message.event_raw_data))
    -- end,

    ---marker
    ---
    ---a text marker to name parts of the song. ("Verse 1", "chorus", etc.) usualy only if first track.
    -- [0x06] = function(state, track, data, start_time)
    --     message.data.marker = string.char(table.unpack(message.event_raw_data))
    -- end,

    ---cue_point
    ---
    ---With film, a description of what happens on screen.
    -- [0x07] = function(state, track, data, start_time)
    --     message.data.cue_point = string.char(table.unpack(message.event_raw_data))
    -- end,

    -- Program name
    --
    -- See: https://drive.google.com/file/d/1hBRgTrIvv5K7jgeuz0rpeXXT9MNAj6qh/view
    -- Names the program used in following bank select and program change messages.
    --
    -- We can use any names defined here instead of relying on the lookup table of program IDs to reccomended Names.
    --
    -- See also:
    [0x08] = function(_, _, _, _)
        -- track.meta_state.custom_program_name = string.char(table.unpack(data))
        -- print("!", track.meta_state.custom_program_name)
    end,

    -- Device (port) name
    --
    -- Instructs the current _track_ (chunk) to output to a speciffic "port,"
    -- aka: output to a different midi device.
    --
    -- This can enable us to have more than 16 channels, if we keep track of tracks and devices
    --
    -- If this event is called, it should only be called once per track chunk, and happen before any sendable events.
    --
    -- See also: https://drive.google.com/file/d/1hBRgTrIvv5K7jgeuz0rpeXXT9MNAj6qh/view
    [0x09] = function(state, track, data, _)
        local new_device_name = string.char(table.unpack(data))

        if track.current_device == new_device_name then
            print_debug("track "..tostring(track.index).." attempted to change devices to a device it's already using. (device `" .. new_device_name .. "`)")
        elseif track.current_device == default_midi_device_name then
            track.current_device = new_device_name
            print_debug("track " ..tostring(track.index) .. "switched to device `" ..new_device_name.."`")
        else
            print_debug("Current device: ".. track.current_device, true, true)
            print_debug("new device: ".. new_device_name, true, true)
            error("Midi tried to switch track #".. tostring(track.index)
                .." to a new device (`"..tostring(new_device_name)
                .."`) after it was already set to device `"..tostring(track.current_device)
                .."`."
            )
        end

        if not state.known_devices[new_device_name] then
            add_new_device(state, new_device_name)
        end

        if track.meta_state.early_program_change_patch_number then
            -- Program Change was called too early. Redo it's effects here. See midi event 11000000 Program Change
            -- HACK: This is a bandaid fix because I'm too lazy to rework the entire reading data logic in order to allow for look-aheads

            local patch_number = track.meta_state.early_program_change_patch_number
            local channel = track.meta_state.early_program_change_channel_number
            local too_early_channel_metadata = state.processed_metadata.channel_data[new_device_name][channel]

            table.insert(too_early_channel_metadata.seen_instruments, {
                id = patch_number,
                name = track.meta_state.custom_program_name or (channel+1 == 10 and "Percussion") or patch_name_lookup[patch_number]
            })

            print_debug("Late change for new device: channel `" .. tostring(channel).. "`, selected instrument `"..patch_name_lookup[patch_number].."`")

            track.meta_state.early_program_change_patch_number = nil
            track.meta_state.early_program_change_channel_number = nil
        end
    end,

    ---midi_channel_prefix
    ---
    ---Sets a prefix for the channel. (0-15 (?)). Ties any following events (eg sysex events) to selected channel, until
    ---next event that defines a channel, or next channel_prefix meta event.
    ---
    ---considered obsolete. https://www.mixagesoftware.com/en/midikit/help/HTML/meta_events.html
    -- [0x20] = function(state, track, data, start_time)
    --     message.data.sequence_number = message.event_raw_data[1]
    -- end,

    -- Midi Port
    --
    -- Essentialy the same thing as [0x09], but data is one byte for the port index, instead of a string.
    --
    -- considered obsolete. Use `0x09`: "Device (port) name" instead. https://www.mixagesoftware.com/en/midikit/help/HTML/meta_events.html
    [0x21] = function(state, track, data, start_time)
        -- convert our data byte to a string so that we can use it as a name
        local new_device_id_as_string_as_bytes = { string.byte(tostring(data[1])) }
        midi_meta_event_functions[0x09](state, track, new_device_id_as_string_as_bytes, start_time)
    end,

    ---end_of_track
    ---
    ---Marker for a cannonical end of a track.
    [0x2F] = function(state, track, _, start_time)
        -- Real cleanup will happen during the "done" stage

        print_debug("end of track "..tostring(track.index)..". Ended at "..tostring(start_time))

        if track.data_index <= #track.data then
            error("Midi processor reached an `end of track` event, but there is still data to read.")
        end

        track.has_ended = true
        track.time_ended = start_time
        if not state.processed_metadata.time_song_end or state.processed_metadata.time_song_end < start_time then
            state.processed_metadata.time_song_end = start_time
        end
    end,

    ---set_tempo
    ---
    --- Used to calculate the correct delta_time. Usualy seen only in the first track.
    --- Stored in microseconds (not milis) per quarter note. If unspecified, default to 500000 (120 bpm)
    ---
    ---Impacts playback. Pair with "devisions" in the midi header chunk
    [0x51] = function(state, track, data, start_time)
        local microseconds_per_midi_quarter_note = bytes_to_number(data)
        -- next_event_tick_delta is usualy only used in the "which event is next" calculation and is updated at the very end of the read
        -- We are already in the read loop, so "next_event_tick_delta" is actualy this event's tick_delta
        local event_start_tick = track.sum_ticks + track.next_event_tick_delta
        table.insert(state.processed_metadata.tempo_changes.ticks_when_tempo_changed, 1, event_start_tick)   -- pos 1 to keep it in reverse order (so index 1 is most recent)
        state.processed_metadata.tempo_changes.delta_tick_multipliers[event_start_tick] =
            recalculate_ticks_to_milis_multiplier(
                state.midi_header_info.ticks_pre_quarter_note,
                microseconds_per_midi_quarter_note
            )

        ---@type Instruction
        local instruction = {
            track_index = 0,
            duration = 0,
            start_time = start_time,
            start_velocity = 0,
            note = 0x51,
            modifiers = {},
            meta_event_data = {
                t = microseconds_per_midi_quarter_note,
                -- bpm = 60000000 / microseconds_per_midi_quarter_note
            }
        }
        table.insert(state.complete_instructions, instruction)
    end,

    ---smpte_offset
    ---
    ---Part of Format 2. Marks the timestamp when this track is supposed to start.
    -- [0x54] = function(state, track, data, start_time) end,

    ---time_signature
    ---
    ---Does not actualy impact playback of a midi file. But used for accurate score info and display.
    ---We will keep parts of it arround for posibly syncing animations.
    ---
    ---Should default to 4/4
    [0x58] = function(state, _, data, start_time)
        local numerator = data[1]
        local denominator = 2^(data[2]) -- denominator is stored as "a negative power of two". (2→4, 3→8 …)
        -- local number_of_midi_clocks_in_a_metronome_click = data[3]
        -- local number_of_notated_32nd_notes_per_beat = data[4]

        ---@type Instruction
        local instruction = {
            track_index = 0,
            duration = 0,
            start_time = start_time,
            start_velocity = 0,
            note = 0x58,
            modifiers = {},
            meta_event_data = {
                n = numerator, d = denominator
            }
        }
        table.insert(state.complete_instructions, instruction)
    end,

    ---key_signature
    ---
    ---Unlike ABC, does not impact playback. Midi notes themselves communicate what notes to play.
    [0x59] = function()
        -- local unsigned_sharps_or_flats = data[1]
        -- local sharps_or_flats = data[1]  -- numb of sharps/flats (negative == flats, positive == sharps. 0 == C)
        -- local major_or_minor = data[2]   --  0 == major, 1 == minor

        -- ---@type Instruction
        -- local instruction = {
        --     track_index = 0,
        --     duration = 0,
        --     start_time = start_time,
        --     note = 0x59,
        --     modifiers = {},
        --     meta_event_data = {
        --         sharps_or_flats = sharps_or_flats,
        --         major_or_minor = major_or_minor,
        --     }
        -- }
        -- table.insert(state.complete_instructions, instruction)
    end,

    ---sequencer_specific_meta_event
    ---
    ---Instructions for speciffic sequencers. There may be common ones we'll want to implement later. Take note of instances where this appears.
    -- [0x7F] = function(state, track, data, start_time)
    --     message.data.sequencer_specific_meta_event_data = message.event_raw_data
    -- end
}

---@type table<integer, true>
local ignored_controll_change_codes = {}

local midi_message_functions    -- pre-initilized so that note-on can call note-off when velocity is 0

---Collection of functions to process midi message events from a Midi Tracks, indexed by their event ID byte.
---
---When these functions return, track.data_index should be ready to index the delta of the next event
---
---These are ran during the `process` stage to turn data bytes into .
---@type table<MidiStandardEventKey, fun(state: MidiProcessorState, track: MidiChunk, channel: MidiChannelId?, start_time: number)>
midi_message_functions = {

    -- ↓ Functions 10000000 through 11100000 (aka 11101111) include a channel ID. This is pre-parsed and passed as a paramiter.

    ---@alias MidiStandardEventKey
    --- | 128  (0x80 / 10000000) note off
    --- | 144  (0x90 / 10010000) note on
    --- | 160  (0xA0 / 10100000) note aftertouch
    --- | 176  (0xB0 / 10110000) Control Change / Channel Mode Messages
    --- | 192  (0xC0 / 11000000) program change
    --- | 208  (0xD0 / 11010000) channel aftertouch
    --- | 224  (0xE0 / 11100000) pitch wheel
    --- | 240  (0xF0 / 11110000) system exclusive start
    --- | 242  (0xF2 / 11110010) song position pointer
    --- | 243  (0xF3 / 11110011) song select
    --- | 246  (0xF6 / 11110110) tune request
    --- | 247  (0xF7 / 11110111) system exclusive continue
    --- | 248  (0xF8 / 11111000) realtime timing clock
    --- | 250  (0xFA / 11111010) realtime playback start
    --- | 251  (0xFB / 11111011) realtime playback continue
    --- | 252  (0xFC / 11111100) realtime playback stop
    --- | 254  (0xFE / 11111110) realtime active sensing
    --- | 255  (0xFF / 11111111) meta event

    ---Note Off event
    [0x80] = function(state, track, channel, start_time)
        -- Save the data for the current note

        local note_id = read_next_chunk_byte(track)
        local _ = read_next_chunk_byte(track)   -- note_velocity

        local note_to_stop = state.instruction_builder[track.current_device][channel].notes[note_id]
        if not note_to_stop then
            print_debug("Note off tried to stop a note that was not been started before. Ignoring.")
            return
        end
        note_to_stop.duration = start_time - note_to_stop.start_time

        print_debug("Ending note: " .. tostring(note_id) .. " (dur: "..tostring(note_to_stop.duration).." ch: "..tostring(channel).." dev: "..tostring(track.current_device)..")")

        table.insert(state.complete_instructions, note_to_stop)
        state.instruction_builder[track.current_device][channel].notes[note_id] = nil

        print_debug("Finished instructions: " .. tostring(#state.complete_instructions))
    end,

    ---Note On event
    ---Special case: if velocity is 0, treat as a note off event. Stacks well with running status.
    [0x90] = function(state, track, channel, start_time)
        local note_id = read_next_chunk_byte(track)
        local note_velocity = read_next_chunk_byte(track)

        if note_velocity == 0 then
            print_debug("Velocity is 0. Forwarding to note off.")
            track.data_index = track.data_index - 2  -- rewind so that the stop event can just read the data itself.
            midi_message_functions[tonumber("10000000", 2)](state, track, channel, start_time)
            return
        end

        if state.instruction_builder[track.current_device][channel].notes[note_id] then
            print_debug("⚠ 0x90 `Note On` recieved for a note that is already playing. Technicaly undefined behavior? Restarting the note.")
            track.data_index = track.data_index - 2  -- rewind so that the stop event can just read the data itself.
            midi_message_functions[tonumber("10000000", 2)](state, track, channel, start_time)
            -- no need to fast forward, we've already consumed the data we need and can just keep moving
        end
        -- initialize a new note in the note builder

        print_debug("Starting new note: " .. tostring(note_id) .. "(v: "..tostring(note_velocity).." ch: "..tostring(channel).." dev: "..tostring(track.current_device)..")")

        local seen_instruments_list = state.processed_metadata.channel_data[track.current_device][channel].seen_instruments

        ---@type Instruction
        local new_note_data = {
            note = note_id,
            start_time = start_time,
            start_velocity = note_velocity,
            track_index = get_or_set_and_get_track_id(
                state,
                track.current_device,
                channel,
                -- Going in chronological order, we can safely assume the last instrument in the list is the current instrument
                seen_instruments_list[#seen_instruments_list].id
            ),
            duration = nil,
            modifiers = {}
        }

        -- import current channel state. not all values may be set
        for key, value in pairs(state.instruction_builder[track.current_device][channel].channel_state) do
            ---@type InstructionModifier
            local new_modifier = { start_time = start_time, type = key, value = value }
            table.insert(new_note_data.modifiers, new_modifier)
        end

        state.instruction_builder[track.current_device][channel].notes[note_id] = new_note_data
    end,

    ---Polyphonic Key Pressure (Aftertouch)
    [0xA0] = function(_, track, _, _)
        -- I don't really care about Aftertouch. None of my test files use it at least.
        local _ = read_next_chunk_byte(track)
    end,

    ---Control Change / Channel Mode Messages
    ---
    ---Some controller numbers are reserved. See "Channel Mode Messages"
    [0xB0] = function(state, track, channel, start_time)
        -- These are two sepperate event types. Be sure to handle each depending on the state.
        local controller_number = read_next_chunk_byte(track)
        local controller_value = read_next_chunk_byte(track)

        if control_change_and_mode_change_functions[controller_number] then
            print_debug("Running control change function ".. tostring(controller_number))
            control_change_and_mode_change_functions[controller_number](state, track, channel, start_time, controller_value)
        else
            if not ignored_controll_change_codes[controller_number] then
                print_debug("Ignoring unrecognized control change code ".. tostring(controller_number)..". Future warnings for this code will be suppressed.", true, true)
                ignored_controll_change_codes[controller_number] = true
            end
            -- error("Controller number `"..tostring(controller_number).."` not in control_change_and_mode_change_functions.")
            -- TODO: It looks like we're not expected to implement every controller event. There are some pre-defined events
            -- that we should take care of, but at some point, I think we can change this error to just a log message.
        end
    end,

    ---Program change
    ---
    ---Sets the recomended instrument/patch for the channel
    [0xC0] = function(state, track, channel, start_time)
        local patch_number = read_next_chunk_byte(track)

        local this_channel_metadata = state.processed_metadata.channel_data[track.current_device][channel]

        if start_time == 0 and track.current_device == default_midi_device_name then
            -- Program change needs to be applied to a channel. But
            -- some files have this event come _before_ the Device Name event,
            -- which changes the bank of channels this track uses.
            -- To solve this correctly, I would need to look ahead at all of the events at time=0
            -- and see if the track needs to use a different device early.
            -- This is hard to do right now because of the way I'm using `read_next_chunk_byte(track)`
            -- and applying changes at the same time. I can't cleanly sepparate reading from processing.
            -- Likewise, I can't cleanly backtrack either to retroactively fix issues.
            --
            -- But Right Now™, this one thing (program change before device name) is the Only™ real
            -- problem this situation causes. So, as a hacky bandaid solution, I can store the data from this event
            -- and check if the stored data exists in the Device Name event.
            --
            -- As a consiquence, this method WILL CHANGE THE PROGRAM of BOTH the default device and the new device.
            -- But I think it's a safe assumption that any file that specifies a device name for one track
            -- will probably™ specify a device for every track. We also later filter the channels to only the
            -- ones we actualy use, so applying IDs to an unused default device will not be a problem long-term.

            track.meta_state.early_program_change_patch_number = patch_number
            track.meta_state.early_program_change_channel_number = channel
        end

        local name = track.meta_state.custom_program_name or (channel+1 == 10 and "Percussion") or patch_name_lookup[patch_number]

        table.insert(this_channel_metadata.seen_instruments, {id = patch_number, name = name})

        print_debug("channel: `" .. tostring(channel) .. "` selected instrument: `" .. tostring(patch_name_lookup[patch_number]) .."`")
    end,

    ---Channel Presure (Channel Aftertouch)
    [0xD0] = function(_, track, _, _)
        -- I don't really care about Aftertouch. None of my test files use it at least.
        local _ = read_next_chunk_byte(track)
    end,

    ---Pitch Wheel Change
    ---
    ---The pitch wheel is measured by a fourteen bit value. Where 3FFF is the maximum value.
    ---
    ---Center (no pitch change) is Hex = 2000, Dec = 8192.
    ---
    ---"Sensitivity is a function of the transmitter." Usualy this is ±2 semitones. Midi by default doesn't encode the range,
    ---but some use a `RPN` (Registered Parameter Number) to encode this message in the control codes.
    [0xE0] = function(state, track, channel, start_time)
        local least_significant_byte = read_next_chunk_byte(track)
        local most_significant_byte = read_next_chunk_byte(track)
        local pitch_value = combine_seven_bit_numbers({ most_significant_byte, least_significant_byte })
        state.instruction_builder[track.current_device][channel].channel_state.pitch_wheel = (pitch_value ~= 8192 and pitch_value or nil)
        update_channel_state_in_currently_playing_notes(state, track, channel, start_time, pitch_value, "pitch_wheel")
    end,

    -- ↑ Has channel ID
    -- ↓ No channel ID. Channel is not used.

    ---System Exclusive
    ---
    ---Each data byte in the system Exclusive message starts with a 0. Only real-time messages can inturrupt a system exclusive message.
    [0xF0] = function(_, track, _, _)
        -- sysex events are messages for "the system." I don't think we need to worry about this type.
        -- sysex events are sometimes stored as packets within the midi file.
        -- normal one-message sysex = `F0 <variable-length quantity> <bytes>`, where final byte is `F7`
        -- Start of message chain   = `F0 <variable-length quantity> <bytes>`, where final byte is not `F7`
        -- Continuation of message  = `F7 <variable-length quantity> <bytes>`, where final byte is not `F7`
        -- end of message chain     = `F7 <variable-length quantity> <bytes>`, where final byte is `F7`.
        -- A final `F7` indicates that the message is done. But we shouldn't need to worry about
        -- system messages like these at all. If we encounter an event starting with `F0` or `F7`,
        -- we can just skip the entire length of bytes.

        local sysex_event_length = read_variable_length_quantity(track)
        for _ = 1, sysex_event_length do
            local _ = read_next_chunk_byte(track)
            -- table.insert(message.event_raw_data, byte)
            -- table.insert(message.data, byte)
        end
    end,

    ---Undefined
    [0xF1] = function()
        error("Undefined midi message")
    end,

    ---Song Position Pointer
    -- [0xF2] = function(state, track, _, start_time) end,

    ---Song Select
    ---
    ---Used to select what sequence/song to play.
    -- [0xF3] = function(state, track, _, start_time) end,

    ---Undefined
    [0xF4] = function()
        error("Undefined midi message")
    end,

    ---Undefined
    [0xF5] = function()
        error("Undefined midi message")
    end,

    ---Tune request
    ---
    ---Request all analogue systems to tune themselves.
    [0xF6] = function()
        -- no data, nothing to tune, safely ignore.
    end,

    ---System exclusive message
    -- [0xF7] = function(state, track, _, start_time)
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
    [0xF8] = function()
        -- no data, no devices to syncronize, safely ignore.
    end,

    ---Undefined
    [0xF9] = function()
        error("Undefined midi message")
    end,

    ---Start
    ---
    ---Start the current sequence playing
    [0xFA] = function()
        -- No data, controlls playback devices in realtime situations. We are not realtime, Safely ignore?
    end,

    ---Continue
    ---
    ---Continue at the point the sequence was stopped
    [0xFB] = function()
        -- No data, controlls playback devices in realtime situations. We are not realtime, Safely ignore?
    end,

    ---Stop
    ---
    ---Stop the current sequence
    [0xFC] = function()
        -- No data, controlls playback devices in realtime situations. We are not realtime, Safely ignore?
    end,

    ---Undefined
    [0xFD] = function()
        error("Undefined midi message")
    end,

    ---Active Sensing
    ---
    ---Optional message. Receivers that get this message will expect another Active Sensing message within 300ms.
    ---Or it will assume the conection has terminated. When it's terminated, receiver will turn off all voices and
    ---return to normal, non active sensing opperation.
    [0xFE] = function()
        -- no data, realtime situations only to make sure everything stays online. Safely ignore.
    end,

    ---Meta event
    ---
    ---Meta events have their own sub IDs and functions assosiated with them.
    ---
    ---@see midi_meta_event_functions
    [0xFF] = function(state, track, _, start_time)
        local meta_event_id = read_next_chunk_byte(track)
        local meta_event_length = read_variable_length_quantity(track)
        local meta_event_data = {}
        for _ = 1, meta_event_length do
            table.insert(meta_event_data, read_next_chunk_byte(track))
        end

        if midi_meta_event_functions[meta_event_id] then
            print_debug("meta ID = "..number_to_dec_and_hex(meta_event_id))
            midi_meta_event_functions[meta_event_id](state, track, meta_event_data, start_time)
        else
            print_debug("⚠ Ignoring unimplemented meta event: "..number_to_dec_and_hex(meta_event_id))
            -- error("Unimplemented meta event: "..number_to_dec_and_hex(meta_event_id))
        end
    end
}

---@alias MidiProcessorStageKey
---| '"init"'
---| '"read"'
---| '"process"'
---| '"done"'

---@alias MidiProcessorFunctionReturn {progress: number, finished_song: Song?}
---@alias MidiProcessorFunction fun(song_holder: SongHolder, state: MidiProcessorState): MidiProcessorFunctionReturn

---@type table<MidiProcessorStageKey, MidiProcessorFunction>
local midi_processor_loop_stage_functions = {
    init = function(song_holder, state)
        -- Ensure everything is ready to go for reading and organizing

        -- Set up input stream for read step, or skip read if not needed

        -- TODO: remove song.data_source entirely? Because we could bundle our own native file format,
        -- we probably don't want to bundle midi files. IE: this function will only be called with filesAPI.
        -- It is worth while to keep track of songs that have host-only data (needs pings) vs songs that are
        -- bundled with the avatar. (Don't need pings for data, just start/stop.) But for the midi parcer
        -- itself, this distinction is not exactly nessesary.
        if song_holder.source.type == "files" then
            state.reader.file_stream = file:openReadStream(song_holder.source.full_path)
            if state.reader.file_stream:available() then state.reader.total_file_size = state.reader.file_stream:available() end
            state.stage = "read"
        else
            error("song.source.type is not `files`. Non files API sources are not supported yet.")
        end
        print_debug("init done", false, true)
        return { progress = 0 }
    end,

    read = function(song_holder, state)
        -- read in data, a few bytes at a time, so that we don't freeze the game reading a hughe file.
        for _ = 1, max_read_steps_per_event, 1 do
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

                        --State holder for some meta events like 0x08 and 0x09
                        ---@class MidiChunkMetaState
                        meta_state = {

                            ---@type string?
                            custom_program_name = nil,

                            ---@type number?
                            early_program_change_patch_number = nil,
                            ---@type MidiChannelId?
                            early_program_change_channel_number = nil
                        },

                        -- Keeps track of our progress through the data table.
                        -- See read_next_chunk_data_byte(chunk)
                        ---@type integer
                        data_index = 1,

                        ---During the process stage, we need to read track messages in chronological order.
                        ---Use this to track the absolute time passed for a track to compare with the next message's delta time.
                        ---@type number
                        sum_ticks = 0,

                        ---Holds the delta of the next event.
                        ---Used to compare this track against every other track, without doing var-length calculations every loop
                        ---@type integer
                        next_event_tick_delta = 1,

                        ---For tracks, stores the index of this track. Sometimes, a meta event needs to know if it's in the
                        ---first track in a file (eg, `0x03` == sequence_or_track_name)
                        ---@type integer?
                        index = nil,

                        ---See meta events 0x09 and 0x21.
                        ---Stores the current "device" this track outputs to.
                        ---
                        ---By default tracks share the same pool of 16 channels. But this assumes all tracks output to the same device.
                        ---Multiple devices enables a midi file to go beyond just 16 channels.
                        ---
                        ---This variable is used to keep track of what device this track is currently pointing to.
                        ---@type MidiDeviceName
                        current_device = default_midi_device_name,

                        has_ended = false,
                        time_ended = nil
                    }

                    state.reader.current_chunk = new_chunk
                    state.reader.current_chunk_length_counter = new_chunk.length

                    if new_chunk.type == midi_chunk_types.track then
                        table.insert(state.chunks.tracks, new_chunk)
                        -- print_debug("Found new track")

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
                            print_debug("Header chunk is larger than expected. Got " .. tostring(header_chunk.length)
                                .. " instead of " .. tostring(expected_header_chunk_length), true, true
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
                                .." Send this MIDI file (".. song_holder.name ..") to https://github.com/charliemikels/figura-music-player/issues/new.")
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
                                .." Send this MIDI file (".. song_holder.name ..") to https://github.com/charliemikels/figura-music-player/issues/new.")
                        else
                            --first bit of first byte of timing data is 0. Use normal ticks-per-quarter-note method
                            local ticks_per_quarter_note_fist_byte = bit32.band(first_byte_of_timing_data, everything_but_first_bit_mask)
                            local ticks_per_quarter_note = bytes_to_number({ticks_per_quarter_note_fist_byte, second_byte_of_timing_data})
                            state.midi_header_info.timing_method = 0

                            state.midi_header_info.ticks_pre_quarter_note = ticks_per_quarter_note
                            local tick_to_milis_multiplier = recalculate_ticks_to_milis_multiplier(ticks_per_quarter_note, midi_default_tempo)
                            table.insert(state.processed_metadata.tempo_changes.ticks_when_tempo_changed, 1, 0)
                            state.processed_metadata.tempo_changes.delta_tick_multipliers[0] = tick_to_milis_multiplier
                        end

                        state.chunks.header = header_chunk

                        state.reader.current_chunk = nil
                        state.reader.current_chunk_length_counter = 0

                    else
                        table.insert(state.chunks.unknown_chunks, new_chunk)
                        print_debug("Found a chunk with an unknown type.", true, true)
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
                track.next_event_tick_delta = read_variable_length_quantity(track)
            end

            state.stage = "process"
            print_debug("read done", false, true)
        end
        return {
            progress = state.reader and (
                ((state.reader.total_file_size - state.reader.file_stream:available()) / state.reader.total_file_size)
                * 0.1
            ) or 0.1
        }
    end,

    process = function(_, state)
        -- Midi files store midi events `<delta_time><event_id><event_data>`
        -- In order to not calculate delta_time every time to figure out the next chronological event,
        -- We will calculate it ahead of time during the end of Read, and update it for the current track at the end of this loop.
        -- So effectively, we will read the data like this: `<event_id><event_data><next_event_delta_time>`

        for _ = 1, max_process_steps_per_event, 1 do

            -- Get next message to process

            local soonest_start_tick = math.huge
            local soonest_track
            local soonest_track_index

            for track_index, track in ipairs(state.chunks.tracks) do
                if not track.has_ended then
                    local tick_of_next_message = track.sum_ticks + track.next_event_tick_delta
                    if tick_of_next_message < soonest_start_tick then
                        soonest_start_tick = tick_of_next_message
                        soonest_track = track
                        soonest_track_index = track_index
                    end
                end
            end
            if not soonest_track then
                -- No tracks passed the get-soonest-track logic. They must all be done.
                print_debug("All tracks ended")
                print_debug("process done" , false, true)
                state.stage = "done"
                return { progress = 0.9 }
            end

            -- calculate the absolute time of this message

            local sum_time_accumulator = 0
            -- walk down the list of tempo changes and calculate the absolute time for this event
            -- ticks_when_tempo_changed is sorted in reverse order. This loop goes from most recent tempo change to tick 0
            for index, tick_where_tempo_changed in ipairs(state.processed_metadata.tempo_changes.ticks_when_tempo_changed) do
                local upper_bound = (index-1 == 0 and soonest_start_tick or state.processed_metadata.tempo_changes.ticks_when_tempo_changed[index-1])
                local lower_bound = tick_where_tempo_changed    -- TODO: we could could cache the previous event's sum_time, break early here, and then add the cache time. This would ensure this loop only goes as few itterations as needed.
                local ticks_spent_in_this_range = upper_bound - lower_bound
                local time_spent_in_this_range = ticks_spent_in_this_range * state.processed_metadata.tempo_changes.delta_tick_multipliers[tick_where_tempo_changed]
                sum_time_accumulator = sum_time_accumulator + time_spent_in_this_range
            end
            local soonest_start_time = sum_time_accumulator

            -- Running Status:
            -- Messages may ommit their status ID if they have the same ID as the status before it. ("Running status")
            -- Check next byte. If it's a data byte, backtrack reader and use previous status ID

            local first_bit_mask = tonumber("10000000", 2)
            local event_id_byte = read_next_chunk_byte(soonest_track)
            if event_id_byte < first_bit_mask then
                -- This isn't a standard midi event, This is the data for running status.
                -- Backtrack, and use the previous event ID
                soonest_track.data_index = soonest_track.data_index -1
                event_id_byte = soonest_track.running_status_id
            else
                --store current status in case
                soonest_track.running_status_id = event_id_byte
            end

            -- Midi Messages < `0x11110000` use the last 4 bits to represent a channel ID
            -- Strip channel info for cleaner lookup.
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
                print_debug("processing event: " ..tostring(event_id_without_channel) .. " track: " .. tostring(soonest_track_index) .. " time: " .. tostring(soonest_start_time))
                midi_message_functions[event_id_without_channel](state, soonest_track, midi_channel, soonest_start_time)
            else
                error("Unimplemented Event ID: "..number_to_dec_and_hex(event_id_without_channel))
            end

            -- see state.processed_song_data for output?

            -- Pre-calculate next message start time for this track:

            soonest_track.sum_ticks = soonest_start_tick
            if not soonest_track.has_ended then
                soonest_track.next_event_tick_delta = read_variable_length_quantity(soonest_track)
            end
        end

        local total_data = 0
        local total_data_processed = 0
        for _, track in ipairs(state.chunks.tracks) do
            if not track.has_ended then
                total_data = total_data + #track.data
                total_data_processed = total_data_processed + track.data_index
            end
        end

        return {progress = (
            -- Target range: 0.1 to 0.9 (width of 0.8)
            ((total_data_processed / total_data) * 0.8) + 0.2
        )}
    end,

    done = function(song_holder, state)
        -- Check note builder for any left over notes.
        for _, device_channels in pairs(state.instruction_builder) do
            for _, channel_data in pairs(device_channels) do
                if #channel_data.notes > 0 then
                    error("Midi processor ended, but some notes were left not stopped.")
                    -- TODO: Instead of erroring on left over notes, should we just set the end time at the song end time
                end
            end
        end

        -- ensure instructions are sorted.
        table.sort(state.complete_instructions, function(a, b)
            if a.start_time == b.start_time then return a.duration < b.duration end
            return a.start_time < b.start_time end
        )

        -- reverse state.processed_metadata.channel_data[(dev)][(channel)] so that we can make a player-ready track list

        ---@type {number: Track}
        local player_track_data = {}

        -- Used to keep track of what instrument names we've already used so that each track has a unique name in the UI
        --
        -- eg: "Alto Sax" and "Alto Sax 2"
        ---@type {string: number}
        local seen_instruments = {}
        for device_name, device in pairs(state.processed_metadata.channel_data) do
            for channel_id, channel_info in pairs(device) do
                for _, instrument in ipairs(channel_info.seen_instruments) do
                    local track_id = get_track_id(state, device_name, channel_id, instrument.id)
                    -- print_debug(track_id, device_name, channel_id, channel_info.instrument_id, channel_info.instrument_name)
                    -- printTable_debug(channel_info)
                    -- Entries with track_id == nil have no notes and we can discard them.

                    if track_id and not player_track_data[track_id] then

                        local track_instrument_type_id = (
                            (instrument.name and instrument.name == "Percussion")
                            and 1 or 0
                        )

                        local track_instrument_name
                        if not instrument.name then
                            track_instrument_name = "Unspecified"
                        elseif seen_instruments[instrument.name] then
                            track_instrument_name =
                                instrument.name .. " " .. tostring(seen_instruments[instrument.name] + 1)
                            seen_instruments[instrument.name] = seen_instruments[instrument.name] +1
                        else
                            track_instrument_name = instrument.name
                            seen_instruments[instrument.name] = 1
                        end

                        ---@type Track
                        player_track_data[track_id] = {
                            instrument_type_id = track_instrument_type_id,
                            recommended_instrument_name = track_instrument_name
                        }
                    end
                end


            end
        end
        seen_instruments = nil

        ---@type Song
        local processed_song = {
            name = song_holder.short_name,
            duration = state.processed_metadata.time_song_end,
            instructions = state.complete_instructions,
            tracks = player_track_data
        }
        printTable_debug(processed_song)

        print_debug(
            "Midi processor successfuly built song `"..song_holder.name
                .. "`. Durration: "..tostring(processed_song.duration/1000).."s"
                .. ", Instruction count: "..tostring(#processed_song.instructions)
                .. ", Track count: "..tostring(#processed_song.tracks)
            , false, true
        )

        state.is_done = true
        return {
            progress = 1,
            finished_song = processed_song
        }
    end
}


--- Convert a song with midi data into a processed song.
---
--- Followup calls will not restart the processor, but just return
---@param song_holder SongHolder
---@return TL_Future<Song>
local function midi_processor(song_holder)
    -- if not host:isHost() then
    --     error("Viewer tried to process a song.")
    -- end

    ---@class MidiProcessorState
    song_holder.data_processor_state = {
        is_done = false,

        ---@type MidiProcessorStageKey
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

        -- list of known devices. If meta event 0x09 tries to use a device not in this list, then we need to create a new device.
        ---@type table<MidiDeviceName, boolean>
        known_devices = {},

        -- Stores temporary info about notes.
        ---@type table<MidiDeviceName, table<MidiChannelId, {channel_state: MidiDeviceChannelState, notes:table<integer, Instruction>}>>
        instruction_builder = {},
        ---@type Instruction[]
        complete_instructions = {},

        -- Metadata about assigned instruments per channel and any host-only song-level information
        --- @class MidiProcessorState.ProcessedMetadata
        processed_metadata = {
            ---@type table<MidiDeviceName, table<MidiChannelId, MidiDeviceChannelData>>
            channel_data = {},
            ---@type number?
            time_song_end = nil,

            --- Lookup tables of start times to delta time multipliers.
            --- See meta event 0x51 and recalculate_ticks_to_milis_multiplier().
            ---@type {ticks_when_tempo_changed: integer[], delta_tick_multipliers: table<integer, number>}
            tempo_changes = {
                ticks_when_tempo_changed = {},  -- An reverced-ordered list of ticks where the tempo changes. These ticks are also keys for delta_tick_multipliers.
                delta_tick_multipliers = {}     -- A list of delta tick multipliers indexed by the tick when they became active.
            }
        },

        -- A lookup table for track IDs used in complete instructions
        --
        -- The music player will not really care about the exact device name or channel ID that appears
        -- in the actual midi file, so we can simplify things and merge them into one ID number.
        --
        -- ID 0 is reserved for meta instructions, like 0x58 Time Signature
        --
        ---@type table<MidiDeviceName, table<MidiChannelId, table<integer, integer>>>
        used_track_ids = {},

        -- A tracker to decide the next track ID humber, if one is not found.
        --
        -- Remember to incriment when creating a new player track
        ---@type integer
        next_track_id = 1,

        reader = {
            file_stream = nil, ---@type InputStream|nil
            current_chunk_length_counter = 0,   ---@type integer
            total_file_size = 0 ---@type integer
        },
        midi_header_info = {
            ---@type 0|1|2      0 == no tracks, 1 == has tracks (play all at once), 2 = Manualy Timed Tracks
            format = nil,

            ---@type integer
            number_of_tracks = nil,

            ---@type 0|1
            timing_method = nil,

            ---@type integer
            ticks_pre_quarter_note = nil
        },
    }

    local state = song_holder.data_processor_state
    add_new_device(state, default_midi_device_name)

    local futures_api =  require("./../futures") ---@type TL_FuturesAPI
    local future_controller, return_future =  futures_api.new_future("Song")

    local function processor_loop()
        if state.is_done then
            -- this probably shouldn't happen. But in case it does, try to stop the render loop again.
            events.WORLD_RENDER:remove(processor_loop)

        elseif midi_processor_loop_stage_functions[state.stage] then
            ---@type boolean, string|MidiProcessorFunctionReturn
            local success, value = pcall(midi_processor_loop_stage_functions[state.stage], song_holder, state)
            if not success then
                ---@cast value string
                state.is_done = true
                future_controller:set_done_with_error(value)
                events.WORLD_RENDER:remove(processor_loop)
            elseif value then
                ---@cast value MidiProcessorFunctionReturn
                if value.progress then
                    future_controller:set_progress(value.progress)
                    -- print_debug("Progress: " .. tostring(value.progress))
                end
                if value.finished_song then
                    state.is_done = true
                    song_holder.processed_song = value.finished_song
                    events.WORLD_RENDER:remove(processor_loop)
                    future_controller:set_done_with_value(value.finished_song)
                end
            end
        end
    end

    print_debug("Starting midi processor for `"..song_holder.name.."`…", false, true)

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

    -- overwrite song's processor function to just return the existing future, instead of restarting the processor
    song_holder.start_or_get_data_processor = function(_) return return_future end

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
        for _, file_paths in ipairs(display_and_full_paths) do
            local file_ext = file_paths.full_path:match("%.([^%.]+)$"):lower()
            for _, supported_file_ext in pairs(supported_extensions) do
                if supported_file_ext == file_ext then
                    ---@type SongHolder
                    local new_song = {
                        uuid = client.intUUIDToString(client.generateUUID()),
                        id = file_paths.full_path,
                        name = file_paths.short_path,
                        short_name = file_paths.short_path:match("([^/]*)%."),
                        source = {type = "files", full_path = file_paths.full_path},
                        start_or_get_data_processor = self.process_song
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
