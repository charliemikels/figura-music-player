---@module "../song_player"

-- local a4_frequency = 440    -- in hz
local a4_id = 69 -- nice. Midi note numbers are 1 semitone away from the next note in the sequence.

local triangle_sine_sound_key = nil
for _, full_sound_id in pairs(sounds:getCustomSounds()) do
    if string.find(full_sound_id, "triangle_sine.triangle_sine") then
        triangle_sine_sound_key = full_sound_id;
        break
    end
end

---Converts a midi note ID to a multiplier usable in minecraft
---@param note_id integer
---@return number
local function midi_note_to_multiplier(note_id, offset)
    -- Semitones away from a4, where negative is lower and positive is higher.
    local semitones_from_a4 = (note_id - a4_id) + (offset or 0)
    return 2^(semitones_from_a4 / 12)
end


local modifier_functions = {
    pitch_wheel = function(active_instruction, value, instrument_config)
        -- max value = 0x3FFF. where 0x2000 is neutral.  0 to 0x3FFF → ±0x2000 → ±1 → ±2
        local semitone_offset = (value - 8192) / 8192 * instrument_config.pitch_bend_sensitivity
        -- print(client:getSystemTime(), value, semitone_offset)
        active_instruction.sound:setPitch(midi_note_to_multiplier(active_instruction.instruction.note, semitone_offset))
    end,
    volume = function(active_instruction, value, _)
        -- from what I can tell, dec`100` is the most "default" value for channels that don't specify volume. `127` is the max.
        active_instruction.sound:setVolume((active_instruction.instruction.start_velocity/127) * (value / 100))
    end,
}

---@param active_instruction {time_started: number, instruction: Instruction, modifier_index: integer, detune_amount: number, sound: Sound}
---@param instrument_config table
local function update_modifiers(active_instruction, instrument_config)
    local modifiers = active_instruction.instruction.modifiers
    for index = active_instruction.modifier_index, #modifiers do
        local modifier_delta_from_instruction_start = modifiers[index].start_time - active_instruction.instruction.start_time
        if active_instruction.time_started + modifier_delta_from_instruction_start > client.getSystemTime() then return end
        if modifier_functions[modifiers[index].type] then
            modifier_functions[modifiers[index].type](active_instruction, modifiers[index].value, instrument_config)
        end
        active_instruction.modifier_index = index + 1
    end
end

local instrument_builder
---@type InstrumentBuilder
instrument_builder = {
    name = "Triangle Sine",         -- Also used when making unique identifiers
    is_available = function() return triangle_sine_sound_key and avatar:canUseCustomSounds() end,       -- Used by dynamicly-loaded instruments to signal when they are ready to go.
    features = {            -- Displayed to users so that they know what features this instrument supports.
        -- percussion = false,
        sustain = true,     -- Notes can "ring" for any amount of time. (Unlike music block notes)
        pitch_bend = true
    },

    new_instance = function(params)

        local song_player_api = require("../../song_player")  ---@type SongPlayerAPI

        local fallback_instrument_builder = song_player_api.get_instrument_builder("MC/Harp")
        local fallback_instrument_instance   = fallback_instrument_builder and fallback_instrument_builder.new_instance({}) or nil

        ---@type {time_started: number, instruction: Instruction, modifier_index: integer, detune_amount: number, sound: Sound}[]
        local active_instructions = {}
        local instrument_config = {
            pitch_bend_sensitivity = 2,
            do_detune = true
        }

        ---@type Instrument
        local new_instance = {
            play_instruction = function(instruction, position, time_since_due)
                -- print("start: " .. tostring(instruction.note) .. " on trk" .. tostring(instruction.track_index) .. " for " .. tostring(instruction.duration) )

                if not instrument_builder.is_available() then
                    if fallback_instrument_instance then
                        fallback_instrument_instance.play_instruction(instruction, position, time_since_due)
                        return
                    end
                end

                local detune_amount = (instrument_config.do_detune and ((math.random()-0.5) * 0.1) or 0)

                local new_sound = sounds[triangle_sine_sound_key]    -- TODO: Make reletive using sounds:getCustomSounds whatver and then substring search
                    :setPos(position)
                    :setVolume((instruction.start_velocity/127))
                    :setLoop(true)
                    :setPitch(midi_note_to_multiplier(instruction.note, detune_amount))
                    :setSubtitle("Music from "..player:getName())

                local active_instruction = {
                    time_started = client.getSystemTime() - time_since_due,
                    instruction = instruction,
                    detune_amount = detune_amount,
                    modifier_index = 1,
                    sound = new_sound
                }
                update_modifiers(active_instruction, instrument_config)

                active_instruction.sound:play()
                table.insert(active_instructions, active_instruction)
            end,
            update_sounds = function(position)
                for active_instruction_key, active_instruction in pairs(active_instructions) do
                    if (active_instruction.time_started + active_instruction.instruction.duration) <= client.getSystemTime() then
                        -- Stop this instruction
                        active_instruction.sound:stop()
                        active_instruction.sound = nil
                        active_instructions[active_instruction_key] = nil
                    else
                        active_instruction.sound:setPos(position)
                        update_modifiers(active_instruction, instrument_config)
                    end
                end
            end,
            stop_one_sound_immediatly = function()
                local active_instruction_key, active_instruction = next(active_instructions)
                if active_instruction_key then
                    active_instruction.sound:stop()
                    active_instruction.sound = nil
                    active_instructions[active_instruction_key] = nil
                end
            end,
            stop_all_sounds_immediatly = function()
                for active_instruction_key, active_instruction in pairs(active_instructions) do
                    active_instruction.sound:stop()
                    active_instruction.sound = nil
                    active_instructions[active_instruction_key] = nil
                end
            end,
            is_finished = function() return next(active_instructions) == nil end
        }
        return new_instance
    end,
}

return { instrument_builder }
