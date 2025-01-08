-- Tanner Limes was here.
-- Music Player V5.0.0-beta.1 (Midi)

events.ENTITY_INIT:register(function ()
	print("=== Dev init: ".. client.getSystemTime() .." ===")
end)

---@class MusicPlayer
---@field library SongLibrary


---@class SongLibrary
---The Song library is the authoritative source of song data. Both the song list, paths, and raw data.
---@field songs SongEntry[]
---

---@class SongEntry
---@field truepath string The authoritative path given to the files API
---@field name string The name used in the displayed song list
---@field name_decorators string[] Extra strings or icons to append to the name. These will be displayed in the song picker
---@field short_name string The name used when displayed to others
---@field data nil|table

---comment
---@return SongLibrary
local function build_song_library()

    return {}
end
