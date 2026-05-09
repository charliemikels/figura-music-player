
---@alias UUID string

---@class ChloeFiguraMidiCloudInstance
---@field ID string
---@field activeSong nil
---@field isRemoved boolean
---@field target Player|BlockState|Vector3  -- https://github.com/ChloeSpacedOut/figura-midi-player/blob/20c4d8031668a3ee2e3b3cb69843fabc46acc81a/ChloesMidiPlayerCloud/externalAPI.lua#L98
---@field volume number         -- float between 0 and 1
---@field attenuation number    -- float between 0 and 1
---@field midi ChloeFiguraMidiCloudMidiApi
---@field soundfont ChloeFiguraMidiCloudSoundfontAPI
---@field lastSysTime number    -- initilized to client.getSystemTime()
---@field lastUpdated number    -- initilized to client.getSystemTime()
---@field shouldKeepAlive boolean
---@field shouldKeepAliveClock number
---@field songs table
---@field tracks table
---@field channels table
---@field parseProjects table

---@class ChloeFiguraMidiCloudMidiApi
---@field channel table
---@field events table
---@field note ChloeFiguraMidiCloudMidiNote
---@field song table

---@class ChloeFiguraMidiCloudMidiNote
---
--- Initilizes a new midi note and plays it.
---
--- This function also takes care of initilizeing new channels and tracks. But will also stop notes if we reuse a pitch on a track.
---
--- `pitch` and `velocity` are midi values, so 0-128 or something.
---
--- `sysTime` should be called with the note's start time. see `client.getSystemTime()`
---
--- `pos` may be nil, in which the note will default to the instance's position.
---@field play fun(self:ChloeFiguraMidiCloudMidiNote, instance:table, pitch:integer, velocity:integer, channelID:integer, trackID:integer, sysTime, pos:Vector3?):ChloeFiguraMidiCloudMidiNote
---
---@field sustain fun(self:ChloeFiguraMidiCloudMidiNote) -- Removes the "main noise" and only plays the sustain loop.
---
--- Stops a note with a small decay.
---
--- `sysTime` is the time the note was released, but it can be set to a future time. Call with `client.getSystemTime()` and add `instruction.duration` to it.
---@field release fun(self:ChloeFiguraMidiCloudMidiNote, sysTime:integer)
---@field stop fun(self:ChloeFiguraMidiCloudMidiNote) -- stops the note immediatly.
---@field releaseTime integer   -- The time the note was released. Because we set this time immediatly after creating the note, we should expect this to allways be something
---@field duration number       -- The amount of extra time it takes for this not to decay after being released.
---@field sound Sound

---@class ChloeFiguraMidiCloudSoundfontAPI

---@class ChloePianoLib
---@field getPianos fun():table<ChloeInstrumentID, ChloePiano>
---@field getPiano fun(ChloePianoID):ChloePiano
---@field playMidiNote fun(pianoID:ChloeInstrumentID, note:integer, velocity:number, type:("PRESS"|"SPAM_HOLD"|"MANUAL_RELEASE")?, playerEntity:Entity?, notePos:Vector3?)   -- if playerEntity is included, crouching will sustain the piano.
---@field releaseMidiNote fun(ChloePianoID, integer)
---@field setInstrumentOverride fun(ChloePianoID, integer)
---@field getInstrumentOverride fun(ChloePianoID)
---@field getItem fun(table):ItemStack
---
---@field playNote fun(pianoID:ChloeInstrumentID, keyID:ChloeKeyID, doesPlaySound:boolean, notePos:Vector3?, noteVolume:number?) -- Fallback for Piano v1 scripts
---@field validPos fun(pianoID:ChloeInstrumentID):boolean       -- Fallback for Piano v1 scripts
---@field getPlayingKeys fun(pianoID:ChloeInstrumentID):table?  -- Fallback for Piano v1 scripts

---@alias ChloeInstrumentID string   -- PianoIDs are the same as tostring( vec3position )

---@class ChloePiano    -- This is a subset of what is in the actual piano. we should primaraly just use IDs and the built-in helper functions.
---@field ID ChloeInstrumentID
---@field lastInstrument integer
---@field model 1|2|3|4                     -- 1-3 == pianos. 4 == drum kit
---@field playingKeys table<integer, table> -- List of keys being held down.
---@field instance ChloeFiguraMidiCloudInstance
---@field midi table

-- Drum speciffic

---@alias ChloeKeyID string -- Piano v1 and drumkit (and Piano 2.0 in fallback mode) use strings like "A#4", "C2", "G#5" to identify what notes to play.

---@class ChloeDrumkitLib
---@field playNote          fun(drumID:ChloeInstrumentID, keyID:ChloeKeyID, doesPlaySound:boolean, notePos:Vector3?, noteVolume:number?)
---@field playSound         fun(keyID:ChloeKeyID, notePos:Vector3, noteVolume:number)
---@field validPos          fun(drumID:ChloeInstrumentID):boolean
---@field getPlayingKeys    fun(drumID:ChloeInstrumentID):table<ChloeKeyID,number>
---@field getDrumIDs        fun():ChloeInstrumentID[]
---@field getDrumPositions  fun():Vector3[]
---@field getNearestDrumID  fun(Vector3):ChloeInstrumentID?, Vector3?




-- player.lua will try to require this file, let's return something valid so that it doesn't complain.
return {}
