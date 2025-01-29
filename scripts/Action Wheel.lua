local root_action_wheel_page = action_wheel:newPage()
action_wheel:setPage(root_action_wheel_page)
-- root_action_wheel_page:setAction(-1, require("scripts/abc_player/abc_player"))

local midiPlayerScriptApi = require("scripts/music_player/midi_player")
local music_player_api = midiPlayerScriptApi:build_default_MusicPlayer()


-- printTable(music_player.library.songs["TL_Songbook/MM/games/Wii Sports - Theme.mid"])
printTable(music_player_api.get_sorted_song_list()[1])



return root_action_wheel_page
