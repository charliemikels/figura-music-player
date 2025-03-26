-- Tanner Limes was here.
-- Music Player V5.0.0-beta.2
--
-- core.lua:
-- The primary entrypoint into the music player scripts, and definitions for some shared types.

-- debug
print("\n\n\n")
print("== MIDI - Script init: ".. client.getSystemTime() .." ==")
events.ENTITY_INIT:register(function ()
    print("== MIDI - Entity init: ".. client.getSystemTime() .." ==")
end)

local core_api = {
    build_default_experiance = function()
        local library = require("./libraries").build_default_library()

        return {
            library = library,
        }
    end
}



return core_api
