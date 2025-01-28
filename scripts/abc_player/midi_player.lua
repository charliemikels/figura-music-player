-- Tanner Limes was here.
-- Music Player V5.0.0-beta.1 (Midi)
print("\n\n\n")
print("== MIDI - Script init: ".. client.getSystemTime() .." ==")
events.ENTITY_INIT:register(function ()
    print("== MIDI - Entity init: ".. client.getSystemTime() .." ==")
end)

-- Debug flags --
local disable_abc = true



-- Defaults --

---@type MusicPlayerBuilderOptions
local default_music_player_options = {
    library_paths = {"TL_Songbook"}
}


-- Defining a bunch of types -- -----------------------------------------------

---Music Player API. Everything you need to control and configure the music player.
---@class MusicPlayerAPI
---@field add_library fun(path: string) Adds all song files found in `path` to the songbook.
---@field add_song fun(song: SongEntry) Validate and add a single song to the songbook.





---The Song library is the authoritative source of song data. Both the song list, paths, and raw data.
---@class SongLibrary
---@field songs SongEntry[]
---@field add_song fun(key: string, song: SongEntry) Adds song to library without validation.

---@class SongEntry
---@field identifier string A unique identifier for this song. Usualy the same as truepath, except for manually created songs.
---@field truepath string The authoritative path given to the files API
---@field name string The name used in the displayed song list
---@field short_name string The name used when displayed to others
---@field library string the path to the library where the song lives.
---@field data nil|table The raw data for a song. Usualy empty and loaded later when data_source is "file"
---@field data_source ("files"|"manual") The data source for a song. "Manual" must have non-nil `data` field.
---@field file_type ( "abc" | "midi" )



---@class MusicPlayerBuilderOptions
---@field library_paths string[]


---@class MusicPlayer
---@field library SongLibrary
---@field api MusicPlayerAPI

---A meta api to control the music player script.
---This api is returned at the end of the script to wherever it was required.
---Then it's the caller's job to create the MusicPlayer.
---@class MusicPlayerScriptAPI
---@field build_empty_MusicPlayer fun(self: MusicPlayerScriptAPI): MusicPlayer
---@field build_MusicPlayer fun(self: MusicPlayerScriptAPI, options: MusicPlayerBuilderOptions): MusicPlayer
---@field build_default_MusicPlayer fun(self: MusicPlayerScriptAPI): MusicPlayer
local script_api = {}

---Creates a blank, bare-bones, music player.
---Use script_api:build_MusicPlayer() to get a ready-to-go music player.
---@return MusicPlayer
function script_api:build_empty_MusicPlayer()
    local music_player  -- pre-initilize music_player so that we can use in inside API calls

    ---@type MusicPlayer
    music_player = {
        library = {
            songs = {},
            add_song = function(key, song)
                music_player.library.songs[key] = song
            end
        },
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

                        local file_type
                        if file_ext == "abc" then
                            file_type = "abc"
                        elseif file_ext == "mid" or file_ext == "midi" then
                            file_type = "midi"
                        end

                        if file_type == "midi" or (not disable_abc and file_type == "abc") then
                            ---@type SongEntry
                            local song = {
                                identifier = full_path,
                                data_source = "files",
                                library = library_path,
                                name = short_path,
                                truepath = full_path,
                                short_name = short_path:match("([^/]*)%."),
                                    -- gets just the name of the file without dirs or extensions.
                                file_type = file_type,
                                -- data = nil
                            }
                            music_player.library.add_song(song.identifier, song)
                        end
                    end
                end
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
                elseif song.data_source == "manual" and (song.data == nil or #song.data < 1) then
                    error("Song `".. song.name .. "` has source `manual`, but the data is empty.")
                    return
                end

                music_player.library.add_song(song.identifier, song)
            end,

            prepare_song = function(song_key)

            end,

            song_is_prepared = function(song_key)

            end,

            play_prepared_song = function(song_key)

            end,

            stop_song = function(song_key)

            end,

            deconstruct = function() end
        }
    }

    return music_player
end

---Build a musicPlayer based on a given options table.
function script_api:build_MusicPlayer(options)
    options = options or {}

    local music_player = self:build_empty_MusicPlayer()

    if options.library_paths then
        for _, path in ipairs(options.library_paths) do
            music_player.api.add_library(path)
        end
    end

    return music_player
end

---Build the default MusicPlayer
function script_api:build_default_MusicPlayer()
    local music_player = script_api:build_MusicPlayer(default_music_player_options)
    return music_player
end





return script_api
