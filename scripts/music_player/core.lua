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
---@field is_done fun(self:TL_Future): boolean      Never errors.
---@field throw_error fun(self:TL_Future)           Throws any stored errors.
---@field get_value fun(self:TL_Future): any        Returns any stored values. Errors if not done,
---@field get_or_error fun(self:TL_Future): any?    In no errors, return the value. Otherwise, throw errors.
---@field then fun(self:TL_Future, fn:function, args:any[]): any?   Register a function to run after the future is done.
---@field set_done fun(self:TL_Future)              Internal: set the state of the future to done. Calls any functions registered with `:then`

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
---@field start_data_processor fun(self:Song): Future



local core_api = {
    build_default_experiance = function()
        local library = require("./libraries"):build_default_library()

        return {
            library = library,
        }
    end
}

return core_api
