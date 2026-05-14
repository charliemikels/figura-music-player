
-- SongPlayers are responcible for actualy playing the Song. Specificaly, they are in charge of
--
-- 1. Managing various event loops
-- 2. Dispatching instructions to instruments
-- 3. Detecting when playback has failed
--    This is done by running a minimal World-Tick event loop just to see if the primary events have stopped responding.
-- 4. Managing and detecting instruments
-- 5. Displaying info text about playback
--
-- When creating a song player, you are actualy given a SongPlayerController.
-- This keeps the internal functions and data safe and, but still gives you plenty of control.



-- TODO: A good chunk of this file is just for gathering instruments. Can that be its own script?

---@type InstrumentName -- An instrument that will allways exist so long as the avatar is loaded.
local fallback_normal_instrument_name = "MC/Harp"
---@type InstrumentName -- An instrument that will allways exist so long as the avatar is loaded.
local fallback_percussion_instrument_name = "Percussion"

---@type InstrumentName
local default_normal_instrument_name = "Triangle Sine"
---@type InstrumentName
local default_percussion_instrument_name = "Percussion"

local do_debug_prints = false

--- Logs a message to the console. But if do_debug_prints is true, it also logs to chat. Use do_debug_prints=true to debug viewers.
---@param message string
---@param is_warning boolean?
---@param allways_log boolean?
local function print_debug(message, is_warning, allways_log)
    if do_debug_prints then print(message) end
    if do_debug_prints or allways_log then
        if is_warning then
            host:warnToLog(message)
        else
            host:writeToLog(message)
        end
    end
end
local function printTable_debug(...) if do_debug_prints then printTable(...) end end
local function print_host(...) if host:isHost() or do_debug_prints then print(...) end end


---@class Instruction
---
--- All instructions belong to a track. Tracks connect an instruction and its modifiers to an instrument. The song_player config system lets us select what instrument to use for each track.
---
--- There are some special exceptions
---
--- - Track `0` is for song-level meta events, like tempo change. When track == 0, the note number and modifiers table might have other exceptions.
--- - Track `nil` is reserved for packet encodeing/decodeing. This allows not modifiers to be stored sepperately from their instructions, and recognized as modifiers. It should not appear as a real track.
---@field track_index integer
---@field start_time number         An absolute time in ms from the start of the song.
---@field start_velocity number     The initial velocity (volume) of the note.
---@field duration number           The amount of time this instruction is active for. May be 0.
---@field note number               The note to play, or ID of a meta event
---@field modifiers InstructionModifier[]
---@field meta_event_data table<string, integer>? Only for use with track 0 meta instructions.

---@class InstructionModifier
---@field start_time number     an absolute time in ms from the start of the song. (not start of instruction)
---@field type string           a string like "pitch", "volume", "pan", that tells us what this modifier controlls.
---@field value number          the strength of this modifier


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
local function get_all_instruments()
    for _, script in ipairs(listFiles("./instruments", true)) do
        local found_instrument_builder_list
        local success, value = pcall(function()
            found_instrument_builder_list = require(script)
        end)
        if not success then
            print_debug(
                "Error: Failed to require the script `"
                    ..script
                    .."` found in the `instruments` folder. Full error below:\n\n"
                    ..tostring(value),
                true
            )
            break
        end

        if type(found_instrument_builder_list) ~= "table" then
            print_debug("The `"..script.."` script did not return a list of instruments.", true)
            break
        end

        for _, found_instrument_builder in ipairs(found_instrument_builder_list) do
            if not (
                        found_instrument_builder.name
                    and (found_instrument_builder.is_available ~= nil)
                    and found_instrument_builder.new_instance
                )
            then
                print_debug(
                    "An instrument was found in the `"
                        .. tostring(script)
                        .."` script, but it doesn't look like an instrument.",
                    true
                )
                break
            end

            if known_instruments[found_instrument_builder.name] then
                print_debug(
                    "Instrument `"
                        .. tostring(found_instrument_builder.name)
                        .. "` is already in known_instruments list",
                    true
                )
                break
            end

            if reserved_instrument_names[string.lower(found_instrument_builder.name)] then
                print_debug(
                    "Instrument `"
                        .. tostring(found_instrument_builder.name)
                        .. "` is useing a reserved name instrument name"
                    , true
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
---@field hide_in_world_info boolean?           Configures if song info should be displayed in the world.
---@field primary_update_event_key string?      See `events:getEvents()`. Defaults to "RENDER." Usefull for playing a song with a player_skull instead of the real avatar.
---@field fallback_update_event_key string?     See `events:getEvents()`. Defaults to "TICK."
---
-- --- Auto stop is important if the song is comming from the player entity.
-- --- Without it, whenever the player is unloaded (eg goes through a nether portal), any running music will freeze and
-- --- drone on continualy until the the events start again, or the avatar is reloaded.
-- --- Only set this to `false` for controlled environments.
-- ---@field auto_stop_if_update_events_fail boolean?

local spinner_states = {[0] = "▙",[1] = "▛",[2] = "▜",[3] = "▟",}   -- indexed by 0 saves instructions in get_spinner. Be carefull if getting length.

---returns a spinner synced to the current time.
---@return string
local function get_spinner()
    return spinner_states[
        math.floor(
            client.getSystemTime()
            /750    -- rescale. `/1000` would get this in seconds
            %1      -- Clamp to 0-1
            *4      -- Scale to 0-3
        )           -- Clamp to whole number
    ]
end

local progress_bar_character = "▊"  -- the same width as a space in Minecraft's font
if client.compareVersions("1.20", client.getVersion() ) > 0 then
	progress_bar_character = "▍"	-- 1.20 updated a lot of Minecraft's fonts. Use this character instead if we are on a pre-1.20 version of Minecraft
end

---Returns a progress bar with a spinner
---@param width integer     -- Width in number of characters
---@param progress number   -- Will be clamped to between 0 and 1.
---@return string
local function progress_bar(width, progress)
    if progress < 0 then progress = 0 elseif progress > 1 then progress = 1 end

	local num_bars = math.floor((width+1) * progress)
	local progress_bar_string = "▎" .. string.rep(progress_bar_character, num_bars) .. (num_bars <= width and get_spinner() or "") .. string.rep(" ", math.max(0, width - num_bars)) .. "▎"
	return progress_bar_string  -- As it turns out, Lua actualy optimizes this declare, set, return pattern into the same number of instructions as just returning and skipping the local part.
end

---@param song_player SongPlayer
---@return boolean
local function client_is_looking_at_song_player(song_player)
    if host:isHost() then return true end   -- means that, for the host, the display is visible at all times (within the distance range), but no funky behaviors in 3rd person or paperdolls.
    if song_player.source_entity and client:getViewer() then
        local viewer_targeted_entity = client:getViewer():getTargetedEntity()
        if viewer_targeted_entity then
            return viewer_targeted_entity:getUUID() == song_player.source_entity:getUUID()
        end
    end
    local source_pos_in_screen_space = vectors.worldToScreenSpace(song_player.source_pos)
    if      source_pos_in_screen_space.z > 1                -- pos is not behind screen
        and source_pos_in_screen_space.xy:length() < 0.2    -- pos is near center of screen
    then
        return true
    end
    return false
end

--- Runs with the song update loop to keep text up to date (and sometimes update some positions)
---@param song_player SongPlayer
local function update_info_display_text(song_player)
    local squared_distance = (client:getCameraPos() - song_player.source_pos):lengthSquared()

    if squared_distance > 32 or not client_is_looking_at_song_player(song_player) then
        song_player.info_display_root_part:setVisible(false)
        return
    end
    song_player.info_display_root_part:setVisible(true)


    local info_text ---@type string?

    if song_player.controller.is_buffering_or_needs_to_buffer() then
        info_text = song_player.info_display_base_string
            .. "Buffering… " .. tostring(math.floor(1 + (song_player.controller.get_remaining_buffer_time() / 1000)) ) .. "s " .. get_spinner()
            -- There's a moment where song_player.controller.get_remaining_buffer_time returns math.huge and this text just says "Buffering… infs"
            -- We could add an extra state for this rare moment where it could say "Waiting for data…" instead.
    else
        info_text = song_player.info_display_base_string
            .. progress_bar(20, song_player.controller.get_progress())
            .. " " .. tostring(math.floor(1 + (song_player.controller.get_remaining_time() / 1000)) ) .. "s"
    end

    song_player.info_display_text_task:setText(info_text)
end

local configed_instruments_to_apply = {} ---@type table<SongPlayer, {track_config:SongPlayerTrackConfig, new_selection:InstrumentSelection}[]>

--- Use with the `apply_config_update_loop_for_this_player` functions inside `eventualy_apply_configed_instrument`.
---@return boolean? is_done
local function apply_config_instrument_update_loop(song_player)
    if #configed_instruments_to_apply[song_player] <= 0 then
        configed_instruments_to_apply[song_player] = nil
        return true
        -- song_player.controller.remove_update_callback(apply_config_update_loop_for_this_player)
    end

    local list_of_instruments_we_need_to_apply = configed_instruments_to_apply[song_player]
    local to_apply_this_time = table.remove(list_of_instruments_we_need_to_apply)
    local previous_instrument = to_apply_this_time.track_config.selected_instrument
    to_apply_this_time.track_config.selected_instrument =
        known_instruments[to_apply_this_time.new_selection.name]
        .new_instance(to_apply_this_time.new_selection.params)
    if not previous_instrument.is_finished() then
        table.insert(song_player.deprecated_instruments, previous_instrument)
    end
end

---Allows us to apply instruments to a config over time (mitigates overran instruction limits on low.)
---@param song_player SongPlayer
---@param track_config SongPlayerTrackConfig
---@param new_selection InstrumentSelection
local function eventualy_apply_configed_instrument(song_player, track_config, new_selection)
    local config_bundle = {
        track_config = track_config,
        new_selection = new_selection
    }

    if configed_instruments_to_apply[song_player] then -- loop is already running
        table.insert(configed_instruments_to_apply[song_player], config_bundle)
    else
        configed_instruments_to_apply[song_player] = {}
        table.insert(configed_instruments_to_apply[song_player], config_bundle)

        local background_process_event = song_player.primary_event

        local function apply_config_instrument_loop_for_this_player()
            local is_done = apply_config_instrument_update_loop(song_player)

            if is_done then
                background_process_event:remove(apply_config_instrument_loop_for_this_player)
                song_player.controller.remove_update_callback(apply_config_instrument_loop_for_this_player)
            end
        end

        apply_config_instrument_loop_for_this_player()  -- manualy call first time. Prevents the start_time=0 notes from useing the wrong instrument.
        background_process_event:register(apply_config_instrument_loop_for_this_player) -- make sure we can continue processing even in background
        song_player.controller.register_update_callback(apply_config_instrument_loop_for_this_player)   -- make sure we'll eventualy process it. (if song plays, we can step.)
    end
end

---Applies config to a SongPlayer
---Used during init, and may be used during playback.
---@param song_player SongPlayer
---@param config SongPlayerConfig
local function apply_config(song_player, config)
    if not config then return end

    -- Update tracks instruments to match selected instruments.
    for track_index, track_config in ipairs(song_player.track_config) do
        local instrument_selection_to_use_instead = nil
        if config.instrument_selections and config.instrument_selections[track_index] then
            instrument_selection_to_use_instead = config.instrument_selections[track_index]
        elseif config.default_normal_instrument and track_config.reccomended_instrument_type == 0 then
            instrument_selection_to_use_instead = config.default_normal_instrument
        elseif config.default_percussion_instrument and track_config.reccomended_instrument_type == 1 then
            instrument_selection_to_use_instead = config.default_percussion_instrument
        end

        if instrument_selection_to_use_instead then
            -- Turns out, calling new_instance() gets very expensive if you have a lot of heavy instruments.
            -- See SSB4 Menu: where there are 3 percussion tracks. if each are set to ChloeSpacedOut Drumkit, then it gets heavy really fast.
            eventualy_apply_configed_instrument(song_player, track_config, instrument_selection_to_use_instead)
        end
    end

    -- Update sound source position

    if config.source_pos then
        song_player.source_pos = config.source_pos
        song_player.source_entity = nil
    end
    if config.source_entity then
        song_player.source_entity = config.source_entity
        if config.source_entity.getPos and config.source_entity:getPos() then
            song_player.source_pos = config.source_entity:getPos(client:getFrameTime()) + vec(0, config.source_entity:getEyeHeight(), 0)
        end
    end

    song_player.info_display_base_string = avatar:getEntityName().." is playing \n\""..song_player.name.."\"\n"

    -- Update info display offsets to match sound positions
    if song_player.source_entity then
        if player:isLoaded() and song_player.source_entity:getUUID() == player:getUUID() then  -- TODO: recover if we have loaded the player entity after the song starts.
            -- source entity is the host. We can use our avatar's atatchment points.

            song_player.info_display_root_part_parent_type = "Model"
            song_player.info_display_root_pos_offset = vectors.vec3(0, player:getEyeHeight(), 0)
            song_player.info_display_text_pos_offset = vectors.vec3(-1 * player:getBoundingBox().x, 0.25, 0)

            song_player.info_display_base_string = ("Playing \""..song_player.name.."\"\n")   -- Shorter name if the host is right there.
        else
            -- entity is not the player, fallback to world positioning

            song_player.info_display_root_part_parent_type = "World"
            song_player.info_display_root_pos_offset = song_player.source_pos     -- update_song should keep this case up to date
            song_player.info_display_text_pos_offset = vectors.vec3(-1 * song_player.source_entity:getBoundingBox().x, 0.25, 0)
        end
    else
        song_player.info_display_root_part_parent_type = "World"
        song_player.info_display_root_pos_offset = song_player.source_pos
        song_player.info_display_text_pos_offset = vectors.vec3(-0.75, 0.25, 0)
    end

    song_player.info_should_be_visible = not config.hide_in_world_info

    if song_player.controller.is_playing() then
        -- The info screens have been created and need to be updated.
        song_player.info_display_root_part:setParentType(song_player.info_display_root_part_parent_type)
        song_player.info_display_root_part:setPos(song_player.info_display_root_pos_offset * 16)
        song_player.info_display_text_task:setPos(song_player.info_display_text_pos_offset * 16)
        song_player.info_display_mute_instructions_text_task:setPos(song_player.info_display_text_task:getPos() + song_player.info_display_mute_instructions_text_pos_offset)

        if config.hide_in_world_info then
            song_player.info_display_root_part:setVisible(false)
        else
            song_player.info_display_root_part:setVisible(true)
        end
    end
end


---@alias TrackID number

---Called by an event loop.
---Dispatches new instructions to instruments based on current system time, and updates all instruments (including deprecated).
---@param song_player SongPlayer
local function update_song(song_player)
    local current_time = client.getSystemTime()

    -- Get sound position.

    if song_player.source_entity then
        song_player.source_pos =
            song_player.source_entity:getPos(client:getFrameTime())
            + vec(0, (song_player.source_entity:getBoundingBox().y * 0.5), 0)

        if song_player.info_display_root_part_parent_type == "World" then
            -- we're useing entity positioning, but our display is useing world space. Update it's positioning to match.
            song_player.info_display_root_pos_offset = song_player.source_pos
            song_player.info_display_root_part:setPos(song_player.info_display_root_pos_offset)
        end
    end

    if song_player.info_should_be_visible then
        update_info_display_text(song_player)
    end


    -- During song_player setup, we already assign a fallback instrument.
    -- This should ensure that all instruments are initilized to something.

    while song_player.next_instruction_index <= #song_player.instructions do
        local this_instruction = song_player.instructions[song_player.next_instruction_index]
        -- The amount of time between the current time, and the time this instruction should have been played.
        -- positive == the instruction is late. 0 == it's right on time. negative == it doesn't need to play yet. ignore if negative.
        local time_since_due = (current_time - song_player.start_time) - this_instruction.start_time
        if time_since_due < 0 then
            -- instruction is not late, we'll take care of it later.
            -- (If all notes are slightly late, then none of the notes are slightly late.)
            break
        end
        if this_instruction.track_index == 0 then   -- this instruction actualy holds song meta data
            -- This meta_data does not impact song playback. But it might hold, for example,
            -- time signature data that other parts of the avatar could sync up to.

            for _, fn in pairs(song_player.on_meta_callback_functions) do
                -- we're just going to trust that whoever wrote this callback function has figured out the meta codes and what they do.
                fn(this_instruction.note, this_instruction.meta_event_data)
            end

            -- Refer to the midi file processor for diffrent note codes and whatever. EG:
            -- - set_tempo = 0x51 → { T = microseconds_per_midi_quarter_note }
            -- - time_signature = 0x58 → { n = numerator, d = denominator }
            -- - -- lyric = 0x05, …
        else
            print_debug(
                tostring(math.floor(song_player.controller.get_progress() * 100)).."%"
                .. " ("..tostring(song_player.next_instruction_index).." / ".. tostring(#song_player.instructions)..") "
                -- , this_instruction
            )
            song_player
                .track_config[this_instruction.track_index]
                .selected_instrument
                .play_instruction(this_instruction, song_player.source_pos, time_since_due)
        end
        song_player.next_instruction_index = song_player.next_instruction_index + 1
    end

    -- All new instructions dispatched. Updating instruments.

    local all_instruments_done = true
    for _, track_config in ipairs(song_player.track_config) do
        track_config.selected_instrument.update_sounds(song_player.source_pos)
        if all_instruments_done then
            all_instruments_done = track_config.selected_instrument.is_finished()
            -- will either continue being true, or this instrument is not done.
        end
    end

    -- Check and update deprecated instruments
    if next(song_player.deprecated_instruments) then
        local finished_deprecated_instrument_keys = {}
        for deprecated_instrument_key, deprecated_instrument in pairs(song_player.deprecated_instruments) do
            deprecated_instrument.update_sounds(song_player.source_pos)
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
            song_player.deprecated_instruments[key_to_remove] = nil
        end
    end

    -- Run any on-update callback functions
    local function_index = 1
    while function_index <= #song_player.on_update_callback_functions do
        local fn = song_player.on_update_callback_functions[function_index]
        local success, value = pcall(fn, song_player.controller)
        if not success then
            ---@cast value string
            print_debug("on_update_callback function "..function_index.." ("..tostring(fn)..") errored.\n"..value, true, true)
            print_debug("Removeing this function from update list.")
            table.remove(song_player.on_update_callback_functions, function_index)
        else
            function_index = function_index + 1
        end
    end

    if song_player.song_duration + song_player.start_time < current_time then
        print_debug("Song_dur + start_time is now less than current time.")
        if all_instruments_done then
            song_player.controller.stop()
            return
        else
            print_debug("Song should stop, but not all instruments are done.")
        end
    end
end

---Gets the earliest possible start time for this song. Will return client:getSystemTime() if past the minimum buffer time.
---@param song_player SongPlayer
---@return number get_earliest_possible_start_time
local function get_earliest_possible_start_time(song_player)
    local earliest_possible_start_time = (
            song_player.buffer_delay
        and song_player.buffer_start_time   -- might be math.huge if song has not received its first instruction.
        and ( song_player.buffer_start_time + song_player.buffer_delay )
        or  client:getSystemTime()
    )
    return (earliest_possible_start_time > client:getSystemTime() and earliest_possible_start_time or client:getSystemTime() )
end

---@class SongPlayerAPI
local song_player_api = {
    --- Create a new SongPlayer and return its SongPlayerController.
    ---
    --- Song players are created per-song. Configs can be updated later with set_new_config(), but each player is responcible for one song.
    ---@type fun(song: Song, config: SongPlayerConfig?): SongPlayerController
    new_player = function (song, config)
        if not config or (not next(config)) then config = {} end
        print_debug("New player for `" .. song.name.."`")
        local song_player

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
            update_song(song_player)
        end

        local watcher_state_key = "idle"
        local emergency_stop_instrument_key_for_next = nil
        local emergency_stop_callback_function_key_for_next = nil

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
                song_player.primary_event:remove(update_this_song)
                song_player.primary_event:register(test_primary_loop)
                song_player.fallback_event:register(update_this_song)
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
                song_player.fallback_event:remove(update_this_song)
                song_player.primary_event:remove(test_primary_loop)
                song_player.primary_event:register(update_this_song)
                watcher_state_key = "check_primary"
            end,


            begin_emergency_stop = function()
                print_debug("The primary and fallback events for song `"..song_player.name.."` are not responding. Starting emergency stop.", true, true)
                song_player.fallback_event:remove(update_this_song)
                song_player.primary_event:remove(update_this_song)
                song_player.start_time = nil
                song_player.elapsed_time = nil
                using_fallback_event = false
                watcher_state_key = "emergency_stop_active_instruments"
            end,
            emergency_stop_active_instruments = function()
                -- run through all tracks, kill running notes one at a time untill all are done.
                local key, track = next(song_player.track_config, emergency_stop_instrument_key_for_next)
                if key then
                    if track.selected_instrument.is_finished() then
                        -- advance the "next()" loop for next time.
                        emergency_stop_instrument_key_for_next = key
                    else
                        track.selected_instrument.stop_one_sound_immediatly()
                    end
                else
                    -- key is nil, we've reached the end of the list
                    emergency_stop_instrument_key_for_next = nil
                    watcher_state_key = "emergency_stop_deprecated_instruments"
                end
            end,
            emergency_stop_deprecated_instruments = function()
                -- run through deprecated_instruments, kill running notes one at a time untill all are done.
                local key, instrument = next(song_player.deprecated_instruments, emergency_stop_instrument_key_for_next)
                if key then
                    if instrument.is_finished() then
                        -- advance the "next()" loop for next time.
                        emergency_stop_instrument_key_for_next = key
                    else
                        instrument.stop_one_sound_immediatly()
                    end
                else
                    -- key is nil, we've reached the end of the list
                    emergency_stop_instrument_key_for_next = nil
                    watcher_state_key = "emergency_info_display_remove_parts"
                end
            end,

            emergency_info_display_remove_parts = function()
                -- I'm pretty sure that the info display is one of the few things that,
                -- if we crash, will be left behind. So we need to clean it up carefully.

                if song_player.info_display_root_part then
                    -- song_player.info_display_text_task:remove()
                    -- song_player.info_display_mute_instructions_text_task:remove()
                    -- song_player.info_display_billboard_part:remove()
                    song_player.info_display_root_part:remove()     -- pretty sure that removeing the root part cascades to its children. We can save a bunch of instructions by just removeing root.

                else    -- huh. info display root is nil. Maybe it was never set? Either way we can skip all the way to the stop functions part.
                    watcher_state_key = "emergency_run_stop_functions"
                    return
                end
                watcher_state_key = "emergency_info_display_nil_parts"
            end,

            emergency_info_display_nil_parts = function()
                if song_player.info_display_root_part then
                    song_player.info_display_text_task = nil
                    song_player.info_display_mute_instructions_text_task = nil
                    song_player.info_display_billboard_part = nil
                    song_player.info_display_root_part = nil
                end
                watcher_state_key = "emergency_run_stop_functions"
            end,

            emergency_run_stop_functions = function()
                -- there's a really good chance that calling these stop functions will over run the resource limits (we're useing the world tick event to do these after all.)
                -- But since we're passing the stop reason to the caller, I think it's safe to just let them deal with not crashing.

                local key, fn = next(song_player.on_stop_callback_functions, emergency_stop_callback_function_key_for_next)
                if key then
                    fn("emergency")
                    emergency_stop_instrument_key_for_next = key
                else
                    -- key is nil, we've reached the end of the list
                    emergency_stop_instrument_key_for_next = nil



                    -- finaly at the end of the emergency functions
                    watcher_state_key = "idle"
                    -- TODO: Is there any extra clean up that needs to be done?
                    events.WORLD_TICK:remove(event_watcher_and_swapper)
                    print_debug("Emergency stop for `"..song_player.name.."` complete.", true, true)
                end
            end,
        }

        -- For playback, we don't need to store the names of the reccomended instruments.

        ---@type table<number, SongPlayerTrackConfig>
        local track_configs = {}
        for track_index, track_data in ipairs(song.tracks) do

            ---@class SongPlayerTrackConfig
            local track_config = {

                --- The instrument type provided by the file_processor. 1 == Percussion, 0 = normal.
                ---
                --- Whenever we implement dynamicly loading instruments (where the client and host might not have the same instruments)
                --- this lets us know what instrument we should use instead.
                ---@type 0|1
                reccomended_instrument_type = track_data.instrument_type_id,

                ---@type Instrument
                selected_instrument = known_instruments[
                    -- This selects a reasonable default instrument. We'll overwride this soon when we apply the real song config.
                        (   track_data.instrument_type_id == 1
                            and (known_instruments[default_percussion_instrument_name] and default_percussion_instrument_name or fallback_percussion_instrument_name)
                            or  (known_instruments[default_normal_instrument_name] and default_normal_instrument_name or fallback_normal_instrument_name)
                        )
                    ].new_instance({})
            }
            track_configs[track_index] = track_config
        end

        --- SongPlayer is for internal use. It manages the data and state of a song while it's playing.
        --- Check out SongPlayerController for API-ready functions to manage the song.
        ---@class SongPlayer
        song_player = {
            name = song.name,   ---@type string The name of the song
            song_uuid = client.intUUIDToString(client.generateUUID()),  -- In case we need to create a key or something to address this song.
                    -- TODO: is a full UUID the right choice for this? could we get away with a simple sequence number, then we could send it ?

            ---@type number The total length of the song
            song_duration = song.duration,
            start_time = nil,   ---@type number? Compare with duration. If start time + duration <= current time, then song has ended
            elapsed_time = 0,   ---@type number? Might allow us to pause a song.
                                -- When resuming a song, get current time, subtract elapsed, and that should give a new start time.

            instructions = song.instructions,
            next_instruction_index = 1,

            --- If this song is being built from pings, this is amount of time it takes for the required amount of packets to arrive from the Host
            ---@type number
            buffer_delay = (song.buffer_delay or nil),

            --- The client time when the song started buffering. Compare with current time and buffer_delay
            --- to see if we've received enough packets to play this song in full.
            ---@type number
            buffer_start_time = (song.buffer_start_time or (song.buffer_delay and math.huge) or nil),

            source_entity = nil,    ---@type Entity? If this is defined, overwrite source_pos every update()
            source_pos = vec(0,0,0),    ---@type Vector3

            info_display_root_part = nil,               ---@type ModelPart?     A world-space positioning
            info_display_billboard_part = nil,          ---@type ModelPart?     should not be manualy positioned. Only for rotation
            info_display_text_task = nil,               ---@type TextTask?      A faux screenspace positioning (since it's a child of the billboard part)
            info_display_mute_instructions_text_task = nil,     ---@type TextTask?

            info_display_root_pos_offset = vec(0,0,0),      ---@type Vector3        -- in block space. Divide by 16 to get model space.
            info_display_text_pos_offset = vec(0,0,0),      ---@type Vector3        -- in block space. Divide by 16 to get model space.
            info_display_mute_instructions_text_pos_offset = vectors.vec3(0, 1.7, 0),  -- Just enough vertical offset for the mute info text to appear above them main text.
            info_display_root_part_parent_type = "World",   ---@type ModelPart.parentType
            info_display_base_string = avatar:getEntityName().." is playing \""..song.name.."\"\n",    ---@type string   -- A base name to reduce the amount of things we need to update when rendering the info text

            info_should_be_visible = true,

            ---@type Event
            primary_event = events:getEvents()[(config.primary_update_event_key or "RENDER")],

            ---@type Event
            fallback_event = events:getEvents()[(config.fallback_update_event_key or "TICK")],

            --- List of Instrument that were use at some point during this song, but have since been swapped out for other instruments.
            --- If they are still playing notes, put them here so that we can close them properly if needed.
            ---@type Instrument[]
            deprecated_instruments = {},

            ---@type SongPlayerTrackConfig[]
            track_config = track_configs, -- SongPlayerTrackConfig

            on_update_callback_functions = {},  ---@type fun()[]
            on_stop_callback_functions = {},    ---@type fun(stop_reason:SongPlayerStopReason)[]
            on_meta_callback_functions = {},    ---@type fun(event_code:integer, meta_event_data:table<string, integer>)[]

            ---@class SongPlayerController
            controller = {
                ---@type fun():boolean
                is_playing = function() return (song_player.start_time and true or false) end,

                ---@type fun()
                play = function()
                    print_host("Playing \"" .. tostring(song.name) .. "\"")
                    if song_player.controller.is_playing() then return end

                    -- Info display building and setup

                    song_player.info_display_root_part = models:newPart("song_info_text_root_"..tostring(song_player.song_uuid))
                    song_player.info_display_root_part
                        :setParentType(song_player.info_display_root_part_parent_type)
                        :setPos(song_player.info_display_root_pos_offset * 16)
                        :setVisible(song_player.info_should_be_visible)

                    song_player.info_display_billboard_part = song_player.info_display_root_part:newPart("song_info_text_billboard_"..tostring(song_player.song_uuid), "Camera")

                    song_player.info_display_text_task = song_player.info_display_billboard_part:newText("song_info_text_task_"..tostring(song_player.song_uuid))
                    song_player.info_display_text_task
                        :setPos(song_player.info_display_text_pos_offset * 16)
                        :setText(song_player.info_display_base_string)
                        :setScale(0.25)
                        :setOpacity(0.8)
                        :setWidth(200)
                        :setSeeThrough(true)
                        :setShadow(true)

                    song_player.info_display_mute_instructions_text_task = song_player.info_display_billboard_part:newText("song_info_mute_instructions_text_task_"..tostring(song_player.song_uuid))
                    song_player.info_display_mute_instructions_text_task
                        :setPos(song_player.info_display_text_task:getPos() + song_player.info_display_mute_instructions_text_pos_offset)
                        :setScale(0.15)
                        :setOpacity(0.5)
                        :setSeeThrough(true)
                        :setText("Annoyed? Permissions, "..avatar:getEntityName()..", ∧, Avatar Sounds Volume") -- ", :mute:"


                    -- Initilize "playing" state

                    song_player.start_time = get_earliest_possible_start_time(song_player)
                    song_player.next_instruction_index = 1

                    -- Kick off update loops

                    primary_event_checks_without_update = 0
                    fallback_event_checks_without_update = 0

                    events.WORLD_TICK:register(event_watcher_and_swapper)
                    watcher_state_key = "check_primary"
                    song_player.primary_event:register(update_this_song)
                end,

                ---@type fun():boolean
                is_buffering_or_needs_to_buffer = function()
                    return (song_player.buffer_delay
                        and song_player.buffer_start_time
                        and (song_player.buffer_start_time + song_player.buffer_delay > client:getSystemTime())
                    )
                end,

                ---@type fun():number
                get_remaining_buffer_time = function()
                    if not song_player.buffer_delay or song_player.buffer_delay == 0 then return 0 end
                    if not song_player.buffer_start_time then return math.huge end
                    return song_player.buffer_delay - (client:getSystemTime() - song_player.buffer_start_time)
                end,

                ---@type fun():number?
                get_buffer_progress = function()
                    if not song_player.buffer_delay or song_player.buffer_start_time then return nil end
                    return math.min(1, (client.getSystemTime() - song_player.buffer_start_time) / song_player.buffer_delay)
                end,

                ---@type fun():number?
                get_progress = function()
                    if not song_player.start_time then return nil end
                    return (client.getSystemTime() - song_player.start_time) / song_player.song_duration
                end,

                ---@type fun():number?
                get_start_time = function()
                    if not song_player.start_time then return nil end
                    return song_player.start_time
                end,

                ---@type fun():number?
                get_duration = function()
                    if not song_player.song_duration then return nil end
                    return song_player.song_duration
                end,

                ---@type fun():number?
                get_remaining_time = function()
                    if not song_player.start_time then return nil end
                    return song_player.song_duration - (client:getSystemTime() - song_player.start_time)
                end,

                ---@type fun()
                stop = function()
                    print_host("Stopping \"".. tostring(song.name) .."\"")

                    -- Shut down player.

                    -- song_player.elapsed_time = client.getSystemTime() - song_player.start_time
                    song_player.elapsed_time = nil
                    song_player.start_time = nil

                    -- REmove events and reset the watcher to initial state.

                    song_player.primary_event:remove(update_this_song)
                    song_player.fallback_event:remove(update_this_song)
                    events.WORLD_TICK:remove(event_watcher_and_swapper)
                    watcher_state_key = "idle"
                    primary_event_checks_without_update = 0
                    fallback_event_checks_without_update = 0

                    -- Instrument Cleanup. If stop() called by update loop, then all instruments should already be done.

                    for _, track in pairs(song_player.track_config) do
                        track.selected_instrument.stop_all_sounds_immediatly()
                    end
                    for key, deprecated_instruments in pairs(song_player.deprecated_instruments) do
                        deprecated_instruments.stop_all_sounds_immediatly()
                        song_player.deprecated_instruments[key] = nil
                    end

                    -- Reset the info display.

                    if song_player.info_display_root_part then
                        song_player.info_display_text_task:remove()
                        song_player.info_display_mute_instructions_text_task:remove()
                        song_player.info_display_billboard_part:remove()
                        song_player.info_display_root_part:remove()

                        song_player.info_display_text_task = nil
                        song_player.info_display_mute_instructions_text_task = nil
                        song_player.info_display_billboard_part = nil
                        song_player.info_display_root_part = nil

                        -- TODO: surely there's a more compressed way to build/store/deconstruct all of this
                    end

                    -- Call stop functions

                    for _, fn in ipairs(song_player.on_stop_callback_functions) do
                        fn("normal")
                    end

                end,

                ---@type fun(new_config: SongPlayerConfig)
                set_new_config = function(new_config)
                    apply_config(song_player, new_config)
                end,

                ---@type fun(call_back: fun(stop_reason:SongPlayerStopReason))
                register_stop_callback = function(call_back)
                    ---@alias SongPlayerStopReason "emergency"|"normal"
                    table.insert(song_player.on_stop_callback_functions, call_back)
                end,

                ---@type fun(call_back: fun(stop_reason:SongPlayerStopReason))
                remove_stop_callback = function(call_back_to_remove)
                    for k, fn in pairs(song_player.on_stop_callback_functions) do
                        if fn == call_back_to_remove then
                            table.remove(song_player.on_stop_callback_functions, k)
                            return
                        end
                    end
                    print_debug("Callback "..tostring(call_back_to_remove).." not found in stop_callbacks list", true, true)
                end,


                ---@type fun(call_back: fun()))
                register_update_callback = function(call_back)
                    table.insert(song_player.on_update_callback_functions, call_back)
                end,

                ---@type fun(call_back: fun()))
                remove_update_callback = function(call_back_to_remove)
                    for k, fn in pairs(song_player.on_update_callback_functions) do
                        if fn == call_back_to_remove then
                            table.remove(song_player.on_update_callback_functions, k)
                            return
                        end
                    end
                    print_debug("Callback "..tostring(call_back_to_remove).." not found in update_callbacks list", true, true)
                end,


                ---@type fun(call_back: fun(event_code:integer, meta_event_data:table<string, integer>)))
                register_meta_event_callback = function(call_back)
                    table.insert(song_player.on_meta_callback_functions, call_back)
                end,

                ---@type fun(call_back: fun(event_code:integer, meta_event_data:table<string, integer>)))
                remove_meta_event_callback = function(call_back_to_remove)
                    for k, fn in pairs(song_player.on_meta_callback_functions) do
                        if fn == call_back_to_remove then
                            table.remove(song_player.on_meta_callback_functions, k)
                            return
                        end
                    end
                    print_debug("Callback "..tostring(call_back_to_remove).." not found in meta_event_callbacks list", true, true)
                end,
            }
        }
        apply_config(song_player, config)

        if       song_player.buffer_delay
            and (song_player.buffer_start_time == math.huge)
            and (#song_player.instructions == 0)
        then -- this song needs to buffer, but that not started yet. Add a metatable that updates buffer_start_time (and start_time) when we receive the first instruction.
            setmetatable(song_player.instructions, {
                __newindex = function(table, index, value)
                    setmetatable(song_player.instructions, nil) -- Remove the metamethod after the first write. Technicaly this will burn all metamethods on `.instructions`, but this is the only one, so… probably fine.
                    table[index] = value                        -- set the index _after_ removeing the metamethod so that this isn't recursive
                    song_player.buffer_start_time = client:getSystemTime()
                    if song_player.controller.is_playing() then
                        song_player.start_time = get_earliest_possible_start_time(song_player)
                    end
                end
            })
        end

        return song_player.controller
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

    ---@param instrument_key string
    ---@return InstrumentBuilder?
    get_instrument_builder = function(instrument_key)
        return known_instruments[instrument_key]
    end
}




return song_player_api
