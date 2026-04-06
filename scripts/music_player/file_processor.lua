
-- An abstraction for handeling different file processor scripts in the file processors dir. (Midi, ABC, etc)
--
-- TODO: Circle back to this speciffic script. Song tables are assigned a data_processor when they're created.
--       Library is (at time of writing) the only other script that uses this script specifficaly, and it's only
--       doing one thing (file_processor_api.song_list_from_paths). We could instead move this script into the
--       library script.

---@class FileProcessor
---@field song_list_from_paths fun( self:FileProcessor, full_and_short_path_pair:FullAndShortPathPair[], library_id:integer):Song[]
---@field process_song fun(song:Song)

local function escape_patern_matching_magic_characters(string_to_escape)
    return string_to_escape:gsub("([^%w])", "%%%1")
end

---A cannonical list of `FileProcessor`s
---@type FileProcessor[]
local file_processors = {}

local file_processor_directory_name = "file_processors"
local file_processor_directory_path = "./" .. file_processor_directory_name
for _, script in pairs(listFiles(file_processor_directory_path, true)) do
    -- Ignore sub directories. Only top level scripts in file_processor_directory_path will be required
    if script:find( escape_patern_matching_magic_characters(file_processor_directory_name).."%.[^%.]*$" )
    then
        local require_success, require_return = pcall(function() return require(script) end)
        if not require_success then
            print("Error: Failed to require file processor `"..script.."` found in the `"..file_processor_directory_path.."` folder. Full error below:\n\n"..tostring(require_return))
        else
            ---@cast require_return FileProcessor
            if require_return and type(require_return) == "table" and require_return.process_song and require_return.song_list_from_paths then
                table.insert(file_processors, require_return)
            else
                print(tostring(script).." is not a file processor and is being skipped")
            end
        end
    else
        print("Ignored script `"..script.."` since it is a sub directory")
    end
end

-- TODO: Bug report? If a script has the same name as a folder, listing the files in the folder will include the script outside of the folder
-- if `file_processors.lua` & `file_processors/midi_processor.lua`
-- and file_processors.lua calls `listFiles("./file_processors", true)`
-- then it returns `{"….file_processors", "`….file_processors`.midi_processors"}`


---Abstracts the file processing logic. Figures out which processor to use for you.
---@class FileProcessorApi
---@field song_list_from_paths fun(full_and_short_path_pair:FullAndShortPathPair, library_id:integer):Song[]
local file_processor_api = {
    song_list_from_paths = function(full_and_short_path_pair, library_id)
        local merged_song_list = {} ---@type Song[]
        for _, processor in ipairs(file_processors) do
            local song_list = processor:song_list_from_paths(full_and_short_path_pair, library_id)
            for _, song in pairs(song_list) do
                table.insert(merged_song_list, song)
            end
        end
        return merged_song_list
    end,
}

---@class FileProcessorApi
return file_processor_api
