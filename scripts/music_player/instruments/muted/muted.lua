---@module "../song_player"

---@type InstrumentBuilder
local muted_instrument_factory = {
    name = "Muted",
    is_available = function() return true end,
    features = {
        percussion = false,
        sustain = false
    },

    new_instance = function(_)

        local new_instance

        ---@type Instrument
        new_instance = {
            play_instruction = function(_, _, _) end,
            update_sounds = function(_) end,
            stop_one_sound_immediatly = function() end,
            stop_all_sounds_immediatly = function() end,
            is_finished = function() return true end
        }
        return new_instance
    end,
}

return { muted_instrument_factory }
