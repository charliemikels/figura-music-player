
-- See https://github.com/ChloeSpacedOut/figura-midi-player/tree/main/ChloesMidiPlayerCloud

-- There have been one too many times where I want to use the figura Piano and there just isn't one nearby.
-- So let's do it for real. Let's just use the midi cloud directly.


---@type UUID
local midi_cloud_player_uuid = "c0cfded1-a213-47d5-8054-94437f4fb906"


-- Trick viewer into loading the Midi Cloud by rendering it's player head.
-- Code basically stolen from Figura Piano 2.0. https://github.com/ChloeSpacedOut/figura-piano-2.0/blob/63a8c67be23970b6896c9f7716d28249de030741/Piano%202.0/main.lua#L6-L11

local midi_cloud_player_uuid_table = {}  ---@type integer[]
midi_cloud_player_uuid_table[1],midi_cloud_player_uuid_table[2],midi_cloud_player_uuid_table[3],midi_cloud_player_uuid_table[4] = client.uuidToIntArray(midi_cloud_player_uuid)

local midi_cloud_player_head_item = world.newItem(
    [=[minecraft:player_head{display:{Name:'{"text":"midiHead"}'},SkullOwner:{Id:[I;]=]
        ..midi_cloud_player_uuid_table[1]..","..midi_cloud_player_uuid_table[2]..","
        ..midi_cloud_player_uuid_table[3]..","..midi_cloud_player_uuid_table[4]
        ..[=[]}}]=]
)
local midi_cloud_player_head_task = models:newItem("chloe_midi_player_head") -- attaches to user's feet.
midi_cloud_player_head_task:setItem(midi_cloud_player_head_item):setScale(0)      -- practically invisible, but still renders.


-- Ripped from Midi Cloud's list of samples.
-- Some samples (like 2 and 3) are missing because cloud reuses another sample for them.
---@type table<integer, {name:string, non_melodic:boolean?, fallback_instrument_name:string?}>
local cloud_instruments_number_to_info = {
    [001] = { name = "Acoustic Grand Piano",             },
    [004] = { name = "Honky-tonk Piano",                 },
    [005] = { name = "Electric Piano 1 (Rhodes Piano)",  },
    [006] = { name = "Electric Piano 2 (Chorused Piano)",},
    [007] = { name = "Harpsichord",                      },
    [008] = { name = "Clavinet",                         },
    [009] = { name = "Celesta",                          },
    [010] = { name = "Glockenspiel",                     },
    [011] = { name = "Music Box",                        },
    [012] = { name = "Vibraphone",                       },
    [013] = { name = "Marimba",                          },
    [014] = { name = "Xylophone",                        },
    [015] = { name = "Tubular Bells",                    },
    [016] = { name = "Dulcimer (Santur)",                },
    [017] = { name = "Drawbar Organ (Hammond)",          },
    [018] = { name = "Percussive Organ",                 },
    [019] = { name = "Rock Organ",                       },
    [020] = { name = "Church Organ",                     },
    [021] = { name = "Reed Organ",                       },
    [022] = { name = "Accordion (French)",               },
    [023] = { name = "Harmonica",                        },
    [024] = { name = "Tango Accordion (Band neon)",      },
    [025] = { name = "Acoustic Guitar (nylon)",          },
    [026] = { name = "Acoustic Guitar (steel)",          },
    [027] = { name = "Electric Guitar (jazz)",           },
    [028] = { name = "Electric Guitar (clean)",          },
    [029] = { name = "Electric Guitar (muted)",          },
    [030] = { name = "Overdriven Guitar",                },
    [031] = { name = "Distortion Guitar",                },
    [032] = { name = "Guitar harmonics",                 },
    [033] = { name = "Acoustic Bass",                    },
    [034] = { name = "Electric Bass (fingered)",         },
    [035] = { name = "Electric Bass (picked)",           },
    [036] = { name = "Fretless Bass",                    },
    [037] = { name = "Slap Bass 1",                      },
    [038] = { name = "Slap Bass 2",                      },
    [039] = { name = "Synth Bass 1",                     },
    [040] = { name = "Synth Bass 2",                     },
    [041] = { name = "Violin",                           },
    [043] = { name = "Cello",                            },
    [044] = { name = "Contrabass",                       },
    [045] = { name = "Tremolo Strings",                  },
    [046] = { name = "Pizzicato Strings",                },
    [047] = { name = "Orchestral Harp",                  },
    [048] = { name = "Timpani",                          },
    [049] = { name = "String Ensemble 1",                },
    [050] = { name = "String Ensemble 2",                },
    [051] = { name = "SynthStrings 1",                   },
    [053] = { name = "Choir Aahs",                       },
    [054] = { name = "Voice Oohs",                       },
    [055] = { name = "Synth Voice",                      },
    [056] = { name = "Orchestra Hit",                    },
    [057] = { name = "Trumpet",                          },
    [058] = { name = "Trombone",                         },
    [059] = { name = "Tuba",                             },
    [060] = { name = "Muted Trumpet",                    },
    [061] = { name = "French Horn",                      },
    [062] = { name = "Brass Section",                    },
    [063] = { name = "SynthBrass 1",                     },
    [064] = { name = "SynthBrass 2",                     },
    [065] = { name = "Soprano Sax",                      },
    [066] = { name = "Alto Sax",                         },
    [067] = { name = "Tenor Sax",                        },
    [068] = { name = "Baritone Sax",                     },
    [069] = { name = "Oboe",                             },
    [070] = { name = "English Horn",                     },
    [071] = { name = "Bassoon",                          },
    [072] = { name = "Clarinet",                         },
    [073] = { name = "Piccolo",                          },
    [074] = { name = "Flute",                            },
    [075] = { name = "Recorder",                         },
    [076] = { name = "Pan Flute",                        },
    [077] = { name = "Blown Bottle",                     },
    [078] = { name = "Shakuhachi",                       },
    [079] = { name = "Whistle",                          },
    [080] = { name = "Ocarina",                          },
    [081] = { name = "Lead 1 (square wave)",             },
    [082] = { name = "Lead 2 (sawtooth wave)",           },
    [083] = { name = "Lead 3 (calliope)",                },
    [084] = { name = "Lead 4 (chiffer)",                 },
    [085] = { name = "Lead 5 (charang)",                 },
    [086] = { name = "Lead 6 (voice solo)",              },
    [087] = { name = "Lead 7 (fifths)",                  },
    [088] = { name = "Lead 8 (bass + lead)",             },
    [089] = { name = "Pad 1 (new age Fantasia)",         },
    [090] = { name = "Pad 2 (warm)",                     },
    [091] = { name = "Pad 3 (polysynth)",                },
    [092] = { name = "Pad 4 (choir)",                    },
    [093] = { name = "Pad 5 (bowed)",                    },
    [094] = { name = "Pad 6 (metallic)",                 },
    [096] = { name = "Pad 8 (sweep)",                    },
    [097] = { name = "FX 1 (rain)",                      },
    [098] = { name = "FX 2 (soundtrack)",                },
    [099] = { name = "FX 3 (crystal)",                   },
    [100] = { name = "FX 4 (atmosphere)",                },
    [101] = { name = "FX 5 (brightness)",                },
    [102] = { name = "FX 6 (goblins)",                   },
    [103] = { name = "FX 7 (echoes)",                    },
    [104] = { name = "FX 8 (sci-fi, star theme)",        },
    [105] = { name = "Sitar",                            },
    [106] = { name = "Banjo",                            },
    [107] = { name = "Shamisen",                         },
    [108] = { name = "Koto",                             },
    [109] = { name = "Kalimba",                          },
    [110] = { name = "Bag pipe",                         },
    [111] = { name = "Fiddle",                           },
    [113] = { name = "Tinkle Bell",                      },
    [114] = { name = "Agogo",                            non_melodic = true, fallback_instrument_name = "MC/Hat"},
    [115] = { name = "Steel Drums",                      },
    [116] = { name = "Woodblock",                        non_melodic = true, fallback_instrument_name = "MC/Hat"},
    [117] = { name = "Taiko Drum",                       },
    [118] = { name = "Melodic Tom",                      },
    [119] = { name = "Synth Drum",                       non_melodic = true, fallback_instrument_name = "MC/Bass Drum"},
    [120] = { name = "Reverse Cymbal",                   non_melodic = true, fallback_instrument_name = "MC/Hat"},
    [121] = { name = "Guitar Fret Noise",                non_melodic = true, fallback_instrument_name = "MC/Hat"},
    [122] = { name = "Breath Noise",                     non_melodic = true, fallback_instrument_name = "MC/Hat"},
    [123] = { name = "Seashore",                         non_melodic = true, fallback_instrument_name = "MC/Hat"},
    [124] = { name = "Bird Tweet",                       },
    [125] = { name = "Telephone Ring",                   non_melodic = true, fallback_instrument_name = "MC/Bit"},
    [126] = { name = "Helicopter",                       non_melodic = true, fallback_instrument_name = "MC/Hat"},
    [127] = { name = "Applause",                         non_melodic = true, fallback_instrument_name = "MC/Hat"},
    [128] = { name = "Gunshot",                          non_melodic = true, fallback_instrument_name = "MC/Hat"},
    [129] = { name = "Percussion",                       non_melodic = true, fallback_instrument_name = "Percussion"},
}


--- see https://github.com/ChloeSpacedOut/figura-midi-player/blob/63ba8fc46c866d0103df38714bb6c738fc71ce1a/ChloesMidiPlayerCloud/externalAPI.lua#L169-L172
---@class ChloeFiguraMidiCloudAvatarVars
---@field newInstance fun(ID:string, target:ChloeFiguraMidiCloudValidInstanceTarget, avatarInstance:AvatarAPI):ChloeFiguraMidiCloudInstance?
---@field listSounds fun():string[]         Wrapper for `sounds:getCustomSounds()`
---@field getSound fun(id:string):Sound     Wrapper for `sounds[id]`
---@field sessionID fun():UUID              The result of `client.generateUUID()`. Unique to this instance of the midi avatar. Can be used to check for reloads.



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

    if avatar:getPermissionLevel() ~= "MAX" then        -- Midi Cloud won't work unless itself **and** the caller (that's us) are set to MAX perms. Added this catch to make sure we're not spamming "failed to create instance" errors. See https://github.com/ChloeSpacedOut/figura-midi-player/blob/cb417ba36452dc82fb8102b4cf7727d77ad20272/ChloesMidiPlayerCloud/externalAPI.lua#L123-L127
        is_midi_cloud_available_last_result = false
        return false
    end

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

local reduced_volume_amount = 0.2      -- On the whole, the midi instruments are quite a bit louder than our baseline. This factor will help bring it in line with the other instruments.

---@type table<string, fun(active_note:MidiCloudInstrumentActiveNote, value:number, note_is_being_initialized)>
local modifier_functions = {
    pitch_mult = function (active_note, value, _)
        local target_pitch = active_note.initial_pitch * (value or 1)
        active_note.note.soundPitch = target_pitch
        if active_note.note.sound then active_note.note.sound:setPitch(target_pitch) end            -- Midi Cloud does not manipulate the pitch mid flight. we're free to manually update it whenever.
        if active_note.note.loopSound then active_note.note.loopSound:setPitch(target_pitch) end
    end,

    volume = function (active_note, value, note_is_being_initialized)
        local target_velocity = (
            (active_note.instruction.start_velocity ) * reduced_volume_amount * (avatar:getVolume() / 100) * (value and (value / 100) or 1)
            / 100   -- Notes initialized with `midi.note:play()`'s velocity are divided by 100 when applied to the note. see: https://github.com/ChloeSpacedOut/figura-midi-player/blob/63ba8fc46c866d0103df38714bb6c738fc71ce1a/ChloesMidiPlayerCloud/midiAPI.lua#L218
                    -- However this is only done by `midi.note:play()`. When we edit note.velocity directly, Midi Cloud does no division for us. So we need to do it ourselves here.
        )
        active_note.note.velocity = target_velocity
        if note_is_being_initialized then   -- unlike pitch, Midi Cloud does manage the sound's volume to do decays and stuff. we should only edit these values directly right at init.
            if active_note.note.sound then active_note.note.sound:setVolume(target_velocity) end
            if active_note.note.loopSound then active_note.note.loopSound:setVolume(target_velocity) end
        end
    end
}

---@param active_note MidiCloudInstrumentActiveNote
---@param note_is_being_initialized boolean?
local function update_modifiers(active_note, note_is_being_initialized)
    local modifiers = active_note.instruction.modifiers
    for modifier_index = active_note.instruction_modifier_index, #modifiers do
        local modifier_delta_from_instruction_start = modifiers[modifier_index].start_time - active_note.instruction.start_time
        if active_note.time_started + modifier_delta_from_instruction_start > client.getSystemTime() then return end

        if modifier_functions[modifiers[modifier_index].type] then
            modifier_functions[modifiers[modifier_index].type](active_note, modifiers[modifier_index].value, note_is_being_initialized)
        end
        active_note.instruction_modifier_index = modifier_index + 1

    end
end


local we_need_to_warn_the_host_that_viewers_will_need_to_boost_cloud_midis_permissions = true
do
    local current_config = config:getName()
    config:setName("TL_music_player_instrument_configs")
    we_need_to_warn_the_host_that_viewers_will_need_to_boost_cloud_midis_permissions = not config:load("midi_cloud_suppress_init_warnings")
    config:setName(current_config)
end


function TL_cloud_midi_instrument_suppress_warning(should_suppress)
    if (should_suppress == nil or should_suppress) and host:isHost() then
        print("Suppressing warning")
        print("You can undo this with: /figura run TL_cloud_midi_instrument_suppress_warning(false)")
    end

    local current_config = config:getName()
    config:setName("TL_music_player_instrument_configs")
    config:save("midi_cloud_suppress_init_warnings", (should_suppress == nil or should_suppress))
    config:setName(current_config)
end

local builders_to_return = {}   ---@type InstrumentBuilder[]
for instrument_midi_number, cloud_instrument_info in pairs(cloud_instruments_number_to_info) do
    ---@type InstrumentBuilder
    local builder = {
        name = "ChloeMidiCloud: " .. string.format("%03d", instrument_midi_number) .. " " .. cloud_instrument_info.name,
        sort_priority = -1,
        features = {
            percussion = not (cloud_instrument_info.non_melodic == nil),
            sustain = (cloud_instrument_info.non_melodic == nil),
            pitch_bend = (cloud_instrument_info.non_melodic == nil)
        },
        is_available = is_midi_cloud_available,
        new_instance = function(params, notify_ui_function)
            local instruments_api = require("../../instruments")  ---@type InstrumentsApi

            local fallback_instrument_builder = instruments_api.get_instrument_builder(cloud_instrument_info.fallback_instrument_name)
            if not fallback_instrument_builder then
                fallback_instrument_builder = instruments_api.get_default_instrument_builder(
                    cloud_instrument_info.non_melodic and 1 or 0
                )
            end

            local fallback_instrument_instance = fallback_instrument_builder.new_instance({}, notify_ui_function)


            if we_need_to_warn_the_host_that_viewers_will_need_to_boost_cloud_midis_permissions then
                if host:isHost() then

                    print("📎\n"
                        .."It looks like you\'re playing a song with a Cloud Midi instrument.\n"
                        .."Please read the figura-music-player README file for some\n"
                        .."important info about that."
                    )

                    -- TODO Update README, then update this link to go directly to the
                    -- TODO: In readme, add a link to how to suppress this warning. (Run `/figura run TL_cloud_midi_instrument_suppress_warning()`)

                    local url = "https://github.com/charliemikels/figura-music-player/blob/direct-midi-cloud-instruments/scripts/music_player/instruments/chloespacedout_instruments/README.md"
                    if client.compareVersions(client.getVersion(), "1.21.5") < 1 then   -- version is 1.21.4 or lower
                        printJson('{"text":"\nClick here to find the README on Github\n", "clickEvent":{"action":"open_url", "value":"'..url..'"}}')
                        printJson('{"text":"'..url..'", "underlined":true, "clickEvent":{"action":"open_url", "value":"'..url..'"}}')
                    else    -- version 1.21.5 changed how URL formatting works for this command.
                        printJson('{"text":"\nClick here to find the README on Github\n", "click_event":{"action":"open_url", "url":"'..url..'"}}')
                        printJson('{"text":"'..url..'", "underlined":true, "click_event":{"action":"open_url", "url":"'..url..'"}}')
                    end

                end

                we_need_to_warn_the_host_that_viewers_will_need_to_boost_cloud_midis_permissions = false
            end


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

            ---@type table<integer, MidiCloudInstrumentActiveNote>     -- integer indexed, but unsorted. use with pairs()
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
                        (instruction.start_velocity) * reduced_volume_amount * (avatar:getVolume() / 100),
                        channel_id,
                        1,
                        client.getSystemTime() - time_since_due,
                        position
                    )

                    new_note:release(new_note.initTime + instruction.duration)

                    ---@class MidiCloudInstrumentActiveNote
                    local new_active_note = {
                        time_started = client.getSystemTime() - time_since_due,
                        instruction = instruction,
                        note = new_note,
                        initial_pitch = new_note.soundPitch,
                        instruction_modifier_index = 1
                    }

                    table.insert(active_notes, new_active_note)

                    update_modifiers(new_active_note, true)

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
                            note.pos = position     -- midi cloud does a pretty good job keeping this updated when we set it

                            update_modifiers(active_note)


                            -- for _, sound in pairs({note.sound, note.loopSound}) do
                            --     if sound then
                            --         -- sound:setPos(position)
                            --     end
                            -- end

                            if is_note_done_for_real(note) then
                                active_notes[key] = nil
                            end
                        end
                    else
                        notify_ui_function("Please set `Chloe's MIDI Player` and `".. (avatar:getEntityName() or avatar:getName()) .."` to MAX perms to use this instrument.")
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
