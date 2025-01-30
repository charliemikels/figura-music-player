---@module "scripts.music_player.music_player"

---Convert a song with midi data into a processed song.
---@param song Song
---@return Future
local function midi_processor(song)
    print("hello from midi parcer")
    printTable(song)

    local dev_future_create_time = client.getSystemTime()
    local future = {}
    ---@type Future
    future = {
        isDone = function()
            if client.getSystemTime() > dev_future_create_time + 1000 then
                return true
            end
            return false
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
