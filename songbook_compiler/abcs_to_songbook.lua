-- Dumps all songs from the abc_files dir and dumps them into a songbook.lua
-- file in the root avatar directory.

local os_is_windows = false	-- WINDOWS SUPPORT UNTESTED! Swaps out the pfile command.

local function dump_abcs_to_songbook()
	print("dumping to songbook")
	local songbook_text = "return {isReady = false, songs = {"
	local pfile
	if os_is_windows then
		pfile = io.popen("dir abc_files /b /ad")
	else
		pfile = io.popen("ls -a abc_files")
	end
	for file_name in pfile:lines() do
		if file_name:match(".abc$") ~= nil then
			--print(file_name)
			local file = io.open("abc_files/"..file_name, "r")
			local file_contents = file:read("a")
			songbook_text = songbook_text .. "\n\n[\""
				..file_name:gsub(".abc$","")
				.."\"] = { name = \"" .. file_name:gsub(".abc$","")
				.."\", abc_data = [["..file_contents .."]]},"
			file:close()
		end
	end
	songbook_text = songbook_text .. "\n} }"
	print(songbook_text)
	pfile:close()

	local write_file = io.open("/songbook.lua","w")
	write_file:write(songbook_text)
	write_file:close()
end

if io ~= nil then
	-- makes sure the io module is installed
	dump_abcs_to_songbook()
end
