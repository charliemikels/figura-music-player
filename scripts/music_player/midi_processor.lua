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

    if song.data_source == "files" and (song.raw_data == nil or song.raw_data == {}) then
        -- Pull in data from files API.
        local file_read_stream = file:openReadStream(song.truepath)
        local byte_array = {}
        while file_read_stream:available() and file_read_stream:available() > 0 do
            table.insert(byte_array, file_read_stream:read())
        end
        file_read_stream:close()

        song.raw_data = byte_array

        print(number_to_dec_and_hex(song.raw_data[1]))
    end



    song.data_processor_state = {
        is_done = false,
        stage = "init",
        incomplete_instructions = {
            -- .track = {
            --      .channel = { instruction }
            -- }
            -- ??
        }
    }

    local max_itterations_per_event = 1000
    local state = song.data_processor_state
    local function processor_loop()
        for i = 1, max_itterations_per_event, 1 do
            if state.stage == "init" then
                -- ensure everything is ready to go for reading and organizing
            elseif state.stage == "read" then
                -- read in data, one byte at a time,
            elseif state.stage == "organize" then

            end
        end

        print("RENDER LOOP")

        -- when processor is done, return self.
        state.is_done = true
        events.WORLD_RENDER:remove(processor_loop)
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
