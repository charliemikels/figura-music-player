---@class Instruction
---@field track_index integer       Used by instruments system. Track 0 is a "meta track" and applies song-level changes like tempo and time signature changes
---@field start_time number         -- TODO: Start times at full midi resolution get large fast. we probably should store this as a delta, and let the network system find ways to include "landmark" times for each packet.
---@field start_velocity number     The initial velocity (volume) of the note.
---@field duration number           May be 0
---@field note number               The note to play, or ID of meta event
---@field modifiers NoteModifier[]  TODO: Modify note during playback, or if end_time is 0 used for metadata

---@alias NoteModifier {start_time: number, type: string, value: number}

---@class InstructionsAPI
local instructions_factory = {
    serialize = function(instruction) error("TODO") end,     -- serialize just one instruction.
    unserialize = function(byte_array, curent_time) error("TODO") end,
}

return instructions_factory
