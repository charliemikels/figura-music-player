
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

local max_search_radius_from_host = 32      ---@type number     -- distance in blocks for Near piano calculations

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
--- `pitch` and `velocity` are midi values, so 0-128 or something.
---
--- `sysTime` should be called with the note's start time. see `client.getSystemTime()`
---
--- `pos` may be nil, in which the note will default to the instance's position.
---@field play fun(self:ChloeFiguraMidiCloudMidiNote, instance:table, pitch:integer, velocity:integer, channelID:integer, trackID:integer, sysTime, pos:Vector3?):ChloeFiguraMidiCloudMidiNote
---
---@field sustain fun(self:ChloeFiguraMidiCloudMidiNote) -- Removes the "main noise" and only plays the sustain loop.
---
--- Notes will decay on their own, but `release`
---
--- `sysTime` is the time the note was released, but it can be set to a future time. Call with `client.getSystemTime()` and add `instruction.duration` to it.
---@field release fun(self:ChloeFiguraMidiCloudMidiNote, sysTime:integer)
---@field stop fun(self:ChloeFiguraMidiCloudMidiNote) -- stops the note immediatly.
---@field releaseTime integer   -- The time the note was released. Because we set this time immediatly after creating the note, we should expect this to allways be something
---@field duration number       -- The amount of extra time it takes for this not to decay after being released.
---@field sound Sound

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
---@param max_distance integer?  -- How far away we're allowed to search for a piano (prevents trying to initilize a piano that's near the viewer, but not near the host.)
---@return UUID?
---@return ChloePianoID?
local function get_nearest_piano_uuid_and_id(target_pos, max_distance)
    local all_known_pianos = get_all_known_pianos()
    if not next(all_known_pianos, nil) then return nil, nil end
    if not max_distance then max_distance = max_search_radius_from_host end

    local nearest_distance_squared = (max_distance*max_distance) or math.huge      -- we don't really care about the exact distance, just the comparison. We can ignore the square root.
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

local function instrument_is_available(target_pos)
    -- TODO: should we limit this to a radius arround the host
    -- TODO: check if piano is a drum kit before reccomending.
    -- TODO: check permissions of the piano avatar and the midi cloud

    local there_is_at_least_one_known_piano = (next(get_all_known_pianos(), nil) and true or false)
    return there_is_at_least_one_known_piano
end

---@type InstrumentBuilder
local piano_builder = {
    name = "ChloeSpacedOut Piano",
    is_available = instrument_is_available,
    features = {
        sustain = true
    },
    new_instance = function(params)

        local fallback_instrument_builders   = require("../triangle_sine/triangle_sine")    ---@type InstrumentBuilder[]
        local _, fallback_instrument_builder = next(fallback_instrument_builders, nil)
        local fallback_instrument_instance   = fallback_instrument_builder.new_instance({})

        local instance_piano_id             ---@type ChloePianoID?
        local instance_piano_lib            ---@type ChloePianoLib?
        -- local instance_piano_lib_uuid       ---@type UUID?
        -- local instance_piano_pos            ---@type Vector3?
        local instance_piano                ---@type ChloePiano
        local instance_piano_midi_note_api  ---@type ChloeFiguraMidiCloudMidiNote

        ---@param lib_uuid UUID
        ---@param piano_id string
        local function set_instance_piano_info(lib_uuid, piano_id)
            if not (lib_uuid and piano_id) then
                instance_piano_id = nil
                instance_piano_lib = nil
                -- instance_piano_lib_uuid = nil
                -- instance_piano_pos = nil
                instance_piano = nil
                instance_piano_midi_note_api = nil
                return
            end
            instance_piano_id = piano_id
            instance_piano_lib = world.avatarVars()[lib_uuid]  ---@type ChloePianoLib
            -- instance_piano_lib_uuid = lib_uuid
            -- instance_piano_pos = piano_id_to_vec(piano_id)
            instance_piano = instance_piano_lib.getPiano(piano_id)
            instance_piano_midi_note_api = instance_piano.instance.midi.note
        end

        -- Assume the host player entity is playing the song. Let's figure out which piano they want to use.
        if player:isLoaded() then
            do  -- Try to get the piano the Host is looking at.
                local targeted_block_state = player:getTargetedBlock(true, nil)
                local targeted_block_pos = targeted_block_state:getPos()
                local targeted_block_pos_string = tostring(targeted_block_pos)
                for lib_uuid, pianos_by_id in pairs(get_all_known_pianos()) do
                    if pianos_by_id[targeted_block_pos_string] then
                        set_instance_piano_info(lib_uuid, targeted_block_pos_string)
                        break
                    end
                end
            end

            if not instance_piano_id then   -- just get the nearest piano
                local nearest_uuid, nearest_piano_id = get_nearest_piano_uuid_and_id(player:getPos())
                if nearest_piano_id then
                    set_instance_piano_info(nearest_uuid, nearest_piano_id)
                end
            end
        end
        -- instance_piano information might still be `nil.` If it is, wait until we get a position from piano_instrument.play_instruction, then re-attempt nearest piano detection.

        
        local known_piano_notes = {}    ---@type ChloeFiguraMidiCloudMidiNote[]

        -- Split off into it's own function so that piano_instrument.stop_all_sounds_immediatly can use it too
        local function stop_one_sound_immediatly()
            local note_to_stop = table.remove(known_piano_notes)
            if note_to_stop then note_to_stop:stop() end
            fallback_instrument_instance.stop_one_sound_immediatly()
        end

        ---@type Instrument
        local piano_instrument = {
            play_instruction = function (instruction, position, time_since_due)
                -- print("playing piano instruction. note "..tostring(instruction.note)..", track: "..tostring(instruction.track_index))
                if not instrument_is_available() then   -- something in the piano system is not available. Reset everything so that we use the fallback instrument.
                    set_instance_piano_info(nil, nil)
                elseif not instance_piano_id then       -- Piano is available, but instance_piano_id is not set. Let's reset it.
                    local nearest_uuid, nearest_piano_id = get_nearest_piano_uuid_and_id(position)
                    if nearest_piano_id then
                        set_instance_piano_info(nearest_uuid, nearest_piano_id)
                    end
                end

                if not instance_piano_id then   -- piano is still invalid. use the fallback instrument.
                    fallback_instrument_instance.play_instruction(instruction, position, time_since_due)
                else
                    -- play piano note as usual

                    local new_note = instance_piano_midi_note_api:play(
                        instance_piano.instance,
                        instruction.note,
                        instruction.start_velocity * 0.5,   -- piano is a little loud by default reletive to my other instruments.

                        instruction.track_index,--1,           -- Channel ID 1 is shared with the piano itself.
                        1,-- instruction.track_index,
                            -- TODO: There's an issue where tracks are initilized with channel ID instead of their track ID.
                            --       My system doesn't care if I send to channel or track, but I'd like to reuse the Piano's built in channel if possible.
                            --       plus haveing both lets be better disambiguate between pianos and instances of my instrument wrapper.
                            --       See https://github.com/ChloeSpacedOut/figura-midi-player/pull/1 to know when we can switch it back.
                        (client.getSystemTime() - time_since_due)
                    )
                    new_note:release((client.getSystemTime() - time_since_due) + instruction.duration)

                    table.insert(known_piano_notes, new_note)

                    -- TODO: Trick piano into moveing it's keys.

                end
            end,

            update_sounds = function (position)
                -- Figura Midi Cloud takes care of stopping the notes for us. But we still need to clean up our trackers.

                local size_of_hole = 0
                for search_index = 1, #known_piano_notes do
                    local should_delete_note =
                        known_piano_notes[search_index].releaseTime + known_piano_notes[search_index].duration
                        < client:getSystemTime()

                    if not should_delete_note then
                        if (size_of_hole > 0) then
                            -- We want to keep this value, but there's a hole in the list. Slide the value so that we fill the hole.
                            known_piano_notes[search_index - size_of_hole] = known_piano_notes[search_index]
                            known_piano_notes[search_index] = nil
                        end
                    else
                        known_piano_notes[search_index] = nil
                        size_of_hole = size_of_hole + 1
                    end
                end

                -- clean up fallback instrument too
                fallback_instrument_instance.update_sounds(position)
            end,

            stop_one_sound_immediatly = stop_one_sound_immediatly,

            stop_all_sounds_immediatly = function ()
                repeat
                    stop_one_sound_immediatly()
                until not known_piano_notes or #known_piano_notes <= 0
                known_piano_notes = {}

                fallback_instrument_instance.stop_all_sounds_immediatly()
            end,

            is_finished = function ()
                local fallback_is_done = fallback_instrument_instance.is_finished()
                local piano_is_done = next(known_piano_notes, nil) == nil

                return fallback_is_done and piano_is_done
            end
        }
        return piano_instrument
    end,
}

return { piano_builder }
