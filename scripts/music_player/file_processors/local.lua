
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
