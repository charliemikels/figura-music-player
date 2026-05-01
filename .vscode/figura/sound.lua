--================================================================================================--
--=====  FUNCTIONS  ==============================================================================--
--================================================================================================--

---Contains functions relating to sounds.
sound = {}

---Returns a table of all currently playing custom sounds.
---
---If `owners` is set, the returned table will alternate sound names and their owner UUIDs.
---@param owners? boolean
---@return string[]
function sound.getCustomSounds(owners) end

---Returns a list of all registered custom sound names.
---@return string[]
function sound.getRegisteredCustomSounds() end

---Returns a list of all sounds the player can hear.
---@return string[]
function sound.getSounds() end

---Returns if a custom sound with the given name is registered.
---@param name string
---@return boolean
function sound.isCustomSoundRegistered(name) end

---Plays a custom sound at the given world position.
---@param name string
---@param pos VectorPos
---@param vol_pitch? Vector2
function sound.playCustomSound(name, pos, vol_pitch) end

---`vol_pitch: Vector2`  
---&emsp;Two numbers that represent the volume and pitch of the sound.
---***
---Plays a sound event at the given world position.  
---Sounds are played on the `player` channel.
---@param name string
---@param pos VectorPos
---@param vol_pitch? Vector2
function sound.playSound(name, pos, vol_pitch) end

---Adds a new custom sound to your model, using data from either a table of bytes, OR a
---base64-encoded string.
---@param name string
---@param data string|integer[]
function sound.registerCustomSound(name, data) end

---Stops the custom sound with the given name.
---@param name string
function sound.stopCustomSound(name) end
