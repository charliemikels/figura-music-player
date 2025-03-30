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

---Futures store the state of an async process. When the process is done, a value or an error can be extracted from the future.
---
---The Future type already sorta exist in Figura (see the networkin/HTTP module),
---but I really wanted a `:then` function to make chaining easier, so I'm defining my own type.
---@class TL_Future
---@field is_done fun(self:TL_Future): boolean      Returns false if background process is still running
---@field has_error fun(self:TL_Future): boolean    Returns true if an error occured inside the future
---@field throw_error fun(self:TL_Future)           Throws any stored errors.
---@field get_value fun(self:TL_Future): any        Returns any stored values. Errors if not done,
---@field get_or_error fun(self:TL_Future): any?    In no errors, return the value. Otherwise, throw errors.
---@field register_callback fun(self:TL_Future, fn:fun(future:TL_Future)):TL_Future   Register a function to run after the future is done.

---Context for the future, so that I can prevent users from directly accessing some parts of the future
---@class TL_FutureContext
---@field value any?
---@field errors any?
---@field callback_functions function[]
---@field future TL_Future
---@field is_done boolean
---@field set_done fun(self:TL_FutureContext)


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

---@class Instruction
---@field track_index integer
---@field start_time number
---@field end_time number
---@field modifiers table? TODO: Modify note during playback
---@field active_sounds Sound? The actual sound object for the instruction.

---@class Track
---@field name string
---@field instrument nil TODO: instrument object

local core_api = {
    build_default_experiance = function()
        local library = require("./libraries"):build_default_library()

        ---@class CoreApi
        ---@field library Library
        return {
            library = library,
        }
    end
}

return core_api
