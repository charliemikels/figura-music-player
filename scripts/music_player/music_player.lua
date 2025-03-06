-- Tanner Limes was here.
-- Music Player V5.0.0-beta.1 (Midi)
print("\n\n\n")
print("== MIDI - Script init: ".. client.getSystemTime() .." ==")
events.ENTITY_INIT:register(function ()
    print("== MIDI - Entity init: ".. client.getSystemTime() .." ==")
end)

-- Defaults --
local dev_warn_unrecognized_file_in_library = false


---@class MusicPlayerBuilderOptions
---@field library_paths string[]
local default_music_player_options = {
    library_paths = {"TL_Songbook"}
}

---@enum SupportedFileTypes
local supported_file_types = {
    -- -- ABC temporaraly disabled to keep final list short
    -- abc = {
    --     extensions = {"abc"},
    --     processor = function(self)
    --         error("ABC processor hasn't been ported yet.")
    --     end
    -- },
    midi = {
        extensions = {"mid", "midi"},
        processor = require("scripts.music_player.midi_processor")
    }
}

-- Defining a bunch of types -- -----------------------------------------------



---@class Song
---@field identifier string A unique identifier for this song. Usualy the same as truepath, except for manually created songs.
---@field truepath string The authoritative path given to the files API
---@field name string The name used in the displayed song list
---@field short_name string The name used when displayed to others
---@field library string the path to the library where the song lives.
---@field processed_data nil|ProcessedSong The instructions produced after processing raw_data
---@field raw_data nil|table|string The raw data for a song. Usualy empty and loaded later when data_source is "file"
---@field data_source ("files"|"manual") The data source for a song. "Manual" must have non-nil `data` field.
---@field start_data_processor fun(self:Song): Future
---@field data_processor_state nil|table



---The song data created by the file processor functions
---
---Stores enough data to apply settings about the song (number of tracks / assigned instruments / disabled tracks),
---and instructions ready to turn into packets.
---@class ProcessedSong
---@field instructions Instruction[]
---@field name string
---@field durration number
---@field tracks Track[]

---@class Instruction
---@field track_index integer
---@field start_time number
---@field end_time number
---@field modifiers table? TODO: Modify note during playback
---@field active_sounds Sound? The actual sound object for the instruction.

---@class Track
---@field name string
---@field instrument nil TODO: instrument object

---A meta api to control the music player script. Use it to create and manage MusicPlayers.
---This api is returned when this script is called with `require()`.
---@class MusicPlayerScriptAPI
---@field build_empty_MusicPlayer fun(self: MusicPlayerScriptAPI): MusicPlayerAPI
---@field build_MusicPlayer fun(self: MusicPlayerScriptAPI, options: MusicPlayerBuilderOptions): MusicPlayerAPI
---@field build_default_MusicPlayer fun(self: MusicPlayerScriptAPI): MusicPlayerAPI
---@field call_when_done fun(self:MusicPlayerScriptAPI, condition: fun():(boolean), callback:fun(...), ...)
local script_api = {}

---Creates a blank, bare-bones, music player.
---Use script_api:build_MusicPlayer() to get a ready-to-go music player.
---@return MusicPlayer
function script_api:build_empty_MusicPlayer()
    local music_player

    ---@class MusicPlayer
    ---@field library SongLibrary
    ---@field api MusicPlayerAPI
    music_player = {

        -- Not metatables because we need to access `music_player` from here.


        ---The Song library is the authoritative source of song data. Both the song list, paths, and raw data.
        ---@class SongLibrary
        ---@field songs table<string, Song> Canonical song list.
        ---@field sorted_songs Song[] Sorted song list. Used to display the songs in alphabetical order.
        ---@field song_keys_are_sorted boolean Flag to determin if sorted_songs is sorted or not.
        ---@field add_song fun(identifier: string, song: Song) Adds song to library without validation.
        ---@field sort_songs fun():nil Rebuilds sorted_songs list.
        library = {
            songs = {},
            sorted_songs = {},
            song_keys_are_sorted = false,
            add_song = function(identifier, song)
                music_player.library.songs[identifier] = song
                music_player.library.song_keys_are_sorted = false
            end,

            remove_song = function(identifier)
                -- TODO: Ensure song is safe to remove
                error("TODO: Ensure song is safe to remove")
                music_player.library.songs[identifier] = nil
                music_player.library.song_keys_are_sorted = false
            end,

            sort_songs = function()
                if music_player.library.song_keys_are_sorted then return end

                ---@type Song[]
                local sorted_songs = {}

                for _, song in pairs(music_player.library.songs) do
                    table.insert(sorted_songs, #sorted_songs +1, song)
                end
                table.sort(sorted_songs, function(a,b) return a.name:lower() < b.name:lower() end)

                music_player.library.sorted_songs = sorted_songs
                music_player.library.song_keys_are_sorted = true
            end
        },

        ---Music Player API. Everything you need to control and configure a music player.
        ---@class MusicPlayerAPI
        ---@field add_library fun(path: string) Adds all song files found in `path` to the songbook.
        ---@field add_song fun(song: Song) For manualy adding your own songs with code. See also `add_library()`
        ---@field get_song_list fun():table<string, Song> Returns the list of songs as a table indexed by song.identifier
        ---@field get_sorted_song_list fun():Song[] Returns the list of songs as a list sorted by song.name
        ---@field get_song_by_id fun(identifier:string):Song Returns a song based on its identifier.
        ---@field get_song_by_sorted_index fun(index:integer):Song Returns a song based on its index in the sorted song table.
        api = {
            add_library = function(library_path)
                if not host:isHost() then
                    error("Viewer script attempted to load a song library")
                    return
                end

                if not file:isPathAllowed(library_path) then
                    error("Attempted to load a path that is not allowed: " .. tostring(library_path))
                    return
                end

                if not file:isDirectory(library_path) then
                    error("Path is not a directory" .. tostring(library_path))
                    return
                end

                local song_paths_to_test = file:list(library_path);

                while #song_paths_to_test > 0 do
                    local short_path = table.remove(song_paths_to_test)
                    local full_path = library_path .. "/" .. short_path

                    if file:isDirectory(full_path) then
                    -- Path is a directory, put its contents into the test loop.
                    for _, sub_path in ipairs(file:list(full_path)) do
                        table.insert(song_paths_to_test, (short_path .. "/" .. sub_path))
                    end
                    elseif file:isFile(full_path) then
                        -- TODO: Add file to library

                        local file_ext = full_path:match("%.([^%.]+)$"):lower()

                        local supported_ext_found = false
                        for file_type, file_type_data in pairs(supported_file_types) do
                            for _, supported_file_ext in pairs(file_type_data.extensions) do
                                if supported_file_ext == file_ext then

                                    ---@type Song
                                    local song = {
                                        identifier = full_path,
                                        data_source = "files",
                                        library = library_path,
                                        name = short_path,
                                        truepath = full_path,
                                        short_name = short_path:match("([^/]*)%."),
                                            -- gets just the name of the file without dirs or extensions.
                                        start_data_processor = file_type_data.processor,
                                        -- data = nil
                                    }
                                    music_player.library.add_song(song.identifier, song)
                                    supported_ext_found = true
                                end
                                if supported_ext_found then break end
                            end
                            if supported_ext_found then break end
                        end

                        if not supported_ext_found and dev_warn_unrecognized_file_in_library then
                            print("File in library found with unsupported extension: `"..full_path .."`")
                        end
                    end
                end
                music_player.library.sort_songs()
            end,

            add_song = function(song)
                -- validation
                if not song.name then
                    printTable(song)
                    error("↑ Above song has no name")
                    return
                end

                if song.data_source == "files" and (not song.truepath or not file:isFile(song.truepath)) then
                    error("Song `".. song.name .. "` has source `files`, but the truepath does not point to a file.")
                    return
                elseif song.data_source == "manual" and (song.raw_data == nil or #song.raw_data < 1) then
                    error("Song `".. song.name .. "` has source `manual`, but the data is empty.")
                    return
                end

                music_player.library.add_song(song.identifier, song)
            end,

            get_song_by_id = function(identifier)
                return music_player.library.songs[identifier]
            end,

            get_song_by_sorted_index = function(index)
                if not music_player.library.song_keys_are_sorted then
                    music_player.library.sort_songs()
                end
                return music_player.library.sorted_songs[index]
            end,

            get_song_list = function()
                return music_player.library.songs
            end,

            get_sorted_song_list = function()
                if not music_player.library.song_keys_are_sorted then
                    music_player.library.sort_songs()
                end
                return music_player.library.sorted_songs
            end,

            prepare_song = function(song_key)

            end,

            song_is_prepared = function(song_key)
                local song = music_player.api.get_song_by_id(song_key)
                return (song and not song.processed_data == nil)
            end,

            play_prepared_song = function(song_key)

            end,

            stop_song = function(song_key)

            end,

            deconstruct = function() end
        }
    }

    return music_player.api
end

---Build a musicPlayer based on a given options table.
function script_api:build_MusicPlayer(options)
    options = options or {}

    local music_player_api = self:build_empty_MusicPlayer()

    if options.library_paths then
        for _, path in ipairs(options.library_paths) do
            music_player_api.add_library(path)
        end
    end

    return music_player_api
end

---Build the default MusicPlayer
function script_api:build_default_MusicPlayer()
    local music_player_api = script_api:build_MusicPlayer(default_music_player_options)
    return music_player_api
end

---Starts a TICK event loop to wait for a condition to be true, then calls the callback with any extra arguments.
function script_api:call_when_done(condition, callback, ...)
    local callback_args = { ... }
    local function wait()
        if condition() then
            callback(table.unpack(callback_args))
            events.TICK:remove(wait)
        end
    end
    events.TICK:register(wait)
end


return script_api
