local root_action_wheel_page = action_wheel:newPage()
action_wheel:setPage(root_action_wheel_page)
-- root_action_wheel_page:setAction(-1, require("scripts/abc_player/abc_player"))

local midiPlayerScriptApi = require("scripts/music_player/music_player")
local music_player_api = midiPlayerScriptApi:build_default_MusicPlayer()

-- printTable(music_player_api.get_song_by_sorted_index(1))
local song_process_future = music_player_api.get_song_by_id("TL_Songbook/MM/games/Wii Sports - Theme.mid"):process_data()
midiPlayerScriptApi:call_when_done(song_process_future.isDone, function( bonus_string )
    print("The future is now. ".. bonus_string)
end, "yay!")


return root_action_wheel_page
