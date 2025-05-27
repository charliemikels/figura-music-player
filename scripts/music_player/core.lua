-- Tanner Limes was here.
-- Music Player V5.0.0-beta.2

-- core.lua:
-- The primary entrypoint into the music player scripts, and definitions for some shared types.

-- debug
print("\n\n\n")
print("== MIDI - Script init: ".. client.getSystemTime() .." ==")
events.ENTITY_INIT:register(function ()
    print("== MIDI - Entity init: ".. client.getSystemTime() .." ==")
end)

-- Shared types ---------------------------------------------------------------

---@alias Byte number

---@alias DataSourceTypes "files"|"local"|"manual"

---@alias DataSource
---| FilesApiDataSource

---@class FilesApiDataSource
---@field type DataSourceTypes
---@field full_path string

---@class LocalDataSource
---@field type DataSourceTypes
---@field raw_data Byte[]

---@class Song
---@field id string A unique identifier for this song. Usualy the same as truepath, except for manually created songs.
---@field name string The name used in the displayed song list
---@field short_name string The name used when displayed to others
---@field source DataSource
---@field processed_data nil|ProcessedSong The instructions produced after processing raw_data
---@field start_data_processor fun(self:Song): TL_Future






---The song data created by the file processor functions
---
---Stores enough data to apply settings about the song (number of tracks / assigned instruments / disabled tracks),
---and instructions ready to turn into packets.
---@class ProcessedSong
---@field instructions Instruction[]    -- Instructions does not account for packets sizes. That's for the network functions to worry about.
---@field name string
---@field durration number
---@field tracks Track[]

---@class Track
---@field name string
---@field instrument nil TODO: instrument object

---@class CoreApi
---@field build_default_experiance fun():MusicPlayerCore    TODO: revisit this type declaration
local core_api = {
    build_default_experiance = function()
        local library = require("./libraries"):build_default_library()

        ---@class MusicPlayerCore
        ---@field library Library
        return {
            library = library,
        }
    end
}

return core_api
