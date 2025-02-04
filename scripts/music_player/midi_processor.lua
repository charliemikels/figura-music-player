---@module "scripts.music_player.music_player"

---Converts a number into a string with both Dec and Hex values. Primaraly for debug
---@param number number
---@return string
local function number_to_dec_and_hex(number)
    return string.format("Dec: %.0f | Hex: %x", number, number)
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
        }
    }

    ---Limits to keep to reduce lag when processing large files.
    local max_read_steps_per_event    = 100000  -- This stage has very few instructions, so it's max count can be very high.
    local max_process_steps_per_event = 1000    -- This stage is far more expensive than max_read_steps.

    local state = song.data_processor_state

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
            state.stage = "done"
            state.is_done = true
            print("done done")

        elseif state.is_done then
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
