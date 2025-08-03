---@module "../player"

---@type InstrumentBuilder
local print_instrument_factory = {
    name = "print",         -- Also used when making unique identifiers
    is_available = function() return true end,       -- Used by dynamicly-loaded instruments to signal when they are ready to go.
    features = {            -- Displayed to users so that they know what features this instrument supports.
        percussion = false,
        sustain = true          -- Notes can "ring" for any amount of time. (Unlike music block notes)
    },

    new_instance = function(params)
        local active_sounds = {}
        local new_instance

        ---@type Instrument
        new_instance = {
            play_instruction = function(instruction, _)
                print("start: " .. tostring(instruction.note) .. " for " .. tostring(instruction.duration) )
            end,
            update_sounds = function(_) end,
            stop_one_sound_immediatly = function() end,
            stop_all_sounds_immediatly = function() end,
            is_finished = function() return (active_sounds == 0) end
        }
        return new_instance
    end,
    sample = function() end,
}

return { print_instrument_factory }
