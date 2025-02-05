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

    function state:raw_data_next_byte()
        local return_data = song.raw_data[self.data_index]
        self.data_index = self.data_index + 1
        return return_data
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
                        break

                    elseif state.current_chunk.type == "MThd" then  -- MIDI header. should be first track in file
                        -- All midi headers are 6 bytes, with 3 2-byte (16-bit) words.
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
                            error("Unimplemented")
                        else
                            --first bit of first byte of timing data is 0. Use normal ticks-per-quarter-note method
                            local ticks_per_quarter_note_fist_byte = bit32.band(first_byte_of_timing_data, everything_but_first_bit_mask)
                            local ticks_per_quarter_note = bytes_to_number({ticks_per_quarter_note_fist_byte, second_byte_of_timing_data})
                            state.midi_header_info.timing_method = 0
                            state.midi_header_info.ticks_pre_quarter_note = ticks_per_quarter_note

                            print(state.midi_header_info.ticks_pre_quarter_note)
                            print(number_to_dec_and_hex(state.midi_header_info.ticks_pre_quarter_note))
                        end



                        -- state.midi_header_info.number_of_tracks = bytes_to_number({song.raw_data[state.data_index+0],song.raw_data[state.data_index+1]})
                        -- state.data_index = state.data_index+2



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
