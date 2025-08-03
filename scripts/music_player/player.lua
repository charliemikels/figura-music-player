---@module "../core"

-- Things player.lua needs to do:
-- 1. Receive a ProcessedSong, or a ProcessedSongStream
-- 2. Start an event loop to watch the current time. Auto-kill the song and loop after durration is met.
-- 3. Every loop tick, check the list of instructions. If there are any new instructions, dispatch them to the relevent instrument.
-- 4. Update each instrument. (They handle things like volume changes and pitch changes when nessesary)
-- 5. Monitor the event loop (use another loop). Dynamicaly switch between high resolution (render) and high reliability (tick) when relevent.
-- 6. Be able to force-stop the song if no events are responding. This should use world tick. use very spearingly.
--    Does not nessesaraly need to stop the song (events might start up again), but it needs to stop currently playing notes.
-- 7. Expose controlls to the caller to start/pause/stop/end the song, and get progress.

---@type InstrumentName An instrument that will allways exist so long as the avatar is loaded.
local fallback_normal_instrument_name = "print"
---@type InstrumentName An instrument that will allways exist so long as the avatar is loaded.
local fallback_percussion_instrument_name = "print"

---A unique string. Instruments loaded from other avatars should be prefixed with their UUID or username or something that won't cause conflicts.
---@alias InstrumentName string

---@class InstrumentBuilder
---@field name InstrumentName
---@field is_available fun():boolean
---@field features table<string, boolean>?
---@field new_instance fun(params: integer[]):Instrument

---@class Instrument
---
--- Queue the given instruction and play it immediatly. Remember to call update_sounds to eventualy stop the instruction.
---@field play_instruction fun(instruction: Instruction, position: Vector3)
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
            print("Error: Failed to require the script `"..script.."` found in the `instruments` folder. Full error below:\n\n"..tostring(value))
        else
            if type(found_instrument_builder_list) ~= "table" then
                print("The `"..script.."` script did not return a list of instruments.")
            else
                for _, found_instrument_builder in ipairs(found_instrument_builder_list) do
                    if      found_instrument_builder.name
                        and found_instrument_builder.is_available
                        and found_instrument_builder.new_instance
                    then
                        if known_instruments[found_instrument_builder.name] then
                            print("instrument `" .. tostring( found_instrument_builder.name) .. "` is already in known_instruments list")
                        else
                            print("Found instrument", found_instrument_builder.name)
                            known_instruments[found_instrument_builder.name] = found_instrument_builder
                        end
                    else
                        print("An instrument was found in the `".. tostring(script) .."` script, but it doesn't look like an instrument.")
                    end
                end
            end
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
---@field source Vector3|Entity
---@field info_display_type string      Configures if/how song info should be displayed in the world.

---Applies config infor to a PlayingSong
---Used during init, and durring playback.
---@param playing_song PlayingSong
---@param config SongPlayerConfig
local function apply_config(playing_song, config)
    if not config then return end

    -- instrument config

    -- During playing_song setup, we already assign a fallback instrument.
    -- This should ensure that all instruments are initilized to something.

    -- Update tracks instruments to match selected instruments.
    for track_index, track_config in ipairs(playing_song.track_config) do
        local instrument_selection_to_use_instead = nil
        if config.instrument_selections and config.instrument_selections[track_index] then
            instrument_selection_to_use_instead = config.instrument_selections[track_index]
        elseif config.default_normal_instrument then        -- TODO: and track is a normal track.
            instrument_selection_to_use_instead = config.default_normal_instrument
        elseif config.default_percussion_instrument then    -- TODO: and track is a percussion track.
            instrument_selection_to_use_instead = config.default_percussion_instrument
        end

        if instrument_selection_to_use_instead then
            local previous_instrument = track_config.selected_instrument
            track_config.selected_instrument = known_instruments[instrument_selection_to_use_instead.name].new_instance(instrument_selection_to_use_instead.params)
            if not previous_instrument.is_finished() then
                table.insert(playing_song.deprecated_instruments, previous_instrument)
            end
        end
    end

    -- TODO: config.source information
    -- TODO: config.info_display_type whatnot
end


---@alias TrackID number

---Called by an event loop.
---Dispatches new instructions to instruments based on current system time, and updates all instruments (including deprecated).
---@param playing_song PlayingSong
local function update_song(playing_song)
    local current_time = client.getSystemTime()
    local source_position = vec(0,60,0)  -- TODO: Replace with the source defined in playingSongConfig or whatever.
    while playing_song.next_instruction_index <= #playing_song.instructions do
        local this_instruction = playing_song.instructions[playing_song.next_instruction_index]
        print(this_instruction)
        if this_instruction.start_time > current_time - playing_song.start_time then
            print("This ain't now")
            break
        end
        playing_song.next_instruction_index = playing_song.next_instruction_index + 1
        if this_instruction.track_index == 0 then
            -- TODO: Track 0 is reserved for meta events like tempo and time signature info.
        else
            playing_song
                .track_config[this_instruction.track_index]
                .selected_instrument
                .play_instruction(this_instruction, source_position)
        end
    end

    -- All new instructions dispatched. Updating instruments.

    local all_instruments_done = true
    for _, track_config in ipairs(playing_song.track_config) do
        track_config.selected_instrument.update_sounds(source_position)
        if all_instruments_done then
            all_instruments_done = track_config.selected_instrument.is_finished()
            -- will either continue being true, or this instrument is not done.
        end
    end

    -- Check and update deprecated instruments
    if #playing_song.deprecated_instruments > 0 then
        local finished_deprecated_instrument_keys = {}
        for deprecated_instrument_key, deprecated_instrument in pairs(playing_song.deprecated_instruments) do
            deprecated_instrument.update_sounds(source_position)
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
end


---@class SongPlayerAPI
local song_player_api = {
    ---@type fun(song: ProcessedSong, config: SongPlayerConfig)
    play_song_local = function (song, config)
        print("Playing", song.name)

        local playing_song
        local playing_song_controller

        -- For playback, we don't need to store the names of the reccomended instruments.

        ---type table<number, PlayingSongTrackConfig>
        local track_configs = {}
        for track_index, track_data in ipairs(song.tracks) do

            ---@class PlayingSongTrackConfig
            local track_config = {

                ---@type Instrument
                selected_instrument = known_instruments[
                        (   track_data.instrument_type_id == 1
                            and fallback_percussion_instrument_name
                            or  fallback_normal_instrument_name
                        )
                    ].new_instance({})
            }
            track_configs[track_index] = track_config
        end
        printTable(track_configs)

        ---@class PlayingSong
        playing_song = {
            ---@type string The name of the song
            name = song.name,
            song_uuid = client.intUUIDToString(client.generateUUID()),  -- In case we need to create a key or something to address this song.
                    -- TODO: is a full UUID the right choice for this? could we get away with a simple sequence number, then we could send it ?

            ---@type number The total length of the song
            song_durration = song.durration,
            start_time = nil,   -- Compare with durration. If start time + durration <= current time, then song has ended
            elapsed_time = 0,   -- Might allow us to pause a song.
                                -- When resuming a song, get current time, subtract elapsed, and that should give a new start time.
            instructions = song.instructions,
            next_instruction_index = 1,

            --- List of Instrument that were use at some point during this song, but have since been swapped out for other instruments.
            --- If they are still playing notes, put them here so that we can close them properly if needed.
            ---@type Instrument[]
            deprecated_instruments = {},

            ---@type PlayingSongTrackConfig[]
            track_config = track_configs, -- PlayingSongTrackConfig
        }

        apply_config(playing_song, config)

        playing_song.start_time = client.getSystemTime()
        update_song(playing_song)
    end
}

return song_player_api
