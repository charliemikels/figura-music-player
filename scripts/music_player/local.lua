--[[
local function escape_patern_matching_magic_characters(string_to_escape)
    return string_to_escape:gsub("([^%w])", "%%%1")
end

---@class LocalSongScript
---@field data PacketDataString[]
---@field name string

local song_script_returns = {}
local local_songs = {}      ---@type Song[]

local local_songs_directory_path = "./local_songs"
for _, script in pairs(listFiles(local_songs_directory_path, true)) do

    local require_success, require_return = pcall(function() return require(script) end)
    if not require_success then
        print("Error: Failed to require local song script `"..script.."`. This script will be skipped. Full error below:\n\n"..tostring(require_return))
    else
        ---@cast require_return LocalSongScript
        if not (require_return and type(require_return) == "table" and require_return.data and require_return.name) then
            print(tostring(script).." exists, but does not look like a local song")
        else
            print("Found local song:", require_return.name)

            ---@type Song
            local detected_song = {
                id = "",
                name = require_return.name,
                short_name = require_return.name,
                start_data_processor = function()
                    local data = require_return.data
                    -- TODO: expose more of the network API
                    return nil
                end,
                processed_data = nil,
                source = nil,   -- TODO: we need to figure out a way to talk about data source. We've got a funky alias to it now that wraps the file API and stuff, but only the that song's data processor actualy cares about what's in source, so we don't need wacky types arround it?

                -- exists_on_viewer = true
            }
            table.insert(local_songs, detected_song)
            table.insert(song_script_returns, require_return)
        end
    end
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

-- TODO: add some sort of "save song" command. that lets a user easily create a local song out of a fileAPI song.


return local_file_processor
--]]
