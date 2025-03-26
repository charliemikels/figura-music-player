
---@class Library
---@field songs Song[]


---@class LibrariesApi
---@field build_default_library fun(self:LibrariesApi) : Library
local libraries_api = {
    build_default_library = function(self)
        local processors_api = require("./file_processors")

        ---@type Library
        return {
            songs = {}
        }
    end
}

return libraries_api
