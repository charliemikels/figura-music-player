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


---A unique string. Instruments loaded from other avatars should be prefixed with their UUID or username or something that won't cause conflicts.
---@alias InstrumentName string

---@class InstrumentBuilder
---@field name InstrumentName
---@field is_available fun():boolean
---@field features table<string, boolean>?
---@field new_instance fun():Instrument

---@class Instrument
---
--- Queue the given instruction and play it immediatly. Remember to call update_sounds to eventualy stop the instruction.
---@field play_instruction fun(instruction: Instruction)
---@field update_sounds fun(position: Vector3)
---
--- For use with an emergency stop feature. In this case, we will likely need to use a world tick loop to stop the song.
--- At low permissions, we only have a handfull of instructions, and so we can't just call every sound to stop it,
--- We might need to go one at a time
---@field stop_one_sound_immediatly fun()
---
--- For when the user chooses to stop a song.
---@field stop_all_sounds_immediatly fun()


---@type table<InstrumentName, InstrumentBuilder>
local known_instruments = {}

local function get_all_instruments()
    for _, script in ipairs(listFiles("./instruments", true)) do
        local found_instruments
        local success, value = pcall(function()
            found_instruments = require(script)
        end)
        if not success then
            print("Error: Failed to require the script `"..script.."` found in the `instruments` folder. Full error below:\n\n"..tostring(value))
        else
            if type(found_instruments) ~= "table" then
                print("The `"..script.."` script did not return a list of instruments.")
            else
                for _, found_instrument in ipairs(found_instruments) do
                    if      found_instrument.name
                        and found_instrument.is_available
                        and found_instrument.new_instance
                    then
                        if known_instruments[found_instrument.name] then
                            print("instrument `" .. tostring( found_instrument.name) .. "` is already in known_instruments list")
                        else
                            print("Found instrument", found_instrument.name)
                            known_instruments[found_instrument.name] = found_instrument
                        end
                    else
                        print("An instrument was found in the `".. tostring(script) .."` script, but it doesn't look like an instrument.")
                    end
                end
            end
        end
    end
end
get_all_instruments()
printTable(known_instruments)
get_all_instruments()
printTable(known_instruments)




---@class SongPlayerConfig
---@field default_normal_instrument InstrumentID    -- Shorthand to apply the same instrument to all tracks
---@field default_percussion_instrument InstrumentID    -- Shorthand to apply the same instrument to all drum tracks
---@field instrument_selections? table<TrackID, InstrumentID>
---@field source Vector3|Entity
---@field info_display_type string      Configures if/how song info should be displayed in the world.

---Applies config infor to a PlayingSong
---Used during init, and durring playback.
---@param playing_song PlayingSong
---@param config SongPlayerConfig
local function apply_config(playing_song, config)
    if not config then return end

    -- TODO: consider default_normal_instrument and default_percussion_instrument

    if config.instrument_selections then
        local removed_instruments = {}
        for track_index, selection in ipairs(config.instrument_selections) do
            error("TODO: When config changes, adjust ")
            local previous_instrument = playing_song.track_config[track_index].selected_instrument
            if selection ~= previous_instrument then
                playing_song.track_config[track_index].selected_instrument = selection
                table.insert(removed_instruments, previous_instrument)
            end
        end
        -- We've swapped out the track's selected instruments with the ones in the config.
        -- But if a removed instrument is no longer being used, we need to make sure we're still ticking.
        error("TODO: keep track of removed instruments. Build a system that continues to tick them until all their notes have ended.")
        -- Clone instument objects per song, keep them seperate from other pusic processes.
    end
end


---@alias TrackID number

--- Unlike InstrumentName, which is static and linked to the instrument itself. InstrumentID will be defined per-song, and be used
--- to look up a track's instrument.
---
--- TODO: Do we really need both? The song itself will only transfer the instrument ID once. We could get away with strings.
---@alias InstrumentID number



---@class SongPlayerAPI
local song_player_api = {
    ---@type fun(song: ProcessedSong, config: SongPlayerConfig)
    play_song_local = function (song, config)
        print("Playing", song.name)

        local playing_song
        local playing_song_controller

        -- For playback, we don't need to store the names of the reccomended instruments.
        local track_configs = {}
        for track_index, track_data in ipairs(song.tracks) do

            ---@class PlayingSongTrackConfig
            local track_config = {
                ---@type number The instrument type provided by the file_processor. -1 == Percussion.
                reccomended_instrument_type = track_data.recommended_instrument_id,
                    -- TODO: Consider: we could boild this down to just 0 == normal, 1 == Percussion,
                    -- Then use the Config API (???) to define default "normal" and "percussion" instruments.

                ---@type number The ID of the chosen instrument. Populated by SongPlayerConfig.
                selected_instrument = nil
            }
            track_configs[track_index] = track_config
        end
        printTable(track_configs)

        -- Possible instrument structure: {name: string, uuid: tbd, use_for: [midi program numbers this instrumment is suted for] }
        --
        -- If we want to be able to support instruments from other avatars, and have it be entirely dynamic, I think
        -- we'll have to use UUIDs and strings of some sort.
        --
        -- Local instruments can have manualy defined IDs that are guarrentied to allways exist.
        --
        -- "Bridge" instruments that, eg, force Figura Piano to be usable, also will have predictable UUIDs, but not guarrentied to by accessable.
        --
        -- Full dynamic (eg created and hosted by another avatar) can still be assigned a unique ID by either incorporating the host's UUID
        -- and a supplied ID / index / name combo, or Username, or something else. Again, they may not allways exist.
        -- Downside is that these IDs will be very large, because it will be the whole UUID or Username or something, and not just a tiny number.
        --
        -- During playback, fallback to an instrument that explicitly supports the reccomended instrument.
        --
        -- PlayingSong must pair together: Track number, reccomended instrument type (eg, -1 == perc.), and Selected Instrument UUID

        ---@class PlayingSong
        playing_song = {
            name = song.name,
            song_uuid = client.intUUIDToString(client.generateUUID()),  -- In case we need to create a key or something to address this song.
                    -- TODO: is a full UUID the right choice for this? could we get away with a simple sequence number, then we could send it ?
            song_durration = song.durration,
            start_time = nil,   -- Compare with durration. If start time + durration <= current time, then song has ended
            elapsed_time = 0,   -- Might allow us to pause a song.
                                -- When resuming a song, get current time, subtract elapsed, and that should give a new start time.
            instructions = song.instructions,
            next_instruction_index = 1,

            ---@type PlayingSongTrackConfig[]
            track_config = track_configs, -- PlayingSongTrackConfig
        }
        printTable(playing_song)
        -- TODO: apply_config(config)
    end
}

return song_player_api
