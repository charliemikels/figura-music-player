
-- Shared constants, enums, lookups, etc for the various packet functions.

---@enum ControlPacketCode
local control_packet_codes = {
    stop = 0,       -- Stop a song by it's transfered ID
    start = 1,      -- Play a song by it's transfered ID
    remove = 2,     -- Delete a song from the transfered song list
}

local packet_ids = {
    control = 0,   -- A very tiny packet to send a few simple control codes.
    header = 1, -- Includeds initial like name, duration, track_types
    data = 2,   -- Bulk of the packet stream
    config = 3, -- A packet that might appear to update a song's configuration
}

-- ---@alias DataSchemaIntegerType {}

-- ---@alias DataSchemaTypes ("integer"|"string"|"list"|"struct"|"switch")
--
-- ---@class DataSchema
-- ---@field type DataSchemaTypes
-- ---@field value table
--
-- ---@type DataSchema

local instruction_schema = {
    type = "struct",
    fields = {
        { name = "time_since_packet_start", schema = { type = "integer" } },
        { name = "track_id", schema = { type = "integer" }},
        { name = "body", schema = { type = "switch",
            selector = {kind = "nil_field", name = "track_id"},
            variants = {
                is_nil = modifier_schema,
                has_value = instruction_body_schema
            }
        }},
    }
}

local data_schema = {
    type = "struct",
    fields = {
        { name = "time_since_song_start", schema = { type = "integer" } },
        { name = "instructions", schema = { type = "list", item = instruction_schema } }
    }
}


local packet_schema = {
    type = "struct",
    fields = {
        { name = "transfer_id", schema = { type = "integer" }},
        { name = "packet_id", schema = { type = "integer" }},
        { name = "body", schema = { type = "switch",
            selector = { kind = "field", name = "packet_id" },
            variants = {
                [packet_ids.control] = control_schema,
                [packet_ids.header]  = header_schema,
                [packet_ids.data]    = data_schema,
                [packet_ids.config]  = config_schema
            }
        }},

        { name = "delta_time", schema = { type = "vlq" }},
        { name = "packet", schema = { type = "vlq" }},


        -- {key = "delta_time", type = "integer", value = ""},
        -- {},



        -- {data_type = "integer", source = nil, name = "Delta since start of song"},
        -- {data_type = "table", source = {
        --     {--[[ start_time ]]},
        --     {--[[ instruction or modifier part. Is this a table part? ]]},
        --     {--[[ idk ]]}
        -- }, name = "instructions and modifiers"}
    }
}





---@class PacketSchemaAPI
local packet_schema_api = {
    control_packet_codes = control_packet_codes
}

return packet_schema_api
