


local do_debug_prints = false

--- Logs a message to the console. But if do_debug_prints is true, it also logs to chat. Use do_debug_prints=true to debug viewers.
---@param message string
---@param is_warning boolean?
---@param always_log boolean?
local function print_debug(message, is_warning, always_log)
    if do_debug_prints then print(message) end
    if do_debug_prints or always_log then
        if is_warning then
            host:warnToLog(message)
        else
            host:writeToLog(message)
        end
    end
end
local function printTable_debug(...) if do_debug_prints then printTable(...) end end
local function print_host(...) if host:isHost() or do_debug_prints then print(...) end end


---@type InstrumentKey
local default_normal_instrument_name = "Triangle Sine"
---@type InstrumentKey
local default_percussion_instrument_name = "Percussion"






---A unique string. Instruments loaded from other avatars should be prefixed with their UUID or username or something that won't cause conflicts.
---@alias InstrumentKey string

---@class InstrumentBuilder
---@field name InstrumentKey
---@field is_available fun():boolean    may be false for instruments with custom sounds and instruments from other avatars.
---@field features table<string, boolean>?
---@field new_instance fun(params: integer[], notify_ui_function:fun(message:string)):Instrument  -- notify_ui_function is a function provided by the song player. An instance can run this function to show notable warnings to the viewer. Message will decay over time, unless instrument keeps it alive.
---@field sort_priority number? -- If nil, defaults to 0

---@alias InstrumentTypeId 0|1 0 for normal, 1 for percussion.

---@class Instrument
---
--- Queue the given instruction and play it immediately. Remember to call update_sounds to eventually stop the instruction.
---@field play_instruction fun(instruction: Instruction, position: Vector3, time_since_due: integer)
---@field update_sounds fun(position: Vector3)
---
--- For use with an emergency stop feature. In this case, we will likely need to use a world tick loop to stop the song.
--- At low permissions, we only have a handful of instructions, and so we can't just call every sound to stop it,
--- We might need to go one at a time
---@field stop_one_sound_immediately fun()
---
--- For when the user chooses to stop a song.
---@field stop_all_sounds_immediately fun()
---
--- Returns true when the instrument has fully handled all instructions given through play_instruction()
---@field is_finished fun():boolean

--- Lookup table of reserved instrument names.
---@type table<InstrumentKey, true>
local reserved_instrument_names = {
    ["default"] = true,
    ["default percussion"] = true
}

---@type table<InstrumentKey, InstrumentBuilder>
local known_instruments = {}

-- TODO: This logic filters out legitimate instruments that happen to end in `instruments`. EG: `chloe_midi_cloud_instruments.lua`
-- Is there a better way to filter out the starting folder/script without banishing items that just happen to be named the same?
local instruments_directory_path = "./instruments"
local instruments_directory_path_but_just_what_is_after_the_slash = instruments_directory_path:gsub(".*%.%/(%a-)", "%1")
local pattern_to_exclude = instruments_directory_path_but_just_what_is_after_the_slash.."$"  -- tests if local song is the last thing in the list (the found path is a path to ourself)


--- Builds a canonical instrument list
--- All instrument builders must exist at upload time, but don't need to be "available" right away.
do
    for _, script_path in pairs(listFiles(instruments_directory_path, true)) do
        if not string.match(script_path, pattern_to_exclude) then

            print_debug("Found possible instrument provider: `"..script_path.."`", false)

            local found_instrument_builder_list
            local success, value = pcall(function()
                found_instrument_builder_list = require(script_path)
            end)
            if not success then
                print_debug(
                    "Error: Failed to require the script `"
                        ..script_path
                        .."` found in the `"..instruments_directory_path.."` folder. Full error below:\n\n"
                        ..tostring(value),
                    true, true
                )
                break
            end

            if type(found_instrument_builder_list) ~= "table" then
                print_debug("The `"..script_path.."` script did not return a list of instruments.", true, true)
                break
            end

            for _, found_instrument_builder in pairs(found_instrument_builder_list) do
                if not (
                            found_instrument_builder.name
                        and (found_instrument_builder.is_available ~= nil)
                        and found_instrument_builder.new_instance
                    )
                then
                    print_debug(
                        "An instrument was found in the `"
                            .. tostring(script_path)
                            .."` script, but it doesn't look like an instrument.",
                        true, true
                    )
                    break
                end

                if known_instruments[found_instrument_builder.name] then
                    print_debug(
                        "Instrument `"
                            .. tostring(found_instrument_builder.name)
                            .. "` is already in known_instruments list",
                        true, true
                    )
                    break
                end

                if reserved_instrument_names[string.lower(found_instrument_builder.name)] then
                    print_debug(
                        "Instrument `"
                            .. tostring(found_instrument_builder.name)
                            .. "` is using a reserved name instrument name"
                        , true, true
                    )
                    break
                end

                print_debug("Found new instrument `".. tostring(found_instrument_builder.name).."`")
                known_instruments[found_instrument_builder.name] = found_instrument_builder
            end
        end
    end

    if not known_instruments[default_normal_instrument_name] then
        error("fallback_normal_instrument_name "
            .. tostring(default_normal_instrument_name)
            .." did not appear in the known_instruments list"
        )
    end
    if not known_instruments[default_percussion_instrument_name] then
        error("fallback_percussion_instrument_name "
            .. tostring(default_percussion_instrument_name)
            .." did not appear in the known_instruments list"
        )
    end
end



---@return table<InstrumentKey, InstrumentBuilder>
local function get_instruments()
    return known_instruments
end

---Returns a list of instrument keys sorted alphabetically.
---@return InstrumentKey[]
local function get_sorted_instrument_keys()
    ---@type InstrumentKey[]
    local keys = {}
    for key, _ in pairs(known_instruments) do
        table.insert(keys, key)
    end
    table.sort(keys, function(a, b)
        if (known_instruments[a].sort_priority or 0) == (known_instruments[b].sort_priority or 0) then
            return string.lower(a) < string.lower(b)
        end
        -- print (a .. " and "..b.." don't match")
        return (known_instruments[a].sort_priority or 0) > (known_instruments[b].sort_priority or 0)
    end)
    return keys
end

---@param instrument_key InstrumentKey
---@return boolean
local function is_instrument_available(instrument_key)
    return known_instruments[instrument_key].is_available()
end

---@param instrument_key InstrumentKey
---@return table<string, boolean>
local function get_instrument_features(instrument_key)
    local features = {} -- protects the real features table from edits.
    for k, v in pairs(known_instruments[instrument_key].features) do
        features[k] = v
    end
    return features
end

---@param instrument_key InstrumentKey
---@return InstrumentBuilder?
local function get_instrument_builder(instrument_key)
    return known_instruments[instrument_key]
end


---@param instrument_type_id InstrumentTypeId   -- TODO: Reconsider. Should this just be an "is percussion" boolean?
---@return InstrumentBuilder?
local function get_default_instrument_builder(instrument_type_id)
    return get_instrument_builder(
        instrument_type_id == 1 and default_percussion_instrument_name or  default_normal_instrument_name
    )
end

---@class InstrumentsApi
local instruments_api = {
    get_instruments             = get_instruments,
    get_sorted_instrument_keys  = get_sorted_instrument_keys,
    is_instrument_available     = is_instrument_available,
    get_instrument_features     = get_instrument_features,
    get_instrument_builder      = get_instrument_builder,
    get_default_instrument_builder      = get_default_instrument_builder,
}

return instruments_api
