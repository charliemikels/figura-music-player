
--- This instrument script lets the Music Player drive ChloeSpacedOut's Figura Pianos
--- In order to use this instrument, first follow "basic usage steps" in
--- the piano's README, then place one nearby. The instrument should
--- become "available" afterwards. Your listeners will also need to follow
--- these settings.
---@see https://github.com/ChloeSpacedOut/figura-piano-2.0

-- TODO: Piano 2.0 is able to also play the drum kit sounds. Should this one script do both?

-- TODO: Piano 2.0 has access to a bunch of instruments. Should we expose all of these, or just the piano one?

---@alias UUID string

---@type UUID[]
local piano_lib_uuids = {
    "943218fd-5bbc-4015-bf7f-9da4f37bac59",     -- Imortalized piano avatar
    "b0e11a12-eada-4f28-bb70-eb8903219fe5",     -- ChloeSpacedIn avatar

    -- Dear end user: If you or a loved one has equipped the piano 2.0 avatar, you
    -- can add your UUID to this list, and it should appear as an available Chloe Piano
}

-- --------------------------------------------------------


---@class ChloePianoLib
---@field getPianos fun():table<ChloePianoID, ChloePiano>
---@field getPiano fun(ChloePianoID):ChloePiano
---@field playMidiNote fun(ChloePianoID, Number, Number, String, entity, vec3)    -- pianoID, pitch, volume, type, playerEntity, notePos
---@field releaseMidiNote fun(ChloePianoID, integer)
---@field setInstrumentOverride fun(ChloePianoID, integer)
---@field getInstrumentOverride fun(ChloePianoID)
---@field getItem fun(table):ItemStack

---@alias ChloePianoID string   -- PianoIDs are the same as tostring( vec3position )

---@class ChloePiano    -- This is a subset of what is in the actual piano. we should primaraly just use IDs and the built-in helper functions.
---@field ID ChloePianoID
---@field lastInstrument integer
---@field model 1|2|3|4     -- 1-3 == pianos. 4 == drum kit



---@return table<UUID, table<ChloePianoID, ChloePiano>>
local function get_all_known_pianos()

    ---@type table<UUID, table<ChloePianoID, ChloePiano>>
    local all_known_pianos = {}

    for _, lib_uuid in pairs(piano_lib_uuids) do
        local piano_lib = world.avatarVars()[lib_uuid]  ---@type ChloePianoLib

        if piano_lib.getPianos then
            all_known_pianos[lib_uuid] = piano_lib.getPianos()
        end
    end

    return all_known_pianos
end

---comment
---@param piano_id ChloePianoID
---@return Vector3
local function piano_id_to_vec(piano_id)
    ---@type string, string, string
    local x_str, y_str, z_str = piano_id:match("{%s*(-?%d+),%s*(-?%d+),%s*(-?%d+)%s*}")
    return vectors.vec3(tonumber(x_str), tonumber(y_str), tonumber(z_str))
end


---@param target_pos Vector3
---@return UUID?
---@return ChloePianoID?
local function get_nearest_piano(target_pos)
    local all_known_pianos = get_all_known_pianos()
    if not next(all_known_pianos, nil) then return nil, nil end

    local nearest_distance_squared = math.huge      -- don't care about the exact distance, just the comparison. We can ignore the square root.
    local nearest_piano_id          ---@type ChloePianoID
    local nearest_piano_lib_uuid    ---@type UUID

    local shift_to_center_of_block = vectors.vec3(0.5, 0.5, 0.5)

    for lib_uuid, pianos_by_id in pairs(all_known_pianos) do
        local piano_lib = world.avatarVars()[lib_uuid]  ---@type ChloePianoLib
        if piano_lib.getPianos then -- This piano Library is still good.
            for piano_id, _ in pairs(pianos_by_id) do
                local piano_position = piano_id_to_vec(piano_id)
                local piano_distance_squared = ((piano_position + shift_to_center_of_block) - target_pos):lengthSquared()
                if piano_distance_squared < nearest_distance_squared then
                    nearest_distance_squared = piano_distance_squared
                    nearest_piano_id = piano_id
                    nearest_piano_lib_uuid = lib_uuid
                end
            end
        end
    end

    return nearest_piano_lib_uuid, nearest_piano_id
end

---@type InstrumentBuilder
local piano_builder = {
    name = "ChloeSpacedOut Piano",
    is_available = function()
        return (next(get_all_known_pianos(), nil) and true or false)
    end,
    features = {
        sustain = true
    },
    new_instance = function(params)

        local fallback_instrument_builders = require("../note_blocks/note_blocks")  ---@type InstrumentBuilder[]
        local fallback_instrument_instance = fallback_instrument_builders[1].new_instance({})
        for _, prefered_fallback_instrument_builder in pairs(fallback_instrument_builders) do
            if prefered_fallback_instrument_builder.name == "MC/Harp" then
                fallback_instrument_instance = prefered_fallback_instrument_builder.new_instance({})
            end
        end


        -- TODO: Pass a starting point into new_instance, so that we can find the nearest known piano.
        --       OR: just allways asume the host player is playing

        local instance_piano_id
        local instance_piano_lib
        local instance_piano_pos
        -- Assume the host player entity is playing the song. Let's figure out which piano they want to use.
        if player:isLoaded() then
            do  -- Try to get the piano the Host is looking at.
                local targeted_block_state = player:getTargetedBlock(true, nil)
                local targeted_block_pos = targeted_block_state:getPos()
                local targeted_block_pos_string = tostring(targeted_block_pos)
                for lib_uuid, pianos_by_id in pairs(get_all_known_pianos()) do
                    if pianos_by_id[targeted_block_pos_string] then
                        instance_piano_id = targeted_block_pos_string
                        instance_piano_lib = world.avatarVars()[lib_uuid]  ---@type ChloePianoLib
                        instance_piano_pos = targeted_block_pos
                    end
                end
            end

            if not instance_piano_id then   -- just get the nearest piano
                local nearest_uuid, nearest_piano = get_nearest_piano(player:getPos())
                if nearest_piano then
                    instance_piano_id = nearest_piano
                    instance_piano_lib = world.avatarVars()[nearest_uuid]  ---@type ChloePianoLib
                    instance_piano_pos = piano_id_to_vec(nearest_piano)
                end
            end
        end


        ---@type Instrument
        local piano_instrument = {
            play_instruction = function (instruction, position, time_since_due)
                -- TODO: what happens if we try to play the same note twice on the same piano?
                --       We need to make sure if we have two piano instrument instances, that we don't mess with the original piano.

                -- TODO: Test if piano is still valid
                -- TODO: If invalid, sent instruction to fallback instrument.
                -- TODO: If valid, send instruction to piano.

            end,
            update_sounds = function (position)

            end,
            stop_one_sound_immediatly = function ()

            end,
            stop_all_sounds_immediatly = function ()

            end,
            is_finished = function ()
                ---@see triangle_sine.lua


                return false
            end
        }
        return piano_instrument
    end,
}

return { piano_builder }
