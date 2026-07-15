
-- TODO:  As of `v6.0.1-27-g5ff4061`, something I changed killed the original Piano instrument (Where we reach into the piano to do stuff.) (Specifically at least, "radioactive" throws a "Overran resource limits!" error somewhere in the cloud_midi's midiAPI.lua file.)

-- See https://github.com/ChloeSpacedOut/figura-midi-player/tree/main/ChloesMidiPlayerCloud

-- There have been one too many times where I want to use the figura Piano and there just isn't one nearby.
-- So let's do it for real. Let's just use the midi cloud directly.


---@type UUID
local midi_cloud_player_uuid = "c0cfded1-a213-47d5-8054-94437f4fb906"


-- Trick viewer into loading the Midi Cloud by rendering it's player head.
-- Code basically stolen from Figura Piano 2.0. https://github.com/ChloeSpacedOut/figura-piano-2.0/blob/63a8c67be23970b6896c9f7716d28249de030741/Piano%202.0/main.lua#L6-L11

local chloe_player_uuid_table = {}  ---@type integer[]
chloe_player_uuid_table[1],chloe_player_uuid_table[2],chloe_player_uuid_table[3],chloe_player_uuid_table[4] = client.uuidToIntArray(midi_cloud_player_uuid)

local chloe_player_head_item = world.newItem(
    [=[minecraft:player_head{display:{Name:'{"text":"midiHead"}'},SkullOwner:{Id:[I;]=]
        ..chloe_player_uuid_table[1]..","..chloe_player_uuid_table[2]..","
        ..chloe_player_uuid_table[3]..","..chloe_player_uuid_table[4]
        ..[=[]}}]=]
)
local chloe_player_head_task = models:newItem("chloe_midi_player_head") -- attaches to user's feet.
chloe_player_head_task:setItem(chloe_player_head_item):setScale(0)


-- Ripped from Midi Cloud's list of samples.
-- Some samples (like 2 and 3) are missing because cloud reuses another sample for them.
---@type table<integer, string>
local cloud_instrument_names = {
    [001] = "Acoustic Grand Piano",
    [004] = "Honky-tonk Piano",
    [005] = "Electric Piano 1 (Rhodes Piano)",
    [006] = "Electric Piano 2 (Chorused Piano)",
    [007] = "Harpsichord",
    [008] = "Clavinet",
    [009] = "Celesta",
    [010] = "Glockenspiel",
    [011] = "Music Box",
    [012] = "Vibraphone",
    [013] = "Marimba",
    [014] = "Xylophone",
    [015] = "Tubular Bells",
    [016] = "Dulcimer (Santur)",
    [017] = "Drawbar Organ (Hammond)",
    [018] = "Percussive Organ",
    [019] = "Rock Organ",
    [020] = "Church Organ",
    [021] = "Reed Organ",
    [022] = "Accordion (French)",
    [023] = "Harmonica",
    [024] = "Tango Accordion (Band neon)",
    [025] = "Acoustic Guitar (nylon)",
    [026] = "Acoustic Guitar (steel)",
    [027] = "Electric Guitar (jazz)",
    [028] = "Electric Guitar (clean)",
    [029] = "Electric Guitar (muted)",
    [030] = "Overdriven Guitar",
    [031] = "Distortion Guitar",
    [032] = "Guitar harmonics",
    [033] = "Acoustic Bass",
    [034] = "Electric Bass (fingered)",
    [035] = "Electric Bass (picked)",
    [036] = "Fretless Bass",
    [037] = "Slap Bass 1",
    [038] = "Slap Bass 2",
    [039] = "Synth Bass 1",
    [040] = "Synth Bass 2",
    [041] = "Violin",
    [043] = "Cello",
    [044] = "Contrabass",
    [045] = "Tremolo Strings",
    [046] = "Pizzicato Strings",
    [047] = "Orchestral Harp",
    [048] = "Timpani",
    [049] = "String Ensemble 1",
    [050] = "String Ensemble 2",
    [051] = "SynthStrings 1",
    [053] = "Choir Aahs",
    [054] = "Voice Oohs",
    [055] = "Synth Voice",
    [056] = "Orchestra Hit",
    [057] = "Trumpet",
    [058] = "Trombone",
    [059] = "Tuba",
    [060] = "Muted Trumpet",
    [061] = "French Horn",
    [062] = "Brass Section",
    [063] = "SynthBrass 1",
    [064] = "SynthBrass 2",
    [065] = "Soprano Sax",
    [066] = "Alto Sax",
    [067] = "Tenor Sax",
    [068] = "Baritone Sax",
    [069] = "Oboe",
    [070] = "English Horn",
    [071] = "Bassoon",
    [072] = "Clarinet",
    [073] = "Piccolo",
    [074] = "Flute",
    [075] = "Recorder",
    [076] = "Pan Flute",
    [077] = "Blown Bottle",
    [078] = "Shakuhachi",
    [079] = "Whistle",
    [080] = "Ocarina",
    [081] = "Lead 1 (square wave)",
    [082] = "Lead 2 (sawtooth wave)",
    [083] = "Lead 3 (calliope)",
    [084] = "Lead 4 (chiffer)",
    [085] = "Lead 5 (charang)",
    [086] = "Lead 6 (voice solo)",
    [087] = "Lead 7 (fifths)",
    [088] = "Lead 8 (bass + lead)",
    [089] = "Pad 1 (new age Fantasia)",
    [090] = "Pad 2 (warm)",
    [091] = "Pad 3 (polysynth)",
    [092] = "Pad 4 (choir)",
    [093] = "Pad 5 (bowed)",
    [094] = "Pad 6 (metallic)",
    [096] = "Pad 8 (sweep)",
    [097] = "FX 1 (rain)",
    [098] = "FX 2 (soundtrack)",
    [099] = "FX 3 (crystal)",
    [100] = "FX 4 (atmosphere)",
    [101] = "FX 5 (brightness)",
    [102] = "FX 6 (goblins)",
    [103] = "FX 7 (echoes)",
    [104] = "FX 8 (sci-fi, star theme)",
    [105] = "Sitar",
    [106] = "Banjo",
    [107] = "Shamisen",
    [108] = "Koto",
    [109] = "Kalimba",
    [110] = "Bag pipe",
    [111] = "Fiddle",
    [113] = "Tinkle Bell",
    [114] = "Agogo",
    [115] = "Steel Drums",
    [116] = "Woodblock",
    [117] = "Taiko Drum",
    [118] = "Melodic Tom",
    [119] = "Synth Drum",
    [120] = "Reverse Cymbal",
    [121] = "Guitar Fret Noise",
    [122] = "Breath Noise",
    [123] = "Seashore",
    [124] = "Bird Tweet",
    [125] = "Telephone Ring",
    [126] = "Helicopter",
    [127] = "Applause",
    [128] = "Gunshot",
    [129] = "Percussion",
}

local sample_is_non_melodic_lookup = {
    [114] = "Agogo",
    [116] = "Woodblock",
    [119] = "Synth Drum",
    [120] = "Reverse Cymbal",
    [121] = "Guitar Fret Noise",
    [123] = "Seashore",
    [125] = "Telephone Ring",
    [126] = "Helicopter",
    [127] = "Applause",
    [128] = "Gunshot",
    [129] = "Percussion"
}

---@type table<integer, string>     Midi number to instrument name lookup (That's Our, TL Instruments. Not Midi instrument names.)
local fallback_instrument_lookup = {
    [114] = "MC/Hat",
    [116] = "MC/Hat",
    [119] = "MC/Bass Drum",
    [120] = "MC/Hat",
    [121] = "MC/Hat",
    [123] = "MC/Hat",
    [125] = "MC/Bit",
    [126] = "MC/Hat",
    [127] = "MC/Hat",
    [128] = "MC/Hat",
    [129] = "Percussion"
}


---@class ChloeFiguraMidiCloudAvatarVars
---@field newInstance fun(ID:string, target:ChloeFiguraMidiCloudValidInstanceTarget, avatarInstance:AvatarAPI):ChloeFiguraMidiCloudInstance?
---@field listSounds fun():string[]         Wrapper for `sounds:getCustomSounds()`
---@field getSound fun(id:string):Sound   Wrapper for `sounds[id]`
---@field sessionID fun():UUID              The result of `client.generateUUID()`. Unique to this instance of the midi avatar. Can be used to check for reloads.
---@see https://github.com/ChloeSpacedOut/figura-midi-player/blob/63ba8fc46c866d0103df38714bb6c738fc71ce1a/ChloesMidiPlayerCloud/externalAPI.lua#L169-L172



---@return ChloeFiguraMidiCloudAvatarVars?
local function get_midi_avatar_vars()
    return world.avatarVars()[midi_cloud_player_uuid]
end


---@return ChloeFiguraMidiCloudInstance?
local function get_midi_instance()
    local midi_cloud_avatar_vars = get_midi_avatar_vars()
    if midi_cloud_avatar_vars == nil or midi_cloud_avatar_vars.newInstance == nil then return nil end

    local instance_uuid = client.intUUIDToString(client.generateUUID())
    local midi_cloud_instance = midi_cloud_avatar_vars.newInstance(
        instance_uuid,
        vectors.vec3(0,0,0), -- remember to update target during playback.
        avatar
    )
    return midi_cloud_instance
end


local is_midi_cloud_available_next_allowed_check_time = 0   -- used to prevent `is_midi_cloud_available` from running many times every update.
local is_midi_cloud_available_last_result = false

---@return boolean
local function is_midi_cloud_available()
    if client.getSystemTime() < is_midi_cloud_available_next_allowed_check_time then
        return is_midi_cloud_available_last_result
    end
    is_midi_cloud_available_next_allowed_check_time = client.getSystemTime() + 2

    local get_instance_success, test_midi_cloud_instance =  pcall(get_midi_instance)    -- if Cloud Midi's avatar is somehow on low permissions, pcall will catch the "overran resource limit" error

    if get_instance_success and test_midi_cloud_instance then    -- clean up the test instance before giving results.
        ---@cast test_midi_cloud_instance ChloeFiguraMidiCloudInstance
        test_midi_cloud_instance:remove()
        test_midi_cloud_instance = nil
        is_midi_cloud_available_last_result = true
        return is_midi_cloud_available_last_result
    end

    -- Nothing to really cleanup if test failed.
    is_midi_cloud_available_last_result = false
    return is_midi_cloud_available_last_result
end



--[[

local test_midi_instance = get_midi_instance()
local test_midi_api = test_midi_instance.midi

-- spawn our own channel

local my_chanel_id = 32 -- midi caps out at 16 channels, but there's no such limit here. Using a big number means we avoid hard-coded channel rules like 9==percussion (when counting from 0)
local new_channel = test_midi_api.channel:new(test_midi_instance, my_chanel_id)
test_midi_instance.channels[my_chanel_id] = new_channel       -- for whatever reason, chloe's script doesn't do this for us

-- Set the channel's instrument

test_midi_instance.channels[my_chanel_id].instrument = 10

-- Init the note

local test_note = test_midi_api.note:play(
    test_midi_instance,
    60, 90,
    my_chanel_id,
    my_chanel_id,  -- TODO: Due to a bug (see here: https://github.com/ChloeSpacedOut/figura-midi-player/pull/1 ), TrackID should always be in sync with the selected channel.
    client.getSystemTime(),
    vec(6, 58, -17)
)

local test_note_id_for_holder = test_note.pitch .. "_" .. test_note.channel .. "_" .. test_note.track

-- Track pitch bend change

local test_note_holder = {}
test_note_holder[test_note_id_for_holder] = {
    chloe_note = test_note,
    base_pitch_multiplier = test_note.soundPitch,
}

-- initial note pitch-bend.

test_note.soundPitch = test_note_holder[test_note_id_for_holder].base_pitch_multiplier * 1.2
test_note.sound:setPitch(test_note.soundPitch)  -- Midi cloud doesn't immediately catch this change (Feels like its updates are running on world TICK, while we usually run on RENDER??). Manually setting the pitch ourselves ensures it updates immediately.

-- Set a release time.

test_note:release(client.getSystemTime() + 1000) -- TODO: is there a meaningful difference between calling release for the future, and waiting until the right time and calling release then?


-- Volume control

test_note.velocity =  0.02                          -- Like soundPitch, velocity sometimes doesn't update on the very first update, and so the old volume can sometimes still be heard
test_note.sound:setVolume(test_note.velocity)       -- Manually set the volume.
                                                    -- We should only do this when we init the sound.
                                                    -- 1. IDK, but I think the midi cloud messes with the sound's volume to implement do decay and stuff. Don't mess with volume in-flight.
                                                    -- 2. After note initialization, there shouldn't be any crazy, precise-timing required jumps in volume. we can let them be 1 tick late or whatever.

local function test_event_loop()
    test_note.velocity = test_note.velocity * 1.2
    if test_note.releaseTime < client.getSystemTime() then
        events.TICK:remove(test_event_loop)
    end
end
events.TICK:register(test_event_loop)



-- Check when done (We need to keep track of notes so that we can pitch bend them and stuff. But we need to know when it's OK to let go.)

for note_holder_key, v in pairs(test_note_holder) do
    if v.chloe_note.releaseTime < client.getSystemTime() then
        test_note_holder[note_holder_key] = nil
        test_note = nil
    end
end

--]]

--- If cloud drops to too-low of a permission level, calling note:stop() can throw the "overran resources limit" error.
--- This function replicates `note:stop()`'s behavior, but we're doing it ourself.
--- See https://github.com/ChloeSpacedOut/figura-midi-player/blob/63ba8fc46c866d0103df38714bb6c738fc71ce1a/ChloesMidiPlayerCloud/midiAPI.lua#L333
---@param note ChloeFiguraMidiCloudMidiNoteInstance
local function manually_stop_note(note)
    if note.sound then note.sound:stop() end
    if note.loopSound then note.loopSound:stop() end
    note.instance.tracks[note.track][note.pitch] = nil
end

--- Checks if a note is actually done playing by checking its internal sounds.
---@param note ChloeFiguraMidiCloudMidiNoteInstance
---@return boolean
local function is_note_done_for_real(note)
    return not ((note.sound and note.sound:isPlaying()) or (note.loopSound and note.loopSound:isPlaying()))
end

-- re-use the vanilla instrument's InstrumentBuilder_builder thing to just grab all the instruments at once. (Be careful with percussion.)

local builders_to_return = {}   ---@type InstrumentBuilder[]
for instrument_midi_number, instrument_midi_name in pairs(cloud_instrument_names) do
    ---@type InstrumentBuilder
    local builder = {
        name = "ChloeMidiCloud: " .. string.format("%03d", instrument_midi_number) .. " " .. instrument_midi_name,
        sort_priority = -1,
        features = {
            percussion = not (sample_is_non_melodic_lookup[instrument_midi_number] == nil),
            sustain = (sample_is_non_melodic_lookup[instrument_midi_number] == nil),
            pitch_bend = (sample_is_non_melodic_lookup[instrument_midi_number] == nil)
        },
        is_available = is_midi_cloud_available,
        new_instance = function(params)
            local instruments_api = require("../../instruments")  ---@type InstrumentsApi

            local fallback_instrument_builder = instruments_api.get_instrument_builder(fallback_instrument_lookup[instrument_midi_number])
            if not fallback_instrument_builder then
                fallback_instrument_builder = instruments_api.get_default_instrument_builder(
                    sample_is_non_melodic_lookup[instrument_midi_number] and 1 or 0
                )
            end

            local fallback_instrument_instance = fallback_instrument_builder.new_instance({})

            -- TODO: on instrument init (beginning of the song), check `is_midi_cloud_available()`, and if it is not,
            -- spawn a one-time floating bit of text to tell viewers to check if cloud midi has perms.

            local midi_cloud_was_previously_available = false
            local midi_instance = nil               ---@type ChloeFiguraMidiCloudInstance?

            local channel_id = (instrument_midi_number == 129 and 9 or 1)

            local instrument_last_updated_time = client.getSystemTime()     -- Driven by check_availability_and_rebuild_state_if_it_changed.

            -- Returns true if this instrument has not been updated in a while. This function will be given
            -- to the Midi Cloud. Cloud will check this function every update and will handle its own deconstruction
            -- if this function returns true.
            --
            -- Useful in case the Host's avatar crashes, so that Midi Cloud can still clean itself up.
            --
            -- See `instance:setShouldKillInstance()`
            ---@param _ ChloeFiguraMidiCloudInstance
            ---@return boolean
            local function should_kill_instance( _ )

                if client.getSystemTime() > instrument_last_updated_time + 1000 then
                    host:warnToLog("Cloud Midi Instrument: No updates in a while, killing midi instance "..tostring(midi_instance.ID))
                    midi_instance = nil
                    return true
                end
                return false
            end

            -- While I'll be using integer indexing, this table will not be sorted.
            ---@type table<integer, {note: ChloeFiguraMidiCloudMidiNoteInstance, initial_pitch: number}>
            local active_notes = {}


            local function check_availability_and_rebuild_state_if_it_changed()
                instrument_last_updated_time = client.getSystemTime()

                local midi_is_currently_available = is_midi_cloud_available()
                if midi_is_currently_available == midi_cloud_was_previously_available then return end

                if midi_is_currently_available then -- We're online, initialize a fresh instance.
                    midi_instance = get_midi_instance()

                    local channel = midi_instance.midi.channel:new(midi_instance, channel_id)    -- Manually init a channel to set the instrument and avoid surprises.
                    midi_instance.channels[channel_id] = channel       -- for whatever reason, chloe's script doesn't do this for us

                    midi_instance.channels[channel_id].instrument = instrument_midi_number

                    midi_instance:setShouldKillInstance(should_kill_instance)

                else -- We're offline. Cleanup any stuff left over

                    for _, notes_by_pitch in pairs(midi_instance.tracks) do
                        for _, note in pairs(notes_by_pitch) do
                            manually_stop_note(note)
                        end
                    end

                    pcall(function() midi_instance:remove() end)    -- Try to clean up the instance itself. If this fails, the midi player itself should still eventually clean it up when it runs should_kill_instance.
                    midi_instance = nil
                    active_notes = {}
                end

                midi_cloud_was_previously_available = midi_is_currently_available
            end


            ---@type Instrument
            local new_instrument = {
                play_instruction = function (instruction, position, time_since_due)
                    check_availability_and_rebuild_state_if_it_changed()
                    if not is_midi_cloud_available() then
                        fallback_instrument_instance.play_instruction(instruction, position, time_since_due)
                        return
                    end

                    local new_note = midi_instance.midi.note:play(
                        midi_instance,
                        instruction.note,
                        instruction.start_velocity * 0.3 * (avatar:getVolume() / 100),   -- On the whole, the midi instruments are quite a bit louder than our baseline.
                        channel_id,
                        channel_id,  -- TODO: Due to a bug (see here: https://github.com/ChloeSpacedOut/figura-midi-player/pull/1 ), TrackID should always be in sync with the selected channel.
                        client.getSystemTime() - time_since_due,
                        position
                    )

                    new_note:release(new_note.initTime + instruction.duration)
                    table.insert(active_notes, {note = new_note, initial_pitch = new_note.soundPitch})

                    -- TODO: Initial Pitch modifiers
                    -- TODO: Initial Volume modifiers

                    new_note.pos = position
                end,
                is_finished = function ()
                    return #active_notes == 0 and fallback_instrument_instance.is_finished()
                end,
                update_sounds = function (position)
                    check_availability_and_rebuild_state_if_it_changed()
                    fallback_instrument_instance.update_sounds(position)

                    if midi_instance then
                        midi_instance:setTarget(position)

                        for key, active_note in pairs(active_notes) do
                            -- We can safely modify lists inside a pairs loop, so long as we do not add keys.

                            local note = active_note.note
                            note.pos = position
                            for _, sound in pairs({note.sound, note.loopSound}) do
                                if sound then
                                    -- sound:setPos(position)

                                    -- TODO: Pitch
                                    -- TODO: Volume
                                end
                            end

                            if is_note_done_for_real(note) then
                                active_notes[key] = nil
                            end
                        end

                    end

                    -- we don't need to do active_notes cleanup here. It should have been cleared already by check_availability_and_rebuild_state_if_it_changed()

                end,
                stop_all_sounds_immediately = function ()
                    fallback_instrument_instance.stop_all_sounds_immediately()

                    if midi_instance then
                        pcall(function() midi_instance:remove() end)    -- pcall avoids issues where the Cloud Midi permissions drop, or is otherwise being funky
                        midi_instance = nil
                    end

                    for _, active_note in pairs(active_notes) do manually_stop_note(active_note.note) end
                    active_notes = {}
                end,
                stop_one_sound_immediately = function ()
                    fallback_instrument_instance.stop_one_sound_immediately()

                    local key, active_note = next(active_notes)
                    if active_note then
                        manually_stop_note(active_note.note)
                        active_notes[key] = nil
                    elseif key == nil and midi_instance then
                        pcall(function() midi_instance:remove() end)    -- pcall avoids issues where the Cloud Midi permissions drop, or is otherwise being funky
                        midi_instance = nil
                    end
                end
            }
            return new_instrument
        end
    }
    table.insert(builders_to_return, builder)
end

-- printTable(builders_to_return)

return builders_to_return
