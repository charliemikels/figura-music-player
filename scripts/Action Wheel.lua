local root_action_wheel_page = action_wheel:newPage()
action_wheel:setPage(root_action_wheel_page)
-- root_action_wheel_page:setAction(-1, require("scripts/abc_player/abc_player"))

local midi_player_core_api = require("scripts/music_player/core")
local music_player_api = midi_player_core_api:build_default_experiance()
printTable(music_player_api.library)

-- printTable(music_player_api.get_song_by_sorted_index(1))
-- local song_process_future = music_player_api.get_song_by_id("TL_Songbook/MM/games/Wii Sports - Theme.mid"):start_data_processor()
-- midiPlayerScriptApi:call_when_done(song_process_future.isDone, function( bonus_string )
--     print("The future is now. ".. bonus_string)
-- end, "yay!")

-- TODO: Workout program flow
--
-- Rename `music_player.lua` to `core.lua`. ?
-- `core.lua`   - The primary userfacing APIs and conective tissue to the other modules. Includes a "default experiance" setup function.
-- `library.lua` - A canonical list of songs tables.
--      Can call files API to get list of files.
--      Gives list of files to processors to build list of song tables.
--      Loads overrides for songs from config data (setting instruments for song tracks.)
-- `player.lua` or `speaker.lua` - All of the logic required for playing a song.
--      Script returns function. Function receives song_instructions, starts event loops, plays song, returns API that can stop song and check status.
--      Instructions may be in-transit.
-- `pinger.lua` - All logic required to ping a song to the listener.
--      Packetizer: splits instructions into packets.
--              packet types: new_song_stream (includes song ID and player ID), spawn/update_player (Player is assigned an ID and positional data),
--      Recievers:
--              Takes in packets and shuttles them to the right song table, or speaker.
-- `world_ui.lua` - Attatched to a speaker. Monitors / is told when song starts/ends to display info in-world.
-- `action_wheel_ui.lua` - In charge of creating action wheel UI. Knows about the full library. Is assigned a speeker. Able to start pinger and player.
-- `instruments.lua` - In charge of finding and listing instrument scripts
--
-- Split Music player into a pinger and the player. Make player able to read from a table that grows between cycles.
-- The player doesn't actualy need it's own



return root_action_wheel_page
