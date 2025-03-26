
-- Logic related to managing song libraries, including registering new songs, and finding songs by ID or other search types.


---Recursively searches for files in a directory.
---@param start_path string
---@return table[]
local function list_files_in_path_recursively(start_path)
    if not host:isHost() then
        error("Viewer script attempted to load a song library")
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

---Assorted functions for the library table.
---@type table
local library_functions = {
    add_source_directory = function(self, new_source_path)
        local display_and_full_paths = list_files_in_path_recursively(new_source_path)
        local file_processor_api = require("./file_processor")
        for _, song in ipairs(file_processor_api.song_list_from_paths(display_and_full_paths)) do
            table.insert(self.songs, song)
        end
    end,
    sort_library = function(self)
        table.sort(self.songs, function (a, b) return a.name < b.name end)
    end
}

---@class LibrariesApi
---@field build_library fun(self:LibrariesApi): Library
---@field build_default_library fun(self:LibrariesApi): Library
local libraries_api = {
    build_library = function(self)
        ---@class Library
        ---@field songs Song[]
        ---@
        local library = {
            songs = {},
            add_source_directory = library_functions.add_source_directory,
            sort_library = library_functions.sort_library
        }
        return library
    end,

    build_default_library = function(self)
        local library = self:build_library()
        library:add_source_directory("TL_Songbook")
        return library
    end
}

return libraries_api
