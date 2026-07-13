
-- See https://github.com/ChloeSpacedOut/figura-midi-player/tree/main/ChloesMidiPlayerCloud

-- There have been one too many times where I want to use the figura Piano and there just isn't one nearby.
-- So let's do it for real. Let's just use the midi cloud directly.


---@type UUID
local chloe_player_uuid = "c0cfded1-a213-47d5-8054-94437f4fb906"



-- Trick viewer into loading the midi cloud by attaching it the player head as an idem to the avatar.

local chloe_player_uuid_table = {}  ---@type integer[]
chloe_player_uuid_table[1],chloe_player_uuid_table[2],chloe_player_uuid_table[3],chloe_player_uuid_table[4] = client.uuidToIntArray(chloe_player_uuid)

local chloe_player_head_item = world.newItem(
    [=[minecraft:player_head{display:{Name:'{"text":"midiHead"}'},SkullOwner:{Id:[I;]=]
        ..chloe_player_uuid_table[1]..","..chloe_player_uuid_table[2]..","
        ..chloe_player_uuid_table[3]..","..chloe_player_uuid_table[4]
        ..[=[]}}]=]
)
local chloe_player_head_task = models:newItem("chloe_midi_player_head") -- attaches to user's feet.
chloe_player_head_task:setItem(chloe_player_head_item):setScale(0)




-- ripped from Midi Cloud's list of samples.
-- Some samples (like 2 and 3) are missing because cloud reuses another sample for them
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
    [129] = true
}

local default_fallback_instrument = "Triangle Sine"

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
    return world.avatarVars()[chloe_player_uuid]
end

---@return ChloeFiguraMidiCloudInstance?
local function get_midi_instance()
    local midi_cloud_avatar_vars = get_midi_avatar_vars()
    if midi_cloud_avatar_vars == nil then return nil end

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
    is_midi_cloud_available_next_allowed_check_time = client.getSystemTime() + 20

    local test_midi_cloud_instance = get_midi_instance()

    if test_midi_cloud_instance then
        test_midi_cloud_instance:remove()
        test_midi_cloud_instance = nil
        is_midi_cloud_available_last_result = true
        return is_midi_cloud_available_last_result
    end

    is_midi_cloud_available_last_result = false
    return is_midi_cloud_available_last_result
end





local midi_instance = get_midi_instance()
local midi_api = midi_instance.midi

-- spawn our own channel

local my_chanel_id = 32 -- midi caps out at 16 channels, but there's no such limit here. Using a big number means we avoid hard-coded channel rules like 9==percussion (when counting from 0)
local new_channel = midi_api.channel:new(midi_instance, my_chanel_id)
midi_instance.channels[my_chanel_id] = new_channel       -- for whatever reason, chloe's script doesn't do this for us

-- Set the channel's instrument

midi_instance.channels[my_chanel_id].instrument = 10

-- Init the note

local test_note = midi_api.note:play(
    midi_instance,
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
test_note.sound:setPitch(test_note.soundPitch)  -- Midi cloud doesn't immediately catch this change (Feels like its updates are running on world TICK, while we usually run on RENDER??). Manually setting the pitch ourselves ensures it updates immediatly.

-- Set a release time.

test_note:release(client.getSystemTime() + 100) -- TODO: is there a meaningful difrence between calling release for the future, and waiting until the right time and calling release then?



-- TODO: Figure out volume control
-- Unlike pitch, the midi api manipulates volume to do decays and stuff.
-- Does it take in changes to test_note.velocity?



-- Check when done (We need to keep track of notes so that we can pitch bend them and stuff. But we need to know when it's OK to let go.)

for note_holder_key, v in pairs(test_note_holder) do
    if v.chloe_note.releaseTime < client.getSystemTime() then
        test_note_holder[note_holder_key] = nil
        test_note = nil
    end
end

-- events.TICK:register(function()
--     print(test_note.releaseTime < client.getSystemTime())    -- Some Instruments (like 10) still clearly decay even after release time.
--     print(test_note.state)                                   -- is set to release immediately after calling `:release()`
-- end)





-- re-use the vanilla instrument's InstrumentBuilder_builder thing to just grab all the instruments at once. (Be careful with percussion.)

local builders_to_return = {}   ---@type InstrumentBuilder[]
for number, name in pairs(cloud_instrument_names) do
    ---@type InstrumentBuilder
    local builder = {
        name = "ChloeMidiCloud: " .. string.format("%03d", number) .. " " .. name,
        sort_priority = -1,
        features = {},
        is_available = is_midi_cloud_available,
        new_instance = function(params)
            ---@type Instrument
            local new_instrument = {
                play_instruction = function (instruction, position, time_since_due)

                end,
                is_finished = function () return true end,
                update_sounds = function (position) end,
                stop_all_sounds_immediately = function () end,
                stop_one_sound_immediately = function () end
            }
            return new_instrument
        end
    }
    table.insert(builders_to_return, builder)
end

-- printTable(builders_to_return)

return builders_to_return
