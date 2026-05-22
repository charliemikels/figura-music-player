
-- a tiny helper script.

--- loops through all files matching the path, but excludes files that are not inside the path.
---
--- Namely if a folder of scripts (like "local_songs") has the same name as it's main script, (like "local_songs.lua")
--- then it will ignore the parent script.
---@generic T
---@param relative_path string
---@return {success: boolean, path: string, result: T}[]
local function require_folder(relative_path)
    local instruments_directory_path = "./instruments"
    local select_everything_after_slash = instruments_directory_path:gsub(".*%.%/(%a-)", "%1")  -- `./../local_song` → `local_song`
    local pattern_to_exclude = select_everything_after_slash.."$"  -- test pattern used to exclude a path if there is nothing after select_everything_after_slash

    ---@generic T
    local results = {}  ---@type {success: boolean, path: string, result: T}[]

    for _, script_path in pairs(listFiles(instruments_directory_path, true)) do
        if not string.match(script_path, pattern_to_exclude) then

            local success, result = pcall(function()
                return require(script_path)
            end)

            table.insert(results, {success = success, result = result, path = script_path})
        end
    end

    return results

end

---@class HelperFunctionsApi
local helpers_api = {
    require_folder = require_folder,
}

return helpers_api
