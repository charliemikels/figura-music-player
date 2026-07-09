
-- It's really nice that I can use the Piano and Drumkit APIs to sorta offload some tasks to the Midi cloud.
-- piano.lua especially can just emit a start time and an end time, and the midi cloud just kinda handles it.
--
-- But reaching through the piano/drumkit library is kinda annoying.
--
-- What if we used the Midi Cloud for real? Then we can expose all the instruments to the viewer.
--
-- Though... this would mean that we need to un-convert out special file format back into real midi?
-- That might be rough. Especially our multiplier-based pitch bending.
--
-- Although, maybe pitch bend won't be so bad. We need just one converter function, and then a system to see if
-- the multiplier is out of range. And if it does go out of range, send the event that boosts the range and
-- update the converter function.
--
-- Actually, pitch bend should really be the only hard part. The only danger is if my avatar crashes,
-- There'll be nothing to clean up the midi notes. But... maybe there's a way around that.
--
-- TODO: see if ChloeFiguraMidiCloudMidiNote:release(stop_time) is part of the actual midi cloud,
-- or part of the piano. This will ensure midi stuff gets cleaned up, and saves us from doing loops.




-- re-use the vanilla instrument's InstrumentBuilder_builder thing to just grab all the instruments at once. (Be careful with percussion.)

---@type InstrumentBuilder[]
return {}
