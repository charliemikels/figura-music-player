
-- Logic related to managing song libraries, including registering new songs, and finding songs by ID or other search types.

-- TODO: This is one of the earliest parts of the v5 rewrite. Do we need this to be its own script? Should it be merged with core.lua? what else can we put in here?

---Used to organize and talk about paths.
---@class FullAndShortPathPair
---@field full_path string?     The full path used by the files api.
---@field short_path string     The shorter "display path" any UI might prefer to display.


---@class SongHolder
---@field uuid string   A 100% unique ID. See client.intUUIDToString(client.generateUUID()). Allows us to keep track of speciffic instances of a song, even if there are in multiple libraries. (and so full_path IDs are not unique)
---@field id string     A unique ID for this song in this library. Usualy the same as full_path.
---@field name string   The name used in the displayed song list
---@field short_name string The name used when displayed to others
---@field source DataSource
---@field processed_song Song? The instructions produced after processing raw_data. May be nil. data_processors are expected to populate this field.
---@field start_or_get_data_processor fun(self:SongHolder): TL_Future<Song>
---@field included_config SongPlayerConfig? Config data provided by the data_processor


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

    ---@type SongHolder[]
    local sorted_songs = {}
    for _, song in pairs(library.song_holders) do
        table.insert(sorted_songs, #sorted_songs +1, song)
    end
    table.sort(sorted_songs, function(a,b) return a.name:lower() < b.name:lower() end)

    library.sorted_song_holders = sorted_songs
    library.song_keys_are_sorted = true
end


---@param library Library
---@param new_source_path string
local function add_source_directory(library, new_source_path)
    library.song_keys_are_sorted = false
    local display_and_full_paths = list_files_in_path_recursively(new_source_path)
    local file_processor_api = require("./file_processor")
    for _, song in ipairs(file_processor_api.song_list_from_paths(display_and_full_paths)) do
        library.song_holders[song.id] = song
    end
end

---@param library Library
---@param id string
---@return SongHolder
local function get_song_by_id (library, id)
    return library.song_holders[id]
end

---@param library Library
---@param index integer
---@return SongHolder
local function get_song_by_sorted_index(library, index)
    if not library.song_keys_are_sorted then sort_library(library) end
    return library.sorted_song_holders[index]
end

---@param library Library
---@return integer
local function get_library_length(library)
    if not library.song_keys_are_sorted then sort_library(library) end
    return #library.sorted_song_holders
end


---@param library Library
local function add_local_songs(library)
    library.song_keys_are_sorted = false
    local local_songs_api = require("./local_songs") ---@type LocalSongApi
    local local_songs = local_songs_api.get_local_song_holders()
    for _, song in pairs(local_songs) do
        library.song_holders[song.id] = song
    end
end


---@class LibrariesApi
---@field build_library fun(self:LibrariesApi): Library
---@field build_default_library fun(self:LibrariesApi): Library
local libraries_api = {

    ---@param self LibrariesApi
    ---@return Library
    build_library = function(self)
        ---@class Library
        ---@field song_holders table<string, SongHolder> Canonical song list.
        ---@field sorted_song_holders SongHolder[] Sorted song list. Used to display the songs in alphabetical order.
        ---@field add_source_directory fun(library:Library, path:string)
        ---@field get_song_by_id fun(library:Library, id:string):SongHolder?
        ---@field get_song_by_sorted_index fun(library:Library, index:integer):SongHolder?
        ---@field get_library_length fun(library:Library):integer
        ---@field package song_keys_are_sorted boolean
        local library = {
            song_holders = {},
            sorted_song_holders = {},
            song_keys_are_sorted = false,
            add_source_directory = add_source_directory,
            get_song_by_id = get_song_by_id,
            get_song_by_sorted_index = get_song_by_sorted_index,
            get_library_length = get_library_length,
            add_local_songs = add_local_songs
        }
        return library
    end,

    ---@param self LibrariesApi
    ---@return Library
    build_default_library = function(self)
        local library = self:build_library()
        if host:isHost() then
            library:add_source_directory("TL_Songbook")
        end
        library:add_local_songs()
        return library
    end
}

return libraries_api
