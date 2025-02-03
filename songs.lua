-- Tanner Limes was here.
-- ABC Music Player V1

--[[	Some notes on this script:
This script has 1 major limitation: Processing ABC song files is expensive. To
avoid this issue, I opted to process songs over time as part of the tick event. 
This means that the client will be unable to hear you until after _they_ 
finish processing the song, which can take longer if the permissions are low.

The alternative is to process the songs rapidly as the host, then send the 
processed data to the clients through pings. The downside for this method is 
that pings are limited to 1kb per second. So depending on the complexity of the 
song, it may take a while to actually start playing the song. 

(The 3rd option is to pre-process all of the song data /before/ uploading it to 
Figura. A V2 version of this script will explore this solution.) 

For the time being, song data is stored in a songbook.lua file. It's a fairly 
simple table that is mostly used to hold the ABC music files as a lua string. I 
have included a script in the songbook_compiler folder to dump ABC files into
a songbook.lua table. Run this script outside of Figura to generate the 
songbook.lua file.

As for playing the song, there was no way to que a sound to play at a specific 
time, and the tick event isn't fast enough for some songs. So song playing is 
attached to the RENDER event, since a player's FPS is usually higher than 20 
ticks per second. This improves timing accuracy, but only when FPS is high.

Also piano compatibility is sometimes broken. Some times it works, sometimes 
something crashes, but it's more stable when both avatars have a high trust. 

ABC Documentation website: https://abcnotation.com/wiki/abc:standard:v2.1
]]

local songbook = require("songbook")
local key_signatures, key_signatures_keys = require("key_signatures")
local piano_lib = world.avatarVars()["b0e11a12-eada-4f28-bb70-eb8903219fe5"]

-- init ------------------------------------------------------------------------
function events.entity_init()
	--print("--- init: songs ------------")
	prepare_songbook()
end

local songbook_prep_tick_event_name = "full_songbook_prep_tick"
function prepare_songbook()
	print("Preparing songbook")
	-- TODO: reset songbook in case we've already prepped it earlier
	songbook.isReady = false
	
	songbook.sorted_song_keys = {}
	for key, song in pairs(songbook.songs) do
		table.insert(songbook.sorted_song_keys, key)
		song.name = key	-- Human Error Proof™
	end
	table.sort(songbook.sorted_song_keys)
	
	songbook.current_song_being_prepped = nil
	songbook.selected_song = songbook.songs[songbook.sorted_song_keys[1]]
	songbook.playing_song = nil
	songbook.stopping_songs = {}
	songbook.selected_chloe_piano_pos = nil
	
	songbook_action_wheel_page_settup()
	
	-- It's far far to expensive to process all the songs at init. So we need
	-- to spread it out over time. These limits will help keep the number of
	-- instructions per tick down when preparing and resetting songs. 
	
	-- these values will need to be adjusted depending on the 
	-- complexity of the other avatar scripts
	
	songbook.num_notes_to_process_per_tick = 2
	if avatar:getMaxTickCount() >= 32768 then 		-- instruction limit per tick for "high"
		songbook.num_notes_to_process_per_tick = 64 -- Hard to say. maxed out around 15000. We run out of notes per line before we run out of instructions 
	elseif avatar:getMaxTickCount() >= 8192 then 	-- tick limit for "default"
		songbook.num_notes_to_process_per_tick = 24	-- ~3000-6500 instructions per tick
	elseif avatar:getMaxTickCount() >= 4096	then 	-- tick count for "low" permission
		songbook.num_notes_to_process_per_tick = 8	-- ~2600-2900 instructions per tick
	elseif avatar:getMaxTickCount() >= 2048 then 	-- Just in case? Likely not nessesary 
		songbook.num_notes_to_process_per_tick = 4
	end
	
	songbook.num_instructions_to_stop_per_tick = 50
	if avatar:getMaxTickCount() >= 32768 then
		songbook.num_instructions_to_stop_per_tick = 250
	elseif avatar:getMaxTickCount() >= 8192 then
		songbook.num_instructions_to_stop_per_tick = 100
	end
	
	-- Start the prepare tick-loop  
	events.TICK:register(prepare_songbook_step, songbook_prep_tick_event_name)
end

-- Prepare Song / Songbook (Ran on every TICK event) ---------------------------
function prepare_songbook_step()
	if songbook.current_song_being_prepped == nil then
		-- find a new song to prep
		for song_key, song in pairs(songbook.songs) do
			if song.isReady == nil or song.isReady ~= true then
				-- Queue song to be prepared next
				--print("Preparing song: "..song_key)
				
				song.prep_status="pre-prep"
				songbook.current_song_being_prepped = song
				return false 
			end
		end
		-- if we are here, then no songs are being prepped,
		-- and no songs need to be prepped.
		-- Remove this function from the tick event
		print("All songs are ready.")
		events.TICK:remove(songbook_prep_tick_event_name)
		songbook.isReady = true
		return true
	else
		-- We're currently prepping a song. Continue. 
		prepare_song(songbook.current_song_being_prepped)
		if songbook.current_song_being_prepped.isReady == true then
			-- Instruct the next loop to find a new song
			songbook.current_song_being_prepped = nil
		end
	end
	return false
end

function prepare_song(song)	
	if song.prep_status == "pre-prep" then
		if song.abc_data == "" then song.prep_status = "done" return end
		
		-- song data init stuff 
		-- song.songbuilder will be deleted once the song is done building
		song.instructions = {}
		
		song.songbuilder = {}
		song.songbuilder.abc_lines = {}
		song.songbuilder.next_note_start_time = 0
		song.songbuilder.key_signature_key = "C"
		song.songbuilder.default_note_length = 0.25
		song.songbuilder.length_of_beat_in_measure = 0.25
		song.songbuilder.notes_per_measure = 4
		song.songbuilder.beats_per_minute = 120
		song.songbuilder.last_processed_note_index = 1
		song.songbuilder.in_note_group = false
		song.songbuilder.group_earliest_stop_time = math.huge
		song.songbuilder.accidentals_memory = {}
		song.songbuilder.note_builder = {
		  	accidentals = "",
		  	letter = "",
		  	octave_ajustments = "",
		  	durration_multiplier = "",
		  	durration_divisor = "",
		  	start_time = song.next_note_start_time
		}
		
		for line in song.abc_data:gmatch("[^\n]+") do
			table.insert(song.songbuilder.abc_lines, line)
		end
		song.songbuilder.line_to_parse_next = 1
		
		song.prep_status = "prepping"
		
	elseif song.prep_status == "prepping" then 
		-- process a line of the song. 
--		for i = 1, num_lines_to_parse_per_tick do
			host:actionbar(song.name.." #"..tostring(song.songbuilder.line_to_parse_next).."/"..tostring(#song.songbuilder.abc_lines))
			
			local done_processing_this_line = parse_song_line(song, song.songbuilder.line_to_parse_next)
			if done_processing_this_line then
				song.songbuilder.line_to_parse_next = song.songbuilder.line_to_parse_next +1
			end
			if song.songbuilder.line_to_parse_next >= #song.songbuilder.abc_lines+1 then --or line_to_parse_next == 9 then
				--print(all_notes_done)
				song.prep_status = "post-prep"
				--break 
			end
--		end
		
	elseif song.prep_status == "post-prep" then
		-- song data clean up
		--printTable(song)
		song.songbuilder = nil
		song.prep_status = "done"
		song.isReady = true
		print("Done prepping: "..song.name)
		songbook_action_wheel_update_select_song_action()
	else
		error("song '"..tostring(song.name).."' has unexpected prep status `"..tostring(song.prep_status).."`." )
	end
	--printTable(song.abc_lines)
end

-- Song Control ----------------------------------------------------------------
local play_song_render_event_name = "play_song_render_event"
function pings.play_song(song_key)
	local song = songbook.songs[song_key]
	if song == nil then
		print("songbook doesn't have a song with key `"..song_key.."`")
		songbook_action_wheel_update_select_song_action(false)
		return
	end
	if song.isReady == nil or song.isReady == false then
		print("The song `"..song_key.."` isn't ready to be played.")
		songbook_action_wheel_update_select_song_action(false)
		return
	end
	
	stop_playing_songs()
	
	print("♫ Now playing: "..song.name.." ♫" )
	
	song.current_playing_index = 0
	song.all_instructions_done = false
	song.start_time = client.getSystemTime()
	songbook.playing_song = song
	
	songbook_action_wheel_update_select_song_action()
	events.RENDER:register(
		play_song_event_loop, 
		play_song_render_event_name
	)
end

local stop_song_tick_event_name = "stop_song_tick_event"
function stop_playing_songs()
	local song = songbook.playing_song
	if song ~= nil then
		--print("stopping song "..song.name)
		events.RENDER:remove(play_song_render_event_name)
		songbook.playing_song = nil
		table.insert(songbook.stopping_songs, song)
		song.prep_status = "stopping"
		song.stop_loop_index = 0
		
		song.isReady = false
		song.start_time = nil
		
		songbook_action_wheel_update_select_song_action(false)
		
		events.TICK:register(stop_playing_song_tick, stop_song_tick_event_name)
	end
end

function stop_playing_song_tick()
	if #songbook.stopping_songs == 0 then 
		print("Done rewinding all songs")
		songbook_action_wheel_update_select_song_action()
		events.TICK:remove(stop_song_tick_event_name)
		return
	end
	local current_stopping_song_index, song = next(songbook.stopping_songs, nil)
	
	for instruction_index = math.max(song.stop_loop_index, 1), math.min(#song.instructions, song.stop_loop_index + songbook.num_instructions_to_stop_per_tick) do
		local instruction = song.instructions[instruction_index]
		if instruction.sound_id ~= nil then
			instruction.sound_id:stop()
			instruction.sound_id = nil
		end
		instruction.already_played = false
		song.stop_loop_index = instruction_index +1 
	end
	
	if song.stop_loop_index >= #song.instructions +1 then
		-- the last index was searched. final cleanup
		song.all_instructions_done = false
		song.current_playing_index = nil
		song.isReady = true
		songbook_action_wheel_update_select_song_action()
		-- TODO: tell action wheel that this song is ready
		songbook.stopping_songs[current_stopping_song_index] = nil
		song.stop_loop_index = nil
	end
end

function pings.stop_playing_songs_ping()
	stop_playing_songs()
end

-- Song Player (Ran on every RENDER event) -------------------------------------
function play_song_event_loop()
	local song = songbook.playing_song
	if 		song == nil 
		or	song.all_instructions_done == true 
	then
		print("song `".. song.name .."` finished")
		stop_playing_songs()
		events.RENDER:remove(play_song_render_event_name)
		return
	end
	
	-- find new notes to play
	song.all_instructions_done = true
	for instruction_index = math.max(1, song.current_playing_index), #song.instructions
	do
		local instruction = song.instructions[instruction_index]
		if instruction.already_played == false then song.all_instructions_done = false end
		
		if instruction.start_time + song.start_time < client.getSystemTime() 
			and type(instruction.sound_id) ~= "Sound"
			and instruction.already_played == false 
			-- if we passed the start point of a instruction, 
			-- and it currently has no sound,
			-- and we haven't played this instruction previously:
		then
		
			if songbook.selected_chloe_piano_pos ~= nil then
				host:actionbar( "#"..instruction_index.." ".. tostring(instruction.chloe_spaced_out_piano_note_code))
			 	--print("playing note "..instruction.chloe_spaced_out_piano_note_code.. " on piano at "..songbook.selected_chloe_piano_pos)
			 	if instruction.chloe_spaced_out_piano_note_code ~= nil then
			 		piano_lib.playNote( songbook.selected_chloe_piano_pos , instruction.chloe_spaced_out_piano_note_code, true)
			 	end
			 	instruction.already_played = true
			 	song.current_playing_index = instruction_index +1	-- Chloe piano can't sustain notes, so we don't need to bother checking if the note's done playing.t
			else
				host:actionbar( "#"..instruction_index.." ".. instruction.string)
				if avatar:canUseCustomSounds() then
					instruction.sound_id = sounds:playSound("triangle_sin", player:getPos(),1,instruction.minecraft_hz_multiplier,true)
				else
					instruction.sound_id = sounds:playSound("minecraft:block.note_block.bell", player:getPos(),1,instruction.minecraft_hz_multiplier_for_noteblock,false)
				end
			end
			
		elseif	instruction.end_time + song.start_time < client.getSystemTime()
			and type(instruction.sound_id) == "Sound"
			-- if the end point of the instruction has passed, 
			-- and it still has a sound id:
		then
			instruction.sound_id:stop()
			instruction.already_played = true
			instruction.sound_id = nil
			
			-- Set a new start index for the note finding loop.
			-- The open end of the for loop needs to start with the oldest, 
			-- still living note. Whenever the oldest note ends, find the next
			-- oldest note to update the index
			if song.current_playing_index +1 == instruction_index 
				or song.current_playing_index == instruction_index
			then
				for walk_index = math.max(1, song.current_playing_index), #song.instructions do
					if song.instructions[walk_index].already_played == nil 
						or song.instructions[walk_index].already_played == false 
					then
						-- found a living note. The previous index was our destination. 
						break
					else
						-- found an non-living note. We'll want to skip it in the future.  
						song.current_playing_index = walk_index
					end
				end
			end
		elseif instruction.start_time + song.start_time > client.getSystemTime() then
			-- If the instruction is queued for the future, break the loop. 
			-- We'll come back to it when this function is called again.
		  	break
		end
	end
end

-- Song Building ---------------------------------------------------------------
local function fracToNumber(str)
	func = assert(loadstring("return " .. str))
	-- !! can easily lead to arbitrary code execution !! --
	-- Make sure to sanitize all ABC files first. (Or make sure the input
	-- is a fraction before processing it.)
	return func()
end

local function reCalculateMilisPerNote(song)
	if 		type(song.songbuilder.beats_per_minute) ~= "number"
		or	type(song.songbuilder.default_note_length) ~= "number"
		or	type(song.songbuilder.length_of_beat_in_measure) ~= "number"
	then return end
	
	local beats_per_second = song.songbuilder.beats_per_minute / 60.0
	local seconds_per_beat = 1/beats_per_second
	local beat_to_default_note_len_multiplier = 
		song.songbuilder.default_note_length / song.songbuilder.length_of_beat_in_measure
		-- Fixes issues where the bpm (`Q:`) is set on quarter notes, but
		-- the default note length (`L:`) is written as half notes. 
	local seconds_per_note_length = 
		beat_to_default_note_len_multiplier * seconds_per_beat
	local millis_per_note_length = seconds_per_note_length * 1000
	
	song.songbuilder.time_per_note = millis_per_note_length
	return millis_per_note_length
end

-- local function semitone_offset_to_hz(semitone_offset, base_frequency)
	-- noteblocks are based on f#. F#4 = 369.99
	-- Standard base is A4 = 440
-- 	return base_frequency * semitone_offset_to_multiplier(semitone_offset)
-- end

function semitone_offset_to_multiplier(semitone_offset)
	return 2^(semitone_offset / 12)
end

local letter_to_semitone_offsets = {
	["b"] = 14,
	["a"] = 12,
	["g"] = 10,
	["f"] = 8,
	["e"] = 7,
	["d"] = 5,
	["c"] = 3,
	["B"] = 2,
	["A"] = 0,
	["G"] = -2,
	["F"] = -4,
	["E"] = -5,
	["D"] = -7,
	["C"] = -9,
}

local chloe_piano_flat_to_sharp_table = {
	["B"] = "A#",
	["A"] = "G#",
	["G"] = "F#",
	["F"] = "E",
	["E"] = "D#",
	["D"] = "C#",
	["C"] = "B",	-- << Special case: downgrade octave number.
}

local function save_note_builder_to_instructions(song)	-- returns the end time of the note. 
	note_builder = song.songbuilder.note_builder
	if note_builder.letter == "" then return note_builder.start_time end 
	--print("Saving note to instruction:")
	
	-- Calculate note duration
	local time_multiplier = 1.0
	if note_builder.durration_multiplier ~= "" then
		time_multiplier = tonumber(note_builder.durration_multiplier)
	end
	if note_builder.durration_divisor ~= "" then
		-- divisor should always have at least 1 slash.
		-- each slash means divide by two, but if there are numbers after 
		-- the slash, don't do the shorthand. A goofy workaround:
		-- multiply the numbers by 2, since there will always be at least 1
		-- slash. It will cancel out the shorthand, without making us test 
		-- if we should use the shorthand
		local numbers, num_devisions = 
			note_builder.durration_divisor:gsub("/", "")
		time_multiplier = time_multiplier / (2.0^num_devisions)
		if numbers ~= "" then
			time_multiplier = (time_multiplier*2.0) / tonumber(numbers)
		end
	end
	
	local note_durration = song.songbuilder.time_per_note * time_multiplier
	
	local end_time = note_builder.start_time + note_durration
	
	-- Generate some strings to use in keys and print statements
	local accidentals_memory_key = note_builder.letter..note_builder.octave_ajustments
	local note_string = note_builder.accidentals 
		.. note_builder.letter 
		.. note_builder.octave_ajustments
		.. note_builder.durration_multiplier
		.. note_builder.durration_divisor
	
	-- Load / Save accidentals to memory / key
	if note_builder.accidentals ~= "" then
		-- If the note has manual accidentals, add them to memory
		song.songbuilder.accidentals_memory[accidentals_memory_key] = note_builder.accidentals
	
	elseif	note_builder.accidentals == "" then
		if type(song.songbuilder.accidentals_memory[accidentals_memory_key]) ~= "nil" then
			-- if the note has no accidentals, but it is in memory,  
			-- add the memory's accidental
			note_builder.accidentals = song.songbuilder.accidentals_memory[accidentals_memory_key]
			note_string = note_string .. "  mem:" ..song.songbuilder.accidentals_memory[accidentals_memory_key]
		elseif type(key_signatures[song.songbuilder.key_signature_key][note_builder.letter:upper()]) == "string"
		then
			-- if the note doesn't have it's own accidentals, and there 
			-- are none set in the memory, add the accidental from the
			-- key signature
			note_builder.accidentals = note_builder.accidentals 
				.. key_signatures[song.songbuilder.key_signature_key][note_builder.letter:upper()]
			note_string = note_string .. "  key:" ..key_signatures[song.songbuilder.key_signature_key][note_builder.letter:upper()]
		end
	end
	
	-- Calculate offset in semitones. Assuming A4 as base note
	local _, num_sharps = note_builder.accidentals:gsub("%^","")
	local _, num_flats = note_builder.accidentals:gsub("_","")
	local accidentals_in_semitones = num_sharps - num_flats
	
	local _, num_octaves_up = note_builder.octave_ajustments:gsub("'","")
	local _, num_octaves_down = note_builder.octave_ajustments:gsub(",","")
	local octave_offset = (num_octaves_up - num_octaves_down)
	local octave_offset_in_semitones = 12 * octave_offset --(num_octaves_up - num_octaves_down)
	
	local note_semitones_from_A4 = 
		(letter_to_semitone_offsets[note_builder.letter] or 0)
		+ octave_offset_in_semitones
		+ accidentals_in_semitones
	
	-- Convert A4 semitone offset to other spaces
	local semitones_from_sharp_F4 = note_semitones_from_A4 +3	-- F#4: Minecraft noteblock tuning (Fallback playing method)
	local semitones_from_C4 = note_semitones_from_A4 +9			-- C4: To make Chloe Piano math easier.
	
	local octave_number = math.floor((semitones_from_C4+48) / 12)
	
	-- Chloe Piano note code
	local chloe_spaced_out_piano_note_code = note_builder.letter:upper()..tostring(octave_number)
	 
	if accidentals_in_semitones > 0 then
		-- There are rare cases where SBC might give "^E" or "^B", which don't exist on a keyboard. (It's the same as saying "F" or "C")
		if note_builder.letter:upper() == "E" then
			chloe_spaced_out_piano_note_code = "F" ..tostring(octave_number)			
		elseif note_builder.letter:upper() == "B" then
			chloe_spaced_out_piano_note_code = "C" ..tostring(octave_number+1)
		else
			chloe_spaced_out_piano_note_code = note_builder.letter:upper().. "#" ..tostring(octave_number)
		end
	elseif accidentals_in_semitones < 0 then
		-- This note is flat, but Piano only accepts sharps. 
		if note_builder.letter:upper() == "C" then 
			chloe_spaced_out_piano_note_code = "B#"..tostring(octave_number-1)
		else
			chloe_spaced_out_piano_note_code = chloe_piano_flat_to_sharp_table[note_builder.letter:upper()]..tostring(octave_number)
		end
	end
	
	-- Limit note range. Max piano range: A0 to B6
	if octave_number > 6
		or (octave_number == 0 and not chloe_spaced_out_piano_note_code:upper():match("[AB]+") )
		or octave_number < 1 then
		chloe_spaced_out_piano_note_code = nil	-- Nil codes will be ignored when playing the song.
	end
	
	-- Save note instructions
	if	note_builder.letter:lower() ~= "z" 
	and note_builder.letter:lower() ~= "x" 
		-- Skip instructions for rest notes.
	then
		table.insert(song.instructions, {
			string = note_string,
			--note_semitones_from_A4 = note_semitones_from_A4,
			--hz = semitone_offset_to_hz(note_semitones_from_A4, 440),
			minecraft_hz_multiplier = semitone_offset_to_multiplier( note_semitones_from_A4 ),
			minecraft_hz_multiplier_for_noteblock = semitone_offset_to_multiplier( semitones_from_sharp_F4 ),
			chloe_spaced_out_piano_note_code = chloe_spaced_out_piano_note_code,
			start_time = note_builder.start_time,
			end_time = end_time,
			sound_id = nil,
			already_played = false,
		})
	end
	
	return end_time
end

local next_note_start_time = 0	-- Todo: move to song_builder?
local in_group = false			-- Todo: move to song_builder?
function parse_song_line(song, line_number)
--	print(line)
	line = song.songbuilder.abc_lines[line_number]
	if line:sub(1,2) == "X:" then 
		-- X is the ID of this song. We'll use out own index instead
	
	elseif line:sub(1,2) == "T:" then
		-- Title of song Title should match the songbook key.
				
	elseif line:sub(1,2) == "Z:" then 
		--song.author = line:sub(3):gsub('^%s*(.-)%s*$', '%1')
		
	elseif line:sub(1,2) == "L:" then 
		song.songbuilder.default_note_length = fracToNumber(line:sub(3):gsub('^%s*(.-)%s*$', '%1'))
		reCalculateMilisPerNote(song)
	
	elseif line:sub(1,2) == "M:" then 
		song.songbuilder.notes_per_measure = fracToNumber(line:sub(3):gsub('^%s*(.-)%s*$', '%1'))
		
	elseif line:sub(1,2) == "Q:" then
		local bpm_key = line:sub(3) --:gsub('^%s*(.-)%s*$', '%1')
		local length_of_beat_in_measure, bpm = bpm_key:match("(.+)=(.+)")
		length_of_beat_in_measure = fracToNumber(length_of_beat_in_measure)
		bpm = tonumber(bpm) 
		
		song.songbuilder.length_of_beat_in_measure = length_of_beat_in_measure
		song.songbuilder.beats_per_minute = bpm
		reCalculateMilisPerNote(song)
	
	elseif line:sub(1,2) == "K:" then
		-- "K:" marks the key signature, and also marks the end of the header
		local song_file_key = line:sub(3):gsub("%s+", ""):upper()
		key_signature_key = ""
		for key, alt_names in pairs(key_signatures_keys) do
			for _, name in pairs(alt_names) do
				if song_file_key:sub(0, math.max(#name, 3)) == name then
					key_signature_key = key
					break
				end
			end
			if key_signature_key ~= '' then
				break
			end
		end
		
		song.songbuilder.key_signature_key = key_signature_key
	
	elseif line:sub(2,2) == ":" then
		-- This line is an unrecognized metadata key. We can ignore all of these
		-- "T:" is song title. Starbound Composer sets this value to 
			-- the name of the midi track (like "1 - Lead"), so it's usually 
			-- unhelpful. Use the filename instead. 
		-- "Z:" is the song Author. Currently we're not displaying this info
			-- so we can just ignore it. 
		-- "X:" is song ID. Useful in the context of a collection of songs, but
			-- we're using our own indexing system.
		-- https://abcnotation.com/wiki/abc:standard:v2.1#information_field_definition 
	
	else	-- Line is not an information line, so it must be a song line. 
		
		-- Get list of notes in this line.
		local notes = {}
		for note in line:gmatch("%[?[[_=%^]*%a[,']*%d*/*%d*]?%]?") do
			-- Note structure that we look for:
			-- might start with 1 `[`							-- Marks the start of a group 
			-- might have any number of `_`, `=`, or `^` characters		-- Marks the note's accidental (Flat or sharp) 
			-- _must_ have 1 letter								-- Marks the note name. Lowercase is up 1 octave. 
			-- might have any number of `,` or `'` characters	-- Marks a shifts in octave. `,` for down, `'` for up.   
			-- might have any number of numbers					-- Marks the duration of the note, in multiples of song.songbuilder.default_note_length set by `L:`
			-- might have any number of `/` characters			-- Flags the next number as a divisor for the duration. If it's not followed by a number, it divides the duration by (2 * number of division signs)
			-- might have any number of numbers					-- When followed by a `/`, marks the divisor of the note length. 
			-- might end with 1 `]`								-- Marks the end of a group. 

			-- Unchecked cases:
			-- Starbound composer usually converts the more exotic cases into individual notes, but these two might be common in traditional ABC files.
			-- `[` can introduce an information header mid-line. SBC puts information fields into their own line, so this case rarely occurs.
			-- `>` and `<` to mark broken rhythm. (see https://abcnotation.com/wiki/abc:standard:v2.1#broken_rhythm) SBC writes these as full fractions, so it rarely occurs.
			-- In song comments. 

			table.insert(notes, note)
		end
		-- We're generating this variable so that we can index into it and
		-- process only a subset of the notes in this line.
		-- TODO: we can improve this be storing this in a song_builder var, and 
			-- only run this loop once per line.
		
		-- Loop through found notes. 
		for note_index, note in pairs({table.unpack(	-- build a subset of notes table
				notes, 
				math.max(song.songbuilder.last_processed_note_index, 1), 
				math.min(#notes, 
					song.songbuilder.last_processed_note_index
					+ songbook.num_notes_to_process_per_tick
					-1
				)
			)})
		do	
			
			if note:match("%[") ~= nil then song.songbuilder.in_group = true end
			
			song.songbuilder.note_builder = {
			  	accidentals = note:match("[_=%^]+") or "",
			  	letter = note:match("%a"),	-- this will match any letter, but should only be given A, B, C, D, E, F, G, Z, or X in upper or lower case.
			  	octave_ajustments = note:match("[,']+") or "",
			  	durration_multiplier = note:match("[%a,'](%d+)") or "",
			  	durration_divisor = note:match("/+%d*") or "",	-- divisor also includes the `/` characters.
			  	start_time = song.songbuilder.next_note_start_time
			}
			
			local returned_note_end_time = save_note_builder_to_instructions(song)
				
			if song.songbuilder.in_group then
				if returned_note_end_time < song.songbuilder.group_earliest_stop_time then
					-- This check is wrong, but it works most of the time?
					-- According to the docs, The end time of the group should be set by the first note's end time,
					-- But this logic finds the shortest note in the group, and uses that end time instead. 
					song.songbuilder.group_earliest_stop_time = returned_note_end_time
				end
			else
				song.songbuilder.next_note_start_time = returned_note_end_time
			end
					
			if note:match("%]") ~= nil then
				--print("ends group")
				song.songbuilder.in_group = false
				song.songbuilder.next_note_start_time = song.songbuilder.group_earliest_stop_time 
				note_builder.start_time = song.songbuilder.next_note_start_time
				song.songbuilder.group_earliest_stop_time = math.huge
			end
			
			song.songbuilder.last_processed_note_index = song.songbuilder.last_processed_note_index +1
		end
		
		if #notes <= song.songbuilder.last_processed_note_index then
			-- we finished processing all the notes in this line
			song.songbuilder.last_processed_note_index = 1
			--in_group = false
			return true
		else
			-- we need to run another loop to get all the notes
			-- print("note limit reached for this tick.")
			return false
		end
	end
	-- this must be one of the information lines. 
	-- We process these in one move, so we can continue on to the next line.
	return true
end

-- Action wheel ----------------------------------------------------------------

function songbook_action_wheel_update_select_song_action(enable)
	songbook.action_wheel.actions["select_song"]
		:title("Scroll to select song\n#"
			..songbook.action_wheel.selected_song_index
			.."/"..#songbook.sorted_song_keys
			..": \""..songbook.selected_song.name.."\""
			.."\nClick to start and stop"
		)
	if songbook.selected_song.start_time ~= nil then
		-- Song is playing
		songbook.action_wheel.actions["select_song"]
			:item("minecraft:music_disc_pigstep")
	elseif songbook.selected_song.isReady then
		songbook.action_wheel.actions["select_song"]
			:item("minecraft:music_disc_mall")
	else
		-- Song is not ready
		songbook.action_wheel.actions["select_song"]
			:item("minecraft:music_disc_11")
	end
		
	if type(enable) == "boolean" then
		songbook.action_wheel.actions["select_song"]:toggled(enable)
	end
end

function pings.set_selected_piano(piano_pos)
	songbook.selected_chloe_piano_pos = piano_pos
	if piano_pos ~= nil then
		piano_lib.playNote( songbook.selected_chloe_piano_pos , "C4", true)
	end
end

function songbook_action_wheel_select_chloe_piano()
	if songbook.playing_song ~= nil then
		print("Cannot change piano selection while playing a song.")
		return nil
	end
	
	local targeted_block = user:getTargetedBlock(true)
	if type(targeted_block.getEntityData) == "function"
		and targeted_block:getEntityData() ~= nil
		and targeted_block:getEntityData().SkullOwner ~= nil
		and targeted_block:getEntityData().SkullOwner.Name == "ChloeSpacedIn"
		-- Crashes still go through sometimes. Check permission level in the ping function? 
	then
		pings.set_selected_piano( targeted_block:getPos():toString() )
		
		songbook.action_wheel.actions["select_chloe_piano"]:toggled(true)
			:title("Select Chloe Piano\nCurrent Piano at ".. targeted_block:getPos():toString() .."\nRun this while looking away to deselect.")
		return true
	end
	if songbook.selected_chloe_piano_pos == nil then
		print("No piano found")
	else
		print("Deselecting piano")
	end
	
	songbook.action_wheel.actions["select_chloe_piano"]:toggled(false):title("Select Chloe Piano")
	pings.set_selected_piano( nil )
	return false
end

function songbook_action_wheel_page_settup()
	local root_action_wheel_page = require("Action Wheel")
	
	songbook.action_wheel = {}
	songbook.action_wheel.page = action_wheel:newPage("Songbook")
	songbook.action_wheel.selected_song_index = 1 
	songbook.action_wheel.actions = {}
	
	-- Add itself to the root action wheel 
	local enter_songbook_action = action_wheel:newAction()
		:title("Songbook")
		:item("minecraft:jukebox")
		:onLeftClick(function() 
			action_wheel:setPage(songbook.action_wheel.page)
		end)
	root_action_wheel_page:setAction(-1, enter_songbook_action)
	
	-- Back Button
	local exit_songbook_action = action_wheel:newAction()
		:title("Back")
		:item("minecraft:arrow")
		:onLeftClick(function() 
			action_wheel:setPage(root_action_wheel_page)
		end)
	songbook.action_wheel.page:setAction(1, exit_songbook_action)
	
	-- Song Selection Action: Scroll to select, Click to start and stop
	songbook.action_wheel.actions["select_song"] = action_wheel:newAction()
		:onScroll(function(scroll_dir)
			-- To invert scroll direction, multiply scroll_dir by -1.
			songbook.action_wheel.selected_song_index = songbook.action_wheel.selected_song_index + (scroll_dir*-1)
			
			-- Overflow correction
			if songbook.action_wheel.selected_song_index > #songbook.sorted_song_keys then 
				songbook.action_wheel.selected_song_index = 1
			elseif songbook.action_wheel.selected_song_index < 1 then 
				songbook.action_wheel.selected_song_index = #songbook.sorted_song_keys
			end
			
			songbook.selected_song = songbook.songs[
				songbook.sorted_song_keys[
					songbook.action_wheel.selected_song_index
				]
			]
			
			-- Update it's text and icon 
			songbook_action_wheel_update_select_song_action()
		end)
		:onToggle(function()
			pings.play_song(songbook.selected_song.name)
		end)
		:onUntoggle(function()
			print("Stopping current song...")
			pings.stop_playing_songs_ping()
		end)
	songbook.action_wheel.page:setAction(3, songbook.action_wheel.actions["select_song"] )
	songbook_action_wheel_update_select_song_action()
	
	-- Select Chloe piano.  Must be aiming at the piano player head to select. 
	-- Looking elsewhere will remove the piano.
	-- WARNING: Sometimes crashes if the piano's perms aren't high enough. 
	songbook.action_wheel.actions["select_chloe_piano"] = action_wheel:newAction()
		:title("Select Chloe Piano")
		:item("loom")
		:onLeftClick( songbook_action_wheel_select_chloe_piano )
	songbook.action_wheel.page:setAction(2, songbook.action_wheel.actions["select_chloe_piano"] )
end

return songbook