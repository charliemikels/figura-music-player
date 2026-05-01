--================================================================================================--
--=====  CLASSES  ================================================================================--
--================================================================================================--

---A Minecraft biome.
---@class Biome
local Biome = {}

---Returns the category the biome belongs to.
---@return BiomeCategory
function Biome.getCategory() end

---Returns how wet the biome is where `0` is dry and `1` is wet.
---@return number
function Biome.getDownfall() end

---Returns the biome fog color.
---@return VectorColor
function Biome.getFogColor() end

---Returns the biome color used on leaves.
---@return VectorColor
function Biome.getFoliageColor() end

---Returns the biome grass color.
---@return VectorColor
function Biome.getGrassColor() end

---Returns the ID of the biome.
---@return BiomeID
function Biome.getID() end

---Returns the rain type of the biome.
---@return BiomePrecipitationType
function Biome.getPrecipitation() end

---Returns the biome sky color as a vector.
---@return VectorColor
function Biome.getSkyColor() end

---Returns the temperature of the biome.
---@return number
function Biome.getTemperature() end

---Returns the biome water color.
---@return VectorColor
function Biome.getWaterColor() end

---Returns the biome underwater fog color.
---@return VectorColor
function Biome.getWaterFogColor() end

---Returns true if the temperature is less than 0.15.
---@return boolean
function Biome.isCold() end

---Returns true if the temperature is greather than 1.
---@return boolean
function Biome.isHot() end

---@alias BiomeCategory
---| "forest"
---| "beach"
---| "plains"
---| "desert"
---| "savana"
---| "river"
---| "jungle"
---| "mesa"
---| "icy"
---| "taiga"
---| "mountain"
---| "underground"
---| "swamp"
---| "extreme_hills"


---A Minecraft biome identifier.
---
---Only the default Minecraft biomes are auto-completed.  
---You can use any biome from any mod, even if it does not auto-complete.
---@alias BiomeID
---| "minecraft:ocean" #Ocean
---| "minecraft:deep_ocean" #Deep Ocean
---| "minecraft:frozen_ocean" #Frozen Ocean
---| "minecraft:deep_frozen_ocean" #Deep Frozen Ocean
---| "minecraft:cold_ocean" #Cold Ocean
---| "minecraft:deep_cold_ocean" #Deep Cold Ocean
---| "minecraft:lukewarm_ocean" #Lukewarm Ocean
---| "minecraft:deep_lukewarm_ocean" #Deep Lukewarm Ocean
---| "minecraft:warm_ocean" #Warm Ocean
---| "minecraft:deep_warm_ocean" #Deep Warm Ocean
---| "minecraft:river" #River
---| "minecraft:frozen_river" #Frozen River
---| "minecraft:beach" #Beach
---| "minecraft:stone_shore" #Stone Shore
---| "minecraft:snowy_beach" #Snowy Beach
---| "minecraft:forest" #Forest
---| "minecraft:wooded_hills" #Wooded Hills
---| "minecraft:flower_forest" #Flower Forest
---| "minecraft:birch_forest" #Birch Forest
---| "minecraft:birch_forest_hills" #Birch Forest Hills
---| "minecraft:tall_birch_forest" #Tall Birch Forest
---| "minecraft:tall_birch_hills" #Tall Birch Hills
---| "minecraft:dark_forest" #Dark Forest
---| "minecraft:dark_forest_hills" #Dark Forest Hills
---| "minecraft:jungle" #Jungle
---| "minecraft:jungle_hills" #Jungle Hills
---| "minecraft:modified_jungle" #Modified Jungle
---| "minecraft:jungle_edge" #Jungle Edge
---| "minecraft:modified_jungle_edge" #Modified Jungle Edge
---| "minecraft:bamboo_jungle" #Bamboo Jungle
---| "minecraft:bamboo_jungle_hills" #Bamboo Jungle Hills
---| "minecraft:taiga" #Taiga
---| "minecraft:taiga_hills" #Taiga Hills
---| "minecraft:taiga_mountains" #Taiga Mountains
---| "minecraft:snowy_taiga" #Snowy Taiga
---| "minecraft:snowy_taiga_hills" #Snowy Taiga Hills
---| "minecraft:snowy_taiga_mountains" #Snowy Taiga Mountains
---| "minecraft:giant_tree_taiga" #Giant Tree Taiga
---| "minecraft:giant_tree_taiga_hills" #Giant Tree Taiga Hills
---| "minecraft:giant_spruce_taiga" #Giant Spruce Taiga
---| "minecraft:giant_spruce_taiga_hills" #Giant Spruce Taiga Hills
---| "minecraft:mushroom_fields" #Mushroom Fields
---| "minecraft:mushroom_field_shore" #Mushroom Field Shore
---| "minecraft:swamp" #Swamp
---| "minecraft:swamp_hills" #Swamp Hills
---| "minecraft:savanna" #Savanna
---| "minecraft:savanna_plateau" #Savanna Plateau
---| "minecraft:shattered_savanna" #Shattered Savanna
---| "minecraft:shattered_savanna_plateau" #Shattered Savanna Plateau
---| "minecraft:plains" #Plains
---| "minecraft:sunflower_plains" #Sunflower Plains
---| "minecraft:desert" #Desert
---| "minecraft:desert_hills" #Desert Hills
---| "minecraft:desert_lakes" #Desert Lakes
---| "minecraft:snowy_tundra" #Snowy Tundra
---| "minecraft:snowy_mountains" #Snowy Mountains
---| "minecraft:ice_spikes" #Ice Spikes
---| "minecraft:mountains" #Mountains
---| "minecraft:wooded_mountains" #Wooded Mountains
---| "minecraft:gravelly_mountains" #Gravelly Mountains
---| "minecraft:modified_gravelly_mountains" #Gravelly Mountains+
---| "minecraft:mountain_edge" #Mountain Edge
---| "minecraft:badlands" #Badlands
---| "minecraft:badlands_plateau" #Badlands Plateau
---| "minecraft:modified_badlands_plateau" #Modified Badlands Plateau
---| "minecraft:wooded_badlands_plateau" #Wooded Badlands Plateau
---| "minecraft:modified_wooded_badlands_plateau" #Modified Wooded Badlands Plateau
---| "minecraft:eroded_badlands" #Eroded Badlands
---| "minecraft:dripstone_caves" #Dripstone Caves
---| "minecraft:lush_caves" #Lush Caves
---| "minecraft:nether_wastes" #Nether Wastes
---| "minecraft:crimson_forest" #Crimson Forest
---| "minecraft:warped_forest" #Warped Forest
---| "minecraft:soul_sand_valley" #Soul Sand Valley
---| "minecraft:basalt_deltas" #Basalt Deltas
---| "minecraft:the_end" #The End
---| "minecraft:small_end_islands" #Small End Islands
---| "minecraft:end_midlands" #End Midlands
---| "minecraft:end_highlands" #End Highlands
---| "minecraft:end_barrens" #End Barrens
---| "minecraft:the_void" #The Void

---@alias BiomePrecipitationType
---| "NONE"
---| "RAIN"
---| "SNOW"

--================================================================================================--
--=====  FUNCTIONS  ==============================================================================--
--================================================================================================--

---Functions relating to biomes
biome = {}

---Returns a biome table of the biome id.
---@param biome BiomeID
---@param pos VectorPos
---@return Biome
function biome.getBiome(biome, pos) end
