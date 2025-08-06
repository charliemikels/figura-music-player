---@module "../player"

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
local function midi_note_to_multiplier(note_id)
    -- Semitones away from a4, where negative is lower and positive is higher.
    local semitones_from_a4 = note_id - a4_id
    return 2^(semitones_from_a4 / 12)
end

---@type InstrumentBuilder
local print_instrument_factory = {
    name = "Triangle Sine",         -- Also used when making unique identifiers
    is_available = function() return triangle_sine_sound_key and avatar:canUseCustomSounds() end,       -- Used by dynamicly-loaded instruments to signal when they are ready to go.
    features = {            -- Displayed to users so that they know what features this instrument supports.
        percussion = false,
        sustain = true          -- Notes can "ring" for any amount of time. (Unlike music block notes)
    },

    new_instance = function(params)

        ---@type table{time_started: number, instruction: Instruction, sound: Sound}[]
        local active_instructions = {}

        ---@type Instrument
        local new_instance = {
            play_instruction = function(instruction, position, time_since_due)
                -- print("start: " .. tostring(instruction.note) .. " on trk" .. tostring(instruction.track_index) .. " for " .. tostring(instruction.duration) )
                local new_sound = sounds[triangle_sine_sound_key]    -- TODO: Make reletive using sounds:getCustomSounds whatver and then substring search
                    :setPos(position)
                    :setVolume((instruction.start_velocity/127))
                    -- :setAttenuation(2)
					:setLoop(true)
					:setPitch(midi_note_to_multiplier(instruction.note))
                    :setSubtitle("Music from "..player:getName())

                new_sound:play()

                table.insert(active_instructions, {
                    time_started = client.getSystemTime() - time_since_due,
                    instruction = instruction,
                    sound = new_sound
                })
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
            is_finished = function() return (#active_instructions == 0) end
        }
        return new_instance
    end,
    sample = function() end,
}

return { print_instrument_factory }
