
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

---@type UUID[]         -- Backends for the possible piano avatars.
local figura_midi_cloud_uuids = {
    "c0cfded1-a213-47d5-8054-94437f4fb906"
}



-- TODO: figura-piano-2.0 has some midi cloud backend. Should we refrence it directly?
--       See https://github.com/ChloeSpacedOut/figura-midi-player/blob/main/ChloesMidiPlayerCloud/externalAPI.lua

-- --------------------------------------------------------


---@class ChloeFiguraMidiCloudInstance
---@field ID string
---@field activeSong nil
---@field isRemoved boolean
---@field target Player|BlockState|Vector3  -- https://github.com/ChloeSpacedOut/figura-midi-player/blob/20c4d8031668a3ee2e3b3cb69843fabc46acc81a/ChloesMidiPlayerCloud/externalAPI.lua#L98
---@field volume number         -- float between 0 and 1
---@field attenuation number    -- float between 0 and 1
---@field midi ChloeFiguraMidiCloudMidiApi
---@field soundfont ChloeFiguraMidiCloudSoundfontAPI
---@field lastSysTime number    -- initilized to client.getSystemTime()
---@field lastUpdated number    -- initilized to client.getSystemTime()
---@field shouldKeepAlive boolean
---@field shouldKeepAliveClock number
---@field songs table
---@field tracks table
---@field channels table
---@field parseProjects table

---@class ChloeFiguraMidiCloudMidiApi
---@field channel table
---@field events table
---@field note ChloeFiguraMidiCloudMidiNote
---@field song table

---@class ChloeFiguraMidiCloudMidiNote
---
--- Initilizes a new midi note and plays it.
---
--- This function also takes care of initilizeing new channels and tracks. But will also stop notes if we reuse a pitch on a track.
---
--- sysTime should be called with the note's start time. see client.getSystemTime()
---
--- pos may be nil, in which the piano will default to the instance's position.
---@field play fun(self:ChloeFiguraMidiCloudMidiNote, instance:table, pitch:number, velocity, channelID, trackID, sysTime, pos:Vector3?):ChloeFiguraMidiCloudMidiNote
---
---@field sustain fun(self:ChloeFiguraMidiCloudMidiNote) -- Removes the "main noise" and only plays the sustain loop.
---@field release fun(self:ChloeFiguraMidiCloudMidiNote, sysTime:integer)  -- call with client.getSystemTime(). Can be mixed with instruction.duration to pre-set a stop point
---@field stop fun(self:ChloeFiguraMidiCloudMidiNote)

---@class ChloeFiguraMidiCloudSoundfontAPI

---@class ChloePianoLib
---@field getPianos fun():table<ChloePianoID, ChloePiano>
---@field getPiano fun(ChloePianoID):ChloePiano
---@field playMidiNote fun(pianoID:ChloePianoID, note:integer, velocity:number, type:("PRESS"|"SPAM_HOLD"|"MANUAL_RELEASE")?, playerEntity:Entity?, notePos:Vector3?)   -- if playerEntity is included, crouching will sustain the piano.
---@field releaseMidiNote fun(ChloePianoID, integer)
---@field setInstrumentOverride fun(ChloePianoID, integer)
---@field getInstrumentOverride fun(ChloePianoID)
---@field getItem fun(table):ItemStack

---@alias ChloePianoID string   -- PianoIDs are the same as tostring( vec3position )

---@class ChloePiano    -- This is a subset of what is in the actual piano. we should primaraly just use IDs and the built-in helper functions.
---@field ID ChloePianoID
---@field lastInstrument integer
---@field model 1|2|3|4                     -- 1-3 == pianos. 4 == drum kit
---@field playingKeys table<integer, table> -- List of keys being held down.
---@field instance ChloeFiguraMidiCloudInstance
---@field midi table



---@return table<UUID, table<ChloePianoID, ChloePiano>>
local function get_all_known_pianos()

    ---@type table<UUID, table<ChloePianoID, ChloePiano>>
    local all_known_pianos = {}

    for _, lib_uuid in pairs(piano_lib_uuids) do
        local piano_lib = world.avatarVars()[lib_uuid]  ---@type ChloePianoLib

        if piano_lib and piano_lib.getPianos then
            -- printTable(piano_lib.getPiano(next(piano_lib.getPianos(), nil)))
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
local function get_nearest_piano_uuid_and_id(target_pos)
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

---@type table<UUID, table<ChloePianoID, table<integer, Instruction>>>
local all_playing_piano_instructions = {} -- I'm pretty sure the default piano API does not allow us to "double up" key presses, so we need to keep track of each piano's key presses so we don't step on our toes too much.


---@type InstrumentBuilder
local piano_builder = {
    name = "ChloeSpacedOut Piano",
    is_available = function()

        --#region piano_test
        local nearest_lib_uuid, nearest_piano_id = get_nearest_piano_uuid_and_id(player:getPos())
        local nearest_piano_lib = world.avatarVars()[nearest_lib_uuid]  ---@type ChloePianoLib
        local nearest_piano = nearest_piano_lib.getPiano(nearest_piano_id)
        local nearest_piano_midi_note_api = nearest_piano.instance.midi.note

        -- Bypasses the piano library and lets us use the piano's midi backend.
        nearest_piano_midi_note_api:play(
            nearest_piano.instance,
            60,
            80,
            1,
            1,
            client:getSystemTime()
        ):release(client:getSystemTime()+750)
        --#endregion piano_test



        -- TODO: check permissions of the piano avatar and the midi cloud



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
        local instance_piano_lib_uuid
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
                        instance_piano_lib_uuid = lib_uuid
                        instance_piano_pos = targeted_block_pos
                    end
                end
            end

            if not instance_piano_id then   -- just get the nearest piano
                local nearest_uuid, nearest_piano = get_nearest_piano_uuid_and_id(player:getPos())
                if nearest_piano then
                    instance_piano_id = nearest_piano
                    instance_piano_lib = world.avatarVars()[nearest_uuid]  ---@type ChloePianoLib
                    instance_piano_lib_uuid = nearest_uuid
                    instance_piano_pos = piano_id_to_vec(nearest_piano)
                end
            end
        end


        ---@type Instrument
        local piano_instrument = {
            play_instruction = function (instruction, position, time_since_due)
                -- TODO: what happens if we try to play the same note twice on the same piano?
                --       We need to make sure if we have two piano instrument instances, that we don't mess with the original piano.
                --       Or, that we don't step on our own toes.






                -- if      all_playing_piano_instructions[instance_piano_lib_uuid]
                --     and all_playing_piano_instructions[instance_piano_lib_uuid][instance_piano_id]
                --     and all_playing_piano_instructions[instance_piano_lib_uuid][instance_piano_id][instruction.note]
                -- then    -- This piano is already playing the note in this instruction.
                --     local previous_instruction = all_playing_piano_instructions[instance_piano_lib_uuid][instance_piano_id][instruction.note]    ---@type Instruction

                --     -- local previous_instruction_velocity = previous_instruction.start_velocity
                --     -- if previous_instruction_velocity > instruction.start_velocity then
                --     --     -- Use previous's velocity, so that we don't loose energy.
                --     --     instance_piano_lib.getPiano(instance_piano_id)
                --     --     instance_piano_lib.releaseMidiNote(
                --     --         instance_piano_id,
                --     --         instruction.note
                --     --     )
                --     --     instance_piano_lib.playMidiNote(
                --     --         instance_piano_id,
                --     --         instruction.note,
                --     --         previous_instruction_velocity/127,
                --     --         "MANUAL_RELEASE"
                --     --     )
                --     -- else
                --     --     instance_piano_lib.releaseMidiNote(
                --     --         instance_piano_id,
                --     --         instruction.note
                --     --     )
                --     --     instance_piano_lib.playMidiNote(
                --     --         instance_piano_id,
                --     --         instruction.note,
                --     --         instruction.start_velocity/127,
                --     --         "MANUAL_RELEASE"
                --     --     )
                --     -- end


                --     -- local previous_instruction_end_time = previous_instruction.start_time + previous_instruction.duration
                --     -- local current_instruction_end_time = instruction.start_time + instruction.duration
                --     -- if previous_instruction_end_time < current_instruction_end_time then
                --     --     -- replace previous instruction with my own note.

                --     --     all_playing_piano_instructions[instance_piano_lib_uuid][instance_piano_id][instruction.note] = instruction

                --     --     -- TODO: triangle_sine has a simplified "active instructions" idea. Do we need to replace the previous instruction? can we keep both arround?
                --     -- end

                --     -- -- We are already useing this key for something.
                -- end




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
                return next(all_playing_piano_instructions, nil) == nil
            end
        }
        return piano_instrument
    end,
}

return { piano_builder }
