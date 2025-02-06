---@module "scripts.music_player.music_player"

-- see: http://www.music.mcgill.ca/~ich/classes/mumt306/StandardMIDIfileformat.html

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

---Convert a song with midi data into a processed song.
---@param song Song
---@return Future
local function midi_processor(song)
    -- if not host:isHost() then
    --     error("Viewer tried to process a song.")
    -- end

    song.data_processor_state = {
        is_done = false,
        stage = "init",
        raw_data = {},
        incomplete_instructions = {
            -- .track = {
            --      .channel = { instruction }
            -- }
            -- ??
        },
        data_index = 1,
        midi_header_info = {},
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
                        break

                    elseif state.current_chunk.data_index > state.current_chunk.length then
                        -- at end of chunk
                        -- (if chunk.data_index == chunk.length, then we need to grab the last state:raw_data_next_byte())

                        state.current_chunk = nil

                    elseif state.current_chunk.type == "MThd" then  -- MIDI header. should be first chunk in file
                        -- All midi headers should be 6 bytes, with 3 2-byte (16-bit) words.
                        state.midi_header_info = {}

                        -- format: 0, 1, or 2.
                        --
                        -- * 0 = one track in the entire file
                        -- * 1 = multiple tracks, each track listed one after the other. { full_track_1, full_track_2 }
                        -- * 2 = multiple tracks woven through each other. { partial_track_1, partial_track_2, partial_track_1, partial_track_2, … }
                        state.midi_header_info.format = bytes_to_number({state:raw_data_next_byte(), state:raw_data_next_byte()})

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
                        -- we've should have already processed the length of the track chunk.
                        -- TODO: Update state:raw_data_next_byte() to tick through the state.data_index counter, AND
                        --       some sort of state.current_cunk.data_index. That way, we can track our progress through
                        --       the chunk, and know when we should be done.

                        -- Track chunks are repeating (delta-times, and events). delta-times are a "variable-lenght quantity"
                        --       create a "parce variable-lenght" function that reads the raw_data, and picks out the number
                        --       it represents, returning in a way that the next part of raw data is after said number.


                        -- Setting up tempo and time signature. Default should be 120bpm and 4/4.
                        -- midi format 0: there should be only one track. The first few events will describe the time signature
                        -- midi format 1: the first track sets up the default time signature info for the whole file.
                        -- midi format 2: each temporaly-independant track, should set up its own time signature info.


                        -- state:read_variable_length_quantity()

                        -- DEV: end early
                        state.data_index = #song.raw_data +1
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
