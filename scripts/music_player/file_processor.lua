
---@class FileProcessor
---@field build_song_list_from_path_list fun(paths:string[]):Song[]
---@field process_song fun(song:Song)


local file_processors = {}
-- establish a canonical list of file processors

---@type FileProcessor[]
for _, script in ipairs(listFiles("./file_processors", true)) do
    table.insert(file_processors, require(script))
end

-- TODO: Bug report. If a script has the same name as a folder, listing the files in the folder will include the script outside of the folder
-- if `file_processors.lua` & `file_processors/midi_processor.lua`
-- and file_processors.lua calls `listFiles("./file_processors", true)`
-- then it returns `{"….file_processors", "`….file_processors`.midi_processors"}`


---Abstracts the file processing logic. Figures out which processor to use for you.
---@class FileProcessorApi
local file_processor_api = {
    song_list_from_paths = function(display_and_full_paths)
        local song_sets = {}
        for _, processor in ipairs(file_processors) do
            table.insert(song_sets, processor:song_list_from_paths(display_and_full_paths))
        end
        return table.unpack(song_sets)
    end,
}

---@class FileProcessorApi
return file_processor_api
