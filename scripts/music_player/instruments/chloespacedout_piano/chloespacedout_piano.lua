
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
    -- can add your UUID to this list, and it should appear as an available Chloe Piano.
    -- You can find your UUID by running `player:getUUID()`
}

---@type UUID[]         -- Backends for the possible piano avatars.
local figura_midi_cloud_uuids = {
    "c0cfded1-a213-47d5-8054-94437f4fb906"
}



--#region   ChloePiano and ChloeFiguraMidi type definitions

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

--#endregion

--- Returns a list of pianos indexed by piano_lib_uuid, then piano_ID.
---
--- filters out drums, pianos that play drum sounds, and libraries where piano_lib.getPianos() is empty.
---
--- Coincidentaly, it also checks if piano and MidiCloud are at max settings, since the piano libs kinda do that for us.
---@return table<UUID, table<ChloePianoID, ChloePiano>>
local function get_all_known_pianos()

    ---@type table<UUID, table<ChloePianoID, ChloePiano>>
    local all_known_pianos = {}

    for _, lib_uuid in pairs(piano_lib_uuids) do
        local piano_lib = world.avatarVars()[lib_uuid]  ---@type ChloePianoLib

        if piano_lib and piano_lib.getPianos then
            local known_pianos_in_this_lib = piano_lib.getPianos()
            if known_pianos_in_this_lib and next(known_pianos_in_this_lib, nil) then
                for piano_id, piano in pairs(known_pianos_in_this_lib) do
                    if      piano
                        and piano.model ~= 4 and piano_lib.getInstrumentOverride(piano_id) ~= 128
                            -- see https://github.com/ChloeSpacedOut/figura-piano-2.0/blob/63a8c67be23970b6896c9f7716d28249de030741/Piano%202.0/main.lua#L564
                            -- getInstrumentOverride(test_piano_id) only applies to the piano's first channel 1, but that should be ok.
                    then
                        if not all_known_pianos[lib_uuid] then all_known_pianos[lib_uuid] = {} end
                        all_known_pianos[lib_uuid][piano_id] = piano
                    end
                end
            end
        end
    end

    return all_known_pianos
end


---@param piano_id ChloePianoID
---@return Vector3
local function piano_id_to_vec(piano_id)
    ---@type string, string, string
    local x_str, y_str, z_str = piano_id:match("{%s*(-?%d+),%s*(-?%d+),%s*(-?%d+)%s*}")
    return vectors.vec3(tonumber(x_str), tonumber(y_str), tonumber(z_str))
end


local max_search_radius_from_host = 32      ---@type number     -- distance in blocks for Near piano calculations

---@param target_pos Vector3
---@return UUID?
---@return ChloePianoID?
local function get_nearest_piano_uuid_and_id(target_pos)
    local all_known_pianos = get_all_known_pianos()
    if not next(all_known_pianos, nil) then return nil, nil end

    local nearest_distance_squared = (max_search_radius_from_host * max_search_radius_from_host)    -- pre-squared to use the cheaper :lengthSquared() for comparisons.
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

---@return boolean
local function instrument_is_available()
    -- TODO: should we limit this to a radius arround the host?

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
                else -- play piano note as usual
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
                -- Figura Midi Cloud takes care of stopping the notes for us. But we still need to clean up our own trackers.

                -- Item removal logic based on https://stackoverflow.com/a/53038524
                -- See also networking.lua → remove_packets_from_outgoing_queue_by_transfer_id()

                local size_of_hole = 0
                for search_index = 1, #known_piano_notes do

                    local current_time_is_after_total_note_duration_and_so_we_should_remove_this_note =
                        known_piano_notes[search_index].releaseTime + known_piano_notes[search_index].duration < client:getSystemTime()

                    if current_time_is_after_total_note_duration_and_so_we_should_remove_this_note then
                        known_piano_notes[search_index] = nil
                        size_of_hole = size_of_hole + 1
                    else
                        if (size_of_hole > 0) then
                            -- We want to keep this value, but there's a hole in the list. Slide the value so that we fill the hole.
                            known_piano_notes[search_index - size_of_hole] = known_piano_notes[search_index]
                            known_piano_notes[search_index] = nil
                        end
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
