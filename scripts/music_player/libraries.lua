
-- Logic related to managing song libraries, including registering new songs, and finding songs by ID or other search types.

---Used to organize and talk about paths.
---@class FullAndShortPathPair
---@field full_path string?     The full path used by the files api.
---@field short_path string     The shorter "display path" any UI might prefer to display.

---Recursively searches for files in a directory.
---@param start_path string
---@return FullAndShortPathPair[]
local function list_files_in_path_recursively(start_path)
    if not host:isHost() then
        error("A non-host script attempted to call `list_files_in_path_recursively`. This uses the Files API and is not allowed")
    end

    if not file:isPathAllowed(start_path) then
        error("Attempted to load a path that is not allowed: " .. tostring(start_path))
    end

    if not file:isDirectory(start_path) then
        error("Path is not a directory" .. tostring(start_path))
    end

    local sub_paths_to_test = file:list(start_path)     ---@type string[]
    local return_files = {}                             ---@type table[]
    while #sub_paths_to_test > 0 do
        local sub_path = table.remove(sub_paths_to_test)    ---@type string
        local full_path = start_path .. "/" .. sub_path

        if file:isDirectory(full_path) then
            -- Path is a directory, put its contents into the test loop.
            for _, file_or_dir_in_sub_path in ipairs(file:list(full_path)) do
                table.insert(sub_paths_to_test, (sub_path .. "/" .. file_or_dir_in_sub_path))
            end
        elseif file:isFile(full_path) then
            table.insert(return_files, {short_path = sub_path, full_path = full_path})
        end
    end
    table.sort(return_files, function (a, b) return a.full_path < b.full_path end)
    return return_files
end

---Defining this function outside of the public library functions because,
---if done right, we should never need the user to sort the library manualy.
---@param library Library
local function sort_library(library)
    if library.song_keys_are_sorted then return end

    ---@type Song[]
    local sorted_songs = {}
    for _, song in pairs(library.songs) do
        table.insert(sorted_songs, #sorted_songs +1, song)
    end
    table.sort(sorted_songs, function(a,b) return a.name:lower() < b.name:lower() end)

    library.sorted_songs = sorted_songs
    library.song_keys_are_sorted = true
end

---Assorted functions for the library table.
---@type table
local library_functions = {
    add_source_directory = function(self, new_source_path)
        self.song_keys_are_sorted = false
        local display_and_full_paths = list_files_in_path_recursively(new_source_path)
        local file_processor_api = require("./file_processor")
        for _, song in ipairs(file_processor_api.song_list_from_paths(display_and_full_paths)) do
            self.songs[song.id] = song
        end
    end,
    get_song_by_id = function(self, id)
        return self.songs[id]
    end,
    get_song_by_sorted_index = function(self, index)
        if not self.song_keys_are_sorted then sort_library(self) end
        return self.sorted_songs[index]
    end,
}

---@class LibrariesApi
---@field build_library fun(self:LibrariesApi): Library
---@field build_default_library fun(self:LibrariesApi): Library
local libraries_api = {
    build_library = function(self)
        ---@class Library
        ---@field songs table<string, Song> Canonical song list.
        ---@field sorted_songs Song[] Sorted song list. Used to display the songs in alphabetical order.
        ---@field add_source_directory fun(self:Library, path:string)
        ---@field get_song_by_id fun(self:Library, id:string):Song
        ---@field get_song_by_sorted_index fun(self:Library, index:integer):Song
        local library = {
            songs = {},
            sorted_songs = {},
            add_source_directory = library_functions.add_source_directory,
            get_song_by_id = library_functions.get_song_by_id,
            get_song_by_sorted_index = library_functions.get_song_by_sorted_index
        }
        return library
    end,

    build_default_library = function(self)
        local library = self:build_library()
        library:add_source_directory("TL_Songbook")
        -- TODO: add local sources
        return library
    end
}

return libraries_api
