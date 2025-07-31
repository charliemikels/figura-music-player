---@module "../core"


---@class SongPlayerAPI
local song_player_api = {
    ---@type fun(song: ProcessedSong)
    play_song_local = function (song)
        print("hello")
        print("playing", song.name)
        print("First instruction")
        printTable(song.instructions[1])
    end
}

return song_player_api
