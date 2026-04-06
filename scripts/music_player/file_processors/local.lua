local function escape_patern_matching_magic_characters(string_to_escape)
    return string_to_escape:gsub("([^%w])", "%%%1")
end

---@class LocalSongScript
---@field data PackedSongPacket[]
---@field name string

local song_script_returns = {}

local local_songs_directory_path = "./local_songs"
for _, script in pairs(listFiles(local_songs_directory_path, true)) do
    local require_success, require_return = pcall(function() return require(script) end)
    if not require_success then
        print("Error: Failed to require local song script `"..script.."`. This script will be skipped. Full error below:\n\n"..tostring(require_return))
    else
        ---@cast require_return LocalSongScript
        if require_return and type(require_return) == "table" and require_return.data and require_return.name then
            print("Found local song:", require_return.name)
            table.insert(song_script_returns, require_return)
        else
            print(tostring(script).." exists, but does not look like a local song")
        end
    end
end

local local_songs = {}      ---@type Song[]
for _, script in pairs(song_script_returns) do
    -- TODO: song_script_return.data to songs. Should we start the processor here, or on demand with pings? (On demand would be like a 3rd way to dispatch songs. (ping to process))
end




---@type table<integer, boolean>
local libraries_we_have_already_added_local_songs_to = {}

---@type FileProcessor
local local_file_processor = {
    process_song = function (song)

    end,
    song_list_from_paths = function (self, full_and_short_path_pair, library_id)
        -- local songs don't follow the same file path system that the other processors use.
        if libraries_we_have_already_added_local_songs_to[library_id] then
            -- We have already added to this library. Do not double-add local songs
            return {}
        end

        -- this is a new library
        libraries_we_have_already_added_local_songs_to[library_id] = true

        -- TODO

        return {}
    end,
}

return local_file_processor
