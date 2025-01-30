local root_action_wheel_page = action_wheel:newPage()
action_wheel:setPage(root_action_wheel_page)
-- root_action_wheel_page:setAction(-1, require("scripts/abc_player/abc_player"))

local midiPlayerScriptApi = require("scripts/music_player/midi_player")
local music_player_api = midiPlayerScriptApi:build_default_MusicPlayer()

-- printTable(music_player_api.get_song_by_sorted_index(1))
music_player_api.get_song_by_id("TL_Songbook/MM/games/Wii Sports - Theme.mid"):data_processor()



return root_action_wheel_page
