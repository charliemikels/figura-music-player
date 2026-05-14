local name_prefix = "MC/"

---@type NoteBlockSound[]
local note_block_sounds = {
    ---@class NoteBlockSound
    ---@field name string
    ---@field is_percussion boolean
    ---@field base_tuning integer   Each note block sound is tuned to F# in different octives. 42 == F#2, 54 == F#3, 66 == F#4, 78 == F#5, 90 == F#6, etc.
    ---@field sound_id string

    { name = "Harp",            is_percussion = false, base_tuning = 66, sound_id = "block.note_block.harp" },
    { name = "Bass",            is_percussion = false, base_tuning = 42, sound_id = "block.note_block.bass" },
    { name = "Bell",            is_percussion = false, base_tuning = 90, sound_id = "block.note_block.bell" },
    { name = "Flute",           is_percussion = false, base_tuning = 78, sound_id = "block.note_block.flute" },
    { name = "Chime",           is_percussion = false, base_tuning = 90, sound_id = "block.note_block.chime" },
    { name = "Guitar",          is_percussion = false, base_tuning = 54, sound_id = "block.note_block.guitar" },
    { name = "Xylophone",       is_percussion = false, base_tuning = 90, sound_id = "block.note_block.xylophone" },
    { name = "Iron Xylophone",  is_percussion = false, base_tuning = 66, sound_id = "block.note_block.iron_xylophone" },
    { name = "Cow Bell",        is_percussion = false, base_tuning = 78, sound_id = "block.note_block.cow_bell" },
    { name = "Didgeridoo",      is_percussion = false, base_tuning = 42, sound_id = "block.note_block.didgeridoo" },
    { name = "Bit",             is_percussion = false, base_tuning = 66, sound_id = "block.note_block.bit" },
    { name = "Banjo",           is_percussion = false, base_tuning = 66, sound_id = "block.note_block.banjo" },
    { name = "Pling",           is_percussion = false, base_tuning = 66, sound_id = "block.note_block.pling" },
    { name = "Snare",           is_percussion = true,  base_tuning = 66, sound_id = "block.note_block.snare" },
    { name = "Hat",             is_percussion = true,  base_tuning = 66, sound_id = "block.note_block.hat" },
    { name = "Bass Drum",       is_percussion = true,  base_tuning = 42, sound_id = "block.note_block.basedrum" },
}

---Converts a midi note ID to a multiplier usable in minecraft (reletive to the instrument's initial tuning)
---@param note_id integer
---@param instrument_base_id integer    The midi id for the instrument's base tuning
---@return number multiplier
local function midi_note_to_multiplier(note_id, instrument_base_id)
    local semitones_from_base_tuning = note_id - instrument_base_id
    return 2^(semitones_from_base_tuning / 12)
end

---@type InstrumentBuilder[]
local compiled_instrument_builders = {}
for _, note_block_sound in ipairs(note_block_sounds) do
    local note_block_instrument_builder = {
        name = name_prefix .. note_block_sound.name,
        is_available = function() return true end,  -- using minecraft built in noteblock sounds. this will allways be available.
        features = {
            percussion = note_block_sound.is_percussion,
        },

        new_instance = function(params)
            ---@type Instrument
            local new_instance = {
                play_instruction = function(instruction, position, _)
                    -- print("start: " .. tostring(instruction.note) .. " on trk" .. tostring(instruction.track_index) .. " for " .. tostring(instruction.duration) )
                    local new_sound = sounds[note_block_sound.sound_id]
                        :setPitch(midi_note_to_multiplier(instruction.note, note_block_sound.base_tuning))
                        :setPos(position)
                        :setSubtitle("Music from "..(player:isLoaded() and player:getName() or avatar:getName()))
                        :setVolume( instruction.start_velocity/127)  -- TODO: :setVolume(… * instruction.modifiers.(now).volume)
                    new_sound:play()
                end,
                update_sounds = function(_)
                    -- Notes do not linger, nothing to update
                end,
                stop_one_sound_immediatly = function()
                    -- Notes do not linger and so there's nothing to clean
                end,
                stop_all_sounds_immediatly = function()
                    -- Notes do not linger and so there's nothing to clean
                end,
                is_finished = function()
                    -- Notes do not linger and so there's nothing to clean
                    return true
                end
            }
            return new_instance
        end
    }
    table.insert(compiled_instrument_builders, note_block_instrument_builder)
end

return compiled_instrument_builders
