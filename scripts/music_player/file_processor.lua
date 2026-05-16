
-- This script searches throughout the file_processors directory and tries to require a FileProcessor out of them
-- It then works with the Library script to create song holders bound to their processing functions.
--
-- This architecture should make adding support for new file types trivial but just dropping in a new processor.
--
-- Local Songs work similarly to file processors, but are a special edge case, and so they're handled in local_songs.lua



-- TODO: Circle back to this specific script. Song tables are assigned a data_processor when they're created.
--       Library is (at time of writing) the only other script that uses this script specifically, and it's only
--       doing one thing (file_processor_api.song_list_from_paths). We could instead move this script into the
--       library script.

---@alias DataSourceTypes "files"|"local" --|"manual"

-- TODO: DataSource is a rat's nest. Especially since we only have either FilesApi songs and Local songs

---@alias DataSource
---| FilesApiDataSource
---| LocalDataSource

---@class FilesApiDataSource
---@field type DataSourceTypes
---@field full_path string

---@class LocalDataSource
---@field type DataSourceTypes
---@field script_path string
---@field result_of_require LocalSongScript?

---@class FileProcessor
---@field song_list_from_paths fun( self:FileProcessor, full_and_short_path_pair:FullAndShortPathPair[]):SongHolder[]
---@field process_song fun(song:SongHolder)


---The song data created by the file processor functions
---
---Stores enough data to apply settings about the song (number of tracks / assigned instruments / disabled tracks),
---and instructions ready to turn into packets.
---@class Song
---@field instructions Instruction[]    -- Instructions does not account for packets sizes. That's for the network functions to worry about.
---@field name string
---@field duration number
---@field tracks Track[]
---@field buffer_start_time number?  The time when the song started buffering
---@field buffer_delay number?       The amount of time we need to wait before playing this song. This ensures we've received the required amount of packets to fully play the song.
---@field is_local boolean?          Is true if song data does not need to be pinged.
---@field packet_decoder_info PacketDecoderInfo?    Temporary space for Packet Decoder to track ongoing information.

---Tracks ProcessedSong are the step immediately before PlayingSong.
---@class Track
---@field instrument_type_id 0|1 0 for normal, 1 for percussion.
---@field recommended_instrument_name string? The name of an instrument for display in a UI


---A canonical list of `FileProcessor`s
---@type FileProcessor[]
local file_processors = {}

local file_processor_directory_path = "./file_processors"
for _, script in pairs(listFiles(file_processor_directory_path, false)) do
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
end

-- TODO: Bug report? If a script has the same name as a folder, listing the files in the folder will include the script outside of the folder
-- if `file_processors.lua` & `file_processors/midi_processor.lua`
-- and file_processors.lua calls `listFiles("./file_processors", true)`
-- then it returns `{"….file_processors", "`….file_processors`.midi_processors"}`


---Abstracts the file processing logic. Figures out which processor to use for you.
---@class FileProcessorApi
---@field song_list_from_paths fun(full_and_short_path_pair:FullAndShortPathPair):SongHolder[]
local file_processor_api = {
    song_list_from_paths = function(full_and_short_path_pair)
        local merged_song_list = {} ---@type SongHolder[]
        for _, processor in ipairs(file_processors) do
            local song_list = processor:song_list_from_paths(full_and_short_path_pair)
            for _, song in pairs(song_list) do
                table.insert(merged_song_list, song)
            end
        end
        return merged_song_list
    end,
}

---@class FileProcessorApi
return file_processor_api
