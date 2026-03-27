---@module "../core"

-- Things player.lua needs to do:
-- - [x] Receive a ProcessedSong, or a ProcessedSongStream
-- - [x] Start an event loop to watch the current time. Auto-kill the song and loop after duration is met.
-- - [x] Every loop tick, check the list of instructions. If there are any new instructions, dispatch them to the relevent instrument.
-- - [x] Update each instrument. (They handle things like volume changes and pitch changes when nessesary)
-- - [x] Monitor the event loop (use another loop). Dynamicaly switch between high resolution (render) and high reliability (tick) when relevent.
-- - [ ] Be able to force-stop the song if no events are responding. This should use world tick. use very spearingly.
--    Does not nessesaraly need to stop the song (events might start up again), but it needs to stop currently playing notes.
-- - [ ] Expose controlls to the caller to start/pause/stop/end the song, and get progress.

---@type InstrumentName An instrument that will allways exist so long as the avatar is loaded.
local fallback_normal_instrument_name = "MC/Harp"
---@type InstrumentName An instrument that will allways exist so long as the avatar is loaded.
local fallback_percussion_instrument_name = "Percussion"

---@type InstrumentName
local default_normal_instrument_name = "Triangle Sine"
---@type InstrumentName
local default_percussion_instrument_name = "Percussion"

local do_debug_prints = false

local function print_debug(...) if do_debug_prints then print(...) end end
local function printTable_debug(...) if do_debug_prints then printTable(...) end end
local function print_host(...) if host:isHost() or do_debug_prints then print(...) end end


---@class Instruction
---@field track_index integer       Used by instruments system. Track 0 is a "meta track" and applies song-level changes like tempo and time signature changes
---@field start_time number
---@field start_velocity number     The initial velocity (volume) of the note.
---@field duration number           May be 0
---@field note number               The note to play, or ID of meta event
---@field modifiers NoteModifier[]  TODO: Modify note during playback, or if end_time is 0 used for metadata

---@alias NoteModifier {start_time: number, type: string, value: number}


---A unique string. Instruments loaded from other avatars should be prefixed with their UUID or username or something that won't cause conflicts.
---@alias InstrumentName string

---@class InstrumentBuilder
---@field name InstrumentName
---@field is_available fun():boolean    may be false for instruments with custom sounds and instruments from other avatars.
---@field features table<string, boolean>?
---@field new_instance fun(params: integer[]):Instrument

---@class Instrument
---
--- Queue the given instruction and play it immediatly. Remember to call update_sounds to eventualy stop the instruction.
---@field play_instruction fun(instruction: Instruction, position: Vector3, time_since_due: integer)
---@field update_sounds fun(position: Vector3)
---
--- For use with an emergency stop feature. In this case, we will likely need to use a world tick loop to stop the song.
--- At low permissions, we only have a handfull of instructions, and so we can't just call every sound to stop it,
--- We might need to go one at a time
---@field stop_one_sound_immediatly fun()
---
--- For when the user chooses to stop a song.
---@field stop_all_sounds_immediatly fun()
---
--- Returns true when the instrument has fully handeled all instructions given through play_instruction()
---@field is_finished fun():boolean

--- Lookup table of reserved instrument names.
---@type table<InstrumentName, true>
local reserved_instrument_names = {
    ["default"] = true,
    ["default percussion"] = true
}

---@type table<InstrumentName, InstrumentBuilder>
local known_instruments = {}

--- A function to fetch all instruments from the `./instruments` folder.
--- Can be re-ran at any time to update the list.
---
--- TODO: Scan other avatars for any that are advertizing instruments.
local function get_all_instruments()
    for _, script in ipairs(listFiles("./instruments", true)) do
        local found_instrument_builder_list
        local success, value = pcall(function()
            found_instrument_builder_list = require(script)
        end)
        if not success then
            print_debug("Error: Failed to require the script `"
                ..script
                .."` found in the `instruments` folder. Full error below:\n\n"
                ..tostring(value)
            )
            break
        end

        if type(found_instrument_builder_list) ~= "table" then
            print_debug("The `"..script.."` script did not return a list of instruments.")
            break
        end

        for _, found_instrument_builder in ipairs(found_instrument_builder_list) do
            if not (
                        found_instrument_builder.name
                    and (found_instrument_builder.is_available ~= nil)
                    and found_instrument_builder.new_instance
                )
            then
                print_debug("An instrument was found in the `"
                    .. tostring(script)
                    .."` script, but it doesn't look like an instrument."
                )
                break
            end

            if known_instruments[found_instrument_builder.name] then
                print_debug("Instrument `"
                    .. tostring(found_instrument_builder.name)
                    .. "` is already in known_instruments list"
                )
                break
            end

            if reserved_instrument_names[string.lower(found_instrument_builder.name)] then
                print_debug("Instrument `"
                    .. tostring(found_instrument_builder.name)
                    .. "` is useing a reserved name instrument name"
                )
                break
            end

            print_debug("Found new instrument", found_instrument_builder.name)
            known_instruments[found_instrument_builder.name] = found_instrument_builder
        end
    end
    if not known_instruments[fallback_normal_instrument_name] then
        error("fallback_normal_instrument_name "
            .. tostring(fallback_normal_instrument_name)
            .." did not appear in the known_instruments list"
        )
    end
    if not known_instruments[fallback_percussion_instrument_name] then
        error("fallback_percussion_instrument_name "
            .. tostring(fallback_percussion_instrument_name)
            .." did not appear in the known_instruments list"
        )
    end
end
get_all_instruments()


---@class InstrumentSelection
---@field name InstrumentName   A key in known_instruments.
---@field params integer[]?     list of params passed to the builder. List of integers for serialization. The instrument is in charge of understanding this.

---@class SongPlayerConfig
---@field default_normal_instrument? InstrumentSelection
---@field default_percussion_instrument? InstrumentSelection
---@field instrument_selections? table<TrackID, InstrumentSelection>
---@field source_pos Vector3?           The location where sound comes from. Setting source_pos will unset source_entity if one was set earlier.
---@field source_entity Entity?   When set, player will update source_pos to match the entitty's position.
---@field info_display_type string?      Configures if/how song info should be displayed in the world.
---@field primary_update_event_key string?      See `events:getEvents()`. Defaults to "RENDER." Usefull for playing a song with a player_skull instead of the real avatar.
---@field fallback_update_event_key string?     See `events:getEvents()`. Defaults to "TICK."
---@field play_immediately boolean?       Effectively calls `.play()` immediatly.
---
-- --- Auto stop is important if the song is comming from the player entity.
-- --- Without it, whenever the player is unloaded (eg goes through a nether portal), any running music will freeze and
-- --- drone on continualy until the the events start again, or the avatar is reloaded.
-- --- Only set this to `false` for controlled environments.
-- ---@field auto_stop_if_update_events_fail boolean?

---Applies config to a PlayingSong
---Used during init, and may be used during playback.
---@param playing_song PlayingSong
---@param config SongPlayerConfig
local function apply_config(playing_song, config)
    if not config then return end

    -- Update tracks instruments to match selected instruments.
    for track_index, track_config in ipairs(playing_song.track_config) do
        local instrument_selection_to_use_instead = nil
        if config.instrument_selections and config.instrument_selections[track_index] then
            instrument_selection_to_use_instead = config.instrument_selections[track_index]
        elseif config.default_normal_instrument and track_config.reccomended_instrument_type == 0 then
            instrument_selection_to_use_instead = config.default_normal_instrument
        elseif config.default_percussion_instrument and track_config.reccomended_instrument_type == 1 then
            instrument_selection_to_use_instead = config.default_percussion_instrument
        end

        if instrument_selection_to_use_instead then
            local previous_instrument = track_config.selected_instrument
            track_config.selected_instrument =
                known_instruments[instrument_selection_to_use_instead.name]
                .new_instance(instrument_selection_to_use_instead.params)
            if not previous_instrument.is_finished() then
                table.insert(playing_song.deprecated_instruments, previous_instrument)
            end
        end
    end

    if config.source_pos then
        playing_song.source_pos = config.source_pos
        playing_song.source_entity = nil
    end
    if config.source_entity then
        playing_song.source_entity = config.source_entity
        if config.source_entity.getPos and config.source_entity:getPos() then
            playing_song.source_pos = config.source_entity:getPos(client:getFrameTime()) + vec(0, config.source_entity:getEyeHeight() ,0)
        end
    end

    -- TODO: config.info_display_type whatnot

    if config.play_immediately then
        if not playing_song.controller.is_playing() then playing_song.controller.play() end
    end
end


---@alias TrackID number

---Called by an event loop.
---Dispatches new instructions to instruments based on current system time, and updates all instruments (including deprecated).
---@param playing_song PlayingSong
local function update_song(playing_song)
    local current_time = client.getSystemTime()

    -- Get sound position.

    if playing_song.source_entity then
        playing_song.source_pos =
            playing_song.source_entity:getPos(client:getFrameTime())
            + vec(0, (playing_song.source_entity:getBoundingBox().y * 0.5), 0)
    end

    -- During playing_song setup, we already assign a fallback instrument.
    -- This should ensure that all instruments are initilized to something.

    while playing_song.next_instruction_index <= #playing_song.instructions do
        local this_instruction = playing_song.instructions[playing_song.next_instruction_index]
        -- The amount of time between the current time, and the time this instruction should have been played.
        -- positive == the instruction is late. 0 == it's right on time. negative == it doesn't need to play yet. ignore if negative.
        local time_since_due = (current_time - playing_song.start_time) - this_instruction.start_time
        if time_since_due < 0 then
            -- instruction is not late, we'll take care of it later.
            -- (If all notes are slightly late, then none of the notes are slightly late.)
            break
        end
        if this_instruction.track_index == 0 then
            -- TODO: Track 0 is reserved for meta events like tempo and time signature info.
        else
            print_debug(
                tostring(math.floor(playing_song.controller.get_progress() * 100)).."%",
                "("..tostring(playing_song.next_instruction_index).." / ".. tostring(#playing_song.instructions)..")",
                this_instruction )
            playing_song
                .track_config[this_instruction.track_index]
                .selected_instrument
                .play_instruction(this_instruction, playing_song.source_pos, time_since_due)
        end
        playing_song.next_instruction_index = playing_song.next_instruction_index + 1
    end

    -- All new instructions dispatched. Updating instruments.

    local all_instruments_done = true
    for _, track_config in ipairs(playing_song.track_config) do
        track_config.selected_instrument.update_sounds(playing_song.source_pos)
        if all_instruments_done then
            all_instruments_done = track_config.selected_instrument.is_finished()
            -- will either continue being true, or this instrument is not done.
        end
    end

    -- Check and update deprecated instruments
    if next(playing_song.deprecated_instruments) then
        local finished_deprecated_instrument_keys = {}
        for deprecated_instrument_key, deprecated_instrument in pairs(playing_song.deprecated_instruments) do
            deprecated_instrument.update_sounds(playing_song.source_pos)
            if deprecated_instrument.is_finished() then
                table.insert(finished_deprecated_instrument_keys, deprecated_instrument_key)
            else
                all_instruments_done = false
            end
        end
        -- extra for loop to remove instruments.
        -- There's a slim chance that removing an instrument from the list will change the order of pairs() output.
        -- Meaning there's a chance an instrument might skip an update.
        -- Honestly the likelyhood of this actualy mattering is extreamly low since the next time update_song() gets
        -- called, any missed instruments will be updated then.
        for _, key_to_remove in ipairs( finished_deprecated_instrument_keys ) do
            playing_song.deprecated_instruments[key_to_remove] = nil
        end
    end

    -- TODO: Check if the song has finished, and all instruments have finished
    if playing_song.song_duration + playing_song.start_time < current_time then
        print_debug("Song_dur + start_time is now less than current time.")
        if all_instruments_done then
            playing_song.controller.stop()
            return
        else
            print_debug("Song should stop, but not all instruments are done.")
        end
    end
end


---@class SongPlayerAPI
local song_player_api = {
    ---@type fun(song: ProcessedSong, config: SongPlayerConfig?): PlayingSongController
    new_player = function (song, config)
        if not config or (not next(config)) then config = {} end
        print_debug("New player for", song.name)
        local playing_song

        local primary_event_checks_without_update = 0
        local fallback_event_checks_without_update = 0
        local max_failed_primary_tests = 4
        local max_failed_fallback_tests = 20

        local using_fallback_event = false

        local function test_primary_loop() primary_event_checks_without_update = 0 end
        -- local function test_fallback_loop() fallback_event_checks_without_update = 0 end

        -- For use in the update loop.
        local function update_this_song()
            if using_fallback_event then
                fallback_event_checks_without_update = 0
            else
                primary_event_checks_without_update = 0
            end
            update_song(playing_song)
        end

        local watcher_state_key = "idle"
        local emergency_stop_instrument_key_for_next = nil
        local event_watcher_and_swapper_state_machine
        -- this watcher might be running at very low permission. we need to make sure it's doing as little per update as possible.
        local function event_watcher_and_swapper()
            event_watcher_and_swapper_state_machine[watcher_state_key]()
        end
        -- Essentialy 5 states:
        -- Using primary, primary is fine, continue
        -- Using primary, primary is down, switch to fallback
        -- Using fallback, primary is down, continue
        -- Using fallback, primary is fine, switch to primary
        -- Using fallback, fallback is down, emergency stop.
        event_watcher_and_swapper_state_machine = {
            idle = function() end,
            check_primary = function()
                if primary_event_checks_without_update >= max_failed_primary_tests then
                    -- primary is no longer working. switch to fallback.
                    watcher_state_key = "switch_to_fallback"
                else
                    -- Primary appears to be running as expected. Bump timeout count.
                    primary_event_checks_without_update = primary_event_checks_without_update + 1
                end
            end,
            switch_to_fallback = function()
                print_debug("switching to fallback event")
                using_fallback_event = true
                playing_song.primary_event:remove(update_this_song)
                playing_song.primary_event:register(test_primary_loop)
                playing_song.fallback_event:register(update_this_song)
                watcher_state_key = "check_fallback"
            end,
            check_fallback = function()
                -- if here, primary was down. Check if fallback works, and then send back to retest primary.
                if fallback_event_checks_without_update >= max_failed_fallback_tests then
                    watcher_state_key = "begin_emergency_stop"
                else
                    -- fallback is running fine. Let's see if primary ha returned
                    fallback_event_checks_without_update  = fallback_event_checks_without_update + 1
                    watcher_state_key = "check_primary_from_fallback"
                end
            end,
            check_primary_from_fallback = function() -- check to see if it's safe to return to the primary event loop.
                if primary_event_checks_without_update >= max_failed_primary_tests then -- primary is still down. return to fallback check
                    watcher_state_key = "check_fallback"
                else -- Primary is back online. Let's switch back
                    watcher_state_key = "switch_to_primary"
                    primary_event_checks_without_update = primary_event_checks_without_update + 1
                end
            end,
            switch_to_primary = function()
                print_debug("switching to primary event")
                using_fallback_event = false
                playing_song.fallback_event:remove(update_this_song)
                playing_song.primary_event:remove(test_primary_loop)
                playing_song.primary_event:register(update_this_song)
                watcher_state_key = "check_primary"
            end,
            begin_emergency_stop = function()
                print_debug("The primary and fallback events for song "..playing_song.name.." are not responding. Starting emergency stop.")
                playing_song.fallback_event:remove(update_this_song)
                playing_song.primary_event:remove(update_this_song)
                playing_song.start_time = nil
                playing_song.elapsed_time = nil
                using_fallback_event = false
                watcher_state_key = "emergency_stop_active_instruments"
            end,
            emergency_stop_active_instruments = function()
                -- run through all tracks, kill running notes one at a time untill all are done.
                local key, track = next(playing_song.track_config, emergency_stop_instrument_key_for_next)
                if key then
                    if track.selected_instrument.is_finished() then
                        -- advance the "next()" loop for next time.
                        emergency_stop_instrument_key_for_next = key
                    else
                        track.selected_instrument.stop_one_sound_immediatly()
                    end
                else
                    -- key is nill, we've reached the end of the list
                    emergency_stop_instrument_key_for_next = nil
                    watcher_state_key = "emergency_stop_deprecated_instruments"
                end
            end,
            emergency_stop_deprecated_instruments = function()
                -- run through deprecated_instruments, kill running notes one at a time untill all are done.
                local key, instrument = next(playing_song.deprecated_instruments, emergency_stop_instrument_key_for_next)
                if key then
                    if instrument.is_finished() then
                        -- advance the "next()" loop for next time.
                        emergency_stop_instrument_key_for_next = key
                    else
                        instrument.stop_one_sound_immediatly()
                    end
                else
                    -- key is nill, we've reached the end of the list
                    emergency_stop_instrument_key_for_next = nil
                    watcher_state_key = "idle"
                    -- TODO: Is there any extra clean up that needs to be done?
                    events.WORLD_TICK:remove(event_watcher_and_swapper)
                end
            end,
        }

        -- For playback, we don't need to store the names of the reccomended instruments.

        ---type table<number, PlayingSongTrackConfig>
        local track_configs = {}
        for track_index, track_data in ipairs(song.tracks) do

            ---@class PlayingSongTrackConfig
            local track_config = {
                ---@type 0|1 The instrument type provided by the file_processor. 1 == Percussion, 0 = normal.
                reccomended_instrument_type = track_data.instrument_type_id,

                ---@type Instrument
                selected_instrument = known_instruments[
                        (   track_data.instrument_type_id == 1
                            and (known_instruments[default_percussion_instrument_name] and default_percussion_instrument_name or fallback_percussion_instrument_name)
                            or  (known_instruments[default_normal_instrument_name] and default_normal_instrument_name or fallback_normal_instrument_name)
                        )
                    ].new_instance({})
            }
            track_configs[track_index] = track_config
        end


        ---@class PlayingSong
        playing_song = {
            ---@type string The name of the song
            name = song.name,
            song_uuid = client.intUUIDToString(client.generateUUID()),  -- In case we need to create a key or something to address this song.
                    -- TODO: is a full UUID the right choice for this? could we get away with a simple sequence number, then we could send it ?

            ---@type number The total length of the song
            song_duration = song.duration,
            start_time = nil,   -- Compare with duration. If start time + duration <= current time, then song has ended
            elapsed_time = 0,   -- Might allow us to pause a song.
                                -- When resuming a song, get current time, subtract elapsed, and that should give a new start time.
            instructions = song.instructions,
            next_instruction_index = 1,

            --- If this song is being built from pings, this is amount of time it takes for the required amount of packets to arrive from the Host
            ---@type number
            buffer_delay = (song.buffer_delay or nil),

            --- The client time when the song started buffering. Compare with current time and buffer_delay
            --- to see if we've received enough packets to play this song in full.
            ---@type number
            buffer_start_time = (song.buffer_start_time or nil),

            ---@type Entity? If this is defined, overwrite source_pos every update()
            source_entity = nil,

            ---@type Vector3
            source_pos = vec(0,0,0),

            ---@type Event
            primary_event = events:getEvents()[(config.primary_update_event_key or "RENDER")],

            ---@type Event
            fallback_event = events:getEvents()[(config.fallback_update_event_key or "TICK")],

            --- List of Instrument that were use at some point during this song, but have since been swapped out for other instruments.
            --- If they are still playing notes, put them here so that we can close them properly if needed.
            ---@type Instrument[]
            deprecated_instruments = {},

            ---@type PlayingSongTrackConfig[]
            track_config = track_configs, -- PlayingSongTrackConfig

            ---@class PlayingSongController
            controller = {
                ---@type fun():boolean
                is_playing = function() return (playing_song.start_time and true or false) end,

                ---@type fun()
                play = function()
                    print_host("Playing \"" .. tostring(song.name) .. "\"")
                    if playing_song.start_time then
                        -- song is already playing.
                        return
                    end

                    primary_event_checks_without_update = 0
                    fallback_event_checks_without_update = 0

                    local earliest_possible_start_time = (
                                playing_song.buffer_delay
                            and playing_song.buffer_start_time
                            and ( playing_song.buffer_start_time + playing_song.buffer_delay )
                        or  client:getSystemTime()
                    )

                    playing_song.start_time = (earliest_possible_start_time > client:getSystemTime() and earliest_possible_start_time or client:getSystemTime() )
                    events.WORLD_TICK:register(event_watcher_and_swapper)
                    watcher_state_key = "check_primary"
                    playing_song.primary_event:register(update_this_song)
                end,

                ---@type fun():number
                get_progress = function()
                    if not playing_song.start_time then return nil end
                    return (client.getSystemTime() - playing_song.start_time) / playing_song.song_duration
                end,

                ---@type fun():number
                get_start_time = function()
                    if not playing_song.start_time then return nil end
                    return playing_song.start_time
                end,

                ---@type fun():number
                get_duration = function()
                    if not playing_song.song_duration then return nil end
                    return playing_song.song_duration
                end,

                ---@type fun()
                stop = function()
                    print_host("Stopping \"".. tostring(song.name) .."\"")
                    -- playing_song.elapsed_time = client.getSystemTime() - playing_song.start_time
                    playing_song.elapsed_time = nil
                    playing_song.start_time = nil

                    playing_song.primary_event:remove(update_this_song)
                    playing_song.fallback_event:remove(update_this_song)
                    events.WORLD_TICK:remove(event_watcher_and_swapper)
                    watcher_state_key = "idle"
                    primary_event_checks_without_update = 0
                    fallback_event_checks_without_update = 0

                    for _, track in pairs(playing_song.track_config) do
                        track.selected_instrument.stop_all_sounds_immediatly()
                    end
                    for key, deprecated_instruments in pairs(playing_song.deprecated_instruments) do
                        deprecated_instruments.stop_all_sounds_immediatly()
                        playing_song.deprecated_instruments[key] = nil
                    end
                end,

                ---@type fun(new_config: SongPlayerConfig)
                set_new_config = function(new_config)
                    apply_config(playing_song, new_config)
                end
            }
        }
        apply_config(playing_song, config)

        return playing_song.controller
    end,

    --- Returns a list of instrument keys sorted alphabeticaly.
    ---@type fun(): string[]
    get_instrument_keys = function()
        ---@type string[]
        local keys = {}
        for key, _ in pairs(known_instruments) do
            table.insert(keys, key)
        end
        table.sort(keys, function(a, b)
            return string.lower(a) < string.lower(b)
        end)
        return keys
    end,

    ---@type fun(instrument_key: string): boolean
    is_instrument_available = function(instrument_key)
        return known_instruments[instrument_key].is_available()
    end,

    ---@type fun(instrument_key: string): table<string, boolean>
    get_instrument_features = function(instrument_key)
        local features = {} -- protects the real features table from edits.
        for k, v in pairs(known_instruments[instrument_key].features) do
            features[k] = v
        end
        return features
    end,
}

return song_player_api
