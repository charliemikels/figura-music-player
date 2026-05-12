
-- Can convert a Song into a "local song" format.
--
-- Local songs are essentialy the same as a stream of data packets, just stored as a
-- lua file, and uploaded with the avatar instead of loaded by the filder api.
--
-- This script exports its songs to a folder inside `[figura_root]/data/`. You'll
-- need to move them from there and into the local_songs folder.
--
-- You may notice that exported songs use a lot of c-style escaped characters.
-- On your computer, this will make songs very large, but Figura will compress
-- these files at upload time, so they won't actualy take up that much space.

local packet_encoder_api = require("./packet_encoder")  ---@type PacketEncoderApi

local exports_dir = "TL_local_song_exports/"
local file_ext = ".lua"

local do_debug_prints = true
--- Logs a message to the console. But if do_debug_prints is true, it also logs to chat. Use do_debug_prints=true to debug viewers.
---@param message string
---@param is_warning boolean?
---@param allways_log boolean?
local function print_debug(message, is_warning, allways_log)
    if do_debug_prints then print(message) end
    if do_debug_prints or allways_log then
        if is_warning then
            host:warnToLog(message)
        else
            host:writeToLog(message)
        end
    end
end
local function printTable_debug(...) if do_debug_prints then printTable(...) end end
local function print_host(...) if host:isHost() or do_debug_prints then print(...) end end

--- Escapes all escapeable characters in a string.
---
--- A useful helper function when dealight with long quotes `[` and `]` are magic characters
---@param str string
---@return string
local function escape_match_magic_characters(str)
    -- All non-alphanumeric characters can be escaped with %. If they weren't magic characters, they are still escaped as if they were.
    -- Allows for future magic characters to be correctly escaped as well.
    ---@see https://www.lua.org/manual/5.2/manual.html#pdf-package.searchers:~:text=Any%20punctuation%20character%20%28even%20the%20non%20magic%29%20can%20be%20preceded%20by%20a%20%27%25%27%20when%20used%20to%20represent%20itself%20in%20a%20pattern%2E

    return (str:gsub(
        "([^%w])",  -- Gets all non-alpha-numeric characters
        "%%%1"      -- prepends a `%` to the capture.
    ))
end

local characters_to_escape = {  -- TODO: make sure that these are all the characters we need to keep track of.
    [ [["]] ] = true,
    [ [[\]] ] = true
}

---Quote and add escape so that we can safely store arbitrary binary data into a file.
---@param unquoted_string string
---@return string
local function safely_wrap_string_in_quotes(unquoted_string)
    -- In order to write a string into a file in a way that lua can
    -- `require()` it back into a string, we need to quote it.

    -- Although lua itself is very happy storeing arbitrary binary data in strings,
    -- it seems to have a hard time loading arbitrary binary data from a require()ed file
    --
    -- This means that we need to encode our binary data in some string-safe format.
    --
    -- Base 64 is a pretty good one. It's only a little larger on disk than the actual
    -- raw byte stream, and Figura gives us data.buffer to easily convert to and from it.
    --
    -- However we can also encode arbitrary binary bytes by useing c-style escape sequences.
    -- On disk, it's much larger than base 64 encodeing. However Figura's default compression
    -- system seems to actualy parse the file enough so that the escaped sequence returns to
    -- a single character at upload time. Meaning it's actualy way more space efficient for
    -- our needs.
    --
    -- See https://www.lua.org/pil/2.4.html#:~:text=the%20escape%20sequence%20%5Cddd
    --
    -- We do need to be careful about escapeing any problem chars in our existing byte stream
    -- (mostly `"` and `\`, ), but that's about it.

    local string_builder = {}   ---@type string[]
    table.insert(string_builder, [["]])

    local unquoted_string_as_bytes = table.pack(unquoted_string:byte(1, #unquoted_string))
    unquoted_string_as_bytes.n = nil

    for i, byte in ipairs(unquoted_string_as_bytes) do
        -- Checking for unicode characters added a lot of complexity but only saved like 3 bytes in `Rush E (full)`.
        -- Way not worth it, but check out the `v5-local-songs-with-unicode` branch to see it. Maybe we can merge it back later.

        if
            (byte >= 32 and byte <= 126) or byte == 9 or byte == 10 or byte == 13    -- TODO: what's the actual range that we could encode as single bytes?
        then -- Character is ascii printable
            local char = string.char(byte)
            if characters_to_escape[char] then
                table.insert(string_builder, [[\]]..char)
            else
                table.insert(string_builder, char)
            end

        else -- Character is some unprintable binary byte and needs to be escaped.

            if unquoted_string_as_bytes[i+1] and (unquoted_string_as_bytes[i+1] >= 48 and unquoted_string_as_bytes[i+1] <= 57)

            then    -- the next character is a ascii-printable number, so we need to take up the full space to avoid collisions with the next normal ascii number
                table.insert(string_builder, string.format("\\%03d", byte))

            else    -- insert this in a minimized form to possibly save space.
                table.insert(string_builder, string.format("\\%d", byte))
            end
        end
    end

    table.insert(string_builder, [["]])

    local return_quoted_string = table.concat(string_builder, "")

    return return_quoted_string
end

---Takes a Song and a config, converts them into packets,
---@param song Song
---@param config SongPlayerConfig?
local function export_song_to_local(song, config)
    print_debug("Starting export of song `"..song.name.."`")

    config = config or {}

    print_debug("Building packets…")
    local config_packet = packet_encoder_api.build_config_packet(config)
    local data_packets, _ = packet_encoder_api.build_data_packets_and_buffer_time(song)
    local head_packet = packet_encoder_api.build_header_packets(song, nil)  -- TODO: nil? should this be 0?

    print_debug("Generated "..tostring(#data_packets).." data packets.")

    ---@type LocalSongScript
    local tmp_layout_table = {
        name = song.name,
        durration = song.duration,
        num_instructions = #song.instructions,
        header = head_packet,
        config = config_packet,
        data = data_packets,
    }

    print_debug("Writing strings to string builder…")

    ---@type string[]
    local string_collector = {}

    table.insert(string_collector, "\n")

    -- Add some human readable info as comments.
    table.insert(string_collector, "-- For use with Figura Music Player\n")
    table.insert(string_collector, "-- https://github.com/charliemikels/figura-music-player\n")
    table.insert(string_collector, "-- Song name: `" .. song.name .. "`\n")
    table.insert(string_collector, "-- Runtime: " .. tostring(song.duration / 1000) .. "s\n")
    table.insert(string_collector, "-- Instruction count: " .. tostring(#song.instructions) .. "\n")
    table.insert(string_collector, "-- Data packet count: " .. tostring(#data_packets) .. "\n")
    table.insert(string_collector, "\n")

    table.insert(string_collector, "---@type LocalSongScript\n")
    table.insert(string_collector, "local local_song = {\n")

    -- it'd be really cool if we wrote a loop to convert from tmp_layout_table's keys and dump the values as strings,
    -- but data is a list. and idk if there's a good way to distinguish between a list and normal key pair table.
    table.insert(string_collector, "  name = "..safely_wrap_string_in_quotes(tmp_layout_table.name)..",\n")
    table.insert(string_collector, "  durration = "..tmp_layout_table.durration..",\n")
    table.insert(string_collector, "  num_instructions = "..tmp_layout_table.num_instructions..",\n")
    table.insert(string_collector, "  header = "..safely_wrap_string_in_quotes(tmp_layout_table.header)..",\n")
    table.insert(string_collector, "  config = "..safely_wrap_string_in_quotes(tmp_layout_table.config)..",\n")

    table.insert(string_collector, "  data = {\n")

    for i, packet in ipairs(tmp_layout_table.data) do
        table.insert(string_collector, "    "..safely_wrap_string_in_quotes(packet)..(i == #tmp_layout_table.data and "" or ",\n"))
    end

    table.insert(string_collector, "\n  }")   -- close data
    table.insert(string_collector, "\n}")   -- close local_song
    table.insert(string_collector, "\n\n")
    table.insert(string_collector, "return local_song")


    print_debug("Creating directory and write stream…")
    local file_path = exports_dir .. song.name .. file_ext
    local file_base_path = file_path:gsub("/[^/]*$", "/")
    print_debug(file_path)
    file:mkdirs(file_base_path)
    local write_stream = file:openWriteStream(file_path)

    print_debug("Creating file string…")
    local final_string = table.concat(string_collector, "")

    print_debug("Creating file bytes…")
    local final_bytes_list = table.pack(string.byte(final_string, 1, #final_string))
    final_bytes_list.n = nil

    print_debug("Writing bytes to write stream…")
    for _, byte in ipairs(final_bytes_list) do
        write_stream:write(byte)
    end

    print_debug("Closeing write stream…")
    write_stream:close()

    print_debug("Export done.\nRemember to move the exported file into this avatar's `local_songs` folder.")
end

---@class LocalSongBuilderApi
local song_to_local_api = {
    export_song_to_local = export_song_to_local
}

return song_to_local_api
