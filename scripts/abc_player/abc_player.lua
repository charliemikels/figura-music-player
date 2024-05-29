-- Tanner Limes was here.
-- ABC Music Player V3.0.1

-- ABC Documentation website: https://abcnotation.com/wiki/abc:standard:v2.1

-- main script vars ------------------------------------------------------------

-- User vars and imports
-- events.ENTITY_INIT:register(function ()
-- 	print("=== Dev init: ".. client.getSystemTime() .." ===")
-- end)

local songbook_root_file_path = "TL_Songbook"  -- default is `"TL_Songbook"`

local song_info_text_pos_offset = vectors.vec(1, 1) -- A multiplier that ajusts
								-- the position of the info display text.
								-- By default, the info box is based on the player's hitbox.
								-- But for avatars that are larger/smaller than the player's
								-- hitbox, this setting can help keep the text visible.


-- config / performance vars:
local default_maximum_ping_size  = 900	-- Theoretical max: ~1000
local default_maximum_ping_rate  = 1200	-- Theoretical min: ~1000
local slowmode_maximum_ping_size = 500
local slowmode_maximum_ping_rate = 1750
local slowmode = false

local maximum_ping_size = default_maximum_ping_size	-- Theoretical max: ~1000
local maximum_ping_rate = default_maximum_ping_rate	-- Theoretical min: ~1000


local num_instructions_to_stop_per_tick = 500
								-- Maximum number of song instructions that
								-- this script can reset per tick. For large
								-- songs, this prevents hitting the resource
								-- limit when they get stopped.

								-- this is ignored in failsafe emergency stop
								-- and instead uses 1 instruction per tick.
								-- This makes it safe to use in the world tick

-- Internal librariess and globals
local info_screen_anchor_part = models["scripts"]["abc_player"]["anchor"].WORLD.anchor	-- Used to attatch song info screen to avatar
local piano_lib = world.avatarVars()["b0e11a12-eada-4f28-bb70-eb8903219fe5"]
local songbook = {}
songbook.incoming_song = nil

-- Event names
local play_song_event_name = "play_song_event"
local send_packets_tick_event_name = "send_packet_tick_event"
local song_player_event_watcher_event_name = "song_player_event_watcher_event"
local avatar_is_loaded_watcher_event_name = "player_is_loaded_watcher_event"
local info_display_event_name = "info_display_event"
local song_info_text_task_name = "song_info_text_task"

-- song list builder -----------------------------------------------------------
local function get_song_list()
	if not host:isHost() then return end

	if not file:isPathAllowed(songbook_root_file_path) then
		-- short-circut future file api requests. 
		print("⚠ Invalid songbook path: `[figura_root]/data/"..tostring(songbook_root_file_path).."`.")
		print("⚠ Check the `songbook_root_file_path` variable.")
		return {}
	end

	if not file:isDirectory(songbook_root_file_path)
	then
		print("Songbook data folder not found")

		if songbook_root_file_path and type(songbook_root_file_path) == "string" then
			local mkdir_was_successfull = file:mkdirs(songbook_root_file_path)
			
			if mkdir_was_successfull then
				print("Created a new songbook folder at `[figura_root]/data/"..songbook_root_file_path.."`")
				print("Place `.abc` song files here, then reload the avatar.")
			else
				print("⚠ Failed to create songbook folder at `[figura_root]/data/"..songbook_root_file_path.."`")
			end

		else
			print("⚠ Can't create new songbook folder at `[figura_root]/data/"..tostring(songbook_root_file_path).."`")
			print("⚠ Check the `songbook_root_file_path` variable.")
		end

		-- songbook was not found. whether we were able to 
		-- create a new one or not, there will be no data to 
		-- find there anyways. Just return `{}`
		return {}
	end

	local song_list = {}
	--	song_list = { 
	--		1: {
	--			name, 			-- string. Short name of file. Excludes path and `.abc`		-- used in display board
	--			display_path	-- string. Path excluding `songbook_root_file_path`			-- used in song picker
	--			full_paths: {	-- table of strings. Set of full paths for files API
	--				1: "Path to main instrument"
	--				2: "Path to percussion track" (if available)
	--				3: "path to TBD 3rd instrument track" (May never be used.)
	--				-- full_path index represents the instrument to use to play the file. Must be an int. 
	--			}		
	-- 		},
	-- 		2: { etc… },
	--		…
	--	}

	-- songbook may have either song files, or directories. 
	-- file:list() doesn't tell us if a path is a directory or a file. 
	-- we need to check all of them. 
	local paths_to_test = file:list(songbook_root_file_path);

	while #paths_to_test > 0 do 
		local current_path = table.remove(paths_to_test)
		local full_path = songbook_root_file_path .. "/" .. current_path

		if file:isDirectory(full_path) then
			-- Path is a directory, put its contents into the test loop. 
			for _,v in ipairs(file:list(full_path)) do
				table.insert(paths_to_test, (current_path .. "/" .. v))
			end
		elseif file:isFile(full_path) then
			if full_path:match("%.([^%.]+)$"):lower() == "abc" then
				song_list[current_path] = {
					name = current_path:match("([^/]*)%."), -- everything after last / and before last .
					display_path = current_path,
					full_paths = {full_path}
				}
			end
		end
	end

	-- Rescan final list to merge songs with drum tracks. 

	for key, song in pairs(song_list) do
		-- captures tags like ` - Drums` and ` (Percussion)`
		local drums_marker_start_index, drums_marker_end_index = 
			song.display_path:lower():find("%s*%-?%s?%(?percussion%)*%s*")
		if not drums_marker_start_index then
			drums_marker_start_index, drums_marker_end_index = 
				song.display_path:lower():find("%s*%-?%s?%(?drums?%)*%s*")
		end

		if drums_marker_start_index then 
			tag_trimmed_display_name = 
				song.display_path:sub(1, drums_marker_start_index-1) 
				.. song.display_path:sub(drums_marker_end_index+1)
			
			local base_song = song_list[tag_trimmed_display_name]
				or song_list[tag_trimmed_display_name:sub(1,-5)
								.." (all)"
								..tag_trimmed_display_name:sub(-5+1)
							]
				or song_list[tag_trimmed_display_name:sub(1,-5)
								.." (All)"
								..tag_trimmed_display_name:sub(-5+1)
							]
				or song_list[tag_trimmed_display_name:sub(1,-5)
								.." (lead)"
								..tag_trimmed_display_name:sub(-5+1)
							]
				or song_list[tag_trimmed_display_name:sub(1,-5)
								.." (Lead)"
								..tag_trimmed_display_name:sub(-5+1)
							]

			if base_song then
				base_song.full_paths[2] = song.full_paths[1]
				base_song.display_path = base_song.display_path .. " 🥁"

				song_list[key] = nil
			else
				-- failed to find the base song, but this song fit the search pattern. 
				-- Set this song instrument to drums anyways
				song.full_paths[2] = song.full_paths[1]
				song.full_paths[1] = nil
				song.display_path = song.display_path .. " §6⚠§r"
			end
		end
	end

	-- Manipulation is done. Convert to int-indexed table for sorting. 
	int_index_song_list = {}
	for _, song in pairs(song_list) do
		table.insert(int_index_song_list, #int_index_song_list +1, song)
	end
	table.sort(int_index_song_list, function(a,b) return a.display_path:lower() < b.display_path:lower() end)

	if #int_index_song_list < 1 then 
		print("No songs found. Add `.abc` song files to `[figura_root]/data/"..songbook_root_file_path.."`. Then reload the avatar.")
		-- idealy, this check would happen sooner, but the # syntax only works on int-indexed tables. ¯\_ :/ _/¯ 
	end

	return int_index_song_list
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
	return songbook.playing_song_path == songbook.song_list[index].display_path
end

local function songbook_action_wheel_page_update_song_picker_button()
	if not host:isHost() then return end

	local num_songs_to_display = 16

	if songbook.song_list == nil or #songbook.song_list < 1 then
		songbook.action_wheel.actions["select_song"]
			:title(
				"No songs in song list."
				..(file:isPathAllowed(songbook_root_file_path) 
					and "\nAdd `.abc` files to [figura_root]/data/"..tostring(songbook_root_file_path).."`" 
					or "\nCorret the `songbook_root_file_path` variable"
				)
				.."\nthen reload the avatar."
			)
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

	local display_string = "Songlist: "..songbook.action_wheel.selected_song_index.."/"..tostring(#songbook.song_list)
	.. (song_is_playing() and " Currently playing: " .. songbook.playing_song_path.name or "" )

	if slowmode then
		display_string = display_string .. "\n"
			.. "§4Slow mode enabled. Right click to disable.§r"
	end

	for i = start_index, end_index do
		local song_is_selected = (songbook.action_wheel.selected_song_index == i)
		-- local is_playing = song_is_playing(i)
		-- local is_queued = is_playing and false or song_is_queued(i)
		display_string = display_string .. "\n"
			.. (song_is_being_stopped(i) and "⏹" or (song_is_playing(i) and "♬" or (song_is_queued(i) and "•" or " ")) )
			.. (song_is_selected and (slowmode and "§4→§r" or "→") or "  ")
			.. " " ..songbook.song_list[i].display_path
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
local stopping_with_world_tick = false
local function stop_playing_song_tick()

	if songbook.incoming_song == nil
		or songbook.incoming_song.stop_loop_index >= #songbook.incoming_song.instructions +1
		or #songbook.incoming_song.instructions == 0
	then

		-- song fully rewound, and all sounds have been stopped
		songbook.incoming_song = nil
		songbook.playing_song_path = nil
		if stopping_with_world_tick then
			events.WORLD_TICK:remove(stop_song_tick_event_name)
			print("Done rewinding song")
			stopping_with_world_tick = false -- reset so that we can play a new song again.  
		else
			events.TICK:remove(stop_song_tick_event_name)
			if host:isHost() then
				-- this opperation is too expensive to run in world_tick.
				-- so just don't lol. >:) :sunglasses:
				songbook_action_wheel_page_update_song_picker_button()
			end
		end

		return
	end

	local incoming_song = songbook.incoming_song

	for instruction_index =
		math.max(songbook.incoming_song.stop_loop_index, 1),
		math.min(
			#songbook.incoming_song.instructions,
			songbook.incoming_song.stop_loop_index 
				+ (stopping_with_world_tick and 1 or num_instructions_to_stop_per_tick)
				-- In the event that there are still notes playing when we 
				-- stopped the song, and the avatar is unloaded (is using 
				-- the world tick event) then this will take a LONG time 
				-- for the playing notes to actualy clear out. But! This is 
				-- suposed to be a failsafe for if the avatar is too far away 
				-- anyways for the TICK event to happen. 
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
	events.TICK:remove(send_packets_tick_event_name)				-- data transfer event.
	events.TICK:remove(song_player_event_watcher_event_name)		-- if avatar goes off screen, changes player event to TICK
	events.WORLD_TICK:remove(avatar_is_loaded_watcher_event_name)	-- if player unloads, stop the song
	events.RENDER:remove(play_song_event_name)						-- core songplayer
	events.TICK:remove(play_song_event_name)						-- core songplayer. Usualy a render event
	events.TICK:remove(info_display_event_name)						-- Info pannel controller
	events.RENDER:remove(info_display_event_name)					-- Info pannel controller. Usualy a render event

	-- reset elements after killing the critical events. 
	if info_screen_anchor_part ~= nil then
		info_screen_anchor_part:removeTask(song_info_text_task_name)
	end
	if songbook.incoming_song ~= nil then
		-- print("stopping song "..songbook.incoming_song.name)
		songbook.incoming_song.stop_loop_index = 0
		songbook.incoming_song.start_time = nil

		if player:isLoaded() then
			stopping_with_world_tick = false
			events.TICK:register(stop_playing_song_tick, stop_song_tick_event_name)
		else
			print("Avatar unloded: Stopping song with world_tick.")
			stopping_with_world_tick = true
			events.WORLD_TICK:register(stop_playing_song_tick, stop_song_tick_event_name)
		end
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
local function isUsingPiano()
	if 		songbook.selected_chloe_piano_pos ~= nil 
		and piano_lib.validPos(songbook.selected_chloe_piano_pos) 
	then 
		return true 
	else 
		return false 
	end
end

local function getPianoPos()
	return vec(songbook.selected_chloe_piano_pos:match("{(-?%d*), (-?%d*), (-?%d*)}"))
end

local drumkitSoundsTable = {
	-- Table of functions that return a sound, so that we'll get a fresh sound every time. 
	-- use with drumkitSoundLookup()
	-- keys are midi codes. see https://zendrum.com/resource-site/drumnotes.htm

	-- semi-incomplete

	[35] = function() -- Acoustic Bass Drum	
		return sounds["block.note_block.basedrum"]:pitch(0.7)
	end,
	[36] = function() -- Bass Drum 1
		return sounds["block.note_block.basedrum"]:pitch(0.8)
	end,
	[37] = function() -- Side Stick
		return sounds["block.note_block.hat"]:pitch(0.8)
	end,
	[38] = function() -- Acoustic Snare
		return sounds["block.note_block.snare"]:pitch(0.7)
	end,
	[39] = function() -- Hand Clap
		return sounds["block.note_block.hat"]:pitch(1)
	end,
	[40] = function() -- Electric snare
		return sounds["block.note_block.snare"]:pitch(0.8)
	end,
	[41] = function() -- Low Floor Tom
		return sounds["block.note_block.basedrum"]:pitch(1.25)
	end,
	[42] = function() -- Closed Hi-Hat
		return sounds[ "block.note_block.hat" ]:pitch(4)
	end,
	[43] = function() -- High Floor Tom
		return sounds["block.note_block.basedrum"]:pitch(1.3)
	end,
	[44] = function() -- Pedal Hi-Hat
		return sounds[ "item.trident.riptide_1" ]:pitch(6 )
	end,
	[45] = function() -- Low Tom
		return sounds["block.note_block.basedrum"]:pitch(1.35)
	end,
	[46] = function() -- Open Hi-Hat
		return sounds[ "item.trident.hit_ground" ]:pitch(6 )
	end,
	[47] = function() -- Low-Mid Tom
		return sounds["block.note_block.basedrum"]:pitch(1.4)
	end,
	[48] = function() -- High-Mid Tom
		return sounds["block.note_block.basedrum"]:pitch(1.45)
	end,
	[49] = function() -- Crash Cymbal 1
		return sounds["item.trident.hit_ground"]:pitch(2)		-- has variations
	end,
	[50] = function() -- High Tom
		return sounds["block.note_block.basedrum"]:pitch(1.5)
	end,
	[51] = function() -- Ride Cymbal 1
		return sounds[ "block.bell.use" ]:pitch(4)			-- has variations
	end,
	[52] = function()	-- Chinese Cymbal
		return sounds[ "block.bell.use" ]:pitch(5)		-- has variations
	end,
	[53] = function() -- Ride Bell
		return sounds[ "block.bell.use" ]:pitch(3)	-- has variations
	end,
	[54] = function() --Tambourine
		return sounds[ "block.beehive.shear" ]:pitch(3.2 )
	end,
	[55] = function() -- Splash Cymbal
		return sounds[ "block.bell.use" ]:pitch(6)		-- has variations
	end,
	[56] = function() -- Cowbell
		return sounds[ "block.note_block.cow_bell" ]:pitch(1.1)
	end,
	[57] = function() -- Crash Cymbal 2
		-- SBC's Crash 2 is nearly identical to Crash 1
		return sounds["item.trident.hit_ground"]:pitch(2)	-- has variations
	end,
	[58] = function() -- Vibroslap
		return sounds[ "entity.arrow.hit" ]:pitch(1.6)		-- has variations
	end,
	[59] = function() -- Ride Cymbal 2
		return sounds[ "block.bell.use" ]:pitch(4.5)	-- has variations
	end,
	[60] = function() -- High Bongo
		return sounds["entity.iron_golem.step"]:pitch(6)	-- has variations
	end,
	[61] = function() -- Low Bongo
		return sounds["entity.iron_golem.step"]:pitch(4)	-- has variations
	end,
	-- [62] = function() -- Muted High Conga
	-- 	return sounds["block.note_block.snare"]:pitch(0.8)
	-- end,
	-- [63] = function() -- High Conga
	-- 	return sounds["block.note_block.snare"]:pitch(0.8)
	-- end,
	-- [64] = function() -- Low Conga
	-- 	return sounds["block.note_block.snare"]:pitch(0.8)
	-- end,
	-- [65] = function() -- High Timbale
	-- 	return sounds["block.note_block.snare"]:pitch(0.8)
	-- end,
	-- [66] = function() -- Low Timbale
	-- 	return sounds["block.note_block.snare"]:pitch(0.8)
	-- end,
	[67] = function() -- High Agogo
		return sounds[ "entity.arrow.hit_player" ]:pitch(1.9)
	end,
	[68] = function() -- Low Agogo
		return sounds[ "entity.arrow.hit_player" ]:pitch(1.7)
	end,
	[69] = function() -- Cabasa
		return sounds[ "entity.silverfish.death" ]:pitch(4)
	end,
	[70] = function() -- Maracas
		return sounds[ "entity.iron_golem.attack" ]:pitch(3)
	end,
	-- [71] = function() -- Short Whistle
	-- 	return sounds["block.note_block.snare"]:pitch(0.8)
	-- end,
	-- [72] = function() -- Long Whistle
	-- 	return sounds["block.note_block.snare"]:pitch(0.8)
	-- end,
	[73] = function() -- Short Guiro
		return sounds["entity.item.break"]:pitch(1.9)
	end,
	[74] = function() -- Long Guiro
		return sounds["block.sculk_sensor.clicking"]:pitch(3)	-- has variations
	end,
	-- [75] = function() -- Claves
	-- 	return sounds["block.note_block.snare"]:pitch(0.8)
	-- end,
	-- [76] = function() -- High Wood Block
	-- 	return sounds["block.note_block.snare"]:pitch(0.8)
	-- end,
	-- [77] = function() -- Low Wood Block
	-- 	return sounds["block.note_block.snare"]:pitch(0.8)
	-- end,
	-- [78] = function() -- Muted Cuica
	-- 	return sounds["block.note_block.snare"]:pitch(0.8)
	-- end,
	-- [79] = function() -- Open Cuica
	-- 	return sounds["block.note_block.snare"]:pitch(0.8)
	-- end,
	-- [80] = function() -- Mute Triangle
	-- 	return sounds["block.note_block.snare"]:pitch(0.8)
	-- end,
	-- [81] = function() -- Open triangle
	-- 	return sounds["block.note_block.snare"]:pitch(0.8)
	-- end,
}

local function drumkitSoundLookup(semitones_from_a4)
	local midi_key = semitones_from_a4 + 69	-- A4 is midi key 69. nice. 
		-- 35 == B1, but SBC calls this B2 for some reason :/
		-- Whatever. It works, and my ABC parcing is (probably) correct. 
	if drumkitSoundsTable[midi_key] then
		return drumkitSoundsTable[midi_key]()
	end

	return sounds["minecraft:block.note_block.hat"]:setPitch(
			semitone_offset_to_multiplier(semitones_from_a4+3-12 +24)
		)
end

local function numberToBase32(n)
	-- ty to https://stackoverflow.com/a/3554821
	n = math.floor(n)
	local digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	local t = {}
	local sign = ""
	if n < 0 then
		sign = "-"
	n = -n
	end
	repeat
		local d = (n % 32) + 1
		n = math.floor(n / 32)
		table.insert(t, 1, digits:sub(d,d))
	until n == 0
	return sign .. table.concat(t,"")
end

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

local midi_code_to_piano_code = {
	-- see  https://inspiredacoustics.com/en/MIDI_note_numbers_and_center_frequencies
	[127] = "G9",
	[126] = "F#9",
	[125] = "F9",
	[124] = "E9",
	[123] = "D#9",
	[122] = "D9",
	[121] = "C#9",
	[120] = "C9",
	[119] = "B8",
	[118] = "A#8",
	[117] = "A8",
	[116] = "G#8",
	[115] = "G8",
	[114] = "F#8",
	[113] = "F8",
	[112] = "E8",
	[111] = "D#8",
	[110] = "D8",
	[109] = "C#8",
	[108] = "C8",
	[107] = "B7",
	[106] = "A#7",
	[105] = "A7",
	[104] = "G#7",
	[103] = "G7",
	[102] = "F#7",
	[101] = "F7",
	[100] = "E7",
	[99] = "D#7",
	[98] = "D7",
	[97] = "C#7",
	[96] = "C7",
	[95] = "B6",	-- Max chloe piano range: A0 to B6
	[94] = "A#6",
	[93] = "A6",
	[92] = "G#6",
	[91] = "G6",
	[90] = "F#6",
	[89] = "F6",
	[88] = "E6",
	[87] = "D#6",
	[86] = "D6",
	[85] = "C#6",
	[84] = "C6",
	[83] = "B5",
	[82] = "A#5",
	[81] = "A5",
	[80] = "G#5",
	[79] = "G5",
	[78] = "F#5",
	[77] = "F5",
	[76] = "E5",
	[75] = "D#5",
	[74] = "D5",
	[73] = "C#5",
	[72] = "C5",
	[71] = "B4",
	[70] = "A#4",
	[69] = "A4",
	[68] = "G#4",
	[67] = "G4",
	[66] = "F#4",
	[65] = "F4",
	[64] = "E4",
	[63] = "D#4",
	[62] = "D4",
	[61] = "C#4",
	[60] = "C4",
	[59] = "B3",
	[58] = "A#3",
	[57] = "A3",
	[56] = "G#3",
	[55] = "G3",
	[54] = "F#3",
	[53] = "F3",
	[52] = "E3",
	[51] = "D#3",
	[50] = "D3",
	[49] = "C#3",
	[48] = "C3",
	[47] = "B2",
	[46] = "A#2",
	[45] = "A2",
	[44] = "G#2",
	[43] = "G2",
	[42] = "F#2",
	[41] = "F2",
	[40] = "E2",
	[39] = "D#2",
	[38] = "D2",
	[37] = "C#2",
	[36] = "C2",
	[35] = "B1",
	[34] = "A#1",
	[33] = "A1",
	[32] = "G#1",
	[31] = "G1",
	[30] = "F#1",
	[29] = "F1",
	[28] = "E1",
	[27] = "D#1",
	[26] = "D1",
	[25] = "C#1",
	[24] = "C1",
	[23] = "B0",
	[22] = "A#0",
	[21] = "A0",
}

local function a4_semitones_to_piano_code(a4_semi_tones)
	midi_code = a4_semi_tones + 69
	
	-- Max chloe piano range: A0 to B6
	if midi_code > 95 or midi_code < 21 then return "X0" end
	
	piano_code = midi_code_to_piano_code[midi_code]
	if piano_code then 
		return piano_code
	end
	return "X0"
end

-- song builder: notes to instructions -----------------------------------------
local function save_abc_note_to_instructions(song)

	-- !! Returns the end time of the note. !!

	-- Converts a single note into an instruction
	-- single note is stored in the notebuilder table. 

	note_builder = song.songbuilder.note_builder
	if note_builder.letter == "" then return note_builder.start_time end
	--print("Saving note to instruction:")

	-- Calculate note duration
	local time_multiplier = 1.0
	if note_builder.duration_multiplier ~= "" then
		time_multiplier = tonumber(note_builder.duration_multiplier)
	end
	if note_builder.duration_divisor ~= "" then
		-- divisor should always have at least 1 slash.
		-- each slash means divide by two, but if there are numbers after
		-- the slash, don't do the shorthand. A goofy workaround:
		-- multiply the numbers by 2, since there will always be at least 1
		-- slash. It will cancel out the shorthand, without making us test
		-- if we should use the shorthand
		local numbers, num_devisions =
			note_builder.duration_divisor:gsub("/", "")
		time_multiplier = time_multiplier / (2.0^num_devisions)
		if numbers ~= "" then
			time_multiplier = (time_multiplier*2.0) / tonumber(numbers)
		end
	end

	local note_duration = song.songbuilder.time_per_note * time_multiplier

	local end_time = note_builder.start_time + note_duration

	-- Generate some strings to use in keys and print statements
	local accidentals_memory_key = note_builder.letter
		..note_builder.octave_ajustments
	local note_string = note_builder.accidentals
		.. note_builder.letter
		.. note_builder.octave_ajustments
		.. note_builder.duration_multiplier
		.. note_builder.duration_divisor

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

	-- Save note instructions
	if	note_builder.letter:lower() ~= "z"
	and note_builder.letter:lower() ~= "x"
		-- Skip instructions for rest notes.
	then
		table.insert(song.instructions, {
			--string = note_string,
			semitones_from_a4 = note_semitones_from_A4,
				-- gets converted to a multiplier in the song player event
			-- chloe_piano = chloe_spaced_out_piano_note_code,
			start_time = note_builder.start_time,
			end_time = end_time,
			duration = end_time - note_builder.start_time,
			instrument_index = song.songbuilder.instrument_index,
		})
	end

	return end_time
end

local function song_data_to_instructions(song_abc_data_string, instrument_index)
	-- Converts a the song.abc file into instructions we can send through pings
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
	song.songbuilder.instrument_index = instrument_index
	song.songbuilder.note_builder = {
	  	accidentals = "",
	  	letter = "",
	  	octave_ajustments = "",
	  	duration_multiplier = "",
	  	duration_divisor = "",
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
				  	duration_multiplier = note:match("[%a,'](%d+)") or "",
				  	duration_divisor = note:match("/+%d*") or "",
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
		or	(song.end_time - client.getSystemTime()) < (-0.25 *1000)
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
				-- .." ".. instruction.semitones_from_a4

			)	-- ` #20/100/2000 A4 `
			if isUsingPiano() and instruction.instrument_index == 1	-- main instrument only
			then
				-- Catches if the piano was broken recently.
			 	-- print("playing note "..instruction.chloe_piano.. " on piano at "..songbook.selected_chloe_piano_pos)
			 	if instruction.chloe_piano ~= "X0" then
					local no_error, pcall_message = pcall( piano_lib.playNote, songbook.selected_chloe_piano_pos , instruction.chloe_piano, true)
					if no_error then
						-- Chloe piano can't sustain notes, so we don't need to 
						-- bother checking if the note's done playing.
						-- Also, checking here means that if pcall fails, the
						-- built-in instrument will try to play this note again. 
						instruction.already_played = true
					else
						print("§4⚠ --== Piano Error ==-- ⚠§r"
							.."\n§6You will need to reload the piano avatar.§r"
							.."\nError message from piano:"
							.."\n"..pcall_message
						)
						print("Falling back to no-piano mode.")
						pings.set_selected_piano(nil)
					end
			 	end
			else
				if instruction.instrument_index == 2 then
					instruction.sound_id = drumkitSoundLookup(instruction.semitones_from_a4)
						:setVolume( isUsingPiano() and 0.8 or 0.5)
				elseif avatar:canUseCustomSounds() then
					instruction.sound_id = sounds["scripts.abc_player.triangle_sin"]
						:setVolume(4)
						:setLoop(true)
						:setPitch(
							semitone_offset_to_multiplier(instruction.semitones_from_a4)
						)
				else
					instruction.sound_id = sounds["minecraft:block.note_block.bell"]
						:setPitch(
							semitone_offset_to_multiplier(instruction.semitones_from_a4+3-12)
						)
				end

				instruction.sound_id
					:setPos(isUsingPiano() and getPianoPos() or player:getPos())
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

-- Emergency stop 

local is_unloaded_timer = 0
local function avatar_is_loaded_watcher_event()
	-- Failsafe: Kill song if avatar is unloaded. 

	-- can happen if avatar walks into a nether portal while playing a song. 
	-- The script won't crash, but TICK events will stopp happening, so 
	-- long notes will go forever. Use world_tick event to monitor the 
	-- standard tick event.

	if player:isLoaded() then 
		is_unloaded_timer = 0
		return 
	else
		is_unloaded_timer = is_unloaded_timer + 1
		if is_unloaded_timer > (20*3) then	-- about 3 seconds
			stop_playing_songs()
			is_unloaded_timer = 0
		end
	end
end

-- Actualy start the song and the player failsafes
local function start_song_player_event()
	--print("Starting song player event")
	current_song_player_event = "TICK"
	events.TICK:register(
		song_player_event_watcher_event,
		song_player_event_watcher_event_name
	)

	events.WORLD_TICK:register(
		avatar_is_loaded_watcher_event,
		avatar_is_loaded_watcher_event_name
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
	deserialize(packet_string)
end

function deserialize(packet_string)
	-- if packet_string:sub(1,1) == "e" then -- found stop packet
	-- 	stop_playing_songs()
	-- end
	if songbook.incoming_song == nil then
		if packet_string:sub(1,1) ~= "n" then
			print("deserialize() Found an instruction packet, but we haven't seen a song-start packet yet!")
			return
		end

		if not player:isLoaded() or stopping_with_world_tick then
			-- avatar is unloaded. Do not accept new songs from them. 
			-- or avatar _was_ unloded, and we're in the middle of 
			-- rewinding the old song in failsafe mode. Do not start a new 
			-- song while rewinding in failsafe. 
			if stopping_with_world_tick then 
				print("Rejecting new song! Songplayer is rewinding in failsafe mode.")
			else
				print("Rejecting new song! Host is unloded.")
			end
			
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
			+ slowmode_maximum_ping_rate -- Ensures there will always be at least one packet waiting and ready to go.

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
				song_instruction.duration,
				song_instruction.instrument_index,
				song_instruction.semitones_from_a4
				-- = serialized_instruction:match("s([%d%u]+)d([%d%u]+)i([^%a]+)t(%-?[^%a]+)p(%a#?%d)")
				= serialized_instruction:match("s([%d%u]+)d([%d%u]+)i([^%a]+)t(%-?[^%a]+)")

			song_instruction.start_time = tonumber(song_instruction.start_time, 32)
			song_instruction.duration = tonumber(song_instruction.duration, 32)
			song_instruction.end_time = song_instruction.start_time + song_instruction.duration
			song_instruction.instrument_index = tonumber(song_instruction.instrument_index)
			song_instruction.semitones_from_a4 = tonumber(song_instruction.semitones_from_a4)
			
			song_instruction.chloe_piano = a4_semitones_to_piano_code(song_instruction.semitones_from_a4)

			--printTable(song_instruction)
			table.insert(songbook.incoming_song.instructions, song_instruction)

			if not song_instruction or song_instruction == {} or not song_instruction.start_time then
				print("Malformed instruction packet!")
				printTable(song_instruction)
				print(serialized_instruction)
				error("Malformed instruction packet: `" .. serialized_instruction .."`")
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
			print("All packets sent")
			events.TICK:remove( send_packets_tick_event_name )
			outgoing_packets = nil
			return
		end

		--print("sending packet "..current_index.."/"..#outgoing_packets.packets.. " ("..#(outgoing_packets.packets[current_index])..")")
		--printTable(outgoing_packets.packets)

		if outgoing_packets.should_send_pings then
			-- pings allways hit the figura server, even in single player. 
			-- We should avoid pings whenever possible. See `send_packets()`.
			pings.deserialize(outgoing_packets.packets[current_index])
		else
			deserialize(outgoing_packets.packets[current_index])
		end

		outgoing_packets.previous_index = current_index
	end
end

local send_packets_used_pings_last_time = false
local function send_packets(packets)
	outgoing_packets = {}
	outgoing_packets.packets = packets
	outgoing_packets.previous_index = 0
	outgoing_packets.first_packet_send_time = client.getSystemTime()
	
	-- don't send pings if no one is arround to hear them. 
	local player_list = world.getPlayers()
	player_list[player:getName()] = nil	-- remove ourselves from list. 

	-- using `#player_list` to get the length of `player_list` doesn't work with 
	-- string-indexed tables??? Gotta do it ourselves. Good news is we only need
	-- to find 1 non-us entry to make it work. 
	outgoing_packets.should_send_pings = false
	for _ in pairs(player_list) do 
		-- loop over the list. if we find anything, there's at least
		-- one nearby player. send pings
		outgoing_packets.should_send_pings = true
		break
	end

	if outgoing_packets.should_send_pings ~= send_packets_used_pings_last_time then 
		send_packets_used_pings_last_time = outgoing_packets.should_send_pings
		if outgoing_packets.should_send_pings then
			print("Players nearby. Sending song over pings.")
		else
			print("No players nearby. Song will not play through pings.")
		end
		
	end

	events.TICK:register(
		send_packets_tick_event,
		send_packets_tick_event_name
	)
end

local function song_instructions_to_packets(song_files, song_instructions)
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
			  "s"..( numberToBase32(math.floor(instruction.start_time)) )
			.."d"..( numberToBase32(math.floor(instruction.duration)) )
			.."i"..( string.format("%0d",instruction.instrument_index) )
			.."t"..( string.format("%0d",instruction.semitones_from_a4) ) -- D drops the decimal place, which is fine since we are allready timing everything in miliseconds. We don't need 11 digets of sub-milisecond presision
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
	ping_packets[1] = "n"..song_files.name.."//"	-- // for end of name
		.."p".. #ping_packets
		.."i".. #song_instructions
		.."d".. minimum_song_start_delay
		.."e".. last_end_time
	
	return ping_packets, minimum_song_start_delay
end

-- Song playing ----------------------------------------------------------------
local function queue_song(song_files)
	songbook.queued_song = {}
	
	-- print("Preparing to play "..song_files.name)
	local song_instructions = {}
	if song_files then
		local song_is_multitrack = false
		for instrument_index, full_path in pairs(song_files.full_paths) do
			if not file:isFile(full_path) then 
				print("No file found at `".. full_path .."`.")
				return 
			end

			local song_abc_data = file:readString(full_path)
			-- Convert data to instructions.
			-- print("Generating instructions for instument #"..tostring(instrument_index).."...")

			local track_instructions = song_data_to_instructions(song_abc_data, instrument_index)
			
			if song_instructions == {} then
				song_instructions = track_instructions
			else
				song_is_multitrack = true
				-- no concatinate tables opperation. :/
				for _, instruction in pairs(track_instructions) do
					table.insert(song_instructions,instruction)
				end
			end

		end
		if song_is_multitrack then
			table.sort(
				song_instructions, 
				function(a,b) 
					return a.start_time < b.start_time 
				end
			)
		end
	end

	--print("Generated "..#song_instructions.." instructions.")

	local packets, time_to_start = song_instructions_to_packets(song_files, song_instructions)

	songbook.queued_song.path = song_files
	songbook.queued_song.buffer_time = time_to_start
	songbook.queued_packets = packets
	print("Ready to play "..song_files.display_path
		.. (maximum_ping_rate*5 < time_to_start and
			"\n  song run time " ..math.ceil(song_instructions[#song_instructions].start_time /1000) .. "s"
			.."\n  §4song needs to buffer for ".. math.ceil(time_to_start/1000).."s§r"
		or "")
		.."\n  Total run time: "..math.ceil(song_instructions[#song_instructions].start_time /1000) + math.ceil(time_to_start/1000) .."s"
	)
end

local function play_song(song_files)
	if song_files ~= songbook.queued_song.path then
		log("`"..song_files.."` is not queued yet. Doing that now.")
		queue_song(song_files)
	end
	print("Playing "..song_files.display_path)
	songbook.playing_song_path = song_files
	--print("Sending packets to listeners.")
	send_packets(songbook.queued_packets)
end

-- Piano and Actionwheel -------------------------------------------------------
local function is_block_piano(targeted_block)	
	-- two return types: result 1 is a bool, 2nd result is the lib for the piano

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
			if songbook.song_list == nil or #songbook.song_list < 1 then return end

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

		:onRightClick(function()
			--slowmode
			if song_is_playing() then
				print("Can't toggle slow mode. Currently playing a song.")
			else
				if slowmode then
					maximum_ping_size = default_maximum_ping_size
					maximum_ping_rate = default_maximum_ping_rate
					print("Returning to default ping rate")
					slowmode = false
				else
					maximum_ping_size = slowmode_maximum_ping_size
					maximum_ping_rate = slowmode_maximum_ping_rate
					print("Entering slow mode. Pings are much smaller and slower now.")
					slowmode = true
				end
				songbook.queued_song = {}
				songbook_action_wheel_page_update_song_picker_button()
			end
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
		keybinds:getVanillaKey("key.sprint")
	)
	--printTable(keybinds:getKeybinds()["Scroll song list faster"])
end

-- globals / returns -----------------------------------------------------------

function get_songbook_actions()
	return songbook.action_wheel.actions
end

function get_currently_playing_song()
	return song_is_playing() and songbook.playing_song_path.name or nil
end

songbook.song_list = get_song_list()	
init_keybinds()
songbook_action_wheel_page_setup()
return songbook.action_wheel.actions["enter_songbook"]
