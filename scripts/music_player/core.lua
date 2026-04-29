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

---@alias Byte integer

---@alias DataSourceTypes "files"|"local" --|"manual"

-- TODO: DataSource is a rat's nest. Especialy since we only have either FilesApi songs and Local songs

---@alias DataSource
---| FilesApiDataSource
---| LocalDataSource

---@class FilesApiDataSource
---@field type DataSourceTypes
---@field full_path string

---@class LocalDataSource
---@field type DataSourceTypes
---@field raw_data PacketDataString[]

---@class Song
---@field uuid string   A 100% unique ID. See client.intUUIDToString(client.generateUUID()). Allows us to keep track of speciffic instances of a song, even if there are in multiple libraries. (and so full_path IDs are not unique)
---@field id string     A unique ID for this song in this library. Usualy the same as fuul_path.
---@field name string   The name used in the displayed song list
---@field short_name string The name used when displayed to others
---@field source DataSource
---@field processed_data ProcessedSong? The instructions produced after processing raw_data. May be nil. data_processors are expected to populate this field.
---@field start_data_processor fun(self:Song): TL_Future<ProcessedSong>






---The song data created by the file processor functions
---
---Stores enough data to apply settings about the song (number of tracks / assigned instruments / disabled tracks),
---and instructions ready to turn into packets.
---@class ProcessedSong
---@field instructions Instruction[]    -- Instructions does not account for packets sizes. That's for the network functions to worry about.
---@field name string
---@field duration number
---@field tracks Track[]
---@field buffer_start_time number?  The time when the song started buffering
---@field buffer_delay number?       The amount of time we need to wait before playing this song. This ensures we've received the required amount of packets to fully play the song.
---@field is_local boolean?          Is true if song data does not need to be pinged.

---Tracks ProcessedSong are the step immediatly before PlayingSong.
---@class Track
---@field instrument_type_id 0|1 0 for normal, 1 for percussion.
---@field recommended_instrument_name string? The name of an instrument for display in a UI

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
