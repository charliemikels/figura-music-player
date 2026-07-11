
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
---@field lastSysTime number    -- initialized to client.getSystemTime()
---@field lastUpdated number    -- initialized to client.getSystemTime()
---@field shouldKeepAlive boolean
---@field shouldKeepAliveClock number
---@field songs table
---@field tracks table
---@field channels table
---@field parseProjects table
---
---@field remove fun(self:ChloeFiguraMidiCloudInstance)     -- Deletes and cleans this instance
---@field newSong fun(self:ChloeFiguraMidiCloudInstance, name:string, midiData:ChloeFiguraMidiCloudMidiData):ChloeFiguraMidiCloudSong
---@field setTarget fun(self:ChloeFiguraMidiCloudInstance, target:ChloeFiguraMidiCloudValidInstanceTarget):ChloeFiguraMidiCloudInstance      -- Change where the player plays in-world.
---@field getTarget fun(self:ChloeFiguraMidiCloudInstance): ChloeFiguraMidiCloudValidInstanceTarget
---@field setVolume fun(self:ChloeFiguraMidiCloudInstance, volume:number): ChloeFiguraMidiCloudInstance     -- will be clamped from 0 to 1
---@field getVolume fun(self:ChloeFiguraMidiCloudInstance): number
---@field getPermissionLevel fun(self:ChloeFiguraMidiCloudInstance): string         -- wrapper for `avatar:getPermissionLevel()`
---@field setOnMidiEvent fun(self:ChloeFiguraMidiCloudInstance, func:function): ChloeFiguraMidiCloudInstance      -- sets a callback function for midi events. -- TODO: does func have some special shape?
---@field setShouldKillInstance fun(self:ChloeFiguraMidiCloudInstance, func:function): ChloeFiguraMidiCloudInstance   -- TODO: does func have some special shape?
---@field setShouldKillInstance fun(self:ChloeFiguraMidiCloudInstance, func:function): ChloeFiguraMidiCloudInstance   -- TODO: does func have some special shape?
---@field keepAlive fun(self:ChloeFiguraMidiCloudInstance): ChloeFiguraMidiCloudInstance    -- sets some keep alive value to true. -- TODO: What is keepAlive?

---@class ChloeFiguraMidiCloudSong
---@field new fun(self:ChloeFiguraMidiCloudSong, instance:ChloeFiguraMidiCloudInstance, ID:string, rawData:ChloeFiguraMidiCloudMidiData):ChloeFiguraMidiCloudSong
---
---@field ID string
---@field activeSong table?  nil
---@field isRemoved boolean
---@field target ChloeFiguraMidiCloudValidInstanceTarget
---@field volume number     -- From 0 to 1
---@field attenuation number    defaults to 1
---@field midi ChloeFiguraMidiCloudMidiApi
    -- self.soundfont = soundfont
    -- self.lastSysTime = client.getSystemTime()
    -- self.lastUpdated = client.getSystemTime()
    -- self.shouldKeepAlive = true
    -- self.shouldKeepAliveClock = 0
    -- self.songs = {}
    -- self.tracks = {}
    -- self.channels = {}
    -- self.parseProjects = {}
---





---@class ChloeFiguraMidiCloudMidiApi
---@field channel table
---@field events table
---@field note ChloeFiguraMidiCloudMidiNote
---@field song ChloeFiguraMidiCloudSong -- just the sone metatable and starting functions.

---@alias ChloeFiguraMidiCloudMidiData Byte[]   -- TODO: I don't actualy know what type this needs to be. It ultimately is "raw midi data", but is it in a string or byte list?

---@class ChloeFiguraMidiCloudMidiNote
---
--- Initializes a new midi note and plays it.
---
--- This function also takes care of initialing new channels and tracks. But will also stop notes if we reuse a pitch on a track.
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
---@field stop fun(self:ChloeFiguraMidiCloudMidiNote) -- stops the note immediately.
---@field releaseTime integer   -- The time the note was released. Because we set this time immediately after creating the note, we should expect this to always be something
---@field duration number       -- The amount of extra time it takes for this not to decay after being released.
---@field sound Sound

---@class ChloeFiguraMidiCloudSoundfontAPI

---@class ChloePianoLib
---@field getPianos fun():table<ChloeInstrumentID, ChloePiano>
---@field getPiano fun(piano_id:ChloeInstrumentID):ChloePiano
---@field playMidiNote fun(piano_id:ChloeInstrumentID, note:integer, velocity:number, type:("PRESS"|"SPAM_HOLD"|"MANUAL_RELEASE")?, playerEntity:Entity?, notePos:Vector3?)   -- if playerEntity is included, crouching will sustain the piano.
---@field releaseMidiNote fun(piano_id:ChloeInstrumentID, note:integer)
---@field setInstrumentOverride fun(piano_id:ChloeInstrumentID, override_id:integer)
---@field getInstrumentOverride fun(piano_id:ChloeInstrumentID):integer?
---@field getItem fun(data:table):ItemStack
---
---@field playNote fun(pianoID:ChloeInstrumentID, keyID:ChloeKeyID, doesPlaySound:boolean, notePos:Vector3?, noteVolume:number?) -- Fallback for Piano v1 scripts
---@field validPos fun(pianoID:ChloeInstrumentID):boolean       -- Fallback for Piano v1 scripts
---@field getPlayingKeys fun(pianoID:ChloeInstrumentID):table?  -- Fallback for Piano v1 scripts

---@alias ChloeInstrumentID string   -- PianoIDs are the same as tostring( vec3position )

---@class ChloePiano    -- This is a subset of what is in the actual piano. we should primally just use IDs and the built-in helper functions.
---@field ID ChloeInstrumentID
---@field lastInstrument integer
---@field model 1|2|3|4                     -- 1-3 == pianos. 4 == drum kit
---@field playingKeys table<integer, table> -- List of keys being held down.
---@field instance ChloeFiguraMidiCloudInstance
---@field midi table

-- Drum specific

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
