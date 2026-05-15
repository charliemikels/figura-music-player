
--- Note: as of writing this commit, the Imortalized Drumkit that you'd find on this post:
--- https://discord.com/channels/1129805506354085959/1340798228165300224/1340798228165300224
--- does not work with this script. It doesn't expose the getDrumIDs function and so we are unable to
--- (quickly and efficiently) find this kind of drumkit.
---
--- (In theory we could do some sort of search algorithm to find nearby drums in a tick loop,
--- but that's certainly the dictionary definition of overenginering. I'll just ask someone
--- in the discord about it)
---
--- The current version of the avatar in the [Figura Drum github page](https://github.com/ChloeSpacedOut/figura-drum)
--- should work just fine, it's just the imortalized one seems to not be useing it.
---
---
---
--- The below script assumes the imortilized drumkit actualy does work.


-- ----------------------------------------------------------------------------------------------


--- This instrument script lets the Music Player drive ChloeSpacedOut's Figura Drums (and v2 pianos in drum mode)
--- In order to use this instrument, you (and your viewers) may need to either
---
--- - follow the "basic usage steps" in Piano 2.0's README      https://github.com/ChloeSpacedOut/figura-piano-2.0
--- - follow the "How to use" section of Piano v1's README (matches current imortilized drumkit usage)      https://github.com/ChloeSpacedOut/figura-piano
---
--- Then place one nearby. The instrument should become "available" afterwards.
---
--- BTW, Drumkit's documentation is a little sparse. It's probably being phased out by Piano 2.0. But you can
--- still summon the imortilized drumkit avatar with these commands.
---
--- - 1.21+:    /give @p minecraft:player_head[minecraft:profile={id:[I;1039887675,1961051688,-1756947787,-2031944347],name:"Drum"}]
--- - 1.20:     /give @p minecraft:player_head{SkullOwner:{Id:[I;1039887675,1961051688,-1756947787,-2031944347]}}



---UUIDs that have [Figura Drum](https://github.com/ChloeSpacedOut/figura-drum) equipped as their avatar.
---@type UUID[]
local drumkit_lib_uuids = {
    "3dfb6d3b-74e3-4628-9747-1ab586e2fd65",     -- Imortilized Drumkit avatar
}

---UUIDs that have [Figura Piano 2.0](https://github.com/ChloeSpacedOut/figura-piano-2.0) equipped as their avatar.
---@type UUID[]
local piano_lib_uuids = {
    "943218fd-5bbc-4015-bf7f-9da4f37bac59",     -- Imortalized Piano avatar
    "b0e11a12-eada-4f28-bb70-eb8903219fe5",     -- ChloeSpacedIn avatar
}


---@param drum_id ChloeInstrumentID
---@return Vector3
local function drum_id_to_vec(drum_id)
    ---@type string, string, string
    local x_str, y_str, z_str = drum_id:match("{%s*(-?%d+),%s*(-?%d+),%s*(-?%d+)%s*}")
    return vectors.vec3(tonumber(x_str), tonumber(y_str), tonumber(z_str))
end


---@type table<UUID, table<ChloeInstrumentID, Vector3?>>
local known_instruments = {}
for _, uuid in pairs(drumkit_lib_uuids) do known_instruments[uuid] = {} end
for _, uuid in pairs(piano_lib_uuids) do known_instruments[uuid] = {} end

local instrument_search_state = "search_piano_drums"
local search_uuid_key = nil ---@type integer?
local search_uuid = nil     ---@type UUID?

---@type table<string, fun()>
local instrument_search_functions = {
    search_piano_drums = function()
        search_uuid_key, search_uuid = next(piano_lib_uuids, search_uuid_key)
        if not search_uuid_key then -- search_uuid_key is nil. we've hit the end of the list. move on.
            instrument_search_state = "search_clasic_drums"
            return
        end

        local valid_drums = {}  ---@type table<ChloeInstrumentID, Vector3>
        local piano_lib = world.avatarVars()[search_uuid]  ---@type ChloePianoLib
        if piano_lib and piano_lib.getPianos then
            local known_pianos_in_this_lib = piano_lib.getPianos()
            if known_pianos_in_this_lib and next(known_pianos_in_this_lib, nil) then -- there are pianos, we just need to filter for pianos in drumkit mode
                for piano_id, piano in pairs(known_pianos_in_this_lib) do
                    if piano
                        and (piano.model == 4 or piano_lib.getInstrumentOverride(piano_id) == 128)   -- in the drumkit model or useing percussion sounds
                        -- TODO: This doesn't check for drumkit models set to play non-drum sounds
                    then
                        valid_drums[piano_id] = drum_id_to_vec(piano_id)
                    end
                end
            end
        end
        known_instruments[search_uuid] = valid_drums
    end,

    search_clasic_drums = function()
        search_uuid_key, search_uuid = next(drumkit_lib_uuids, search_uuid_key)
        if not search_uuid_key then -- search_uuid_key is nil. we've hit the end of the list. move on.
            instrument_search_state = "search_piano_drums"
            return
        end
        local valid_drums = {}  ---@type table<ChloeInstrumentID, Vector3>
        local drumkit_lib = world.avatarVars()[search_uuid]    ---@type ChloeDrumkitLib
        if drumkit_lib and drumkit_lib.getDrumIDs then
            for _, drumkit_id in pairs(drumkit_lib.getDrumIDs()) do
                valid_drums[drumkit_id] = drum_id_to_vec(drumkit_id)
            end
        end
        known_instruments[search_uuid] = valid_drums
    end,

    -- purge_old = function() end,
}

local last_update_check_gametime = world.getTime()
local function step_update_known_instruments()
    if last_update_check_gametime ~= world.getTime() then -- limit to one check per tick. if there's like 5 pianos all hitting the step function,
        last_update_check_gametime = world.getTime()
        instrument_search_functions[instrument_search_state]()
    end
end



local max_search_radius_from_host = 10      ---@type number     -- distance in blocks for Near piano calculations
local last_nearest_check_gametime = world.getTime()

---@param target_pos Vector3
---@return UUID?
---@return ChloeInstrumentID?
local function get_nearest_drum_uuid_and_id(target_pos)
    if last_nearest_check_gametime == world.getTime() then -- limit to one check per tick. if there's like 5 pianos all hitting the step function,
        return
    else
        last_nearest_check_gametime = world.getTime()
    end

    step_update_known_instruments()

    local nearest_distance_squared = (max_search_radius_from_host * max_search_radius_from_host)    -- pre-squared to use the cheaper :lengthSquared() for comparisons.
    local nearest_drum_id          ---@type ChloeInstrumentID?
    local nearest_drum_lib_uuid    ---@type UUID?

    local shift_to_center_of_block = vectors.vec3(0.5, 0.5, 0.5)

    for lib_uuid, drum_ids_and_positions in pairs(known_instruments) do
        local drum_lib = world.avatarVars()[lib_uuid]  ---@type ChloePianoLib|ChloeDrumkitLib
        if drum_lib.playNote then -- This library is still good.
            for drum_id, drum_position in pairs(drum_ids_and_positions) do
                local drum_distance_squared = ((drum_position + shift_to_center_of_block) - target_pos):lengthSquared()
                if drum_distance_squared < nearest_distance_squared then
                    nearest_distance_squared = drum_distance_squared
                    nearest_drum_id = drum_id
                    nearest_drum_lib_uuid = lib_uuid
                end
            end
        end
    end

    return nearest_drum_lib_uuid, nearest_drum_id
end

---@return boolean
local function instrument_is_available()
    step_update_known_instruments()
    -- TODO: should we limit this to a radius arround the host?
    for _, drum_ids_and_positions in pairs(known_instruments) do
        if next(drum_ids_and_positions) then -- there is at least one drum in the list
            return true
        end
    end
    return false
end


local all_drum_info_display_roots = nil ---@type ModelPart?

---@type table<ChloeInstrumentID, {time:number, part:ModelPart}>
local drum_time_to_info_text_timeout = {}
local info_text_clear_time_padding = 2*1000

local previous_key_for_drum_time_to_info_text_timeout = nil
local function display_text_timeouts_watcher()
    local this_drum_id, this_timeout_value = next(drum_time_to_info_text_timeout, previous_key_for_drum_time_to_info_text_timeout)
    if not this_drum_id then
        -- key is nil. We might just be at the end of the list.
        if not previous_key_for_drum_time_to_info_text_timeout then
            -- the previous key was also nil. This means the list is empty. Clean up.
            all_drum_info_display_roots:remove()
            events.world_tick:remove(display_text_timeouts_watcher)
            return
        end
    else -- key and value are good
        if this_timeout_value.time < client:getSystemTime() then
            -- This value has expired and we may remove it.
            this_timeout_value.part:remove()
            drum_time_to_info_text_timeout[this_drum_id] = nil
        end
    end

    previous_key_for_drum_time_to_info_text_timeout = this_drum_id -- Step down the list. If nil, we check the start of list next loop.
end

local function start_display_text_timeouts_watcher()
    all_drum_info_display_roots = models:newPart("piano_info_display_super_parrent", "World")
    events.world_tick:register(display_text_timeouts_watcher)
end

local function add_or_update_display_text(drum_id, new_timeout_time)
    if drum_time_to_info_text_timeout[drum_id] then   -- We know about this piano already. Let's just update the time.
        drum_time_to_info_text_timeout[drum_id].time = math.max(drum_time_to_info_text_timeout[drum_id].time, new_timeout_time)
        return
    end

    if not next(drum_time_to_info_text_timeout) then   -- this is the first piano and the watcher is not running
        start_display_text_timeouts_watcher()   -- initilizes some things for us
    end

    local this_drum_root = all_drum_info_display_roots:newPart(drum_id, "World")
    this_drum_root:setPos((drum_id_to_vec(drum_id) * 16) + vectors.vec3(0.5*16, 2.25*16, 0.5*16))

    local this_drum_camera = this_drum_root:newPart(drum_id.."_billboard", "Camera")

    local this_drum_text_task = this_drum_camera:newText( tostring(drum_id).."_info_text")
    this_drum_text_task:setText("Controlled by "..avatar:getEntityName())
    this_drum_text_task:setScale(0.2)
    this_drum_text_task:setOpacity(0.75)
    this_drum_text_task:setAlignment("CENTER")

    drum_time_to_info_text_timeout[drum_id] = {time = new_timeout_time, part = this_drum_root}
end


--#region
-- Build a lookup table to go from Midi numbers to
-- Essentialy a reversed version of the string→number lookup in Piano 2.0: https://github.com/ChloeSpacedOut/figura-piano-2.0/blob/63a8c67be23970b6896c9f7716d28249de030741/Piano%202.0/main.lua#L38-L56

---@type table<integer, ChloeKeyID>
local base_note_name_lookup = {
    [0] = "C",
    [1] = "C#",
    [2] = "D",
    [3] = "D#",
    [4] = "E",
    [5] = "F",
    [6] = "F#",
    [7] = "G",
    [8] = "G#",
    [9] = "A",
    [10] = "A#",
    [11] = "B",
}

---@type table<integer, ChloeKeyID>
local note_number_to_string = {}
for i = 21, 95 do
    note_number_to_string[i] = (base_note_name_lookup[i % 12] .. math.floor(i/12) - 1)
end

--#endregion

---@param midi_note integer
---@return ChloeKeyID?
local function midi_note_to_string(midi_note)
    return note_number_to_string[midi_note]
end

---@type InstrumentBuilder
local drumkit_builder = {
    name = "ChloeSpacedOut Drumkit",
    is_available = instrument_is_available,
    features = {
        percussion = true,
    },
    new_instance = function( _ )

        local fallback_instrument_builders   = require("../percussion/percussion")    ---@type InstrumentBuilder[]
        local _, fallback_instrument_builder = next(fallback_instrument_builders, nil)
        local fallback_instrument_instance   = fallback_instrument_builder.new_instance({})

        local instance_drum_id             ---@type ChloeInstrumentID?
        local instance_drum_lib            ---@type (ChloePianoLib|ChloeDrumkitLib)?

        ---@param lib_uuid UUID?
        ---@param drum_id ChloeInstrumentID?
        local function set_instance_drum_info(lib_uuid, drum_id)
            -- may be nil, nil to essentialy un-find a drum kit

            if not (lib_uuid and drum_id) then
                instance_drum_id = nil
                instance_drum_lib = nil
                return
            end
            instance_drum_id = drum_id
            instance_drum_lib = world.avatarVars()[lib_uuid]  ---@type (ChloePianoLib|ChloeDrumkitLib)?
        end

        -- piano is initilized to nil. Play instruction will give us a position to work with, we can get the nearest piano from there

        ---@type Instrument
        local drum_instrument = {
            play_instruction = function (instruction, position, time_since_due)
                if not instrument_is_available() then   -- something in the drum system is not available. Reset everything so that we use the fallback instrument.
                    set_instance_drum_info(nil, nil)
                elseif not instance_drum_id then       -- Drum is available, but instance_drum_id is not set. Let's reset it.
                    local nearest_uuid, nearest_drum_id = get_nearest_drum_uuid_and_id(position)
                    if nearest_drum_id then
                        set_instance_drum_info(nearest_uuid, nearest_drum_id)
                    end
                end

                local note_to_string = midi_note_to_string(instruction.note)

                if not instance_drum_id or not note_to_string then   -- drum is still invalid (or the note is out of range). use the fallback instrument.
                    fallback_instrument_instance.play_instruction(instruction, position, time_since_due)
                else -- play drum note as usual
                    instance_drum_lib.playNote(
                        instance_drum_id,
                        note_to_string,
                        true,
                        nil,
                        instruction.start_velocity
                            * 0.02                         -- Drum is a little loud by default reletive to the other instruments.
                            * (avatar:getVolume() / 100)    -- Respect if viewer has muted the host.
                    )   -- playNote is kinda a legacy function for Piano 2.0, but it's the same signature for old and new drums.

                    add_or_update_display_text(instance_drum_id, (client.getSystemTime() + info_text_clear_time_padding))

                end
            end,

            update_sounds = function (position)
                -- Drum kit is only impulses. no need to keep track of notes
                fallback_instrument_instance.update_sounds(position)
            end,

            stop_one_sound_immediatly = function()
                -- Drum kit is only impulses. All sounds will naturaly stop
                fallback_instrument_instance.stop_one_sound_immediatly()
            end,

            stop_all_sounds_immediatly = function ()
                -- Drum kit is only impulses. All sounds will naturaly stop
                fallback_instrument_instance.stop_all_sounds_immediatly()
            end,

            is_finished = function ()
                -- Drum kit is only impulses. We are allways (effectively) finished. Defer to fallback, just in case it's not finished.
                return fallback_instrument_instance.is_finished()
            end
        }
        return drum_instrument
    end,
}

return { drumkit_builder }
