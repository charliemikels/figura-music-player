
local root_action_wheel_page = action_wheel:newPage()
action_wheel:setPage(root_action_wheel_page)
-- root_action_wheel_page:setAction(-1, require("scripts/abc_player/abc_player"))

if host:isHost() then
    local default_library = require("scripts/music_player/libraries"):build_default_library()
    local song = default_library:get_song_by_sorted_index(14)      -- 10: rush e full. 14: Starbound Atlas
    local song_processor_future = song:start_data_processor()
    song_processor_future:register_callback(function (_)
        -- print("Instruction test")
        -- local starting_ammount = avatar:getCurrentInstructions()
        -- print("starting_ammount:", starting_ammount)
        -- local exported_json = toJson(song.processed_data)
        -- local post_tojson = avatar:getCurrentInstructions()
        -- print("instructions after toJson", post_tojson - starting_ammount)  -- OK: going to and from json is actualy extreamly cheep instruction-wise. Space-wise it's pretty rough.

        local networking_api = require("scripts/music_player/networking")
        local config_api = require("scripts/music_player/config_cache")
        local song_config = config_api.load_song_config(song.id)
        local packets = networking_api.song_to_packets(song.processed_data, song_config)

        -- convert packets into one big long string, and wrap it in lua long quotes and a return statement so that we can load it later.

        local packets_raw_file_name = "TL_song_exports/"..song.name..".raw_packets.lua"
        local packets_raw_base_path = packets_raw_file_name:gsub("/[^/]*$", "/")
        file:mkdirs(packets_raw_base_path)


        local write_stream = file:openWriteStream(packets_raw_file_name)

        local file_string_table = {}

        -- Add some human readable info as comments.
        table.insert(file_string_table, "-- "..song.name.."\n")
        table.insert(file_string_table, "-- "..tostring(#song.processed_data.instructions).. " instructions".."\n")
        table.insert(file_string_table, "-- "..tostring(#packets).. " packets".."\n")
        table.insert(file_string_table, "\n")

        -- Start of the packet strings table.
        table.insert(file_string_table, "local processed_song_data = {\n")  -- return ".. '"'.. song.name ..'"'

        --- long quotes use `[` and `]`. These are magic characters in string.match, so we'll need to escape them.
        local function escape_match_magic_characters(str)
            -- All non-alphanumeric characters can be escaped with %. If they weren't magic characters, they are still escaped as if they were.
            -- Allows for future magic characters to be correctly escaped as well.
            ---@see https://www.lua.org/manual/5.2/manual.html#pdf-package.searchers:~:text=Any%20punctuation%20character%20%28even%20the%20non%20magic%29%20can%20be%20preceded%20by%20a%20%27%25%27%20when%20used%20to%20represent%20itself%20in%20a%20pattern%2E

            return (str:gsub(
                "([^%w])",  -- Gets all non-alpha-numeric characters
                "%%%1")     -- appends a `%` to the capture.
            )
        end

        local function safely_wrap_string_in_quotes(unquoted_string)
            -- In order to write a string into a file in a way that lua can
            -- `require()` it back into a string, we need to quote it.
            -- Typicaly `"` and `'` would be good enough, but they can allow
            -- for escape sequences, and as single characters they are pretty
            -- frequent occurances anyways.
            --
            -- Instead, we can use long brackets. These ignore escape sequences
            -- but still have a few exceptions:
            --
            -- - If a string begins with a new line, that newline it is ignored.    -- TODO: I think we can work accound this
            -- - Sequences of new lines and carriage return are converted to a single new line.
            --
            -- (https://www.lua.org/manual/5.2/manual.html#:~:text=long%20brackets)

            local required_long_quote_level = -1    -- first loop will bump this to `0` for us
            local opening_long_quote
            local closeing_long_quote
            local string_includes_these_long_quotes
            repeat
                required_long_quote_level = required_long_quote_level + 1
                opening_long_quote = "["..string.rep("=", required_long_quote_level).."["
                closeing_long_quote = "]"..string.rep("=", required_long_quote_level).."]"
                string_includes_these_long_quotes =
                        string.match(unquoted_string, escape_match_magic_characters(closeing_long_quote))
                    or  string.match(unquoted_string, escape_match_magic_characters(opening_long_quote))
            until not string_includes_these_long_quotes

            return opening_long_quote..unquoted_string..closeing_long_quote
        end

        -- Quote packets and add to table.
        for _, packet in ipairs(packets) do
            table.insert(file_string_table, safely_wrap_string_in_quotes(packet) ..",\n")
        end

        -- close processed_song_data table
        table.insert(file_string_table, "}\n\n")

        -- return processed_song_data with some metadata
        table.insert(file_string_table, "return {data = processed_song_data, name = ".. safely_wrap_string_in_quotes(song.name) .."}")

        local final_string = table.concat(file_string_table, "")

        local bytes = table.pack(string.byte(final_string, 1, #final_string))
        bytes.n = nil

        for _, byte in ipairs(bytes) do
            write_stream:write(byte)
        end

        write_stream:close()

        -- local baptized_info = require("./music_player/file_processors/local/local_songs/starbound-atlas.mid.raw_packets")
        -- printTable(baptized_info)



    end)
end


-- More or less: the current checklist
-- - [x] Ping Networking
-- - [x] UI
--   - [x] Store song configs with config API
-- - [ ] Use commands to save a processed song so that it can be uploaded with the avatar
-- - [ ] Port the ABC player to a new processor
-- - [x] Minecraft Note Block instruments
-- - [x] Figura Piano instrument
-- - [ ] Load instruments from other avatars
-- - [ ] test if I can force the viewer to load an offline avatar by making them render a player head
--   - See also: Chloe Piano 2.0 → https://github.com/ChloeSpacedOut/figura-midi-player/blob/3c2888209ac75b1c0ec57c7ea4ca0b49aee291bb/ChloesMidiPlayerClientExample/midiPlayerClient.lua#L85-L90
-- - [ ] Register callback functions through song controller for song end / meta event received / etc.
-- - [ ] Figura Drum Kit instrument
--       https://discord.com/channels/1129805506354085959/1340798228165300224/1340798228165300224
--       /give @p minecraft:player_head[minecraft:profile={id:[I;1039887675,1961051688,-1756947787,-2031944347],name:"Drum"}]

if host:isHost() then   -- TODO: it's host only b/c build_default_library() calls file API. should we instead have build_default_library() skip filesAPI if non-host? (possibly allows for local songs)
    local ui_api = require("scripts/music_player/ui")
    local default_library = require("scripts/music_player/libraries"):build_default_library()
    local enter_music_player_action_wheel_ui = ui_api.new_action_wheel_ui(default_library)
    root_action_wheel_page:setAction(-1, enter_music_player_action_wheel_ui )
end
return root_action_wheel_page
