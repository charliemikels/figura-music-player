---@module "../song_player"

-- local a4_frequency = 440    -- in hz
local a4_id = 69

---Converts a midi note ID to a multiplier usable in minecraft
---@param note_id integer
---@return number
local function midi_note_to_multiplier(note_id)
    -- Semitones away from a4, where negative is lower and positive is higher.
    local semitones_from_a4 = note_id - a4_id
    return 2^(semitones_from_a4 / 12)
end

--- Use with drumkit_sound_lookup()
--- Stored as functions to quickly get a fresh sound instance every time.
--- See https://zendrum.com/resource-site/drumnotes.htm to see how each midi note pairs to what sound.
---@type table<integer, fun():Sound>[]
local drumkit_sounds_lookup = {
    [35] = function() -- Acoustic Bass Drum
        return sounds["block.note_block.basedrum"]:pitch(0.7)
    end,
    [36] = function() -- Bass Drum 1
        return sounds["block.note_block.basedrum"]:pitch(0.8)
    end,
    [37] = function() -- Side Stick
        return sounds["block.note_block.hat"]:pitch(0.8)
    end,
    [38] = function() -- Acoustic Snare
        return sounds["block.note_block.snare"]:pitch(0.7)
    end,
    [39] = function() -- Hand Clap
        return sounds[ "item.trident.riptide_1" ]:pitch(6 )
    end,
    [40] = function() -- Electric snare
        return sounds["block.note_block.snare"]:pitch(0.8)
    end,
    [41] = function() -- Low Floor Tom
        return sounds["block.note_block.basedrum"]:pitch(1.25)
    end,
    [42] = function() -- Closed Hi-Hat
        return sounds[ "entity.player.hurt_on_fire" ]:pitch(10 )
    end,
    [43] = function() -- High Floor Tom
        return sounds["block.note_block.basedrum"]:pitch(1.3)
    end,
    [44] = function() -- Pedal Hi-Hat
        return sounds[ "item.trident.hit_ground" ]:pitch(6 )
    end,
    [45] = function() -- Low Tom
        return sounds["block.note_block.basedrum"]:pitch(1.35)
    end,
    [46] = function() -- Open Hi-Hat
        return sounds[ "block.fire.extinguish" ]:pitch(16)
    end,
    [47] = function() -- Low-Mid Tom
        return sounds["block.note_block.basedrum"]:pitch(1.4)
    end,
    [48] = function() -- High-Mid Tom
        return sounds["block.note_block.basedrum"]:pitch(1.45)
    end,
    [49] = function() -- Crash Cymbal 1
        return sounds["item.trident.hit_ground"]:pitch(2)        -- has variations
    end,
    [50] = function() -- High Tom
        return sounds["block.note_block.basedrum"]:pitch(1.5)
    end,
    [51] = function() -- Ride Cymbal 1
        return sounds[ "block.bell.use" ]:pitch(4)            -- has variations
    end,
    [52] = function()    -- Chinese Cymbal
        return sounds[ "block.bell.use" ]:pitch(5)        -- has variations
    end,
    [53] = function() -- Ride Bell
        return sounds[ "block.bell.use" ]:pitch(3)    -- has variations
    end,
    [54] = function() --Tambourine
        return sounds[ "block.beehive.shear" ]:pitch(3.2 )
    end,
    [55] = function() -- Splash Cymbal
        return sounds[ "block.bell.use" ]:pitch(6)        -- has variations
    end,
    [56] = function() -- Cowbell
        return sounds[ "block.note_block.cow_bell" ]:pitch(1.1)
    end,
    [57] = function() -- Crash Cymbal 2
        -- SBC's Crash 2 is nearly identical to Crash 1
        return sounds["item.trident.hit_ground"]:pitch(2)    -- has variations
    end,
    [58] = function() -- Vibroslap
        return sounds[ "entity.arrow.hit" ]:pitch(1.6)        -- has variations
    end,
    [59] = function() -- Ride Cymbal 2
        return sounds[ "block.bell.use" ]:pitch(4.5)    -- has variations
    end,
    [60] = function() -- High Bongo
        return sounds["entity.iron_golem.step"]:pitch(6)    -- has variations
    end,
    [61] = function() -- Low Bongo
        return sounds["entity.iron_golem.step"]:pitch(4)    -- has variations
    end,
    -- [62] = function() -- Muted High Conga
    --     return sounds["block.note_block.snare"]:pitch(0.8)
    -- end,
    -- [63] = function() -- High Conga
    --     return sounds["block.note_block.snare"]:pitch(0.8)
    -- end,
    -- [64] = function() -- Low Conga
    --     return sounds["block.note_block.snare"]:pitch(0.8)
    -- end,
    -- [65] = function() -- High Timbale
    --     return sounds["block.note_block.snare"]:pitch(0.8)
    -- end,
    -- [66] = function() -- Low Timbale
    --     return sounds["block.note_block.snare"]:pitch(0.8)
    -- end,
    [67] = function() -- High Agogo
        return sounds[ "entity.arrow.hit_player" ]:pitch(1.9):setVolume(0.4)
    end,
    [68] = function() -- Low Agogo
        return sounds[ "entity.arrow.hit_player" ]:pitch(1.7):setVolume(0.4)
    end,
    [69] = function() -- Cabasa
        return sounds[ "entity.silverfish.death" ]:pitch(4)
    end,
    [70] = function() -- Maracas
        return sounds[ "entity.iron_golem.attack" ]:pitch(3)
    end,
    -- [71] = function() -- Short Whistle
    --     return sounds["block.note_block.snare"]:pitch(0.8)
    -- end,
    -- [72] = function() -- Long Whistle
    --     return sounds["block.note_block.snare"]:pitch(0.8)
    -- end,
    [73] = function() -- Short Guiro
        return sounds["entity.player.burp"]:pitch(7)
    end,
    [74] = function() -- Long Guiro
        return sounds["block.sculk_sensor.clicking"]:pitch(3)    -- has variations
    end,
    -- [75] = function() -- Claves
    --     return sounds["block.note_block.snare"]:pitch(0.8)
    -- end,
    -- [76] = function() -- High Wood Block
    --     return sounds["block.note_block.snare"]:pitch(0.8)
    -- end,
    -- [77] = function() -- Low Wood Block
    --     return sounds["block.note_block.snare"]:pitch(0.8)
    -- end,
    -- [78] = function() -- Muted Cuica
    --     return sounds["block.note_block.snare"]:pitch(0.8)
    -- end,
    -- [79] = function() -- Open Cuica
    --     return sounds["block.note_block.snare"]:pitch(0.8)
    -- end,
    -- [80] = function() -- Mute Triangle
    --     return sounds["block.note_block.snare"]:pitch(0.8)
    -- end,
    -- [81] = function() -- Open triangle
    --     return sounds["block.note_block.snare"]:pitch(0.8)
    -- end,
}

---Convert a midi key to a drumkit shound
---@param midi_key integer
---@return Sound
local function drumkit_sound_lookup(midi_key)
    if drumkit_sounds_lookup[midi_key] then
        return drumkit_sounds_lookup[midi_key]()
    end
    return sounds["minecraft:block.note_block.hat"]:setPitch(
        midi_note_to_multiplier(midi_key)
    )
end

---@type InstrumentBuilder
local print_instrument_factory = {
    name = "Percussion",         -- Also used when making unique identifiers
    is_available = function() return true end,       -- Used by dynamicly-loaded instruments to signal when they are ready to go.
    features = {            -- Displayed to users so that they know what features this instrument supports.
        percussion = true,
    },

    new_instance = function(params)

        ---@type table{time_started: number, instruction: Instruction, sound: Sound}[]
        -- local active_instructions = {}

        ---@type Instrument
        local new_instance = {
            play_instruction = function(instruction, position, _)
                -- print("start: " .. tostring(instruction.note) .. " on trk" .. tostring(instruction.track_index) .. " for " .. tostring(instruction.duration) )
                local new_sound = drumkit_sound_lookup(instruction.note)
                    :setPos(position)
                    :setSubtitle("Music from "..(player:isLoaded() and player:getName() or avatar:getName()))
                new_sound:setVolume( new_sound:getVolume() * (instruction.start_velocity/127))  -- TODO: :setVolume(… * instruction.modifiers.(now).volume)

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
    end,
}

return { print_instrument_factory }
