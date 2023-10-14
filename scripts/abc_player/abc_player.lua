-- Tanner Limes was here.
-- ABC Music Player V3.0.0-beta.0

-- ABC Documentation website: https://abcnotation.com/wiki/abc:standard:v2.1

-- main script vars ------------------------------------------------------------

-- User vars and imports
-- events.ENTITY_INIT:register(function ()
-- 	print("=== Dev init: ".. client.getSystemTime() .." ===")
-- end)

local song_info_text_pos_offset = vectors.vec(1, 1) -- A multiplier that ajusts
								-- the position of the info display text.
								-- By default, the info box is based on the player's hitbox.
								-- But for avatars that are larger/smaller than the player's
								-- hitbox, this setting can help keep the text visible.


-- config / performance vars:
local maximum_ping_size = 900	-- Theoretical min: ~1000
local maximum_ping_rate = 1200	-- Theoretical min: ~1000

local num_instructions_to_stop_per_tick = 500
								-- Maximum number of song instructions that
								-- this script can reset per tick. For large
								-- songs, this prevents hitting the resource
								-- limit when they get stopped.

-- Internal librariess and globals
local info_screen_anchor_part = models["scripts"]["abc_player"]["anchor"].WORLD.anchor	-- Used to attatch song info screen to avatar
local piano_lib = world.avatarVars()["b0e11a12-eada-4f28-bb70-eb8903219fe5"]
local songbook = {}
songbook.incoming_song = nil

-- Event names
local play_song_event_name = "play_song_event"
local send_packets_tick_event_name = "send_packet_tick_event"
local song_player_event_watcher_event_name = "song_player_event_watcher_event"
local info_display_event_name = "info_display_event"
local song_info_text_task_name = "song_info_text_task"

-- song list builder -----------------------------------------------------------
local function song_path_to_song_name(song_path)
	-- everything between the final slash and before `.abc`
	return song_path:match(".*/(.+)%.abc$")
end

local function song_path_to_simple_path(song_path)
	-- everything after the first slash and before `.abc`
	-- includes sub directories, excludes root song dir.
	return song_path:match("/(.+)%.abc$")
end

local function get_song_list()
	if not host:isHost() then return end

	local curr_config_file = config:getName()
	config:name("TL_Songbook_Index")
	song_list = config:load("index")
	config:name(curr_config_file)

	-- Songlist was a [] of paths. 
	-- Now it's a table of nice paths (name), and real paths (safe_path). 
	return song_list
end

-- Action Wheel Updating -------------------------------------------------------
local function song_is_queued(index)
	if not songbook.queued_song then return false end
	if not index then return songbook.queued_song ~= nil end
	if type(index) == "string" then
		return songbook.queued_song.path == index
	end
	return songbook.queued_song.path == songbook.song_list[index]
end

local function song_is_playing(index)
	if not songbook.playing_song_path then return false end
	if not index then return songbook.playing_song_path ~= nil end
	if type(index) == "string" then
		return songbook.playing_song_path == index
	end
	return songbook.playing_song_path == songbook.song_list[index]
end

local function song_is_being_stopped(index)
	if not songbook.incoming_song
	or not songbook.incoming_song.stop_loop_index
	or not songbook.playing_song_path then return false end
	if not index then return songbook.incoming_song.stop_loop_index ~= nil end
	if type(index) == "string" then
		return songbook.playing_song_path == index
	end
	return songbook.playing_song_path == songbook.song_list[index].name
end

local function songbook_action_wheel_page_update_song_picker_button()
	if not host:isHost() then return end

	local num_songs_to_display = 16

	if songbook.song_list == nil or #songbook.song_list < 1 then
		songbook.action_wheel.actions["select_song"]
			:title("No songs in song list")
			:item("minecraft:music_disc_11")
			return
	end

	local start_index = songbook.action_wheel.selected_song_index - math.floor(num_songs_to_display / 2)
	local end_index = start_index + num_songs_to_display

	if start_index < 1 then
		start_index = 1
		end_index = math.min(#songbook.song_list, num_songs_to_display +1)
	elseif end_index > #songbook.song_list then
		end_index = #songbook.song_list
		start_index = math.max(end_index - num_songs_to_display ,1)
	end

	local selected_song_state = ""

	local display_string = "Songlist: "..songbook.action_wheel.selected_song_index.."/"..tostring(#songbook.song_list)
	.. (song_is_playing() and " Currently playing: " .. song_path_to_song_name(songbook.playing_song_path.name) or "" )
	for i = start_index, end_index do
		local song_is_selected = (songbook.action_wheel.selected_song_index == i)
		-- local is_playing = song_is_playing(i)
		-- local is_queued = is_playing and false or song_is_queued(i)
		display_string = display_string .. "\n"
			.. (song_is_being_stopped(i) and "⏹" or (song_is_playing(i) and "♬" or (song_is_queued(i) and "•" or " ")) )
			.. (song_is_selected and "→" or "  ")
			.. " " ..song_path_to_simple_path(songbook.song_list[i].name)
	end

	display_string = display_string .. "\n"
	if song_is_playing(songbook.action_wheel.selected_song_index)
	or (song_is_queued(songbook.action_wheel.selected_song_index) and song_is_playing())
	then
		display_string = display_string .. "Click to stop current song"
	elseif song_is_queued(songbook.action_wheel.selected_song_index) and song_is_being_stopped() then
		display_string = display_string .. "§4Another song is still being stopped§r"
	elseif song_is_queued(songbook.action_wheel.selected_song_index) then
		display_string = display_string .. "Click to play selected song"
	else
		display_string = display_string .. "Click to queue selected song"
	end

	if song_is_queued(songbook.action_wheel.selected_song_index) then
		display_string = display_string .. "\n"
			.. (songbook.queued_song.buffer_time > maximum_ping_rate *3 and "§4" or "")
			.. "Queued song starts in "..math.ceil(songbook.queued_song.buffer_time/1000).." seconds."
	end

	songbook.action_wheel.actions["select_song"]
		:title(display_string)
		:item("minecraft:music_disc_wait")
end

-- song stopping ---------------------------------------------------------------
-- Loops through a song, stopping all active sounds and then deleting
-- the incoming_song table.
-- This is done as a tick event, since looping through all notes has a small
-- chance to hit the instruction limit.
local stop_song_tick_event_name = "stop_song_tick_event"
local function stop_playing_song_tick()

	if songbook.incoming_song == nil
		or songbook.incoming_song.stop_loop_index >= #songbook.incoming_song.instructions +1
		or #songbook.incoming_song.instructions == 0
	then

		-- song fully rewound, and all sounds have been stopped
		--print("Done rewinding song")
		events.TICK:remove(stop_song_tick_event_name)
		songbook.incoming_song = nil
		songbook.playing_song_path = nil
		songbook_action_wheel_page_update_song_picker_button()

		return
	end

	local incoming_song = songbook.incoming_song
	for instruction_index =
		math.max(songbook.incoming_song.stop_loop_index, 1),
		math.min(
			#songbook.incoming_song.instructions,
			songbook.incoming_song.stop_loop_index + num_instructions_to_stop_per_tick
		)
	do
		local instruction = songbook.incoming_song.instructions[instruction_index]

		if type(instruction.sound_id) == "Sound" then
			instruction.sound_id:stop()
		end
		instruction.sound_id = nil
		instruction.already_played = false
		songbook.incoming_song.stop_loop_index = instruction_index +1
	end
end

local function stop_playing_songs()
	-- remove song playing events. Only one of the play_song_events will
	-- be active, but it doesn't hurt to remove both?
	songbook.playing_song_path = nil
	events.TICK:remove(send_packets_tick_event_name)
	events.TICK:remove(song_player_event_watcher_event_name)
	events.RENDER:remove(play_song_event_name)
	events.TICK:remove(play_song_event_name)
	events.TICK:remove(info_display_event_name)
	events.RENDER:remove(info_display_event_name)
	if info_screen_anchor_part ~= nil then
		info_screen_anchor_part:removeTask(song_info_text_task_name)
	end
	if songbook.incoming_song ~= nil then
		-- print("stopping song "..song.name)
		songbook.incoming_song.stop_loop_index = 0
		songbook.incoming_song.start_time = nil

		events.TICK:register(stop_playing_song_tick, stop_song_tick_event_name)
	end
	if host:isHost() then
		songbook_action_wheel_page_update_song_picker_button()
	end
end

function pings.stop_playing_songs_ping()
	print("Stopping song")
	stop_playing_songs()
end

-- song builder: helpers -------------------------------------------------------
local function fracToNumber(str)
	local top, bot = str:match("(%d)/(%d)")
	--print(str.." > "..top.." / "..bot)
	return top / bot
end

local function reCalculateMilisPerNote(songbuilder)
	if 		type(songbuilder.beats_per_minute) ~= "number"
		or	type(songbuilder.default_note_length) ~= "number"
		--or	type(songbuilder.length_of_beat_in_measure) ~= "number"
	then return end

	local beats_per_second = songbuilder.beats_per_minute / 60.0
	local seconds_per_beat = 1/beats_per_second
	local beat_to_default_note_len_multiplier = 1
	if songbuilder.length_of_beat_in_measure ~= nil then
		beat_to_default_note_len_multiplier =
			songbuilder.default_note_length / songbuilder.length_of_beat_in_measure
		-- Fixes issues where the bpm (`Q:`) is set on quarter notes, but
		-- the default note length (`L:`) is written as half notes.
	else
		-- But `Q:` doesn't allways specify a specific length though. This is
		-- technicaly deprecated behavior, but still appears in some default
		-- Starbound songs. See: https://abcnotation.com/wiki/abc:standard:v2.1#outdated_information_field_syntax
		beat_to_default_note_len_multiplier = 1--/songbuilder.default_note_length
	end
	local seconds_per_note_length =
		beat_to_default_note_len_multiplier * seconds_per_beat
	local millis_per_note_length = seconds_per_note_length * 1000

	songbuilder.time_per_note = millis_per_note_length
	return millis_per_note_length
end

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

local key_signatures_keys = {
	["7#"] = {"C#", "A#M", "G#MIX", "D#DOR", "E#PHR", "F#LYD", "B#LOC"},
	["6#"] = {"F#", "D#M", "C#MIX", "G#DOR", "A#PHR", "BLYD",  "E#LOC"},
	["5#"] = {"B",  "G#M", "F#MIX", "C#DOR", "D#PHR", "ELYD",  "A#LOC"},
	["4#"] = {"E",  "C#M", "BMIX",  "F#DOR", "G#PHR", "ALYD",  "D#LOC"},
	["3#"] = {"A",  "F#M", "EMIX",  "BDOR",  "C#PHR", "DLYD",  "G#LOC"},
	["2#"] = {"D",  "BM",  "AMIX",  "EDOR",  "F#PHR", "GLYD",  "C#LOC"},
	["1#"] = {"G",  "EM",  "DMIX",  "ADOR",  "BPHR",  "CLYD",  "F#LOC"},
	["0" ] = {"C",  "AM",  "GMIX",  "DDOR",  "EPHR",  "FLYD",  "BLOC" },
	["1b"] = {"F",  "DM",  "CMIX",  "GDOR",  "APHR",  "BBLYD", "ELOC" },
	["2b"] = {"BB", "GM",  "FMIX",  "CDOR",  "DPHR",  "EBLYD", "ALOC" },
	["3b"] = {"EB", "CM",  "BBMIX", "FDOR",  "GPHR",  "ABLYD", "DLOC" },
	["4b"] = {"AB", "FM",  "EBMIX", "BBDOR", "CPHR",  "DBLYD", "GLOC" },
	["5b"] = {"DB", "BBM", "ABMIX", "EBDOR", "FPHR",  "GBLYD", "CLOC" },
	["6b"] = {"GB", "EBM", "DBMIX", "ABDOR", "BBPHR", "CBLYD", "FLOC" },
	["7b"] = {"CB", "ABM", "GBMIX", "DBDOR", "EBPHR", "FBLYD", "BBLOC"}
}

local key_signatures = {
	["7#"] = {F = "^",C = "^",G = "^",D = "^",A = "^",E = "^",D = "^",},
	["6#"] = {F = "^",C = "^",G = "^",D = "^",A = "^",E = "^",},
	["5#"] = {F = "^",C = "^",G = "^",D = "^",A = "^",},
	["4#"] = {F = "^",C = "^",G = "^",D = "^",},
	["3#"] = {F = "^",C = "^",G = "^",},
	["2#"] = {F = "^",C = "^",},
	["1#"] = {F = "^",},
	["0"]  = {},
	["1b"] = {B = "_",},
	["2b"] = {B = "_",E = "_",},
	["3b"] = {B = "_",E = "_",A = "_",},
	["4b"] = {B = "_",E = "_",A = "_",D = "_",},
	["5b"] = {B = "_",E = "_",A = "_",D = "_",G = "_",},
	["6b"] = {B = "_",E = "_",A = "_",D = "_",G = "_",C = "_",},
	["7b"] = {B = "_",E = "_",A = "_",D = "_",G = "_",C = "_",F = "_",},
}

-- song builder: notes to instructions -----------------------------------------
local function save_abc_note_to_instructions(song)	-- returns note's end time
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
	local accidentals_memory_key = note_builder.letter
		..note_builder.octave_ajustments
	local note_string = note_builder.accidentals
		.. note_builder.letter
		.. note_builder.octave_ajustments
		.. note_builder.durration_multiplier
		.. note_builder.durration_divisor

	-- Load / Save accidentals to memory / key
	if note_builder.accidentals ~= "" then
		-- If the note has manual accidentals, add them to memory
		song.songbuilder.accidentals_memory[accidentals_memory_key]
			= note_builder.accidentals

	elseif	note_builder.accidentals == "" then
		if type(song.songbuilder.accidentals_memory[accidentals_memory_key])
				~= "nil"
		then
			-- if the note has no accidentals, but it is in memory,
			-- add the memory's accidental
			note_builder.accidentals
				= song.songbuilder.accidentals_memory[accidentals_memory_key]
			note_string = note_string .. "  mem:"
				..song.songbuilder.accidentals_memory[accidentals_memory_key]
		elseif type(
				key_signatures[song.songbuilder.key_signature_key]
				              [note_builder.letter:upper()]
			) == "string"
		then
			-- If the note doesn't have it's own accidentals, and there
			-- are none set in the memory, add the accidental from the
			-- key signature
			note_builder.accidentals = note_builder.accidentals
				.. key_signatures
					[song.songbuilder.key_signature_key]
					[note_builder.letter:upper()]

			note_string = note_string .. "  key:"
				..key_signatures
					[song.songbuilder.key_signature_key]
					[note_builder.letter:upper()]
		end
	end

	-- Calculate offset from A4 in semitones. Used to find HZ multiplier.
	-- The included sound file is tuned to A4, add +3 to get F#4, Minecraft's
	-- noteblock tuneing
	local _, num_sharps = note_builder.accidentals:gsub("%^","")
	local _, num_flats = note_builder.accidentals:gsub("_","")
	local accidentals_in_semitones = num_sharps - num_flats

	local _, num_octaves_up = note_builder.octave_ajustments:gsub("'","")
	local _, num_octaves_down = note_builder.octave_ajustments:gsub(",","")
	local octave_offset = (num_octaves_up - num_octaves_down)
	local octave_offset_in_semitones = 12 * octave_offset

	local note_semitones_from_A4 =
		(letter_to_semitone_offsets[note_builder.letter] or 0)
		+ octave_offset_in_semitones
		+ accidentals_in_semitones

	-- Convert ABC note strings to Chloe Piano strings

	local semitones_from_C4 = note_semitones_from_A4 +9
	local octave_number = math.floor((semitones_from_C4+48) / 12)

	-- Note is neither flat nor sharp:
	local chloe_spaced_out_piano_note_code
		= note_builder.letter:upper()..tostring(octave_number)

	-- TODO: accidentals_in_semitones does not check if the note is double
	-- sharp or double flat.
	if accidentals_in_semitones > 0 then
		-- Note is sharp. Add "#" to the string.
		if note_builder.letter:upper() == "E" then
			-- Edge case where SBC sometimes outputs "^E" or "^B". These are
			-- invalid, so we need to upgrade them to their neutral alternative.
			chloe_spaced_out_piano_note_code = "F" ..tostring(octave_number)
		elseif note_builder.letter:upper() == "B" then
			chloe_spaced_out_piano_note_code = "C" ..tostring(octave_number+1)
		else
			chloe_spaced_out_piano_note_code
				= note_builder.letter:upper() .."#" ..tostring(octave_number)
		end
	elseif accidentals_in_semitones < 0 then
		-- This note is flat, convert to sharps
		if note_builder.letter:upper() == "C" then
			-- edge case where C flat crosses the octave line.
			chloe_spaced_out_piano_note_code = "B"..tostring(octave_number-1)
		else
			chloe_spaced_out_piano_note_code
				= chloe_piano_flat_to_sharp_table[note_builder.letter:upper()]
					..tostring(octave_number)
		end
	end

	-- Max piano range: A0 to B6
	if octave_number > 6
		or (octave_number == 0
			and not chloe_spaced_out_piano_note_code:upper():match("[AB]+")
			-- A and B are the only legal letters in octave 0
		)
		or octave_number < 1 then
		chloe_spaced_out_piano_note_code = nil
		-- Nil codes will be ignored when playing the song.
	end

	-- Save note instructions
	if	note_builder.letter:lower() ~= "z"
	and note_builder.letter:lower() ~= "x"
		-- Skip instructions for rest notes.
	then
		table.insert(song.instructions, {
			--string = note_string,
			semitones_from_a4 = note_semitones_from_A4,
				-- gets converted to a multiplier in the song player event
			chloe_piano = chloe_spaced_out_piano_note_code,
			start_time = note_builder.start_time,
			end_time = end_time,
		})
	end

	return end_time
end

local function song_data_to_instructions(song_abc_data_string)
	local song = {}

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

	for line in song_abc_data_string:gmatch("[^\n]+") do
		line = line:match("(.*)%%") or line
			-- % marks the rest of the line is a comment. Remove it and the
			-- comment from the line. (`%%` to escape the %)
		if line == nil or line == "" then
			-- do nothing
		elseif line:sub(2,2) == ":" then
			-- Metadata lines.
			-- "T:" song title. Usually wrong or unhelpful. Use filename instead.
			-- "Z:" is the song Author.
			-- "X:" is song ID. Use our own indexing system
			-- https://abcnotation.com/wiki/abc:standard:v2.1#information_field_definition

			if line:sub(1,2) == "L:" then
				song.songbuilder.default_note_length
					= fracToNumber(line:sub(3):gsub('^%s*(.-)%s*$', '%1'))
				reCalculateMilisPerNote(song.songbuilder)

			elseif line:sub(1,2) == "M:" then
				song.songbuilder.notes_per_measure
					= fracToNumber(line:sub(3):gsub('^%s*(.-)%s*$', '%1'))

			elseif line:sub(1,2) == "Q:" then
				local bpm_key = line:sub(3)
				local length_of_beat_in_measure, bpm
					= bpm_key:match("(.+)=(.+)")

				if bpm == nil then
					bpm = bpm_key:match("%d+")
					-- ^^ This usage is technicly deprecated in ABC 2.1, but some of the
					-- default starbound songs use the `Q:90` (no fraction syntax)
				else
					length_of_beat_in_measure = fracToNumber(length_of_beat_in_measure)
				end
				bpm = tonumber(bpm)

				song.songbuilder.length_of_beat_in_measure = length_of_beat_in_measure
				song.songbuilder.beats_per_minute = bpm
				reCalculateMilisPerNote(song.songbuilder)

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
			end
		else
			-- Non information line. Assume it's a chain of notes
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

				if note:match("%[") ~= nil then song.songbuilder.in_group = true end

				song.songbuilder.note_builder = {
				  	accidentals = note:match("[_=%^]+") or "",
				  	letter = note:match("%a"),
				  		-- this will match any letter, but should only be given
				  		-- A, B, C, D, E, F, G, Z, or X in upper or lower case.
				  	octave_ajustments = note:match("[,']+") or "",
				  	durration_multiplier = note:match("[%a,'](%d+)") or "",
				  	durration_divisor = note:match("/+%d*") or "",
				  		-- divisor also includes the `/` characters.
				  	start_time = song.songbuilder.next_note_start_time
				}

				local returned_note_end_time = save_abc_note_to_instructions(song)

				if song.songbuilder.in_group then
					if returned_note_end_time
						< song.songbuilder.group_earliest_stop_time
					then
						-- This check is wrong, but it works most of the time?
						-- According to the docs, The end time of the group
						-- should be set by the first note's end time, But this
						-- logic finds the shortest note in the group, and
						-- uses that end time instead.
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
		end
	end

	song.songbuilder = nil
	return song.instructions
end


-- song player event -----------------------------------------------------------
function play_song_event_loop()
	local song = songbook.incoming_song

	if 		song == nil
		or	song.all_instructions_done
	then
		print("song `".. song.name .."` finished")
		stop_playing_songs()
		return
	end

	-- find new notes to play
	song.all_instructions_done
		= (song.reseved_packets == song.num_expected_packets)
		-- default state. assume we're done if we are not waiting on more packets
	for instruction_index = math.max(1, song.current_playing_index)
			, #song.instructions
	do
		local instruction = song.instructions[instruction_index]
		if not instruction.already_played then
			song.all_instructions_done = false
		end

		if instruction.start_time + song.start_time < client.getSystemTime()
			and type(instruction.sound_id) ~= "Sound"
			and not instruction.already_played -- catches if false and if nil
			-- if current time is passed the start point of the instruction,
			-- and it currently has no sound,
			-- and we haven't played this instruction previously:
		then
			host:actionbar(
				"#"..instruction_index
				.."/"..#song.instructions
				.."/"..song.num_expected_instructions
				.." ".. instruction.chloe_piano .. (#instruction.chloe_piano > 2 and "" or " ")

			)	-- ` #20/100/2000 A4 `
			if songbook.selected_chloe_piano_pos ~= nil and piano_lib.validPos(songbook.selected_chloe_piano_pos) then
				-- Catches if the piano was broken recently.
			 	-- print("playing note "..instruction.chloe_piano.. " on piano at "..songbook.selected_chloe_piano_pos)
			 	if instruction.chloe_piano ~= "X0" then
			 		piano_lib.playNote( songbook.selected_chloe_piano_pos , instruction.chloe_piano, true)
			 	end
			 	instruction.already_played = true
			 	-- Chloe piano can't sustain notes, so we don't need to bother
			 	-- checking if the note's done playing.
			else
				--print( instruction_index.." > ".. instruction.chloe_piano)
				if avatar:canUseCustomSounds() then
					instruction.sound_id = sounds["scripts.abc_player.triangle_sin"]
				else
					instruction.sound_id = sounds["minecraft:block.note_block.bell"]
				end

				instruction.sound_id
					:setPos(player:getPos())
					:setLoop(avatar:canUseCustomSounds())
					:setPitch(avatar:canUseCustomSounds()
						and semitone_offset_to_multiplier(instruction.semitones_from_a4)
						or semitone_offset_to_multiplier(instruction.semitones_from_a4+3-12)
					)
					:setSubtitle("Music from "..player:getName())
					:play()
					-- todo: use nameplate instead of player:getName()
						-- fall back to player:getName() if nameplate name is > 48 chars.
						-- (48 == max subtitle len)
			end

		elseif	instruction.end_time + song.start_time < client.getSystemTime()
		--	and type(instruction.sound_id) == "Sound"
			-- if the end point of the instruction has passed,
			-- and it still has a sound id:
		then
			if type(instruction.sound_id) == "Sound" then
				instruction.sound_id:stop()
			end
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
					if not song.instructions[walk_index].already_played then
						-- found a note queued for the future.
						-- The previous index was our destination.
						break
					else
						-- found an old note. We'll want to skip it next loop.
						song.current_playing_index = walk_index
					end
				end
			end

		elseif instruction.start_time + song.start_time > client.getSystemTime() then
			-- If the instruction is queued for the future, break the loop.
			-- We'll come back to it when this function is called again.
			-- Instructions are sorted by start_time.
		  	break
		end
	end
end

-- Song event player control ---------------------------------------------------
-- Using the tick event doesn't give us enough presision when playing audio,
-- But the render event (at default trust) only works when the viewer is
-- looking at the avatar. This code watches if the avatar is being rendered,
-- then chooses the correct event to use.
local function is_offscreen()
	local screenspace_pos = vectors.worldToScreenSpace(
		player:getPos()
		+ vectors.vec3(0, player:getBoundingBox().y/2 , 0)
	)

	if 		screenspace_pos.x > -1 and screenspace_pos.x < 1
		and screenspace_pos.y > -1 and screenspace_pos.y < 1
		and screenspace_pos.z > 1
	then
		return false
	end
	return true
end

local time_at_last_render_event = 0
events.RENDER:register(function() time_at_last_render_event = client.getSystemTime() end)

local function should_play_with_render_event()
	if client.getSystemTime() - time_at_last_render_event > 200 then
		-- RENDER has taken too long to respond.
		-- It probably hasn't been called and we should fall back to TICK
		return false
	end
	if not is_offscreen() or avatar:canRenderOffscreen() then
		return true
	end
	return false
end

local current_song_player_event = "TICK"
local function song_player_event_watcher_event()
	-- change event if offscreen
	if should_play_with_render_event() and current_song_player_event ~= "RENDER" then
		--log("Song player Switching to RENDER")
		current_song_player_event = "RENDER"
		events.TICK:remove(play_song_event_name)
		events.RENDER:register(play_song_event_loop, play_song_event_name)
	elseif not should_play_with_render_event() and current_song_player_event ~= "TICK" then
		--log("Song player Switching to TICK")
		current_song_player_event = "TICK"
		events.RENDER:remove(play_song_event_name)
		events.TICK:register(play_song_event_loop, play_song_event_name)
	end

	-- If playing on piano, make sure it stays a valid play target.
	if songbook.selected_chloe_piano_pos ~= nil and not piano_lib.validPos(songbook.selected_chloe_piano_pos) then
		print("Piano at "..songbook.selected_chloe_piano_pos.." is now invalid and will be untargeted.")
		pings.set_selected_piano(nil)
	end
end

local function start_song_player_event()
	--print("Starting song player event")
	current_song_player_event = "TICK"
	events.TICK:register(
		song_player_event_watcher_event,
		song_player_event_watcher_event_name
	)
end

-- Display info ----------------------------------------------------------------
local spinner_states = {[1] = "▙",[2] = "▛",[3] = "▜",[4] = "▟",}
local last_spinner_state = 1
local spinner_delay_counter = 1
local spinner_delay_counter_max = 5
local function info_display_spinner()
	if spinner_delay_counter > spinner_delay_counter_max then
		last_spinner_state = (last_spinner_state+1) % #spinner_states
		spinner_delay_counter = 1
	end
	spinner_delay_counter = spinner_delay_counter + 1
	return spinner_states[last_spinner_state+1]
end

local function progress_bar(width, progress)
	local progress = math.max( 0, math.min( progress, 1 ) )
	local num_bars = math.floor((width+1) * progress)
	local num_space = width - num_bars

	local bar = "▍"	-- same width as space in minecraft	(pre 1.20)
	local version_number = client.getVersion()
	local _, num_points_in_version = client.getVersion():gsub("%.","")
	if num_points_in_version == 1 then version_number = version_number..".0" end
	-- There's a r14 Figura bug in compareVersion. It errors when comparring
	-- versions without 3 numbers, like "1.20". We're adding a `.0` to make
	-- versions like "1.20" valid.
	if client.compareVersions("1.20.0", version_number ) < 1 then
		bar = "▊"	-- minecraft updated their font for 1.20
	end

	local return_val = "▎"
	for b = 0, width do
		return_val = return_val .. (b < num_bars and bar or (b == num_bars and info_display_spinner() or  " "))
	end
	return_val = return_val .. "▎"
	return return_val
end

local info_display_current_pos = vec(0, 0, 0)
local info_display_previous_pos = vec(0, 0, 0)
local info_display_current_rot = vec(0, 0, 0)
local info_display_previous_rot = vec(0, 0, 0)

local function update_info_display_pos_rot()
	info_display_previous_pos = info_display_current_pos
	info_display_previous_rot = info_display_current_rot
	if songbook.selected_chloe_piano_pos then
		local piano_pos = vec(songbook.selected_chloe_piano_pos:match("{(-?%d*), (-?%d*), (-?%d*)}"))
		info_display_current_pos = vec(
			(piano_pos.x+0.5)*16,
			(piano_pos.y+2)*16,
			(piano_pos.z+0.5)*16
		)
	else

		local tmp = player:getPos()
		tmp.y = tmp.y + (player:getBoundingBox().y * song_info_text_pos_offset.y)

		local offset = vec(0, 0, 0)
		offset.x = -1* math.max(player:getBoundingBox().x, player:getBoundingBox().z)
		offset.x = offset.x * song_info_text_pos_offset.x
		offset = vectors.rotateAroundAxis(client.getCameraRot().y*-1, offset, vec(0, 1, 0))

		info_display_current_pos = vec(
			(tmp.x+offset.x)*16,
			tmp.y*16,
			(tmp.z+offset.z)*16
		)
	end
	tmp = client.getCameraRot()
	tmp.y = tmp.y*-1
	info_display_current_rot = tmp
end

local function update_info_display()
	local using_piano = (songbook.selected_chloe_piano_pos ~= nil)
	update_info_display_pos_rot()
		-- songbook.incoming_song.name,
		-- songbook.incoming_song.num_expected_packets,
		-- songbook.incoming_song.num_expected_instructions,
		-- songbook.incoming_song.start_time_delay

	local display_text = ""
	if songbook.incoming_song and songbook.incoming_song.start_time then
		display_text = (using_piano and player:getName() .. " is playing\n" or "Playing ")
		display_text = display_text.."\""..songbook.incoming_song.name.."\""

		-- if songbook.incoming_song.num_expected_packets > songbook.incoming_song.reseved_packets then
		-- 	display_text = display_text .. "\n"
		-- 		..songbook.incoming_song.reseved_packets
		-- 		.."/"..songbook.incoming_song.num_expected_packets
		-- 		.." packets loaded"
		-- 		-- .."\n"..info_display_spinner()
		-- end

		if songbook.incoming_song.start_time > client.getSystemTime() then
			-- songbook.incoming_song.first_packet_received_time
			display_text = display_text .. "\nBuffering: "
				..tostring( math.round((songbook.incoming_song.start_time - client.getSystemTime()) /1000) )
				.."s left ".. info_display_spinner()
		else
			display_text = display_text
				.. "\n".. progress_bar((using_piano and 35 or 20), (client.getSystemTime() - songbook.incoming_song.start_time) / songbook.incoming_song.song_length)
				.. " " .. math.ceil((songbook.incoming_song.end_time - client.getSystemTime()) / 1000) .. "s"
		end

	else
		display_text = "No song playing"
	end

	local targeted_entity = client.getViewer():getTargetedEntity()
	local should_display_info = false
	if targeted_entity then
		should_display_info = ( ( targeted_entity:getUUID() == avatar:getUUID() ) )
	end
	if not should_display_info then
		should_display_info = using_piano
	end

	local pos = player:getPos()
	songbook.info_display_task
		:setPos( using_piano and vec(0,8,0) or vec(0,0,0) )
		:setScale(0.25, 0.25, 0.25)
		:shadow(true)
		:width( using_piano and 300 or 150 )
		:setAlignment(using_piano and "CENTER" or "LEFT")
		:setText(display_text)
		-- :setLight(math.max(world.getLightLevel(player:getPos()), 8), world.getSkyLightLevel(player:getPos()) )

	if songbook.info_display_task.setVisible then
		-- FN name changed. Re evaluate when r15 is stable.
		-- Set enable for r14, set visible for dev as of Jun 8th, 2023
		songbook.info_display_task:setVisible(should_display_info or (host:isHost() and not renderer:isFirstPerson() ) )
	else
		songbook.info_display_task:setEnabled(should_display_info or (host:isHost() and not renderer:isFirstPerson() ) )
	end

end

local function info_display_tick_event()
	update_info_display()
end

local function info_display_render_event(delta)
	info_screen_anchor_part:setPos(
		math.lerp(info_display_previous_pos.x, info_display_current_pos.x, delta),
		math.lerp(info_display_previous_pos.y, info_display_current_pos.y, delta),
		math.lerp(info_display_previous_pos.z, info_display_current_pos.z, delta)
	)
	info_screen_anchor_part:setRot(
		math.lerpAngle(info_display_previous_rot.x, info_display_current_rot.x, delta),
		math.lerpAngle(info_display_previous_rot.y, info_display_current_rot.y, delta),
		math.lerpAngle(info_display_previous_rot.z, info_display_current_rot.z, delta)
	)

	--songbook.info_display_task
		--:setPos(math.lerp(info_display_previous_pos, info_display_current_pos, delta))
		--:setRot(math.lerpAngle(info_display_previous_rot, info_display_current_rot, delta))
end

local function start_info_display_event()
	if info_screen_anchor_part == nil then return end
	songbook.info_display_task = info_screen_anchor_part:newText(song_info_text_task_name)
	events.TICK:register(info_display_tick_event, info_display_event_name)
	events.RENDER:register(info_display_render_event, info_display_event_name)
end

-- Data transfer ---------------------------------------------------------------
function pings.deserialize(packet_string)
	-- if packet_string:sub(1,1) == "e" then -- found stop packet
	-- 	stop_playing_songs()
	-- end
	if songbook.incoming_song == nil then
		if packet_string:sub(1,1) ~= "n" then
			print("deserialize() Found an instruction packet, but we haven't seen a song-start packet yet!")
			return
		end

		songbook.incoming_song = {}
		songbook.incoming_song.name,
			songbook.incoming_song.num_expected_packets,
			songbook.incoming_song.num_expected_instructions,
			songbook.incoming_song.start_time_delay,
			songbook.incoming_song.song_length
			= packet_string:match("n(.*)//p(%d*)i(%d*)d(%d*)e(%d*)")

		songbook.incoming_song.num_expected_packets = tonumber(songbook.incoming_song.num_expected_packets)
		songbook.incoming_song.num_expected_instructions = tonumber(songbook.incoming_song.num_expected_instructions)
		songbook.incoming_song.start_time_delay = tonumber(songbook.incoming_song.start_time_delay)

		songbook.incoming_song.start_time = client.getSystemTime() + songbook.incoming_song.start_time_delay
			+ maximum_ping_rate -- Ensures there will always be at least one packet waiting and ready to go.

		songbook.incoming_song.end_time = songbook.incoming_song.start_time + songbook.incoming_song.song_length

		songbook.incoming_song.first_packet_received_time = client.getSystemTime()

		songbook.incoming_song.reseved_packets = 1
		songbook.incoming_song.instructions = {}

		if not host:isHost() then
			print("Deserializer got the first of ".. songbook.incoming_song.num_expected_packets .." packets")
			print("Receiving data for `".. songbook.incoming_song.name .."`")
		end

		songbook.incoming_song.current_playing_index = 0

		start_info_display_event()
		start_song_player_event()
	else
		if packet_string:sub(1,1) == "n" then
			print("deserialize() Expected a data packet, but found the start of a song!")
			-- We are probably out of sync with the host!
			print("Ending current song to start new song.")
			stop_playing_songs()
			songbook.incoming_song = nil
			pings.deserialize(packet_string)
			return
		end

		songbook.incoming_song.reseved_packets = songbook.incoming_song.reseved_packets +1
		--print("Deserializer got packet "..songbook.incoming_song.reseved_packets.."/"..songbook.incoming_song.num_expected_packets)

		for serialized_instruction in packet_string:gmatch("[^%s]*") do	-- splits on space
			local song_instruction = {}
			song_instruction.start_time,
				song_instruction.end_time,
				song_instruction.semitones_from_a4,
				song_instruction.chloe_piano
				= serialized_instruction:match("s([^%a]+)e([^%a]+)t(%-?[^%a]+)p(%a#?%d)")

			song_instruction.start_time = tonumber(song_instruction.start_time)
			song_instruction.end_time = tonumber(song_instruction.end_time)
			song_instruction.semitones_from_a4 = tonumber(song_instruction.semitones_from_a4)

			--printTable(song_instruction)
			table.insert(songbook.incoming_song.instructions, song_instruction)

			if not song_instruction or song_instruction == {} or not song_instruction.start_time then
				printTable(song_instruction)
				print(serialized_instruction)
				error("soups")
			end

		end
		if songbook.incoming_song.reseved_packets == songbook.incoming_song.num_expected_packets and not host:isHost() then
			print("Deserializer got last packet")
		end
	end
end

local outgoing_packets
local function send_packets_tick_event()
	-- call as a tick event
	if client.getSystemTime() > outgoing_packets.first_packet_send_time
		+ (maximum_ping_rate * outgoing_packets.previous_index)
	then
		local current_index = outgoing_packets.previous_index +1

		if current_index > #outgoing_packets.packets then
			-- break event if there are no more packets to send
			print("All packets sent to listeners")
			events.TICK:remove( send_packets_tick_event_name )
			outgoing_packets = nil
			return
		end

		--print("sending packet "..current_index.."/"..#outgoing_packets.packets.. " ("..#(outgoing_packets.packets[current_index])..")")
		--printTable(outgoing_packets.packets)
		pings.deserialize(outgoing_packets.packets[current_index])

		outgoing_packets.previous_index = current_index
	end
end

local function send_packets(packets)
	outgoing_packets = {}
	outgoing_packets.packets = packets
	outgoing_packets.previous_index = 0
	outgoing_packets.first_packet_send_time = client.getSystemTime()

	events.TICK:register(
		send_packets_tick_event,
		send_packets_tick_event_name
	)
end

local function song_instructions_to_packets(song_file_path, song_instructions)
	local minimum_song_start_delay = maximum_ping_rate
	local ping_packets = {}
	local packet_builder = ""
	table.insert(ping_packets, "placeholder for expected packets/instructions and when to start playing the song.")
	local last_end_time = 0
	for index, instruction in ipairs(song_instructions) do

		-- Check if we've buffered the song enough to play this instruction on time
		local earliest_time_supported_by_this_packet =
			maximum_ping_rate*(#ping_packets) - minimum_song_start_delay
		if instruction.start_time < earliest_time_supported_by_this_packet then
			-- This case can appear when a packet holds less than
			-- 1 second's worth of information. (Ie when the song plays several
			-- notes at the same time.) Use minimum_song_start_delay to
			-- add more time for the pings to arrive before they need to play

			-- print("Instruction #"..index.." starts too early!"
			-- 	.."\nInstruction start time: "..instruction.start_time
			-- 	.."\nEarliest supported time: "..earliest_time_supported_by_this_packet
			-- )
			minimum_song_start_delay = math.ceil(minimum_song_start_delay + earliest_time_supported_by_this_packet - instruction.start_time)

			earliest_time_supported_by_this_packet =
				maximum_ping_rate*(#ping_packets) - minimum_song_start_delay

			-- print("Minimum song delay increased to "..minimum_song_start_delay
			-- .."\nEarliest supported time is now "..earliest_time_supported_by_this_packet
			-- .."\n("..(earliest_time_supported_by_this_packet/1000).."s) ("..((earliest_time_supported_by_this_packet/1000) /60).."m)")
		end

		local serialized_instruction =
			  "s"..( string.format("%0d",instruction.start_time) )	-- D drops the decimal place, which is fine since we are allready timing everything in miliseconds. We don't need 11 digets of sub-milisecond presision
			.."e"..( string.format("%0d",instruction.end_time) )
			.."t"..( string.format("%0d",instruction.semitones_from_a4) )
			.."p"..( instruction.chloe_piano and instruction.chloe_piano or "X0" )		-- Piano commands might be nil if out of range. Replace with X.
		-- if instruction.chloe_piano == nil then print(serialized_instruction) end

		if instruction.end_time > last_end_time then last_end_time = instruction.end_time end

		if #(packet_builder..serialized_instruction) >= maximum_ping_size then
			table.insert(ping_packets, packet_builder)
			packet_builder = ""
		end
		if packet_builder == "" then
			packet_builder = serialized_instruction
		else
			-- deserializer splits on spaces.
			-- (too lazy to get splitting on s to work correctly)
			packet_builder = packet_builder .. " " .. serialized_instruction
		end
	end
	-- Out of loop, dump left over packets to table
	if packet_builder ~= "" then table.insert(ping_packets, packet_builder) end

	-- Info packet. Reserve this space before inserting instructions. (or append this packet to the front. it needs to be sent first)
	ping_packets[1] = "n"..song_path_to_song_name(song_file_path.name).."//"	-- // for end of name
		.."p".. #ping_packets
		.."i".. #song_instructions
		.."d".. minimum_song_start_delay
		.."e".. last_end_time

	return ping_packets, minimum_song_start_delay
end

-- Song playing ----------------------------------------------------------------
local function queue_song(song_file_path)
	songbook.queued_song = {}

	local current_config_path = config:getName()
	config:name(
		song_file_path.safe_path:gsub(".json", "")
		-- TODO: we don't need the js extension inside of Lua. 
		-- we can remove it from the JS side
	)
	local song_file = config:load(song_file_path.safe_path)
	config:name(current_config_path)
	
	-- print("Preparing to play "..song_path_to_simple_path(song_file_path.name))

	if song_file ~= nil and song_file.data == nil then
		-- TODO: Sanity check.
		print("No song found at `".. song_file_path.name .."`.")
		return
	end
	local song_abc_data = song_file.data

	-- Convert data to instructions.
	--print("Generating instructions...")

	local song_instructions = song_data_to_instructions(song_abc_data)
	--print("Generated "..#song_instructions.." instructions.")

	local packets, time_to_start = song_instructions_to_packets(song_file_path, song_instructions)

	--print("serializer made "..#packets.." packets")
	--print("The song lasts "..math.ceil(song_instructions[#song_instructions].start_time /1000).."s")
	-- if maximum_ping_rate*5 < time_to_start then
	-- 	print("This song is heavy. It will take "..math.ceil(time_to_start/1000).." seconds to buffer enough packets")
	-- end

	songbook.queued_song.path = song_file_path
	songbook.queued_song.buffer_time = time_to_start
	songbook.queued_packets = packets
	print("Ready to play "..song_path_to_simple_path(song_file_path.name)
		.. (maximum_ping_rate*5 < time_to_start and
			"\n  song run time " ..math.ceil(song_instructions[#song_instructions].start_time /1000) .. "s"
			.."\n  §4song needs to buffer for ".. math.ceil(time_to_start/1000).."s§r"
		or "")
		.."\n  Total run time: "..math.ceil(song_instructions[#song_instructions].start_time /1000) + math.ceil(time_to_start/1000) .."s"
	)
end

local function play_song(song_file_path)
	if song_file_path ~= songbook.queued_song.path then
		log("`"..song_path_to_simple_path(song_file_path).."` is not queued yet. Doing that now.")
		queue_song(song_file_path)
	end
	print("Playing "..song_path_to_simple_path(song_file_path.name))
	songbook.playing_song_path = song_file_path
	--print("Sending packets to listeners.")
	send_packets(songbook.queued_packets)
end

-- Piano and Actionwheel -------------------------------------------------------
local function is_block_piano(targeted_block)	-- if true, 2nd value is the lib for the piano
	if type(targeted_block) == "Vector3" then
		targeted_block = world.getBlockState(targeted_block)
	end

	if type(targeted_block) == "BlockState"
		and type(targeted_block.getEntityData) == "function"
		and targeted_block:getEntityData() ~= nil
		and targeted_block:getEntityData().SkullOwner ~= nil
	then	-- targeted block has a skull
		if targeted_block:getEntityData().SkullOwner.Name == "ChloeSpacedIn" then
			return true, world.avatarVars()["b0e11a12-eada-4f28-bb70-eb8903219fe5"]

		elseif table.concat(targeted_block:getEntityData().SkullOwner.Id)
				== table.concat({-1808656131,1539063829,-1082155612,-209998759})
			-- ^^ Immortalized piano skull ID
		then
			return true, world.avatarVars()["943218fd-5bbc-4015-bf7f-9da4f37bac59"]
		end
	end
	return false, nil
end

function pings.set_selected_piano(piano_block_pos)
	if piano_block_pos == nil then
		-- A nill value was an intentional "clear the current piano" opperation.
		songbook.selected_chloe_piano_pos = nil
		if host:isHost() then
			songbook.action_wheel.actions["select_chloe_piano"]:toggled(false):title("Select Chloe Piano")
		end
		return
	end

	local block_is_piano, block_piano_lib = is_block_piano(piano_block_pos)

	if block_is_piano and block_piano_lib ~= nil and block_piano_lib.playNote ~= nil then
		songbook.selected_chloe_piano_pos = tostring(piano_block_pos)
		piano_lib = block_piano_lib

		log("targeted piano at "..tostring(piano_block_pos))
		piano_lib.playNote( songbook.selected_chloe_piano_pos , "C4", true)
		if host:isHost() then
			songbook.action_wheel.actions["select_chloe_piano"]:toggled(true)
				:title("Select Chloe Piano\nCurrent Piano at ".. songbook.selected_chloe_piano_pos .."\nClick while looking away to deselect.")
		end
	else
			-- Host tried to set a piano at this position, but for whatever reason, we failed find a piano at that pos
			log("Couldn't find Piano at "..tostring(piano_block_pos))
	end
end

local function songbook_action_wheel_select_chloe_piano()
	local targeted_block = user:getTargetedBlock(true)
	local block_is_piano, _ = is_block_piano(targeted_block)

	if block_is_piano then
		pings.set_selected_piano( targeted_block:getPos() )
		return true
	end
	if songbook.selected_chloe_piano_pos == nil then
		print("No piano found")
	else
		print("Deselecting piano")
	end

	pings.set_selected_piano( nil )
	return false
end

local function songbook_action_wheel_page_setup()
	songbook.action_wheel = {}
	songbook.action_wheel.page = action_wheel:newPage("Songbook")
	songbook.action_wheel.entry_point = nil
	songbook.action_wheel.selected_song_index = 1
	songbook.action_wheel.actions = {}

	-- Create action wheel page entry point
	songbook.action_wheel.actions["enter_songbook"] = action_wheel:newAction()
		:title("Songbook")
		:item("minecraft:jukebox")
		:onLeftClick(function()
			songbook.action_wheel.entry_point = action_wheel:getCurrentPage()
			action_wheel:setPage(songbook.action_wheel.page)
		end)
	--root_action_wheel_page:setAction(-1, enter_songbook_action)

	-- Back Button
	songbook.action_wheel.actions["exit_songbook"] = action_wheel:newAction()
		:title("Back")
		:item("minecraft:arrow")
		:onLeftClick(function()
			action_wheel:setPage(songbook.action_wheel.entry_point)
		end)
	songbook.action_wheel.page:setAction(1,
		songbook.action_wheel.actions["exit_songbook"]
	)

	-- Song Selection Action: Scroll to select, Click to start and stop
	songbook.action_wheel.actions["select_song"] = action_wheel:newAction()
		:onScroll(function(scroll_dir)
			-- To invert scroll direction, multiply scroll_dir by -1.
			local scroll_speed_multiplier = 1
			if keybinds:getKeybinds()["Scroll song list faster"]:isPressed() then
				scroll_speed_multiplier = scroll_speed_multiplier *20
			end

			songbook.action_wheel.selected_song_index
				= songbook.action_wheel.selected_song_index + (scroll_dir*scroll_speed_multiplier*-1)

			-- Overflow correction
			if songbook.action_wheel.selected_song_index > #songbook.song_list
			then
				songbook.action_wheel.selected_song_index = 1
			elseif songbook.action_wheel.selected_song_index < 1 then
				songbook.action_wheel.selected_song_index = #songbook.song_list
			end

			-- Update it's text and icon
			songbook_action_wheel_page_update_song_picker_button()
		end)

		:onLeftClick(function()
			if song_is_playing(songbook.action_wheel.selected_song_index)
			or (song_is_queued(songbook.action_wheel.selected_song_index) and song_is_playing())
			then
				-- reselecting the playing song should stop it
				-- If trying to play a new song, stop old song
				pings.stop_playing_songs_ping()
			elseif song_is_queued(songbook.action_wheel.selected_song_index)
			and not song_is_being_stopped()
			then
				play_song(songbook.song_list[songbook.action_wheel.selected_song_index])
			else
				queue_song(songbook.song_list[songbook.action_wheel.selected_song_index])
			end

			songbook_action_wheel_page_update_song_picker_button()
		end)

	songbook.action_wheel.page:setAction(3,
		songbook.action_wheel.actions["select_song"]
	)
	songbook_action_wheel_page_update_song_picker_button()

	-- Select Chloe piano.  Must be aiming at the piano player head to select.
	-- Looking elsewhere will remove the piano.
	-- WARNING: Sometimes crashes if the piano's perms aren't high enough.
	songbook.action_wheel.actions["select_chloe_piano"] = action_wheel:newAction()
		:title("Select Chloe Piano")
		:item("loom")
		:onLeftClick( songbook_action_wheel_select_chloe_piano )
	songbook.action_wheel.page:setAction(2, songbook.action_wheel.actions["select_chloe_piano"] )
end

-- Keybinds --------------------------------------------------------------------
local function init_keybinds()
	keybinds:newKeybind(
		"Scroll song list faster",
		keybinds:getVanillaKey("key.sneak")
	)
	--printTable(keybinds:getKeybinds()["Scroll song list faster"])
end

-- globals / returns -----------------------------------------------------------

function get_songbook_actions()
	return songbook.action_wheel.actions
end

function get_currently_playing_song()
	return song_is_playing() and song_path_to_song_name(songbook.playing_song_path) or nil
end

songbook.song_list = get_song_list()
init_keybinds()
songbook_action_wheel_page_setup()
return songbook.action_wheel.actions["enter_songbook"]
