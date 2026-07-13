
--- This instrument script lets the Music Player drive ChloeSpacedOut's Figura Pianos
--- In order to use this instrument, first follow "basic usage steps" in
--- the piano's README, then place one nearby. The instrument should
--- become "available" afterwards. Your listeners will also need to follow
--- these settings.
---@see https://github.com/ChloeSpacedOut/figura-piano-2.0

--- Note: this script is specifically built for Piano 2.0. The older versions of the piano will not be detected


---@type UUID[]
local piano_lib_uuids = {
    "943218fd-5bbc-4015-bf7f-9da4f37bac59",     -- Immortalized piano avatar
    "b0e11a12-eada-4f28-bb70-eb8903219fe5",     -- ChloeSpacedIn avatar

    -- Dear end user: If you or a loved one has equipped the piano 2.0 avatar, you
    -- can add your UUID to this list, and it should appear as an available Chloe Piano.
    -- You can find your UUID by running `player:getUUID()`
}


---@param piano_id ChloeInstrumentID
---@return Vector3
local function piano_id_to_vec(piano_id)
    ---@type string, string, string
    local x_str, y_str, z_str = piano_id:match("{%s*(-?%d+),%s*(-?%d+),%s*(-?%d+)%s*}")
    return vectors.vec3(tonumber(x_str), tonumber(y_str), tonumber(z_str))
end

---@type table<UUID, table<ChloeInstrumentID, Vector3?>>
local known_instruments = {}
for _, uuid in pairs(piano_lib_uuids) do known_instruments[uuid] = {} end

local instrument_search_state = "search_pianos"
local search_uuid_key = nil ---@type integer?
local search_uuid = nil     ---@type UUID?

---@type table<string, fun()>
local instrument_search_functions = {
    search_pianos = function()
        search_uuid_key, search_uuid = next(piano_lib_uuids, search_uuid_key)
        if not search_uuid_key then -- search_uuid_key is nil. we've hit the end of the list. move on.
            -- instrument_search_state = "search_pianos"    -- we actually don't have anywhere to go at this time
            return
        end

        local valid_piano = {}  ---@type table<ChloeInstrumentID, Vector3>
        local piano_lib = world.avatarVars()[search_uuid]  ---@type ChloePianoLib
        if piano_lib and piano_lib.getPianos then
            local known_pianos_in_this_lib = piano_lib.getPianos()
            if known_pianos_in_this_lib and next(known_pianos_in_this_lib, nil) then -- there are pianos, we just need to filter out pianos in drumkit mode
                for piano_id, piano in pairs(known_pianos_in_this_lib) do
                    if      piano
                        and piano.model ~= 4
                        and piano_lib.getInstrumentOverride(piano_id) ~= 128
                            -- see https://github.com/ChloeSpacedOut/figura-piano-2.0/blob/63a8c67be23970b6896c9f7716d28249de030741/Piano%202.0/main.lua#L564
                            -- getInstrumentOverride(test_piano_id) only applies to the piano's first channel 1, but that should be ok.
                    then
                        valid_piano[piano_id] = piano_id_to_vec(piano_id)
                    end
                end
            end
        end
        known_instruments[search_uuid] = valid_piano
    end,

    -- purge_old = function() end,
}

local last_update_check_world_time = world.getTime()
local function step_update_known_instruments()
    if last_update_check_world_time ~= world.getTime() then -- limit to one check per tick. if there's like 5 pianos all hitting the step function,
        last_update_check_world_time = world.getTime()
        instrument_search_functions[instrument_search_state]()
    end
end




local max_search_radius_from_host = 10      ---@type number     -- distance in blocks for Near piano calculations
local last_nearest_check_world_time = world.getTime()


---@param target_pos Vector3
---@return UUID?
---@return ChloeInstrumentID?
local function get_nearest_piano_uuid_and_id(target_pos)
    if last_nearest_check_world_time == world.getTime() then -- limit to one check per tick. if there's like 5 pianos all hitting the step function,
        return
    else
        last_nearest_check_world_time = world.getTime()
    end

    step_update_known_instruments()

    local nearest_distance_squared = (max_search_radius_from_host * max_search_radius_from_host)    -- pre-squared to use the cheaper :lengthSquared() for comparisons.
    local nearest_piano_id          ---@type ChloeInstrumentID?
    local nearest_piano_lib_uuid    ---@type UUID?

    local shift_to_center_of_block = vectors.vec3(0.5, 0.5, 0.5)

    for lib_uuid, piano_ids_and_positions in pairs(known_instruments) do
        local piano_lib = world.avatarVars()[lib_uuid]  ---@type ChloePianoLib
        if piano_lib and piano_lib.getPianos then -- This piano Library is still good.
            for piano_id, piano_position in pairs(piano_ids_and_positions) do
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
    step_update_known_instruments()
    -- TODO: should we limit this to a radius around the host?

    for _, piano_ids_and_positions in pairs(known_instruments) do
        if next(piano_ids_and_positions) then -- there is at least one drum in the list
            return true
        end
    end
    return false
end


local all_piano_info_display_roots = nil ---@type ModelPart?

---@type table<ChloeInstrumentID, {time:number, part:ModelPart}>
local piano_time_to_info_text_timeout = {}
local info_text_clear_time_padding = 2*1000

local previous_key_for_piano_time_to_info_text_timeout = nil
local function display_text_timeouts_watcher()
    local this_piano_id, this_timeout_value = next(piano_time_to_info_text_timeout, previous_key_for_piano_time_to_info_text_timeout)
    if not this_piano_id then
        -- key is nil. We might just be at the end of the list.
        if not previous_key_for_piano_time_to_info_text_timeout then
            -- the previous key was also nil. This means the list is empty. Clean up.
            all_piano_info_display_roots:remove()
            events.world_tick:remove(display_text_timeouts_watcher)
            return
        end
    else -- key and value are good
        if this_timeout_value.time < client:getSystemTime() then
            -- This value has expired and we may remove it.
            this_timeout_value.part:remove()
            piano_time_to_info_text_timeout[this_piano_id] = nil
        end
    end

    previous_key_for_piano_time_to_info_text_timeout = this_piano_id -- Step down the list. If nil, we check the start of list next loop.
end

local function start_display_text_timeouts_watcher()
    all_piano_info_display_roots = models:newPart("piano_info_display_super_parent", "World")
    events.world_tick:register(display_text_timeouts_watcher)
end

local function add_or_update_display_text(piano_id, new_timeout_time)
    if piano_time_to_info_text_timeout[piano_id] then   -- We know about this piano already. Let's just update the time.
        piano_time_to_info_text_timeout[piano_id].time = math.max(piano_time_to_info_text_timeout[piano_id].time, new_timeout_time)
        return
    end

    if not next(piano_time_to_info_text_timeout) then   -- this is the first piano and the watcher is not running
        start_display_text_timeouts_watcher()   -- initializes some things for us
    end

    local this_piano_root = all_piano_info_display_roots:newPart(piano_id, "World")
    this_piano_root:setPos((piano_id_to_vec(piano_id) * 16) + vectors.vec3(0.5*16, 2.25*16, 0.5*16))

    local this_piano_camera = this_piano_root:newPart(piano_id.."_billboard", "Camera")

    local this_piano_text_task = this_piano_camera:newText( tostring(piano_id).."_info_text")
    this_piano_text_task:setText("Controlled by "..avatar:getEntityName())
    this_piano_text_task:setScale(0.2)
    this_piano_text_task:setOpacity(0.75)
    this_piano_text_task:setAlignment("CENTER")

    piano_time_to_info_text_timeout[piano_id] = {time = new_timeout_time, part = this_piano_root}
end


---@type InstrumentBuilder
local piano_builder = {
    name = "ChloeSpacedOut Piano",
    is_available = instrument_is_available,
    features = {
        sustain = true
    },
    new_instance = function( _ )

        local instruments_api = require("../../instruments")  ---@type InstrumentsApi

        local fallback_instrument_builder = instruments_api.get_instrument_builder("Triangle Sine")
        local fallback_instrument_instance = fallback_instrument_builder and fallback_instrument_builder.new_instance({}) or nil

        local instance_piano_id             ---@type ChloeInstrumentID?
        local instance_piano_lib            ---@type ChloePianoLib?
        local instance_piano                ---@type ChloePiano
        local instance_piano_midi_note_api  ---@type ChloeFiguraMidiCloudMidiNoteBuilder

        local time_this_piano_will_be_done = client:getSystemTime()

        ---@param lib_uuid UUID
        ---@param piano_id string
        local function set_instance_piano_info(lib_uuid, piano_id)
            local previous_piano_id = instance_piano_id
            if not (lib_uuid and piano_id) then
                instance_piano_id = nil
                instance_piano_lib = nil
                instance_piano = nil
                instance_piano_midi_note_api = nil
                return
            end
            instance_piano_id = piano_id
            instance_piano_lib = world.avatarVars()[lib_uuid]  ---@type ChloePianoLib
            instance_piano = instance_piano_lib.getPiano(piano_id)
            instance_piano_midi_note_api = instance_piano.instance.midi.note

            if time_this_piano_will_be_done > client:getSystemTime() then
                add_or_update_display_text(piano_id, piano_time_to_info_text_timeout[previous_piano_id])
            end
        end

        -- piano is initialized to nil. Play instruction will give us a position to work with, we can get the nearest piano from there

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
                        instruction.start_velocity
                            * 0.5                           -- Piano is a little loud by default relative to the other instruments.
                            * (avatar:getVolume() / 100),   -- Respect if viewer has muted the host.

                        instruction.track_index+16,--1,           -- Channel ID 1 is shared with the piano itself. Channel 10 is percussion stuff. +20 ensures we're well outside any pre-configured channels. (luckily piano doesn't care that chanel 20 is also way outside midi spec.)
                        1,-- instruction.track_index,
                            -- TODO: There's an issue where tracks are initialized with channel ID instead of their track ID.
                            --       My system doesn't care if I send to channel or track, but piano has special rules for channels (piano itself uses channel 1)
                            --       and it's kinda silly to use instruction.track_index as channels.
                            --       See https://github.com/ChloeSpacedOut/figura-midi-player/pull/1 to know when we can switch it back.
                        (client.getSystemTime() - time_since_due)
                    )
                    local note_release_time = (client.getSystemTime() - time_since_due) + instruction.duration
                    new_note:release(note_release_time)

                    if note_release_time > time_this_piano_will_be_done then time_this_piano_will_be_done = note_release_time end

                    -- Visual updates

                    add_or_update_display_text(instance_piano_id, (note_release_time + info_text_clear_time_padding))

                    -- TODO: Trick piano into moving it's keys.

                end
            end,

            update_sounds = function (position)
                -- We can trust the piano to take care of its own notes

                fallback_instrument_instance.update_sounds(position)
            end,

            stop_one_sound_immediately = function()
                -- we can trust the piano to stop its own notes
                fallback_instrument_instance.stop_one_sound_immediately()
            end,

            stop_all_sounds_immediately = function ()
                -- we can trust the piano to stop its own notes
                fallback_instrument_instance.stop_all_sounds_immediately()
            end,

            is_finished = function ()
                local fallback_is_done = fallback_instrument_instance.is_finished()
                local piano_is_done = time_this_piano_will_be_done < client:getSystemTime()

                return fallback_is_done and piano_is_done
            end
        }
        return piano_instrument
    end,
}

return { piano_builder }
