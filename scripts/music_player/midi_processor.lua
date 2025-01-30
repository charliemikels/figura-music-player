---@module "scripts.music_player.music_player"

---Convert a song with midi data into a processed song.
---@param song Song
local function midi_processor(song)
    print("hello from midi parcer")
    printTable(song)
end

return midi_processor
