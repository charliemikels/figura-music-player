--================================================================================================--
--=====  FUNCTIONS  ==============================================================================--
--================================================================================================--

---Contains functions involving saving and loading data to and from files.  
---It uses the avatar name as the default file name.
---
---Data files can be found at `./minecraft/figura/stored_vars`
data = {}

---Sets if you are allowed to appear in `world.getPlayers()`.
---
---This is enabled by default.
---@param bool boolean
function data.allowTracking(bool) end

---Completely removes the active data file.
function data.deleteFile() end

---Gets the name of the active data file.
---@return string
function data.getName() end

---Returns if you are allowed to appear in `world.getPlayers()`.
---@return boolean
function data.hasTracking() end

---Returns a value from the given key in the active data file.  
---Returns nil if the key does not exist.
---@param key string
---@return string|table|Vector
function data.load(key) end

---Returns a table containing all the saved variables in the active data file.
---@return table<string, string|table|Vector>
function data.loadAll() end

---Removes the given key from the active data file.
---@param key string
function data.remove(key) end

---Save a value in the active data file.
---@param key string
---@param value any
function data.save(key, value) end

---Makes a different file the active data file.
---@param name string
function data.setName(name) end
