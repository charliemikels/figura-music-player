---@module "../song_player"

---@type InstrumentBuilder
local print_instrument_factory = {
    name = "Print",         -- Also used when making unique identifiers
    is_available = function() return true end,       -- Used by dynamicly-loaded instruments to signal when they are ready to go.
    features = {            -- Displayed to users so that they know what features this instrument supports.
        percussion = false,
        sustain = true          -- Notes can "ring" for any amount of time. (Unlike music block notes)
    },

    new_instance = function(params)

        ---@type table{time_started: number, instruction: Instruction}[]
        local active_instructions = {}
        local new_instance

        ---@type Instrument
        new_instance = {
            play_instruction = function(instruction, _, time_since_due)
                print("start: " .. tostring(instruction.note) .. " on trk" .. tostring(instruction.track_index) .. " for " .. tostring(instruction.duration) )
                table.insert(active_instructions, {
                    time_started = client.getSystemTime() - time_since_due,
                    instruction = instruction
                })
            end,
            update_sounds = function(_)
                for active_instruction_key, active_instruction in pairs(active_instructions) do
                    if (active_instruction.time_started + active_instruction.instruction.duration) <= client.getSystemTime() then
                        print("stopping: " .. tostring(active_instruction.instruction.note) .. " on trk" .. tostring(active_instruction.instruction.track_index))
                        active_instructions[active_instruction_key] = nil
                        -- As it turns out, setting an element to nil in a for pairs() loop is fine.
                        -- See docs for pair() which point to next() https://www.lua.org/manual/5.4/manual.html#pdf-next
                        -- "…You may however modify existing fields. In particular, you may set existing fields to nil."
                    end
                end
            end,
            stop_one_sound_immediatly = function()
                local key, _ = next(active_instructions)
                active_instructions[key] = nil
            end,
            stop_all_sounds_immediatly = function()
                active_instructions = {}
            end,
            is_finished = function() return next(active_instructions) == nil end
        }
        return new_instance
    end,
}

return { print_instrument_factory }
