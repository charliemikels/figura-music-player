--================================================================================================--
--=====  CLASSES  ================================================================================--
--================================================================================================--

---A 4-bit int.
---@alias NibbleInt 0|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15

---A phase of the moon.
---@alias MoonPhase
---| 0 #Full Moon
---| 1 #Waning Gibbous
---| 2 #Third Quarter
---| 3 #Waning Crescent
---| 4 #New Moon
---| 5 #Waxing Crescent
---| 6 #First Quarter
---| 7 #Waxing Gibbous

---A Minecraft world.
---@class World
local World = {}

---Returns the `Biome` at the specified world position.
---@param pos VectorPos
---@return Biome
function World.getBiome(pos) end

---Returns the block-light level at the given block position.
---
---Note: Returns `15` if the block position is not loaded.
---@param pos VectorPos
---@return NibbleInt
function World.getBlockLightLevel(pos) end

---Returns the block state at the given block position.
---
---Note: Always returns a valid block state, even if the block position is unloaded.
---@param pos VectorPos
---@return BlockState
function World.getBlockState(pos) end

---Returns all players in view distance (including yourself.)
---@return table<string, Player>
function World.getPlayers() end

---Returns the combined light level at the given block position.
---
---Note: Returns `15` if the block position is not loaded.
---@param pos VectorPos
---@return NibbleInt
function World.getLightLevel(pos) end

---See `.getTimeOfDay()`.
---@deprecated
---@return integer
function World.getLunarTime() end

---Returns the current moon phase.
---@return MoonPhase
function World.getMoonPhase() end

---Returns how heavy rain is falling in this world.  
---`0` is no rain, `1` is full rain.
---@param delta number
---@return number
function World.getRainGradient(delta) end

---Returns the redstone power the given block position is receiving.  
---This does *not* return the redstone power the block is sending.
---
---Note: Returns `0` if the block position is not loaded.
---@param pos VectorPos
---@return NibbleInt
function World.getRedstonePower(pos) end

---Returns the sky-light level of the given block position.
---
---Note: Returns `15` if the block position is not loaded.
---@param pos VectorPos
---@return NibbleInt
function World.getSkyLightLevel(pos) end

---Returns the strong redstone power of the block position is receiving.  
---This does *not* return the redstone power the block is sending.  
---This *only* checks for direct connections, redstone power sent through non-redstone blocks are
---ignored.
---@param pos VectorPos
---@return NibbleInt
function World.getStrongRedstonePower(pos) end

---Returns the total amount of ticks the server has run for.
---@return integer
function World.getTime() end

---Returns the total amount of ticks that have passed since the start of day 0.  
---This will not always sync up with `getTime` if the world's time is modified.
---@return integer
function World.getTimeOfDay() end

---Returns if the world actually exists.  
---This is useful for checking if the avatar is currently in a "fake" world.
---@return boolean
function World.hasWorld() end

---Returns if the current weather is thunder.
---@return boolean
function World.isLightning() end

---Returns if the given position has sky access.
---@param pos VectorPos
---@return boolean
function World.isOpenSky(pos) end

--================================================================================================--
--=====  FUNCTIONS  ==============================================================================--
--================================================================================================--

---The world that this script is running in currently.
---@type World
world = {}
