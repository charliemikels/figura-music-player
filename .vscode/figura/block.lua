--================================================================================================--
--=====  CLASSES  ================================================================================--
--================================================================================================--

---A Minecraft block identifier.
---
---Only the default Minecraft blocks are auto-completed.  
---You can use any block from any mod, even if it does not auto-complete.
---@alias BlockID
---| "minecraft:acacia_button" #Acacia Button
---| "minecraft:acacia_door" #Acacia Door
---| "minecraft:acacia_fence" #Acacia Fence
---| "minecraft:acacia_fence_gate" #Acacia Fence Gate
---| "minecraft:acacia_leaves" #Acacia Leaves
---| "minecraft:acacia_log" #Acacia Log
---| "minecraft:acacia_planks" #Acacia Planks
---| "minecraft:acacia_pressure_plate" #Acacia Pressure Plate
---| "minecraft:acacia_sapling" #Acacia Sapling
---| "minecraft:acacia_sign" #Acacia Sign
---| "minecraft:acacia_slab" #Acacia Slab
---| "minecraft:acacia_stairs" #Acacia Stairs
---| "minecraft:acacia_trapdoor" #Acacia Trapdoor
---| "minecraft:acacia_wall_sign" #Acacia Wall Sign
---| "minecraft:acacia_wood" #Acacia Wood
---| "minecraft:activator_rail" #Activator Rail
---| "minecraft:air" #Air
---| "minecraft:allium" #Allium
---| "minecraft:amethyst_block" #Block of Amethyst
---| "minecraft:amethyst_cluster" #Amethyst Cluster
---| "minecraft:ancient_debris" #Ancient Debris
---| "minecraft:andesite" #Andesite
---| "minecraft:andesite_slab" #Andesite Slab
---| "minecraft:andesite_stairs" #Andesite Stairs
---| "minecraft:andesite_wall" #Andesite Wall
---| "minecraft:anvil" #Anvil
---| "minecraft:attached_melon_stem" #Attached Melon Stem
---| "minecraft:attached_pumpkin_stem" #Attached Pumpkin Stem
---| "minecraft:azalea" #Azalea
---| "minecraft:azalea_leaves" #Azalea Leaves
---| "minecraft:azure_bluet" #Azure Bluet
---| "minecraft:bamboo" #Bamboo
---| "minecraft:bamboo_sapling" #Bamboo Shoot
---| "minecraft:barrel" #Barrel
---| "minecraft:barrier" #Barrier
---| "minecraft:basalt" #Basalt
---| "minecraft:beacon" #Beacon
---| "minecraft:bedrock" #Bedrock
---| "minecraft:bee_nest" #Bee Nest
---| "minecraft:beehive" #Beehive
---| "minecraft:beetroots" #Beetroots
---| "minecraft:bell" #Bell
---| "minecraft:big_dripleaf" #Big Dripleaf
---| "minecraft:big_dripleaf_stem" #Big Dripleaf Stem
---| "minecraft:birch_button" #Birch Button
---| "minecraft:birch_door" #Birch Door
---| "minecraft:birch_fence" #Birch Fence
---| "minecraft:birch_fence_gate" #Birch Fence Gate
---| "minecraft:birch_leaves" #Birch Leaves
---| "minecraft:birch_log" #Birch Log
---| "minecraft:birch_planks" #Birch Planks
---| "minecraft:birch_pressure_plate" #Birch Pressure Plate
---| "minecraft:birch_sapling" #Birch Sapling
---| "minecraft:birch_sign" #Birch Sign
---| "minecraft:birch_slab" #Birch Slab
---| "minecraft:birch_stairs" #Birch Stairs
---| "minecraft:birch_trapdoor" #Birch Trapdoor
---| "minecraft:birch_wall_sign" #Birch Wall Sign
---| "minecraft:birch_wood" #Birch Wood
---| "minecraft:black_banner" #Black Banner
---| "minecraft:black_bed" #Black Bed
---| "minecraft:black_candle" #Black Candle
---| "minecraft:black_candle_cake" #Cake with Black Candle
---| "minecraft:black_carpet" #Black Carpet
---| "minecraft:black_concrete" #Black Concrete
---| "minecraft:black_concrete_powder" #Black Concrete Powder
---| "minecraft:black_glazed_terracotta" #Black Glazed Terracotta
---| "minecraft:black_shulker_box" #Black Shulker Box
---| "minecraft:black_stained_glass" #Black Stained Glass
---| "minecraft:black_stained_glass_pane" #Black Stained Glass Pane
---| "minecraft:black_terracotta" #Black Terracotta
---| "minecraft:black_wall_banner" #Black Wall Banner
---| "minecraft:black_wool" #Black Wool
---| "minecraft:blackstone" #Blackstone
---| "minecraft:blackstone_slab" #Blackstone Slab
---| "minecraft:blackstone_stairs" #Blackstone Stairs
---| "minecraft:blackstone_wall" #Blackstone Wall
---| "minecraft:blast_furnace" #Blast Furnace
---| "minecraft:blue_banner" #Blue Banner
---| "minecraft:blue_bed" #Blue Bed
---| "minecraft:blue_candle" #Blue Candle
---| "minecraft:blue_candle_cake" #Cake with Blue Candle
---| "minecraft:blue_carpet" #Blue Carpet
---| "minecraft:blue_concrete" #Blue Concrete
---| "minecraft:blue_concrete_powder" #Blue Concrete Powder
---| "minecraft:blue_glazed_terracotta" #Blue Glazed Terracotta
---| "minecraft:blue_ice" #Blue Ice
---| "minecraft:blue_orchid" #Blue Orchid
---| "minecraft:blue_shulker_box" #Blue Shulker Box
---| "minecraft:blue_stained_glass" #Blue Stained Glass
---| "minecraft:blue_stained_glass_pane" #Blue Stained Glass Pane
---| "minecraft:blue_terracotta" #Blue Terracotta
---| "minecraft:blue_wall_banner" #Blue Wall Banner
---| "minecraft:blue_wool" #Blue Wool
---| "minecraft:bone_block" #Bone Block
---| "minecraft:bookshelf" #Bookshelf
---| "minecraft:brain_coral" #Brain Coral
---| "minecraft:brain_coral_block" #Brain Coral Block
---| "minecraft:brain_coral_fan" #Brain Coral Fan
---| "minecraft:brain_coral_wall_fan" #Brain Coral Wall Fan
---| "minecraft:brewing_stand" #Brewing Stand
---| "minecraft:brick_slab" #Brick Slab
---| "minecraft:brick_stairs" #Brick Stairs
---| "minecraft:brick_wall" #Brick Wall
---| "minecraft:bricks" #Bricks
---| "minecraft:brown_banner" #Brown Banner
---| "minecraft:brown_bed" #Brown Bed
---| "minecraft:brown_candle" #Brown Candle
---| "minecraft:brown_candle_cake" #Cake with Brown Candle
---| "minecraft:brown_carpet" #Brown Carpet
---| "minecraft:brown_concrete" #Brown Concrete
---| "minecraft:brown_concrete_powder" #Brown Concrete Powder
---| "minecraft:brown_glazed_terracotta" #Brown Glazed Terracotta
---| "minecraft:brown_mushroom" #Brown Mushroom
---| "minecraft:brown_mushroom_block" #Brown Mushroom Block
---| "minecraft:brown_shulker_box" #Brown Shulker Box
---| "minecraft:brown_stained_glass" #Brown Stained Glass
---| "minecraft:brown_stained_glass_pane" #Brown Stained Glass Pane
---| "minecraft:brown_terracotta" #Brown Terracotta
---| "minecraft:brown_wall_banner" #Brown Wall Banner
---| "minecraft:brown_wool" #Brown Wool
---| "minecraft:bubble_column" #Bubble Column
---| "minecraft:bubble_coral" #Bubble Coral
---| "minecraft:bubble_coral_block" #Bubble Coral Block
---| "minecraft:bubble_coral_fan" #Bubble Coral Fan
---| "minecraft:bubble_coral_wall_fan" #Bubble Coral Wall Fan
---| "minecraft:budding_amethyst" #Budding Amethyst
---| "minecraft:cactus" #Cactus
---| "minecraft:cake" #Cake
---| "minecraft:calcite" #Calcite
---| "minecraft:campfire" #Campfire
---| "minecraft:candle" #Candle
---| "minecraft:candle_cake" #Cake with Candle
---| "minecraft:carrots" #Carrots
---| "minecraft:cartography_table" #Cartography Table
---| "minecraft:carved_pumpkin" #Carved Pumpkin
---| "minecraft:cauldron" #Cauldron
---| "minecraft:cave_air" #Cave Air
---| "minecraft:cave_vines" #Cave Vines
---| "minecraft:cave_vines_plant" #Cave Vines Plant
---| "minecraft:chain" #Chain
---| "minecraft:chain_command_block" #Chain Command Block
---| "minecraft:chest" #Chest
---| "minecraft:chipped_anvil" #Chipped Anvil
---| "minecraft:chiseled_deepslate" #Chiseled Deepslate
---| "minecraft:chiseled_nether_bricks" #Chiseled Nether Bricks
---| "minecraft:chiseled_polished_blackstone" #Chiseled Polished Blackstone
---| "minecraft:chiseled_quartz_block" #Chiseled Quartz Block
---| "minecraft:chiseled_red_sandstone" #Chiseled Red Sandstone
---| "minecraft:chiseled_sandstone" #Chiseled Sandstone
---| "minecraft:chiseled_stone_bricks" #Chiseled Stone Bricks
---| "minecraft:chorus_flower" #Chorus Flower
---| "minecraft:chorus_plant" #Chorus Plant
---| "minecraft:clay" #Clay
---| "minecraft:coal_block" #Block of Coal
---| "minecraft:coal_ore" #Coal Ore
---| "minecraft:coarse_dirt" #Coarse Dirt
---| "minecraft:cobbled_deepslate" #Cobbled Deepslate
---| "minecraft:cobbled_deepslate_slab" #Cobbled Deepslate Slab
---| "minecraft:cobbled_deepslate_stairs" #Cobbled Deepslate Stairs
---| "minecraft:cobbled_deepslate_wall" #Cobbled Deepslate Wall
---| "minecraft:cobblestone" #Cobblestone
---| "minecraft:cobblestone_slab" #Cobblestone Slab
---| "minecraft:cobblestone_stairs" #Cobblestone Stairs
---| "minecraft:cobblestone_wall" #Cobblestone Wall
---| "minecraft:cobweb" #Cobweb
---| "minecraft:cocoa" #Cocoa
---| "minecraft:command_block" #Command Block
---| "minecraft:comparator" #Redstone Comparator
---| "minecraft:composter" #Composter
---| "minecraft:conduit" #Conduit
---| "minecraft:copper_block" #Block of Copper
---| "minecraft:copper_ore" #Copper Ore
---| "minecraft:cornflower" #Cornflower
---| "minecraft:cracked_deepslate_bricks" #Cracked Deepslate Bricks
---| "minecraft:cracked_deepslate_tiles" #Cracked Deepslate Tiles
---| "minecraft:cracked_nether_bricks" #Cracked Nether Bricks
---| "minecraft:cracked_polished_blackstone_bricks" #Cracked Polished Blackstone Bricks
---| "minecraft:cracked_stone_bricks" #Cracked Stone Bricks
---| "minecraft:crafting_table" #Crafting Table
---| "minecraft:creeper_head" #Creeper Head
---| "minecraft:creeper_wall_head" #Creeper Wall Head
---| "minecraft:crimson_button" #Crimson Button
---| "minecraft:crimson_door" #Crimson Door
---| "minecraft:crimson_fence" #Crimson Fence
---| "minecraft:crimson_fence_gate" #Crimson Fence Gate
---| "minecraft:crimson_fungus" #Crimson Fungus
---| "minecraft:crimson_hyphae" #Crimson Hyphae
---| "minecraft:crimson_nylium" #Crimson Nylium
---| "minecraft:crimson_planks" #Crimson Planks
---| "minecraft:crimson_pressure_plate" #Crimson Pressure Plate
---| "minecraft:crimson_roots" #Crimson Roots
---| "minecraft:crimson_sign" #Crimson Sign
---| "minecraft:crimson_slab" #Crimson Slab
---| "minecraft:crimson_stairs" #Crimson Stairs
---| "minecraft:crimson_stem" #Crimson Stem
---| "minecraft:crimson_trapdoor" #Crimson Trapdoor
---| "minecraft:crimson_wall_sign" #Crimson Wall Sign
---| "minecraft:crying_obsidian" #Crying Obsidian
---| "minecraft:cut_copper" #Cut Copper
---| "minecraft:cut_copper_slab" #Cut Copper Slab
---| "minecraft:cut_copper_stairs" #Cut Copper Stairs
---| "minecraft:cut_red_sandstone" #Cut Red Sandstone
---| "minecraft:cut_red_sandstone_slab" #Cut Red Sandstone Slab
---| "minecraft:cut_sandstone" #Cut Sandstone
---| "minecraft:cut_sandstone_slab" #Cut Sandstone Slab
---| "minecraft:cyan_banner" #Cyan Banner
---| "minecraft:cyan_bed" #Cyan Bed
---| "minecraft:cyan_candle" #Cyan Candle
---| "minecraft:cyan_candle_cake" #Cake with Cyan Candle
---| "minecraft:cyan_carpet" #Cyan Carpet
---| "minecraft:cyan_concrete" #Cyan Concrete
---| "minecraft:cyan_concrete_powder" #Cyan Concrete Powder
---| "minecraft:cyan_glazed_terracotta" #Cyan Glazed Terracotta
---| "minecraft:cyan_shulker_box" #Cyan Shulker Box
---| "minecraft:cyan_stained_glass" #Cyan Stained Glass
---| "minecraft:cyan_stained_glass_pane" #Cyan Stained Glass Pane
---| "minecraft:cyan_terracotta" #Cyan Terracotta
---| "minecraft:cyan_wall_banner" #Cyan Wall Banner
---| "minecraft:cyan_wool" #Cyan Wool
---| "minecraft:damaged_anvil" #Damaged Anvil
---| "minecraft:dandelion" #Dandelion
---| "minecraft:dark_oak_button" #Dark Oak Button
---| "minecraft:dark_oak_door" #Dark Oak Door
---| "minecraft:dark_oak_fence" #Dark Oak Fence
---| "minecraft:dark_oak_fence_gate" #Dark Oak Fence Gate
---| "minecraft:dark_oak_leaves" #Dark Oak Leaves
---| "minecraft:dark_oak_log" #Dark Oak Log
---| "minecraft:dark_oak_planks" #Dark Oak Planks
---| "minecraft:dark_oak_pressure_plate" #Dark Oak Pressure Plate
---| "minecraft:dark_oak_sapling" #Dark Oak Sapling
---| "minecraft:dark_oak_sign" #Dark Oak Sign
---| "minecraft:dark_oak_slab" #Dark Oak Slab
---| "minecraft:dark_oak_stairs" #Dark Oak Stairs
---| "minecraft:dark_oak_trapdoor" #Dark Oak Trapdoor
---| "minecraft:dark_oak_wall_sign" #Dark Oak Wall Sign
---| "minecraft:dark_oak_wood" #Dark Oak Wood
---| "minecraft:dark_prismarine" #Dark Prismarine
---| "minecraft:dark_prismarine_slab" #Dark Prismarine Slab
---| "minecraft:dark_prismarine_stairs" #Dark Prismarine Stairs
---| "minecraft:daylight_detector" #Daylight Detector
---| "minecraft:dead_brain_coral" #Dead Brain Coral
---| "minecraft:dead_brain_coral_block" #Dead Brain Coral Block
---| "minecraft:dead_brain_coral_fan" #Dead Brain Coral Fan
---| "minecraft:dead_brain_coral_wall_fan" #Dead Brain Coral Wall Fan
---| "minecraft:dead_bubble_coral" #Dead Bubble Coral
---| "minecraft:dead_bubble_coral_block" #Dead Bubble Coral Block
---| "minecraft:dead_bubble_coral_fan" #Dead Bubble Coral Fan
---| "minecraft:dead_bubble_coral_wall_fan" #Dead Bubble Coral Wall Fan
---| "minecraft:dead_bush" #Dead Bush
---| "minecraft:dead_fire_coral" #Dead Fire Coral
---| "minecraft:dead_fire_coral_block" #Dead Fire Coral Block
---| "minecraft:dead_fire_coral_fan" #Dead Fire Coral Fan
---| "minecraft:dead_fire_coral_wall_fan" #Dead Fire Coral Wall Fan
---| "minecraft:dead_horn_coral" #Dead Horn Coral
---| "minecraft:dead_horn_coral_block" #Dead Horn Coral Block
---| "minecraft:dead_horn_coral_fan" #Dead Horn Coral Fan
---| "minecraft:dead_horn_coral_wall_fan" #Dead Horn Coral Wall Fan
---| "minecraft:dead_tube_coral" #Dead Tube Coral
---| "minecraft:dead_tube_coral_block" #Dead Tube Coral Block
---| "minecraft:dead_tube_coral_fan" #Dead Tube Coral Fan
---| "minecraft:dead_tube_coral_wall_fan" #Dead Tube Coral Wall Fan
---| "minecraft:deepslate" #Deepslate
---| "minecraft:deepslate_brick_slab" #Deepslate Brick Slab
---| "minecraft:deepslate_brick_stairs" #Deepslate Brick Stairs
---| "minecraft:deepslate_brick_wall" #Deepslate Brick Wall
---| "minecraft:deepslate_bricks" #Deepslate Bricks
---| "minecraft:deepslate_coal_ore" #Deepslate Coal Ore
---| "minecraft:deepslate_copper_ore" #Deepslate Copper Ore
---| "minecraft:deepslate_diamond_ore" #Deepslate Diamond Ore
---| "minecraft:deepslate_emerald_ore" #Deepslate Emerald Ore
---| "minecraft:deepslate_gold_ore" #Deepslate Gold Ore
---| "minecraft:deepslate_iron_ore" #Deepslate Iron Ore
---| "minecraft:deepslate_lapis_ore" #Deepslate Lapis Lazuli Ore
---| "minecraft:deepslate_redstone_ore" #Deepslate Redstone Ore
---| "minecraft:deepslate_tile_slab" #Deepslate Tile Slab
---| "minecraft:deepslate_tile_stairs" #Deepslate Tile Stairs
---| "minecraft:deepslate_tile_wall" #Deepslate Tile Wall
---| "minecraft:deepslate_tiles" #Deepslate Tiles
---| "minecraft:detector_rail" #Detector Rail
---| "minecraft:diamond_block" #Block of Diamond
---| "minecraft:diamond_ore" #Diamond Ore
---| "minecraft:diorite" #Diorite
---| "minecraft:diorite_slab" #Diorite Slab
---| "minecraft:diorite_stairs" #Diorite Stairs
---| "minecraft:diorite_wall" #Diorite Wall
---| "minecraft:dirt" #Dirt
---| "minecraft:dirt_path" #Dirt Path
---| "minecraft:dispenser" #Dispenser
---| "minecraft:dragon_egg" #Dragon Egg
---| "minecraft:dragon_head" #Dragon Head
---| "minecraft:dragon_wall_head" #Dragon Wall Head
---| "minecraft:dried_kelp_block" #Dried Kelp Block
---| "minecraft:dripstone_block" #Dripstone Block
---| "minecraft:dropper" #Dropper
---| "minecraft:emerald_block" #Block of Emerald
---| "minecraft:emerald_ore" #Emerald Ore
---| "minecraft:enchanting_table" #Enchanting Table
---| "minecraft:end_gateway" #End Gateway
---| "minecraft:end_portal" #End Portal
---| "minecraft:end_portal_frame" #End Portal Frame
---| "minecraft:end_rod" #End Rod
---| "minecraft:end_stone" #End Stone
---| "minecraft:end_stone_brick_slab" #End Stone Brick Slab
---| "minecraft:end_stone_brick_stairs" #End Stone Brick Stairs
---| "minecraft:end_stone_brick_wall" #End Stone Brick Wall
---| "minecraft:end_stone_bricks" #End Stone Bricks
---| "minecraft:ender_chest" #Ender Chest
---| "minecraft:exposed_copper" #Exposed Copper
---| "minecraft:exposed_cut_copper" #Exposed Cut Copper
---| "minecraft:exposed_cut_copper_slab" #Exposed Cut Copper Slab
---| "minecraft:exposed_cut_copper_stairs" #Exposed Cut Copper Stairs
---| "minecraft:farmland" #Farmland
---| "minecraft:fern" #Fern
---| "minecraft:fire" #Fire
---| "minecraft:fire_coral" #Fire Coral
---| "minecraft:fire_coral_block" #Fire Coral Block
---| "minecraft:fire_coral_fan" #Fire Coral Fan
---| "minecraft:fire_coral_wall_fan" #Fire Coral Wall Fan
---| "minecraft:fletching_table" #Fletching Table
---| "minecraft:flower_pot" #Flower Pot
---| "minecraft:flowering_azalea" #Flowering Azalea
---| "minecraft:flowering_azalea_leaves" #Flowering Azalea Leaves
---| "minecraft:frosted_ice" #Frosted Ice
---| "minecraft:furnace" #Furnace
---| "minecraft:gilded_blackstone" #Gilded Blackstone
---| "minecraft:glass" #Glass
---| "minecraft:glass_pane" #Glass Pane
---| "minecraft:glow_lichen" #Glow Lichen
---| "minecraft:glowstone" #Glowstone
---| "minecraft:gold_block" #Block of Gold
---| "minecraft:gold_ore" #Gold Ore
---| "minecraft:granite" #Granite
---| "minecraft:granite_slab" #Granite Slab
---| "minecraft:granite_stairs" #Granite Stairs
---| "minecraft:granite_wall" #Granite Wall
---| "minecraft:grass" #Grass
---| "minecraft:grass_block" #Grass Block
---| "minecraft:gravel" #Gravel
---| "minecraft:gray_banner" #Gray Banner
---| "minecraft:gray_bed" #Gray Bed
---| "minecraft:gray_candle" #Gray Candle
---| "minecraft:gray_candle_cake" #Cake with Gray Candle
---| "minecraft:gray_carpet" #Gray Carpet
---| "minecraft:gray_concrete" #Gray Concrete
---| "minecraft:gray_concrete_powder" #Gray Concrete Powder
---| "minecraft:gray_glazed_terracotta" #Gray Glazed Terracotta
---| "minecraft:gray_shulker_box" #Gray Shulker Box
---| "minecraft:gray_stained_glass" #Gray Stained Glass
---| "minecraft:gray_stained_glass_pane" #Gray Stained Glass Pane
---| "minecraft:gray_terracotta" #Gray Terracotta
---| "minecraft:gray_wall_banner" #Gray Wall Banner
---| "minecraft:gray_wool" #Gray Wool
---| "minecraft:green_banner" #Green Banner
---| "minecraft:green_bed" #Green Bed
---| "minecraft:green_candle" #Green Candle
---| "minecraft:green_candle_cake" #Cake with Green Candle
---| "minecraft:green_carpet" #Green Carpet
---| "minecraft:green_concrete" #Green Concrete
---| "minecraft:green_concrete_powder" #Green Concrete Powder
---| "minecraft:green_glazed_terracotta" #Green Glazed Terracotta
---| "minecraft:green_shulker_box" #Green Shulker Box
---| "minecraft:green_stained_glass" #Green Stained Glass
---| "minecraft:green_stained_glass_pane" #Green Stained Glass Pane
---| "minecraft:green_terracotta" #Green Terracotta
---| "minecraft:green_wall_banner" #Green Wall Banner
---| "minecraft:green_wool" #Green Wool
---| "minecraft:grindstone" #Grindstone
---| "minecraft:hanging_roots" #Hanging Roots
---| "minecraft:hay_block" #Hay Bale
---| "minecraft:heavy_weighted_pressure_plate" #Heavy Weighted Pressure Plate
---| "minecraft:honey_block" #Honey Block
---| "minecraft:honeycomb_block" #Honeycomb Block
---| "minecraft:hopper" #Hopper
---| "minecraft:horn_coral" #Horn Coral
---| "minecraft:horn_coral_block" #Horn Coral Block
---| "minecraft:horn_coral_fan" #Horn Coral Fan
---| "minecraft:horn_coral_wall_fan" #Horn Coral Wall Fan
---| "minecraft:ice" #Ice
---| "minecraft:infested_chiseled_stone_bricks" #Infested Chiseled Stone Bricks
---| "minecraft:infested_cobblestone" #Infested Cobblestone
---| "minecraft:infested_cracked_stone_bricks" #Infested Cracked Stone Bricks
---| "minecraft:infested_deepslate" #Infested Deepslate
---| "minecraft:infested_mossy_stone_bricks" #Infested Mossy Stone Bricks
---| "minecraft:infested_stone" #Infested Stone
---| "minecraft:infested_stone_bricks" #Infested Stone Bricks
---| "minecraft:iron_bars" #Iron Bars
---| "minecraft:iron_block" #Block of Iron
---| "minecraft:iron_door" #Iron Door
---| "minecraft:iron_ore" #Iron Ore
---| "minecraft:iron_trapdoor" #Iron Trapdoor
---| "minecraft:jack_o_lantern" #Jack o'Lantern
---| "minecraft:jigsaw" #Jigsaw Block
---| "minecraft:jukebox" #Jukebox
---| "minecraft:jungle_button" #Jungle Button
---| "minecraft:jungle_door" #Jungle Door
---| "minecraft:jungle_fence" #Jungle Fence
---| "minecraft:jungle_fence_gate" #Jungle Fence Gate
---| "minecraft:jungle_leaves" #Jungle Leaves
---| "minecraft:jungle_log" #Jungle Log
---| "minecraft:jungle_planks" #Jungle Planks
---| "minecraft:jungle_pressure_plate" #Jungle Pressure Plate
---| "minecraft:jungle_sapling" #Jungle Sapling
---| "minecraft:jungle_sign" #Jungle Sign
---| "minecraft:jungle_slab" #Jungle Slab
---| "minecraft:jungle_stairs" #Jungle Stairs
---| "minecraft:jungle_trapdoor" #Jungle Trapdoor
---| "minecraft:jungle_wall_sign" #Jungle Wall Sign
---| "minecraft:jungle_wood" #Jungle Wood
---| "minecraft:kelp" #Kelp
---| "minecraft:kelp_plant" #Kelp Plant
---| "minecraft:ladder" #Ladder
---| "minecraft:lantern" #Lantern
---| "minecraft:lapis_block" #Block of Lapis Lazuli
---| "minecraft:lapis_ore" #Lapis Lazuli Ore
---| "minecraft:large_amethyst_bud" #Large Amethyst Bud
---| "minecraft:large_fern" #Large Fern
---| "minecraft:lava" #Lava
---| "minecraft:lava_cauldron" #Lava Cauldron
---| "minecraft:lectern" #Lectern
---| "minecraft:lever" #Lever
---| "minecraft:light" #Light
---| "minecraft:light_blue_banner" #Light Blue Banner
---| "minecraft:light_blue_bed" #Light Blue Bed
---| "minecraft:light_blue_candle" #Light Blue Candle
---| "minecraft:light_blue_candle_cake" #Cake with Light Blue Candle
---| "minecraft:light_blue_carpet" #Light Blue Carpet
---| "minecraft:light_blue_concrete" #Light Blue Concrete
---| "minecraft:light_blue_concrete_powder" #Light Blue Concrete Powder
---| "minecraft:light_blue_glazed_terracotta" #Light Blue Glazed Terracotta
---| "minecraft:light_blue_shulker_box" #Light Blue Shulker Box
---| "minecraft:light_blue_stained_glass" #Light Blue Stained Glass
---| "minecraft:light_blue_stained_glass_pane" #Light Blue Stained Glass Pane
---| "minecraft:light_blue_terracotta" #Light Blue Terracotta
---| "minecraft:light_blue_wall_banner" #Light Blue Wall Banner
---| "minecraft:light_blue_wool" #Light Blue Wool
---| "minecraft:light_gray_banner" #Light Gray Banner
---| "minecraft:light_gray_bed" #Light Gray Bed
---| "minecraft:light_gray_candle" #Light Gray Candle
---| "minecraft:light_gray_candle_cake" #Cake with Light Gray Candle
---| "minecraft:light_gray_carpet" #Light Gray Carpet
---| "minecraft:light_gray_concrete" #Light Gray Concrete
---| "minecraft:light_gray_concrete_powder" #Light Gray Concrete Powder
---| "minecraft:light_gray_glazed_terracotta" #Light Gray Glazed Terracotta
---| "minecraft:light_gray_shulker_box" #Light Gray Shulker Box
---| "minecraft:light_gray_stained_glass" #Light Gray Stained Glass
---| "minecraft:light_gray_stained_glass_pane" #Light Gray Stained Glass Pane
---| "minecraft:light_gray_terracotta" #Light Gray Terracotta
---| "minecraft:light_gray_wall_banner" #Light Gray Wall Banner
---| "minecraft:light_gray_wool" #Light Gray Wool
---| "minecraft:light_weighted_pressure_plate" #Light Weighted Pressure Plate
---| "minecraft:lightning_rod" #Lightning Rod
---| "minecraft:lilac" #Lilac
---| "minecraft:lily_of_the_valley" #Lily of the Valley
---| "minecraft:lily_pad" #Lily Pad
---| "minecraft:lime_banner" #Lime Banner
---| "minecraft:lime_bed" #Lime Bed
---| "minecraft:lime_candle" #Lime Candle
---| "minecraft:lime_candle_cake" #Cake with Lime Candle
---| "minecraft:lime_carpet" #Lime Carpet
---| "minecraft:lime_concrete" #Lime Concrete
---| "minecraft:lime_concrete_powder" #Lime Concrete Powder
---| "minecraft:lime_glazed_terracotta" #Lime Glazed Terracotta
---| "minecraft:lime_shulker_box" #Lime Shulker Box
---| "minecraft:lime_stained_glass" #Lime Stained Glass
---| "minecraft:lime_stained_glass_pane" #Lime Stained Glass Pane
---| "minecraft:lime_terracotta" #Lime Terracotta
---| "minecraft:lime_wall_banner" #Lime Wall Banner
---| "minecraft:lime_wool" #Lime Wool
---| "minecraft:lodestone" #Lodestone
---| "minecraft:loom" #Loom
---| "minecraft:magenta_banner" #Magenta Banner
---| "minecraft:magenta_bed" #Magenta Bed
---| "minecraft:magenta_candle" #Magenta Candle
---| "minecraft:magenta_candle_cake" #Cake with Magenta Candle
---| "minecraft:magenta_carpet" #Magenta Carpet
---| "minecraft:magenta_concrete" #Magenta Concrete
---| "minecraft:magenta_concrete_powder" #Magenta Concrete Powder
---| "minecraft:magenta_glazed_terracotta" #Magenta Glazed Terracotta
---| "minecraft:magenta_shulker_box" #Magenta Shulker Box
---| "minecraft:magenta_stained_glass" #Magenta Stained Glass
---| "minecraft:magenta_stained_glass_pane" #Magenta Stained Glass Pane
---| "minecraft:magenta_terracotta" #Magenta Terracotta
---| "minecraft:magenta_wall_banner" #Magenta Wall Banner
---| "minecraft:magenta_wool" #Magenta Wool
---| "minecraft:magma_block" #Magma Block
---| "minecraft:medium_amethyst_bud" #Medium Amethyst Bud
---| "minecraft:melon" #Melon
---| "minecraft:melon_stem" #Melon Stem
---| "minecraft:moss_block" #Moss Block
---| "minecraft:moss_carpet" #Moss Carpet
---| "minecraft:mossy_cobblestone" #Mossy Cobblestone
---| "minecraft:mossy_cobblestone_slab" #Mossy Cobblestone Slab
---| "minecraft:mossy_cobblestone_stairs" #Mossy Cobblestone Stairs
---| "minecraft:mossy_cobblestone_wall" #Mossy Cobblestone Wall
---| "minecraft:mossy_stone_brick_slab" #Mossy Stone Brick Slab
---| "minecraft:mossy_stone_brick_stairs" #Mossy Stone Brick Stairs
---| "minecraft:mossy_stone_brick_wall" #Mossy Stone Brick Wall
---| "minecraft:mossy_stone_bricks" #Mossy Stone Bricks
---| "minecraft:moving_piston" #Moving Piston
---| "minecraft:mushroom_stem" #Mushroom Stem
---| "minecraft:mycelium" #Mycelium
---| "minecraft:nether_brick_fence" #Nether Brick Fence
---| "minecraft:nether_brick_slab" #Nether Brick Slab
---| "minecraft:nether_brick_stairs" #Nether Brick Stairs
---| "minecraft:nether_brick_wall" #Nether Brick Wall
---| "minecraft:nether_bricks" #Nether Bricks
---| "minecraft:nether_gold_ore" #Nether Gold Ore
---| "minecraft:nether_portal" #Nether Portal
---| "minecraft:nether_quartz_ore" #Nether Quartz Ore
---| "minecraft:nether_sprouts" #Nether Sprouts
---| "minecraft:nether_wart" #Nether Wart
---| "minecraft:nether_wart_block" #Nether Wart Block
---| "minecraft:netherite_block" #Block of Netherite
---| "minecraft:netherrack" #Netherrack
---| "minecraft:note_block" #Note Block
---| "minecraft:oak_button" #Oak Button
---| "minecraft:oak_door" #Oak Door
---| "minecraft:oak_fence" #Oak Fence
---| "minecraft:oak_fence_gate" #Oak Fence Gate
---| "minecraft:oak_leaves" #Oak Leaves
---| "minecraft:oak_log" #Oak Log
---| "minecraft:oak_planks" #Oak Planks
---| "minecraft:oak_pressure_plate" #Oak Pressure Plate
---| "minecraft:oak_sapling" #Oak Sapling
---| "minecraft:oak_sign" #Oak Sign
---| "minecraft:oak_slab" #Oak Slab
---| "minecraft:oak_stairs" #Oak Stairs
---| "minecraft:oak_trapdoor" #Oak Trapdoor
---| "minecraft:oak_wall_sign" #Oak Wall Sign
---| "minecraft:oak_wood" #Oak Wood
---| "minecraft:observer" #Observer
---| "minecraft:obsidian" #Obsidian
---| "minecraft:orange_banner" #Orange Banner
---| "minecraft:orange_bed" #Orange Bed
---| "minecraft:orange_candle" #Orange Candle
---| "minecraft:orange_candle_cake" #Cake with Orange Candle
---| "minecraft:orange_carpet" #Orange Carpet
---| "minecraft:orange_concrete" #Orange Concrete
---| "minecraft:orange_concrete_powder" #Orange Concrete Powder
---| "minecraft:orange_glazed_terracotta" #Orange Glazed Terracotta
---| "minecraft:orange_shulker_box" #Orange Shulker Box
---| "minecraft:orange_stained_glass" #Orange Stained Glass
---| "minecraft:orange_stained_glass_pane" #Orange Stained Glass Pane
---| "minecraft:orange_terracotta" #Orange Terracotta
---| "minecraft:orange_tulip" #Orange Tulip
---| "minecraft:orange_wall_banner" #Orange Wall Banner
---| "minecraft:orange_wool" #Orange Wool
---| "minecraft:oxeye_daisy" #Oxeye Daisy
---| "minecraft:oxidized_copper" #Oxidized Copper
---| "minecraft:oxidized_cut_copper" #Oxidized Cut Copper
---| "minecraft:oxidized_cut_copper_slab" #Oxidized Cut Copper Slab
---| "minecraft:oxidized_cut_copper_stairs" #Oxidized Cut Copper Stairs
---| "minecraft:packed_ice" #Packed Ice
---| "minecraft:peony" #Peony
---| "minecraft:petrified_oak_slab" #Petrified Oak Slab
---| "minecraft:pink_banner" #Pink Banner
---| "minecraft:pink_bed" #Pink Bed
---| "minecraft:pink_candle" #Pink Candle
---| "minecraft:pink_candle_cake" #Cake with Pink Candle
---| "minecraft:pink_carpet" #Pink Carpet
---| "minecraft:pink_concrete" #Pink Concrete
---| "minecraft:pink_concrete_powder" #Pink Concrete Powder
---| "minecraft:pink_glazed_terracotta" #Pink Glazed Terracotta
---| "minecraft:pink_shulker_box" #Pink Shulker Box
---| "minecraft:pink_stained_glass" #Pink Stained Glass
---| "minecraft:pink_stained_glass_pane" #Pink Stained Glass Pane
---| "minecraft:pink_terracotta" #Pink Terracotta
---| "minecraft:pink_tulip" #Pink Tulip
---| "minecraft:pink_wall_banner" #Pink Wall Banner
---| "minecraft:pink_wool" #Pink Wool
---| "minecraft:piston" #Piston
---| "minecraft:piston_head" #Piston Head
---| "minecraft:player_head" #Player Head
---| "minecraft:player_wall_head" #Player Wall Head
---| "minecraft:podzol" #Podzol
---| "minecraft:pointed_dripstone" #Pointed Dripstone
---| "minecraft:polished_andesite" #Polished Andesite
---| "minecraft:polished_andesite_slab" #Polished Andesite Slab
---| "minecraft:polished_andesite_stairs" #Polished Andesite Stairs
---| "minecraft:polished_basalt" #Polished Basalt
---| "minecraft:polished_blackstone" #Polished Blackstone
---| "minecraft:polished_blackstone_brick_slab" #Polished Blackstone Brick Slab
---| "minecraft:polished_blackstone_brick_stairs" #Polished Blackstone Brick Stairs
---| "minecraft:polished_blackstone_brick_wall" #Polished Blackstone Brick Wall
---| "minecraft:polished_blackstone_bricks" #Polished Blackstone Bricks
---| "minecraft:polished_blackstone_button" #Polished Blackstone Button
---| "minecraft:polished_blackstone_pressure_plate" #Polished Blackstone Pressure Plate
---| "minecraft:polished_blackstone_slab" #Polished Blackstone Slab
---| "minecraft:polished_blackstone_stairs" #Polished Blackstone Stairs
---| "minecraft:polished_blackstone_wall" #Polished Blackstone Wall
---| "minecraft:polished_deepslate" #Polished Deepslate
---| "minecraft:polished_deepslate_slab" #Polished Deepslate Slab
---| "minecraft:polished_deepslate_stairs" #Polished Deepslate Stairs
---| "minecraft:polished_deepslate_wall" #Polished Deepslate Wall
---| "minecraft:polished_diorite" #Polished Diorite
---| "minecraft:polished_diorite_slab" #Polished Diorite Slab
---| "minecraft:polished_diorite_stairs" #Polished Diorite Stairs
---| "minecraft:polished_granite" #Polished Granite
---| "minecraft:polished_granite_slab" #Polished Granite Slab
---| "minecraft:polished_granite_stairs" #Polished Granite Stairs
---| "minecraft:poppy" #Poppy
---| "minecraft:potatoes" #Potatoes
---| "minecraft:potted_acacia_sapling" #Potted Acacia Sapling
---| "minecraft:potted_allium" #Potted Allium
---| "minecraft:potted_azalea_bush" #Potted Azalea
---| "minecraft:potted_azure_bluet" #Potted Azure Bluet
---| "minecraft:potted_bamboo" #Potted Bamboo
---| "minecraft:potted_birch_sapling" #Potted Birch Sapling
---| "minecraft:potted_blue_orchid" #Potted Blue Orchid
---| "minecraft:potted_brown_mushroom" #Potted Brown Mushroom
---| "minecraft:potted_cactus" #Potted Cactus
---| "minecraft:potted_cornflower" #Potted Cornflower
---| "minecraft:potted_crimson_fungus" #Potted Crimson Fungus
---| "minecraft:potted_crimson_roots" #Potted Crimson Roots
---| "minecraft:potted_dandelion" #Potted Dandelion
---| "minecraft:potted_dark_oak_sapling" #Potted Dark Oak Sapling
---| "minecraft:potted_dead_bush" #Potted Dead Bush
---| "minecraft:potted_fern" #Potted Fern
---| "minecraft:potted_flowering_azalea_bush" #Potted Flowering Azalea
---| "minecraft:potted_jungle_sapling" #Potted Jungle Sapling
---| "minecraft:potted_lily_of_the_valley" #Potted Lily of the Valley
---| "minecraft:potted_oak_sapling" #Potted Oak Sapling
---| "minecraft:potted_orange_tulip" #Potted Orange Tulip
---| "minecraft:potted_oxeye_daisy" #Potted Oxeye Daisy
---| "minecraft:potted_pink_tulip" #Potted Pink Tulip
---| "minecraft:potted_poppy" #Potted Poppy
---| "minecraft:potted_red_mushroom" #Potted Red Mushroom
---| "minecraft:potted_red_tulip" #Potted Red Tulip
---| "minecraft:potted_spruce_sapling" #Potted Spruce Sapling
---| "minecraft:potted_warped_fungus" #Potted Warped Fungus
---| "minecraft:potted_warped_roots" #Potted Warped Roots
---| "minecraft:potted_white_tulip" #Potted White Tulip
---| "minecraft:potted_wither_rose" #Potted Wither Rose
---| "minecraft:powder_snow" #Powder Snow
---| "minecraft:powder_snow_cauldron" #Powder Snow Cauldron
---| "minecraft:powered_rail" #Powered Rail
---| "minecraft:prismarine" #Prismarine
---| "minecraft:prismarine_brick_slab" #Prismarine Brick Slab
---| "minecraft:prismarine_brick_stairs" #Prismarine Brick Stairs
---| "minecraft:prismarine_bricks" #Prismarine Bricks
---| "minecraft:prismarine_slab" #Prismarine Slab
---| "minecraft:prismarine_stairs" #Prismarine Stairs
---| "minecraft:prismarine_wall" #Prismarine Wall
---| "minecraft:pumpkin" #Pumpkin
---| "minecraft:pumpkin_stem" #Pumpkin Stem
---| "minecraft:purple_banner" #Purple Banner
---| "minecraft:purple_bed" #Purple Bed
---| "minecraft:purple_candle" #Purple Candle
---| "minecraft:purple_candle_cake" #Cake with Purple Candle
---| "minecraft:purple_carpet" #Purple Carpet
---| "minecraft:purple_concrete" #Purple Concrete
---| "minecraft:purple_concrete_powder" #Purple Concrete Powder
---| "minecraft:purple_glazed_terracotta" #Purple Glazed Terracotta
---| "minecraft:purple_shulker_box" #Purple Shulker Box
---| "minecraft:purple_stained_glass" #Purple Stained Glass
---| "minecraft:purple_stained_glass_pane" #Purple Stained Glass Pane
---| "minecraft:purple_terracotta" #Purple Terracotta
---| "minecraft:purple_wall_banner" #Purple Wall Banner
---| "minecraft:purple_wool" #Purple Wool
---| "minecraft:purpur_block" #Purpur Block
---| "minecraft:purpur_pillar" #Purpur Pillar
---| "minecraft:purpur_slab" #Purpur Slab
---| "minecraft:purpur_stairs" #Purpur Stairs
---| "minecraft:quartz_block" #Block of Quartz
---| "minecraft:quartz_bricks" #Quartz Bricks
---| "minecraft:quartz_pillar" #Quartz Pillar
---| "minecraft:quartz_slab" #Quartz Slab
---| "minecraft:quartz_stairs" #Quartz Stairs
---| "minecraft:rail" #Rail
---| "minecraft:raw_copper_block" #Block of Raw Copper
---| "minecraft:raw_gold_block" #Block of Raw Gold
---| "minecraft:raw_iron_block" #Block of Raw Iron
---| "minecraft:red_banner" #Red Banner
---| "minecraft:red_bed" #Red Bed
---| "minecraft:red_candle" #Red Candle
---| "minecraft:red_candle_cake" #Cake with Red Candle
---| "minecraft:red_carpet" #Red Carpet
---| "minecraft:red_concrete" #Red Concrete
---| "minecraft:red_concrete_powder" #Red Concrete Powder
---| "minecraft:red_glazed_terracotta" #Red Glazed Terracotta
---| "minecraft:red_mushroom" #Red Mushroom
---| "minecraft:red_mushroom_block" #Red Mushroom Block
---| "minecraft:red_nether_brick_slab" #Red Nether Brick Slab
---| "minecraft:red_nether_brick_stairs" #Red Nether Brick Stairs
---| "minecraft:red_nether_brick_wall" #Red Nether Brick Wall
---| "minecraft:red_nether_bricks" #Red Nether Bricks
---| "minecraft:red_sand" #Red Sand
---| "minecraft:red_sandstone" #Red Sandstone
---| "minecraft:red_sandstone_slab" #Red Sandstone Slab
---| "minecraft:red_sandstone_stairs" #Red Sandstone Stairs
---| "minecraft:red_sandstone_wall" #Red Sandstone Wall
---| "minecraft:red_shulker_box" #Red Shulker Box
---| "minecraft:red_stained_glass" #Red Stained Glass
---| "minecraft:red_stained_glass_pane" #Red Stained Glass Pane
---| "minecraft:red_terracotta" #Red Terracotta
---| "minecraft:red_tulip" #Red Tulip
---| "minecraft:red_wall_banner" #Red Wall Banner
---| "minecraft:red_wool" #Red Wool
---| "minecraft:redstone_block" #Block of Redstone
---| "minecraft:redstone_lamp" #Redstone Lamp
---| "minecraft:redstone_ore" #Redstone Ore
---| "minecraft:redstone_torch" #Redstone Torch
---| "minecraft:redstone_wall_torch" #Redstone Wall Torch
---| "minecraft:redstone_wire" #Redstone Wire
---| "minecraft:repeater" #Redstone Repeater
---| "minecraft:repeating_command_block" #Repeating Command Block
---| "minecraft:respawn_anchor" #Respawn Anchor
---| "minecraft:rooted_dirt" #Rooted Dirt
---| "minecraft:rose_bush" #Rose Bush
---| "minecraft:sand" #Sand
---| "minecraft:sandstone" #Sandstone
---| "minecraft:sandstone_slab" #Sandstone Slab
---| "minecraft:sandstone_stairs" #Sandstone Stairs
---| "minecraft:sandstone_wall" #Sandstone Wall
---| "minecraft:scaffolding" #Scaffolding
---| "minecraft:sculk_sensor" #Sculk Sensor
---| "minecraft:sea_lantern" #Sea Lantern
---| "minecraft:sea_pickle" #Sea Pickle
---| "minecraft:seagrass" #Seagrass
---| "minecraft:shroomlight" #Shroomlight
---| "minecraft:shulker_box" #Shulker Box
---| "minecraft:skeleton_skull" #Skeleton Skull
---| "minecraft:skeleton_wall_skull" #Skeleton Wall Skull
---| "minecraft:slime_block" #Slime Block
---| "minecraft:small_amethyst_bud" #Small Amethyst Bud
---| "minecraft:small_dripleaf" #Small Dripleaf
---| "minecraft:smithing_table" #Smithing Table
---| "minecraft:smoker" #Smoker
---| "minecraft:smooth_basalt" #Smooth Basalt
---| "minecraft:smooth_quartz" #Smooth Quartz Block
---| "minecraft:smooth_quartz_slab" #Smooth Quartz Slab
---| "minecraft:smooth_quartz_stairs" #Smooth Quartz Stairs
---| "minecraft:smooth_red_sandstone" #Smooth Red Sandstone
---| "minecraft:smooth_red_sandstone_slab" #Smooth Red Sandstone Slab
---| "minecraft:smooth_red_sandstone_stairs" #Smooth Red Sandstone Stairs
---| "minecraft:smooth_sandstone" #Smooth Sandstone
---| "minecraft:smooth_sandstone_slab" #Smooth Sandstone Slab
---| "minecraft:smooth_sandstone_stairs" #Smooth Sandstone Stairs
---| "minecraft:smooth_stone" #Smooth Stone
---| "minecraft:smooth_stone_slab" #Smooth Stone Slab
---| "minecraft:snow" #Snow
---| "minecraft:snow_block" #Snow Block
---| "minecraft:soul_campfire" #Soul Campfire
---| "minecraft:soul_fire" #Soul Fire
---| "minecraft:soul_lantern" #Soul Lantern
---| "minecraft:soul_sand" #Soul Sand
---| "minecraft:soul_soil" #Soul Soil
---| "minecraft:soul_torch" #Soul Torch
---| "minecraft:soul_wall_torch" #Soul Wall Torch
---| "minecraft:spawner" #Spawner
---| "minecraft:sponge" #Sponge
---| "minecraft:spore_blossom" #Spore Blossom
---| "minecraft:spruce_button" #Spruce Button
---| "minecraft:spruce_door" #Spruce Door
---| "minecraft:spruce_fence" #Spruce Fence
---| "minecraft:spruce_fence_gate" #Spruce Fence Gate
---| "minecraft:spruce_leaves" #Spruce Leaves
---| "minecraft:spruce_log" #Spruce Log
---| "minecraft:spruce_planks" #Spruce Planks
---| "minecraft:spruce_pressure_plate" #Spruce Pressure Plate
---| "minecraft:spruce_sapling" #Spruce Sapling
---| "minecraft:spruce_sign" #Spruce Sign
---| "minecraft:spruce_slab" #Spruce Slab
---| "minecraft:spruce_stairs" #Spruce Stairs
---| "minecraft:spruce_trapdoor" #Spruce Trapdoor
---| "minecraft:spruce_wall_sign" #Spruce Wall Sign
---| "minecraft:spruce_wood" #Spruce Wood
---| "minecraft:sticky_piston" #Sticky Piston
---| "minecraft:stone" #Stone
---| "minecraft:stone_brick_slab" #Stone Brick Slab
---| "minecraft:stone_brick_stairs" #Stone Brick Stairs
---| "minecraft:stone_brick_wall" #Stone Brick Wall
---| "minecraft:stone_bricks" #Stone Bricks
---| "minecraft:stone_button" #Stone Button
---| "minecraft:stone_pressure_plate" #Stone Pressure Plate
---| "minecraft:stone_slab" #Stone Slab
---| "minecraft:stone_stairs" #Stone Stairs
---| "minecraft:stonecutter" #Stonecutter
---| "minecraft:stripped_acacia_log" #Stripped Acacia Log
---| "minecraft:stripped_acacia_wood" #Stripped Acacia Wood
---| "minecraft:stripped_birch_log" #Stripped Birch Log
---| "minecraft:stripped_birch_wood" #Stripped Birch Wood
---| "minecraft:stripped_crimson_hyphae" #Stripped Crimson Hyphae
---| "minecraft:stripped_crimson_stem" #Stripped Crimson Stem
---| "minecraft:stripped_dark_oak_log" #Stripped Dark Oak Log
---| "minecraft:stripped_dark_oak_wood" #Stripped Dark Oak Wood
---| "minecraft:stripped_jungle_log" #Stripped Jungle Log
---| "minecraft:stripped_jungle_wood" #Stripped Jungle Wood
---| "minecraft:stripped_oak_log" #Stripped Oak Log
---| "minecraft:stripped_oak_wood" #Stripped Oak Wood
---| "minecraft:stripped_spruce_log" #Stripped Spruce Log
---| "minecraft:stripped_spruce_wood" #Stripped Spruce Wood
---| "minecraft:stripped_warped_hyphae" #Stripped Warped Hyphae
---| "minecraft:stripped_warped_stem" #Stripped Warped Stem
---| "minecraft:structure_block" #Structure Block
---| "minecraft:structure_void" #Structure Void
---| "minecraft:sugar_cane" #Sugar Cane
---| "minecraft:sunflower" #Sunflower
---| "minecraft:sweet_berry_bush" #Sweet Berry Bush
---| "minecraft:tall_grass" #Tall Grass
---| "minecraft:tall_seagrass" #Tall Seagrass
---| "minecraft:target" #Target
---| "minecraft:terracotta" #Terracotta
---| "minecraft:tinted_glass" #Tinted Glass
---| "minecraft:tnt" #TNT
---| "minecraft:torch" #Torch
---| "minecraft:trapped_chest" #Trapped Chest
---| "minecraft:tripwire" #Tripwire
---| "minecraft:tripwire_hook" #Tripwire Hook
---| "minecraft:tube_coral" #Tube Coral
---| "minecraft:tube_coral_block" #Tube Coral Block
---| "minecraft:tube_coral_fan" #Tube Coral Fan
---| "minecraft:tube_coral_wall_fan" #Tube Coral Wall Fan
---| "minecraft:tuff" #Tuff
---| "minecraft:turtle_egg" #Turtle Egg
---| "minecraft:twisting_vines" #Twisting Vines
---| "minecraft:twisting_vines_plant" #Twisting Vines Plant
---| "minecraft:vine" #Vines
---| "minecraft:void_air" #Void Air
---| "minecraft:wall_torch" #Wall Torch
---| "minecraft:warped_button" #Warped Button
---| "minecraft:warped_door" #Warped Door
---| "minecraft:warped_fence" #Warped Fence
---| "minecraft:warped_fence_gate" #Warped Fence Gate
---| "minecraft:warped_fungus" #Warped Fungus
---| "minecraft:warped_hyphae" #Warped Hyphae
---| "minecraft:warped_nylium" #Warped Nylium
---| "minecraft:warped_planks" #Warped Planks
---| "minecraft:warped_pressure_plate" #Warped Pressure Plate
---| "minecraft:warped_roots" #Warped Roots
---| "minecraft:warped_sign" #Warped Sign
---| "minecraft:warped_slab" #Warped Slab
---| "minecraft:warped_stairs" #Warped Stairs
---| "minecraft:warped_stem" #Warped Stem
---| "minecraft:warped_trapdoor" #Warped Trapdoor
---| "minecraft:warped_wall_sign" #Warped Wall Sign
---| "minecraft:warped_wart_block" #Warped Wart Block
---| "minecraft:water" #Water
---| "minecraft:water_cauldron" #Water Cauldron
---| "minecraft:waxed_copper_block" #Waxed Block of Copper
---| "minecraft:waxed_cut_copper" #Waxed Cut Copper
---| "minecraft:waxed_cut_copper_slab" #Waxed Cut Copper Slab
---| "minecraft:waxed_cut_copper_stairs" #Waxed Cut Copper Stairs
---| "minecraft:waxed_exposed_copper" #Waxed Exposed Copper
---| "minecraft:waxed_exposed_cut_copper" #Waxed Exposed Cut Copper
---| "minecraft:waxed_exposed_cut_copper_slab" #Waxed Exposed Cut Copper Slab
---| "minecraft:waxed_exposed_cut_copper_stairs" #Waxed Exposed Cut Copper Stairs
---| "minecraft:waxed_oxidized_copper" #Waxed Oxidized Copper
---| "minecraft:waxed_oxidized_cut_copper" #Waxed Oxidized Cut Copper
---| "minecraft:waxed_oxidized_cut_copper_slab" #Waxed Oxidized Cut Copper Slab
---| "minecraft:waxed_oxidized_cut_copper_stairs" #Waxed Oxidized Cut Copper Stairs
---| "minecraft:waxed_weathered_copper" #Waxed Weathered Copper
---| "minecraft:waxed_weathered_cut_copper" #Waxed Weathered Cut Copper
---| "minecraft:waxed_weathered_cut_copper_slab" #Waxed Weathered Cut Copper Slab
---| "minecraft:waxed_weathered_cut_copper_stairs" #Waxed Weathered Cut Copper Stairs
---| "minecraft:weathered_copper" #Weathered Copper
---| "minecraft:weathered_cut_copper" #Weathered Cut Copper
---| "minecraft:weathered_cut_copper_slab" #Weathered Cut Copper Slab
---| "minecraft:weathered_cut_copper_stairs" #Weathered Cut Copper Stairs
---| "minecraft:weeping_vines" #Weeping Vines
---| "minecraft:weeping_vines_plant" #Weeping Vines Plant
---| "minecraft:wet_sponge" #Wet Sponge
---| "minecraft:wheat" #Wheat Crops
---| "minecraft:white_banner" #White Banner
---| "minecraft:white_bed" #White Bed
---| "minecraft:white_candle" #White Candle
---| "minecraft:white_candle_cake" #Cake with White Candle
---| "minecraft:white_carpet" #White Carpet
---| "minecraft:white_concrete" #White Concrete
---| "minecraft:white_concrete_powder" #White Concrete Powder
---| "minecraft:white_glazed_terracotta" #White Glazed Terracotta
---| "minecraft:white_shulker_box" #White Shulker Box
---| "minecraft:white_stained_glass" #White Stained Glass
---| "minecraft:white_stained_glass_pane" #White Stained Glass Pane
---| "minecraft:white_terracotta" #White Terracotta
---| "minecraft:white_tulip" #White Tulip
---| "minecraft:white_wall_banner" #White Wall Banner
---| "minecraft:white_wool" #White Wool
---| "minecraft:wither_rose" #Wither Rose
---| "minecraft:wither_skeleton_skull" #Wither Skeleton Skull
---| "minecraft:wither_skeleton_wall_skull" #Wither Skeleton Wall Skull
---| "minecraft:yellow_banner" #Yellow Banner
---| "minecraft:yellow_bed" #Yellow Bed
---| "minecraft:yellow_candle" #Yellow Candle
---| "minecraft:yellow_candle_cake" #Cake with Yellow Candle
---| "minecraft:yellow_carpet" #Yellow Carpet
---| "minecraft:yellow_concrete" #Yellow Concrete
---| "minecraft:yellow_concrete_powder" #Yellow Concrete Powder
---| "minecraft:yellow_glazed_terracotta" #Yellow Glazed Terracotta
---| "minecraft:yellow_shulker_box" #Yellow Shulker Box
---| "minecraft:yellow_stained_glass" #Yellow Stained Glass
---| "minecraft:yellow_stained_glass_pane" #Yellow Stained Glass Pane
---| "minecraft:yellow_terracotta" #Yellow Terracotta
---| "minecraft:yellow_wall_banner" #Yellow Wall Banner
---| "minecraft:yellow_wool" #Yellow Wool
---| "minecraft:zombie_head" #Zombie Head
---| "minecraft:zombie_wall_head" #Zombie Wall Head

---@alias BlockMaterial
---| "field_15913" #Cobwebs (`COBWEB`)
---| "field_15914" #Stone-like (`STONE`)
---| "field_15915" #Bubble Column (`BUBBLE_COLUMN`)
---| "field_15916" #Sand-like (`AGGREGATE`)
---| "field_15917" #Sponge (`SPONGE`)
---| "field_15918" #Lamp (`REDSTONE_LAMP`)
---| "field_15919" #Portal (`PORTAL`)
---| "field_15920" #Water (`WATER`)
---| "field_15921" #Moss Block (`MOSS_BLOCK`)
---| "field_15922" #Lava (`LAVA`)
---| "field_15923" #Leafy (`LEAVES`)
---| "field_15924" #Small Decoration (`DECORATION`)
---| "field_15925" #Cactus (`CACTUS`)
---| "field_15926" #Replacable Underwater Plant (`REPLACEABLE_UNDERWATER_PLANT`)
---| "field_15927" #Structure Void (`STRUCTURE_VOID`)
---| "field_15928" #Dense Ice (`DENSE_ICE`)
---| "field_15930" #Egg (`EGG`)
---| "field_15931" #Wooly (`WOOL`)
---| "field_15932" #Wooden (`WOOD`)
---| "field_15933" #Piston (`PISTON`)
---| "field_15934" #Snow Block (`SNOW_BLOCK`)
---| "field_15935" #Plant (`PLANT`)
---| "field_15936" #Organic / Infested (`ORGANIC_PRODUCT`)
---| "field_15937" #Cake (`CAKE`)
---| "field_15938" #Bamboo Sapling (`BAMBOO_SAPLING`)
---| "field_15941" #Dirt (`SOIL`)
---| "field_15942" #Glass (`GLASS`)
---| "field_15943" #Fire (`FIRE`)
---| "field_15945" #Plant Block (`SOLID_ORGANIC`)
---| "field_15946" #Bamboo (`BAMBOO`)
---| "field_15947" #Small Coral (`UNDERWATER_PLANT`)
---| "field_15948" #Small Snow (`SNOW_LAYER`)
---| "field_15949" #Metallic Misc (`REPAIR_STATION`)
---| "field_15952" #Barrier (`BARRIER`)
---| "field_15953" #Metallic (`METAL`)
---| "field_15954" #Gourd (`GOURD`)
---| "field_15955" #Explosives (`TNT`)
---| "field_15956" #Misc Plants (`REPLACEABLE_PLANT`)
---| "field_15957" #Carpet (`CARPET`)
---| "field_15958" #Weak Ice (`ICE`)
---| "field_15959" #Air (`AIR`)
---| "field_17008" #Skuler (`SHULKER_BOX`)
---| "field_22223" #Nether Wooden (`NETHER_WOOD`)
---| "field_26708" #Nether Plants (`NETHER_SHOOTS`)
---| "field_27340" #Amethyst (`AMETHYST`)
---| "field_27890" #Powder Snow (`POWDER_SNOW`)
---| "field_28242" #Sculk (`SCULK`)


---A `table` containing blockstate properties.
---
---Only the default Minecraft block state properties are auto-completed.  
---You can use any block state property from any mod, even if it does not auto-complete.
---@class BlockStateProperties
---@field [string] string
local BlockStateProperties = {
  ---Tracks the age of plants to handle growth and of fire to handle spread.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"0".."1"` | `minecraft:bamboo` |
  ---> | `"0".."2"` | `minecraft:cocoa` |
  ---> | `"0".."3"` | `minecraft:beetroots` `minecraft:frosted_ice` `minecraft:nether_wart` `minecraft:sweet_berry_bush` |
  ---> | `"0".."5"` | `minecraft:chorus_flower` |
  ---> | `"0".."7"` | `minecraft:carrots` `minecraft:melon_stem` `minecraft:potatoes` `minecraft:pumpkin_stem` `minecraft:wheat` |
  ---> | `"0".."15"` | `minecraft:cactus` `minecraft:fire` `minecraft:sugar_cane` |
  ---> | `"0".."25"` | `minecraft:kelp` |
  ---@type "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20"|"21"|"22"|"23"|"24"|"25"
  age = nil,

  ---Whether the tripwire hook is connected to a valid tripwire circuit or not.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:tripwire` `minecraft:tripwire_hook` |
  ---@type "false"|"true"
  attached = nil,

  ---How this block is attached to the block it is on.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"ceiling"` `"double_wall"` `"floor"` `"single_wall"` | `minecraft:bell` |
  ---@type "ceiling"|"double_wall"|"floor"|"single_wall"
  attachment = nil,

  ---What axis the block is oriented to.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"x"` `"y"` `"z"` | `minecraft:acacia_log` `minecraft:acacia_wood` `minecraft:basalt` `minecraft:birch_log` `minecraft:birch_wood` `minecraft:bone_block` `minecraft:chain` `minecraft:crimson_hyphae` `minecraft:crimson_stem` `minecraft:dark_oak_log` `minecraft:dark_oak_wood` `minecraft:deepslate` `minecraft:hay_block` `minecraft:jungle_log` `minecraft:jungle_wood` `minecraft:oak_log` `minecraft:oak_wood` `minecraft:polished_basalt` `minecraft:purpur_pillar` `minecraft:quartz_pillar` `minecraft:spruce_log` `minecraft:spruce_wood` `minecraft:stripped_acacia_log` `minecraft:stripped_acacia_wood` `minecraft:stripped_birch_log` `minecraft:stripped_birch_wood` `minecraft:stripped_crimson_hyphae` `minecraft:stripped_crimson_stem` `minecraft:stripped_dark_oak_log` `minecraft:stripped_dark_oak_wood` `minecraft:stripped_jungle_log` `minecraft:stripped_jungle_wood` `minecraft:stripped_oak_log` `minecraft:stripped_oak_wood` `minecraft:stripped_spruce_log` `minecraft:stripped_spruce_wood` `minecraft:stripped_warped_hyphae` `minecraft:stripped_warped_stem` `minecraft:warped_hyphae` `minecraft:warped_stem` |
  ---> | `"x"` `"z"` | `minecraft:nether_portal` |
  ---@type "x"|"y"|"z"
  axis = nil,

  ---The number of bites taken from the cake.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"0".."6"` | `minecraft:cake` |
  ---@type "0"|"1"|"2"|"3"|"4"|"5"|"6"
  bites = nil,

  ---Whether this scaffolding is floating (shows the bottom).
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:scaffolding` |
  ---@type "false"|"true"
  bottom = nil,

  ---Tracks the remaining uses of respawn anchors.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"0".."4"` | `minecraft:respawn_anchor` |
  ---@type "0"|"1"|"2"|"3"|"4"
  charges = nil,

  ---Whether or not the command block is conditional.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:chain_command_block` `minecraft:command_block` `minecraft:repeating_command_block` |
  ---@type "false"|"true"
  conditional = nil,

  ---The amount of time between receiving a signal and responding.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"1".."4"` | `minecraft:repeater` |
  ---@type "1"|"2"|"3"|"4"
  delay = nil,

  ---Whether the tripwire is broken using shears or not.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:tripwire` |
  ---@type "false"|"true"
  disarmed = nil,

  ---The distance from a base block.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"0".."7"` | `minecraft:scaffolding` |
  ---> | `"1".."7"` | `minecraft:acacia_leaves` `minecraft:azalea_leaves` `minecraft:birch_leaves` `minecraft:dark_oak_leaves` `minecraft:flowering_azalea_leaves` `minecraft:jungle_leaves` `minecraft:oak_leaves` `minecraft:spruce_leaves` |
  ---@type "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"
  distance = nil,

  ---Determines whether something is below the block.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:brown_mushroom_block` `minecraft:chorus_plant` `minecraft:mushroom_stem` `minecraft:red_mushroom_block` |
  ---@type "false"|"true"
  down = nil,

  ---Determines whether the bubble column is a whirlpool or upwards.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:bubble_column` |
  ---@type "false"|"true"
  drag = nil,

  ---Determines whether something is on the east side of the block.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:acacia_fence` `minecraft:birch_fence` `minecraft:black_stained_glass_pane` `minecraft:blue_stained_glass_pane` `minecraft:brown_mushroom_block` `minecraft:brown_stained_glass_pane` `minecraft:chorus_plant` `minecraft:crimson_fence` `minecraft:cyan_stained_glass_pane` `minecraft:dark_oak_fence` `minecraft:fire` `minecraft:glass_pane` `minecraft:gray_stained_glass_pane` `minecraft:green_stained_glass_pane` `minecraft:iron_bars` `minecraft:jungle_fence` `minecraft:light_blue_stained_glass_pane` `minecraft:light_gray_stained_glass_pane` `minecraft:lime_stained_glass_pane` `minecraft:magenta_stained_glass_pane` `minecraft:mushroom_stem` `minecraft:nether_brick_fence` `minecraft:oak_fence` `minecraft:orange_stained_glass_pane` `minecraft:pink_stained_glass_pane` `minecraft:purple_stained_glass_pane` `minecraft:red_mushroom_block` `minecraft:red_stained_glass_pane` `minecraft:spruce_fence` `minecraft:tripwire` `minecraft:vine` `minecraft:warped_fence` `minecraft:white_stained_glass_pane` `minecraft:yellow_stained_glass_pane` |
  ---> | `"none"` `"side"` `"up"` | `minecraft:redstone_wire` |
  ---> | `"low"` `"none"` `"tall"` | `minecraft:andesite_wall` `minecraft:blackstone_wall` `minecraft:brick_wall` `minecraft:cobbled_deepslate_wall` `minecraft:cobblestone_wall` `minecraft:deepslate_brick_wall` `minecraft:deepslate_tile_wall` `minecraft:diorite_wall` `minecraft:end_stone_brick_wall` `minecraft:granite_wall` `minecraft:mossy_cobblestone_wall` `minecraft:mossy_stone_brick_wall` `minecraft:nether_brick_wall` `minecraft:polished_blackstone_brick_wall` `minecraft:polished_blackstone_wall` `minecraft:polished_deepslate_wall` `minecraft:prismarine_wall` `minecraft:red_nether_brick_wall` `minecraft:red_sandstone_wall` `minecraft:sandstone_wall` `minecraft:stone_brick_wall` |
  ---@type "false"|"true"|"none"|"side"|"up"|"low"|"tall"
  east = nil,

  ---The amount of eggs in this block.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"1".."4"` | `minecraft:turtle_egg` |
  ---@type "1"|"2"|"3"|"4"
  eggs = nil,

  ---Whether or not the hopper can collect and transfer items.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:hopper` |
  ---@type "false"|"true"
  enabled = nil,

  ---Whether or not the piston is extended.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:piston` `minecraft:sticky_piston` |
  ---@type "false"|"true"
  extended = nil,

  ---Whether the frame contains an eye of ender.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:end_portal_frame` |
  ---@type "false"|"true"
  eye = nil,

  ---What side of a block the attached block is on.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"ceiling"` `"floor"` `"wall"` | `minecraft:acacia_button` `minecraft:birch_button` `minecraft:crimson_button` `minecraft:dark_oak_button` `minecraft:grindstone` `minecraft:jungle_button` `minecraft:lever` `minecraft:oak_button` `minecraft:polished_blackstone_button` `minecraft:spruce_button` `minecraft:stone_button` `minecraft:warped_button` |
  ---@type "ceiling"|"floor"|"wall"
  face = nil,

  ---For most blocks, what direction the block faces.  
  ---  
  ---For wall-attached bells as well as cocoa, the opposite is true.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"down"` `"east"` `"north"` `"south"` `"west"` `"up"` | `minecraft:amethyst_cluster` `minecraft:barrel` `minecraft:black_shulker_box` `minecraft:blue_shulker_box` `minecraft:brown_shulker_box` `minecraft:chain_command_block` `minecraft:command_block` `minecraft:cyan_shulker_box` `minecraft:dispenser` `minecraft:dropper` `minecraft:end_rod` `minecraft:gray_shulker_box` `minecraft:green_shulker_box` `minecraft:large_amethyst_bud` `minecraft:light_blue_shulker_box` `minecraft:light_gray_shulker_box` `minecraft:lime_shulker_box` `minecraft:magenta_shulker_box` `minecraft:medium_amethyst_bud` `minecraft:moving_piston` `minecraft:observer` `minecraft:orange_shulker_box` `minecraft:pink_shulker_box` `minecraft:piston` `minecraft:piston_head` `minecraft:purple_shulker_box` `minecraft:red_shulker_box` `minecraft:repeating_command_block` `minecraft:shulker_box` `minecraft:small_amethyst_bud` `minecraft:sticky_piston` `minecraft:white_shulker_box` `minecraft:yellow_shulker_box` |
  ---> | `"east"` `"north"` `"south"` `"west"` | `minecraft:acacia_button` `minecraft:acacia_door` `minecraft:acacia_fence_gate` `minecraft:acacia_stairs` `minecraft:acacia_trapdoor` `minecraft:acacia_wall_sign` `minecraft:andesite_stairs` `minecraft:anvil` `minecraft:attached_melon_stem` `minecraft:attached_pumpkin_stem` `minecraft:bee_nest` `minecraft:beehive` `minecraft:bell` `minecraft:birch_button` `minecraft:birch_door` `minecraft:birch_fence_gate` `minecraft:birch_stairs` `minecraft:birch_trapdoor` `minecraft:birch_wall_sign` `minecraft:black_bed` `minecraft:black_glazed_terracotta` `minecraft:blackstone_stairs` `minecraft:blast_furnace` `minecraft:blue_bed` `minecraft:blue_glazed_terracotta` `minecraft:brain_coral_wall_fan` `minecraft:brick_stairs` `minecraft:brown_bed` `minecraft:brown_glazed_terracotta` `minecraft:bubble_coral_wall_fan` `minecraft:campfire` `minecraft:carved_pumpkin` `minecraft:chest` `minecraft:chipped_anvil` `minecraft:cobbled_deepslate_stairs` `minecraft:cobblestone_stairs` `minecraft:cocoa` `minecraft:comparator` `minecraft:crimson_button` `minecraft:crimson_door` `minecraft:crimson_fence_gate` `minecraft:crimson_stairs` `minecraft:crimson_trapdoor` `minecraft:crimson_wall_sign` `minecraft:cut_copper_stairs` `minecraft:cyan_bed` `minecraft:cyan_glazed_terracotta` `minecraft:damaged_anvil` `minecraft:dark_oak_button` `minecraft:dark_oak_door` `minecraft:dark_oak_fence_gate` `minecraft:dark_oak_stairs` `minecraft:dark_oak_trapdoor` `minecraft:dark_oak_wall_sign` `minecraft:dark_prismarine_stairs` `minecraft:dead_brain_coral_wall_fan` `minecraft:dead_bubble_coral_wall_fan` `minecraft:dead_fire_coral_wall_fan` `minecraft:dead_horn_coral_wall_fan` `minecraft:dead_tube_coral_wall_fan` `minecraft:deepslate_brick_stairs` `minecraft:deepslate_tile_stairs` `minecraft:diorite_stairs` `minecraft:end_portal_frame` `minecraft:end_stone_brick_stairs` `minecraft:ender_chest` `minecraft:exposed_cut_copper_stairs` `minecraft:fire_coral_wall_fan` `minecraft:furnace` `minecraft:granite_stairs` `minecraft:gray_bed` `minecraft:gray_glazed_terracotta` `minecraft:green_bed` `minecraft:green_glazed_terracotta` `minecraft:grindstone` `minecraft:horn_coral_wall_fan` `minecraft:iron_door` `minecraft:iron_trapdoor` `minecraft:jack_o_lantern` `minecraft:jungle_button` `minecraft:jungle_door` `minecraft:jungle_fence_gate` `minecraft:jungle_stairs` `minecraft:jungle_trapdoor` `minecraft:jungle_wall_sign` `minecraft:ladder` `minecraft:lectern` `minecraft:lever` `minecraft:light_blue_bed` `minecraft:light_blue_glazed_terracotta` `minecraft:light_gray_bed` `minecraft:light_gray_glazed_terracotta` `minecraft:lime_bed` `minecraft:lime_glazed_terracotta` `minecraft:loom` `minecraft:magenta_bed` `minecraft:magenta_glazed_terracotta` `minecraft:mossy_cobblestone_stairs` `minecraft:mossy_stone_brick_stairs` `minecraft:nether_brick_stairs` `minecraft:oak_button` `minecraft:oak_door` `minecraft:oak_fence_gate` `minecraft:oak_stairs` `minecraft:oak_trapdoor` `minecraft:oak_wall_sign` `minecraft:orange_bed` `minecraft:orange_glazed_terracotta` `minecraft:oxidized_cut_copper_stairs` `minecraft:pink_bed` `minecraft:pink_glazed_terracotta` `minecraft:polished_andesite_stairs` `minecraft:polished_blackstone_brick_stairs` `minecraft:polished_blackstone_button` `minecraft:polished_blackstone_stairs` `minecraft:polished_deepslate_stairs` `minecraft:polished_diorite_stairs` `minecraft:polished_granite_stairs` `minecraft:prismarine_brick_stairs` `minecraft:prismarine_stairs` `minecraft:purple_bed` `minecraft:purple_glazed_terracotta` `minecraft:purpur_stairs` `minecraft:quartz_stairs` `minecraft:red_bed` `minecraft:red_glazed_terracotta` `minecraft:red_nether_brick_stairs` `minecraft:red_sandstone_stairs` `minecraft:redstone_wall_torch` `minecraft:repeater` `minecraft:sandstone_stairs` `minecraft:smoker` `minecraft:smooth_quartz_stairs` `minecraft:smooth_red_sandstone_stairs` `minecraft:smooth_sandstone_stairs` `minecraft:soul_campfire` `minecraft:soul_wall_torch` `minecraft:spruce_button` `minecraft:spruce_door` `minecraft:spruce_fence_gate` `minecraft:spruce_stairs` `minecraft:spruce_trapdoor` `minecraft:spruce_wall_sign` `minecraft:stone_brick_stairs` `minecraft:stone_button` `minecraft:stone_stairs` `minecraft:stonecutter` `minecraft:trapped_chest` `minecraft:tripwire_hook` `minecraft:tube_coral_wall_fan` `minecraft:wall_torch` `minecraft:warped_button` `minecraft:warped_door` `minecraft:warped_fence_gate` `minecraft:warped_stairs` `minecraft:warped_trapdoor` `minecraft:warped_wall_sign` `minecraft:waxed_cut_copper_stairs` `minecraft:waxed_exposed_cut_copper_stairs` `minecraft:waxed_oxidized_cut_copper_stairs` `minecraft:waxed_weathered_cut_copper_stairs` `minecraft:weathered_cut_copper_stairs` `minecraft:white_bed` `minecraft:white_glazed_terracotta` `minecraft:yellow_bed` `minecraft:yellow_glazed_terracotta` |
  ---> | `"down"` `"east"` `"north"` `"south"` `"west"` | `minecraft:hopper` |
  ---@type "down"|"east"|"north"|"south"|"west"|"up"
  facing = nil,

  ---For tall plants and doors, which half of the door or plant occupies the block space. For trapdoors and stairs, what part of the block space they are in.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"lower"` `"upper"` | `minecraft:acacia_door` `minecraft:birch_door` `minecraft:crimson_door` `minecraft:dark_oak_door` `minecraft:iron_door` `minecraft:jungle_door` `minecraft:large_fern` `minecraft:lilac` `minecraft:oak_door` `minecraft:peony` `minecraft:rose_bush` `minecraft:spruce_door` `minecraft:sunflower` `minecraft:tall_grass` `minecraft:tall_seagrass` `minecraft:warped_door` |
  ---> | `"bottom"` `"top"` | `minecraft:acacia_stairs` `minecraft:acacia_trapdoor` `minecraft:andesite_stairs` `minecraft:birch_stairs` `minecraft:birch_trapdoor` `minecraft:blackstone_stairs` `minecraft:brick_stairs` `minecraft:cobbled_deepslate_stairs` `minecraft:cobblestone_stairs` `minecraft:crimson_stairs` `minecraft:crimson_trapdoor` `minecraft:cut_copper_stairs` `minecraft:dark_oak_stairs` `minecraft:dark_oak_trapdoor` `minecraft:dark_prismarine_stairs` `minecraft:deepslate_brick_stairs` `minecraft:deepslate_tile_stairs` `minecraft:diorite_stairs` `minecraft:end_stone_brick_stairs` `minecraft:exposed_cut_copper_stairs` `minecraft:granite_stairs` `minecraft:iron_trapdoor` `minecraft:jungle_stairs` `minecraft:jungle_trapdoor` `minecraft:mossy_cobblestone_stairs` `minecraft:mossy_stone_brick_stairs` `minecraft:nether_brick_stairs` `minecraft:oak_stairs` `minecraft:oak_trapdoor` `minecraft:oxidized_cut_copper_stairs` `minecraft:polished_andesite_stairs` `minecraft:polished_blackstone_brick_stairs` `minecraft:polished_blackstone_stairs` `minecraft:polished_deepslate_stairs` `minecraft:polished_diorite_stairs` `minecraft:polished_granite_stairs` `minecraft:prismarine_brick_stairs` `minecraft:prismarine_stairs` `minecraft:purpur_stairs` `minecraft:quartz_stairs` `minecraft:red_nether_brick_stairs` `minecraft:red_sandstone_stairs` `minecraft:sandstone_stairs` `minecraft:smooth_quartz_stairs` `minecraft:smooth_red_sandstone_stairs` `minecraft:smooth_sandstone_stairs` `minecraft:spruce_stairs` `minecraft:spruce_trapdoor` `minecraft:stone_brick_stairs` `minecraft:stone_stairs` `minecraft:warped_stairs` `minecraft:warped_trapdoor` `minecraft:waxed_cut_copper_stairs` `minecraft:waxed_exposed_cut_copper_stairs` `minecraft:waxed_oxidized_cut_copper_stairs` `minecraft:waxed_weathered_cut_copper_stairs` `minecraft:weathered_cut_copper_stairs` |
  ---@type "lower"|"upper"|"bottom"|"top"
  half = nil,

  ---Whether or not the lantern hangs on the ceiling.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:lantern` `minecraft:soul_lantern` |
  ---@type "false"|"true"
  hanging = nil,

  ---Whether or not this lectern holds a book.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:lectern` |
  ---@type "false"|"true"
  has_book = nil,

  ---Whether or not a bottle is in slot 1 of the brewing stand.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:brewing_stand` |
  ---@type "false"|"true"
  has_bottle_0 = nil,

  ---Whether or not a bottle is in slot 2 of the brewing stand.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:brewing_stand` |
  ---@type "false"|"true"
  has_bottle_1 = nil,

  ---Whether or not a bottle is in slot 3 of the brewing stand.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:brewing_stand` |
  ---@type "false"|"true"
  has_bottle_2 = nil,

  ---True when the jukebox contains a music disc.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:jukebox` |
  ---@type "false"|"true"
  has_record = nil,

  ---Determines how close an egg is to hatching; starts at 0 and is randomly incremented.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"0".."2"` | `minecraft:turtle_egg` |
  ---@type "0"|"1"|"2"
  hatch = nil,

  ---Identifies the side the hinge is on (when facing the same direction as the door's inside).
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"left"` `"right"` | `minecraft:acacia_door` `minecraft:birch_door` `minecraft:crimson_door` `minecraft:dark_oak_door` `minecraft:iron_door` `minecraft:jungle_door` `minecraft:oak_door` `minecraft:spruce_door` `minecraft:warped_door` |
  ---@type "left"|"right"
  hinge = nil,

  ---The level of honey inside the beehive and bee nest.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"0".."5"` | `minecraft:bee_nest` `minecraft:beehive` |
  ---@type "0"|"1"|"2"|"3"|"4"|"5"
  honey_level = nil,

  ---If true, the gate is lowered by three pixels, to accommodate attaching more cleanly with walls.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:acacia_fence_gate` `minecraft:birch_fence_gate` `minecraft:crimson_fence_gate` `minecraft:dark_oak_fence_gate` `minecraft:jungle_fence_gate` `minecraft:oak_fence_gate` `minecraft:spruce_fence_gate` `minecraft:warped_fence_gate` |
  ---@type "false"|"true"
  in_wall = nil,

  ---The instrument sound the note block makes when it gets powered or used.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"banjo"` `"basedrum"` `"bass"` `"bell"` `"bit"` `"chime"` `"cow_bell"` `"digeridoo"` `"flute"` `"guitar"` `"harp"` `"hat"` `"iron_xylophone"` `"snare"` `"xylophone"` | `minecraft:note_block` |
  ---@type "banjo"|"basedrum"|"bass"|"bell"|"bit"|"chime"|"cow_bell"|"digeridoo"|"flute"|"guitar"|"harp"|"hat"|"iron_xylophone"|"snare"|"xylophone"
  instrument = nil,

  ---Whether the daylight detector detects light (false) or darkness (true).
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:daylight_detector` |
  ---@type "false"|"true"
  inverted = nil,

  ---How many layers of snow are on top of each other.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"1".."8"` | `minecraft:snow` |
  ---@type "1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"
  layers = nil,

  ---How big the leaves are on this bamboo.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"large"` `"none"` `"small"` | `minecraft:bamboo` |
  ---@type "large"|"none"|"small"
  leaves = nil,

  ---How much water or lava is in this block or cauldron.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"0".."3"` | `minecraft:powder_snow_cauldron` |
  ---> | `"0".."8"` | `minecraft:composter` |
  ---> | `"0".."15"` | `minecraft:lava` `minecraft:water` |
  ---@type "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"
  level = nil,

  ---Whether the block is turned on or off.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:blast_furnace` `minecraft:campfire` `minecraft:furnace` `minecraft:redstone_lamp` `minecraft:redstone_ore` `minecraft:redstone_torch` `minecraft:redstone_wall_torch` `minecraft:smoker` `minecraft:soul_campfire` |
  ---@type "false"|"true"
  lit = nil,

  ---Whether the repeater can change it is powered state (false) or not (true).
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:repeater` |
  ---@type "false"|"true"
  locked = nil,

  ---The mode the comparator or structure block is in.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"compare"` `"subtract"` | `minecraft:comparator` |
  ---> | `"corner"` `"data"` `"load"` `"save"` | `minecraft:structure_block` |
  ---@type "compare"|"subtract"|"corner"|"data"|"load"|"save"
  mode = nil,

  ---How wet the farmland is.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"0".."7"` | `minecraft:farmland` |
  ---@type "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"
  moisture = nil,

  ---Determines whether something is on the north side of the block.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:acacia_fence` `minecraft:birch_fence` `minecraft:black_stained_glass_pane` `minecraft:blue_stained_glass_pane` `minecraft:brown_mushroom_block` `minecraft:brown_stained_glass_pane` `minecraft:chorus_plant` `minecraft:crimson_fence` `minecraft:cyan_stained_glass_pane` `minecraft:dark_oak_fence` `minecraft:fire` `minecraft:glass_pane` `minecraft:gray_stained_glass_pane` `minecraft:green_stained_glass_pane` `minecraft:iron_bars` `minecraft:jungle_fence` `minecraft:light_blue_stained_glass_pane` `minecraft:light_gray_stained_glass_pane` `minecraft:lime_stained_glass_pane` `minecraft:magenta_stained_glass_pane` `minecraft:mushroom_stem` `minecraft:nether_brick_fence` `minecraft:oak_fence` `minecraft:orange_stained_glass_pane` `minecraft:pink_stained_glass_pane` `minecraft:purple_stained_glass_pane` `minecraft:red_mushroom_block` `minecraft:red_stained_glass_pane` `minecraft:spruce_fence` `minecraft:tripwire` `minecraft:vine` `minecraft:warped_fence` `minecraft:white_stained_glass_pane` `minecraft:yellow_stained_glass_pane` |
  ---> | `"up"` `"side"` `"none"` | `minecraft:redstone_wire` |
  ---> | `"low"` `"none"` `"tall"` | `minecraft:andesite_wall` `minecraft:blackstone_wall` `minecraft:brick_wall` `minecraft:cobbled_deepslate_wall` `minecraft:cobblestone_wall` `minecraft:deepslate_brick_wall` `minecraft:deepslate_tile_wall` `minecraft:diorite_wall` `minecraft:end_stone_brick_wall` `minecraft:granite_wall` `minecraft:mossy_cobblestone_wall` `minecraft:mossy_stone_brick_wall` `minecraft:nether_brick_wall` `minecraft:polished_blackstone_brick_wall` `minecraft:polished_blackstone_wall` `minecraft:polished_deepslate_wall` `minecraft:prismarine_wall` `minecraft:red_nether_brick_wall` `minecraft:red_sandstone_wall` `minecraft:sandstone_wall` `minecraft:stone_brick_wall` |
  ---@type "false"|"true"|"up"|"side"|"none"|"low"|"tall"
  north = nil,

  ---The note the note block plays when it gets powered.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"0".."24"` | `minecraft:note_block` |
  ---@type "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"|"16"|"17"|"18"|"19"|"20"|"21"|"22"|"23"|"24"
  note = nil,

  ---If there's already a player in this bed.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:black_bed` `minecraft:blue_bed` `minecraft:brown_bed` `minecraft:cyan_bed` `minecraft:gray_bed` `minecraft:green_bed` `minecraft:light_blue_bed` `minecraft:light_gray_bed` `minecraft:lime_bed` `minecraft:magenta_bed` `minecraft:orange_bed` `minecraft:pink_bed` `minecraft:purple_bed` `minecraft:red_bed` `minecraft:white_bed` `minecraft:yellow_bed` |
  ---@type "false"|"true"
  occupied = nil,

  ---Whether the door is open or closed.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:acacia_door` `minecraft:acacia_fence_gate` `minecraft:acacia_trapdoor` `minecraft:barrel` `minecraft:birch_door` `minecraft:birch_fence_gate` `minecraft:birch_trapdoor` `minecraft:crimson_door` `minecraft:crimson_fence_gate` `minecraft:crimson_trapdoor` `minecraft:dark_oak_door` `minecraft:dark_oak_fence_gate` `minecraft:dark_oak_trapdoor` `minecraft:iron_door` `minecraft:iron_trapdoor` `minecraft:jungle_door` `minecraft:jungle_fence_gate` `minecraft:jungle_trapdoor` `minecraft:oak_door` `minecraft:oak_fence_gate` `minecraft:oak_trapdoor` `minecraft:spruce_door` `minecraft:spruce_fence_gate` `minecraft:spruce_trapdoor` `minecraft:warped_door` `minecraft:warped_fence_gate` `minecraft:warped_trapdoor` |
  ---@type "false"|"true"
  open = nil,

  ---Direction the arrows point, followed by the position of the line face.  
  ---
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"down_east"` `"down_north"` `"down_south"` `"down_west"` `"east_up"` `"north_up"` `"south_up"` `"up_east"` `"up_north"` `"up_south"` `"up_west"` `"west_up"` |  |
  ---@type "down_east"|"down_north"|"down_south"|"down_west"|"east_up"|"north_up"|"south_up"|"up_east"|"up_north"|"up_south"|"up_west"|"west_up"
  orientation = nil,

  ---Whether this is the foot or head end of the bed.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"foot"` `"head"` | `minecraft:black_bed` `minecraft:blue_bed` `minecraft:brown_bed` `minecraft:cyan_bed` `minecraft:gray_bed` `minecraft:green_bed` `minecraft:light_blue_bed` `minecraft:light_gray_bed` `minecraft:lime_bed` `minecraft:magenta_bed` `minecraft:orange_bed` `minecraft:pink_bed` `minecraft:purple_bed` `minecraft:red_bed` `minecraft:white_bed` `minecraft:yellow_bed` |
  ---@type "foot"|"head"
  part = nil,

  ---Whether leaves decay (false) or not (true)
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:acacia_leaves` `minecraft:azalea_leaves` `minecraft:birch_leaves` `minecraft:dark_oak_leaves` `minecraft:flowering_azalea_leaves` `minecraft:jungle_leaves` `minecraft:oak_leaves` `minecraft:spruce_leaves` |
  ---@type "false"|"true"
  persistent = nil,

  ---The amount of pickles in this block.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"1".."4"` | `minecraft:sea_pickle` |
  ---@type "1"|"2"|"3"|"4"
  pickles = nil,

  ---The power level of Redstone emission.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"0".."15"` | `minecraft:daylight_detector` `minecraft:heavy_weighted_pressure_plate` `minecraft:light_weighted_pressure_plate` `minecraft:redstone_wire` |
  ---@type "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"
  power = nil,

  ---Whether the block is powered.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:acacia_button` `minecraft:acacia_door` `minecraft:acacia_fence_gate` `minecraft:acacia_pressure_plate` `minecraft:acacia_trapdoor` `minecraft:activator_rail` `minecraft:birch_button` `minecraft:birch_door` `minecraft:birch_fence_gate` `minecraft:birch_pressure_plate` `minecraft:birch_trapdoor` `minecraft:comparator` `minecraft:crimson_button` `minecraft:crimson_door` `minecraft:crimson_fence_gate` `minecraft:crimson_pressure_plate` `minecraft:crimson_trapdoor` `minecraft:dark_oak_button` `minecraft:dark_oak_door` `minecraft:dark_oak_fence_gate` `minecraft:dark_oak_pressure_plate` `minecraft:dark_oak_trapdoor` `minecraft:detector_rail` `minecraft:iron_door` `minecraft:iron_trapdoor` `minecraft:jungle_button` `minecraft:jungle_door` `minecraft:jungle_fence_gate` `minecraft:jungle_pressure_plate` `minecraft:jungle_trapdoor` `minecraft:lectern` `minecraft:lever` `minecraft:note_block` `minecraft:oak_button` `minecraft:oak_door` `minecraft:oak_fence_gate` `minecraft:oak_pressure_plate` `minecraft:oak_trapdoor` `minecraft:observer` `minecraft:polished_blackstone_button` `minecraft:polished_blackstone_pressure_plate` `minecraft:powered_rail` `minecraft:repeater` `minecraft:spruce_button` `minecraft:spruce_door` `minecraft:spruce_fence_gate` `minecraft:spruce_pressure_plate` `minecraft:spruce_trapdoor` `minecraft:stone_button` `minecraft:stone_pressure_plate` `minecraft:tripwire` `minecraft:tripwire_hook` `minecraft:warped_button` `minecraft:warped_door` `minecraft:warped_fence_gate` `minecraft:warped_pressure_plate` `minecraft:warped_trapdoor` |
  ---@type "false"|"true"
  powered = nil,

  ---The rotation of standing heads, signs and banners.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"0".."15"` | `minecraft:acacia_sign` `minecraft:birch_sign` `minecraft:black_banner` `minecraft:blue_banner` `minecraft:brown_banner` `minecraft:crimson_sign` `minecraft:cyan_banner` `minecraft:dark_oak_sign` `minecraft:gray_banner` `minecraft:green_banner` `minecraft:jungle_sign` `minecraft:light_blue_banner` `minecraft:light_gray_banner` `minecraft:lime_banner` `minecraft:magenta_banner` `minecraft:oak_sign` `minecraft:ominous_banner` `minecraft:orange_banner` `minecraft:pink_banner` `minecraft:purple_banner` `minecraft:red_banner` `minecraft:spruce_sign` `minecraft:warped_sign` `minecraft:white_banner` `minecraft:yellow_banner` |
  ---@type "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8"|"9"|"10"|"11"|"12"|"13"|"14"|"15"
  rotation = nil,

  ---The way this block connects to its neighbors.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"ascending_east"` `"ascending_north"` `"ascending_south"` `"ascending_west"` `"east_west"` `"north_south"` | `minecraft:activator_rail` `minecraft:detector_rail` `minecraft:powered_rail` |
  ---> | `"inner_left"` `"inner_right"` `"outer_left"` `"outer_right"` `"straight"` | `minecraft:acacia_stairs` `minecraft:andesite_stairs` `minecraft:birch_stairs` `minecraft:blackstone_stairs` `minecraft:brick_stairs` `minecraft:cobbled_deepslate_stairs` `minecraft:cobblestone_stairs` `minecraft:crimson_stairs` `minecraft:cut_copper_stairs` `minecraft:dark_oak_stairs` `minecraft:dark_prismarine_stairs` `minecraft:deepslate_brick_stairs` `minecraft:deepslate_tile_stairs` `minecraft:diorite_stairs` `minecraft:end_stone_brick_stairs` `minecraft:exposed_cut_copper_stairs` `minecraft:granite_stairs` `minecraft:jungle_stairs` `minecraft:mossy_cobblestone_stairs` `minecraft:mossy_stone_brick_stairs` `minecraft:nether_brick_stairs` `minecraft:oak_stairs` `minecraft:oxidized_cut_copper_stairs` `minecraft:polished_andesite_stairs` `minecraft:polished_blackstone_brick_stairs` `minecraft:polished_blackstone_stairs` `minecraft:polished_deepslate_stairs` `minecraft:polished_diorite_stairs` `minecraft:polished_granite_stairs` `minecraft:prismarine_brick_stairs` `minecraft:prismarine_stairs` `minecraft:purpur_stairs` `minecraft:quartz_stairs` `minecraft:red_nether_brick_stairs` `minecraft:red_sandstone_stairs` `minecraft:sandstone_stairs` `minecraft:smooth_quartz_stairs` `minecraft:smooth_red_sandstone_stairs` `minecraft:smooth_sandstone_stairs` `minecraft:spruce_stairs` `minecraft:stone_brick_stairs` `minecraft:stone_stairs` `minecraft:warped_stairs` `minecraft:waxed_cut_copper_stairs` `minecraft:waxed_exposed_cut_copper_stairs` `minecraft:waxed_oxidized_cut_copper_stairs` `minecraft:waxed_weathered_cut_copper_stairs` `minecraft:weathered_cut_copper_stairs` |
  ---> | `"ascending_east"` `"ascending_north"` `"ascending_south"` `"ascending_west"` `"east_west"` `"north_south"` `"north_east"` `"north_west"` `"south_east"` `"south_west"` | `minecraft:rail` |
  ---@type "ascending_east"|"ascending_north"|"ascending_south"|"ascending_west"|"east_west"|"north_south"|"inner_left"|"inner_right"|"outer_left"|"outer_right"|"straight"|"north_east"|"north_west"|"south_east"|"south_west"
  shape = nil,

  ---Whether this piston head's arm is 4/16th of a block shorter
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:piston_head` |
  ---@type "false"|"true"
  short = nil,

  ---Whether this campfire has higher smoke or not.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:campfire` `minecraft:soul_campfire` |
  ---@type "false"|"true"
  signal_fire = nil,

  ---Whether this block uses the snowy side texture.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:grass_block` `minecraft:mycelium` `minecraft:podzol` |
  ---@type "false"|"true"
  snowy = nil,

  ---Determines whether something is on the south side of the block.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:acacia_fence` `minecraft:birch_fence` `minecraft:black_stained_glass_pane` `minecraft:blue_stained_glass_pane` `minecraft:brown_mushroom_block` `minecraft:brown_stained_glass_pane` `minecraft:chorus_plant` `minecraft:crimson_fence` `minecraft:cyan_stained_glass_pane` `minecraft:dark_oak_fence` `minecraft:fire` `minecraft:glass_pane` `minecraft:gray_stained_glass_pane` `minecraft:green_stained_glass_pane` `minecraft:iron_bars` `minecraft:jungle_fence` `minecraft:light_blue_stained_glass_pane` `minecraft:light_gray_stained_glass_pane` `minecraft:lime_stained_glass_pane` `minecraft:magenta_stained_glass_pane` `minecraft:mushroom_stem` `minecraft:nether_brick_fence` `minecraft:oak_fence` `minecraft:orange_stained_glass_pane` `minecraft:pink_stained_glass_pane` `minecraft:purple_stained_glass_pane` `minecraft:red_mushroom_block` `minecraft:red_stained_glass_pane` `minecraft:spruce_fence` `minecraft:tripwire` `minecraft:vine` `minecraft:warped_fence` `minecraft:white_stained_glass_pane` `minecraft:yellow_stained_glass_pane` |
  ---> | `"none"` `"side"` `"up"` | `minecraft:redstone_wire` |
  ---> | `"low"` `"none"` `"tall"` | `minecraft:andesite_wall` `minecraft:blackstone_wall` `minecraft:brick_wall` `minecraft:cobbled_deepslate_wall` `minecraft:cobblestone_wall` `minecraft:deepslate_brick_wall` `minecraft:deepslate_tile_wall` `minecraft:diorite_wall` `minecraft:end_stone_brick_wall` `minecraft:granite_wall` `minecraft:mossy_cobblestone_wall` `minecraft:mossy_stone_brick_wall` `minecraft:nether_brick_wall` `minecraft:polished_blackstone_brick_wall` `minecraft:polished_blackstone_wall` `minecraft:polished_deepslate_wall` `minecraft:prismarine_wall` `minecraft:red_nether_brick_wall` `minecraft:red_sandstone_wall` `minecraft:sandstone_wall` `minecraft:stone_brick_wall` |
  ---@type "false"|"true"|"none"|"side"|"up"|"low"|"tall"
  south = nil,

  ---Whether this sapling is ready to grow.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"0".."1"` | `minecraft:acacia_sapling` `minecraft:bamboo` `minecraft:bamboo_sapling` `minecraft:birch_sapling` `minecraft:dark_oak_sapling` `minecraft:jungle_sapling` `minecraft:oak_sapling` `minecraft:potted_acacia_sapling` `minecraft:potted_birch_sapling` `minecraft:potted_dark_oak_sapling` `minecraft:potted_jungle_sapling` `minecraft:potted_oak_sapling` `minecraft:potted_spruce_sapling` `minecraft:spruce_sapling` |
  ---@type "0"|"1"
  stage = nil,

  ---Whether this block has been activated.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:dispenser` `minecraft:dropper` |
  ---@type "false"|"true"
  triggered = nil,

  ---Determines the variant of this block.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"normal"` `"sticky"` | `minecraft:moving_piston` `minecraft:piston_head` |
  ---> | `"left"` `"right"` `"single"` | `minecraft:chest` `minecraft:trapped_chest` |
  ---> | `"bottom"` `"double"` `"top"` | `minecraft:acacia_slab` `minecraft:andesite_slab` `minecraft:birch_slab` `minecraft:blackstone_slab` `minecraft:brick_slab` `minecraft:cobbled_deepslate_slab` `minecraft:cobblestone_slab` `minecraft:crimson_slab` `minecraft:cut_copper_slab` `minecraft:cut_red_sandstone_slab` `minecraft:cut_sandstone_slab` `minecraft:dark_oak_slab` `minecraft:dark_prismarine_slab` `minecraft:deepslate_brick_slab` `minecraft:deepslate_tile_slab` `minecraft:diorite_slab` `minecraft:end_stone_brick_slab` `minecraft:exposed_cut_copper_slab` `minecraft:granite_slab` `minecraft:jungle_slab` `minecraft:mossy_cobblestone_slab` `minecraft:mossy_stone_brick_slab` `minecraft:nether_brick_slab` `minecraft:oak_slab` `minecraft:oxidized_cut_copper_slab` `minecraft:petrified_oak_slab` `minecraft:polished_andesite_slab` `minecraft:polished_blackstone_brick_slab` `minecraft:polished_blackstone_slab` `minecraft:polished_deepslate_slab` `minecraft:polished_diorite_slab` `minecraft:polished_granite_slab` `minecraft:prismarine_brick_slab` `minecraft:prismarine_slab` `minecraft:purpur_slab` `minecraft:quartz_slab` `minecraft:red_nether_brick_slab` `minecraft:red_sandstone_slab` `minecraft:sandstone_slab` `minecraft:smooth_quartz_slab` `minecraft:smooth_red_sandstone_slab` `minecraft:smooth_sandstone_slab` `minecraft:smooth_stone_slab` `minecraft:spruce_slab` `minecraft:stone_brick_slab` `minecraft:stone_slab` `minecraft:warped_slab` `minecraft:waxed_cut_copper_slab` `minecraft:waxed_exposed_cut_copper_slab` `minecraft:waxed_oxidized_cut_copper_slab` `minecraft:waxed_weathered_cut_copper_slab` `minecraft:weathered_cut_copper_slab` |
  ---@type "normal"|"sticky"|"left"|"right"|"single"|"bottom"|"double"|"top"
  type = nil,

  ---Whether the TNT explodes when punched or not.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:tnt` |
  ---@type "false"|"true"
  unstable = nil,

  ---Determines whether something is above the block.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:andesite_wall` `minecraft:blackstone_wall` `minecraft:brick_wall` `minecraft:brown_mushroom_block` `minecraft:chorus_plant` `minecraft:cobbled_deepslate_wall` `minecraft:cobblestone_wall` `minecraft:deepslate_brick_wall` `minecraft:deepslate_tile_wall` `minecraft:diorite_wall` `minecraft:end_stone_brick_wall` `minecraft:fire` `minecraft:granite_wall` `minecraft:mossy_cobblestone_wall` `minecraft:mossy_stone_brick_wall` `minecraft:mushroom_stem` `minecraft:nether_brick_wall` `minecraft:polished_blackstone_brick_wall` `minecraft:polished_blackstone_wall` `minecraft:polished_deepslate_wall` `minecraft:prismarine_wall` `minecraft:red_mushroom_block` `minecraft:red_nether_brick_wall` `minecraft:red_sandstone_wall` `minecraft:sandstone_wall` `minecraft:stone_brick_wall` `minecraft:vine` |
  ---@type "false"|"true"
  up = nil,

  ---Whether the block has water in it.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:acacia_fence` `minecraft:acacia_sign` `minecraft:acacia_slab` `minecraft:acacia_stairs` `minecraft:acacia_trapdoor` `minecraft:acacia_wall_sign` `minecraft:andesite_slab` `minecraft:andesite_stairs` `minecraft:andesite_wall` `minecraft:birch_fence` `minecraft:birch_sign` `minecraft:birch_slab` `minecraft:birch_stairs` `minecraft:birch_trapdoor` `minecraft:birch_wall_sign` `minecraft:black_stained_glass_pane` `minecraft:blackstone_slab` `minecraft:blackstone_stairs` `minecraft:blackstone_wall` `minecraft:blue_stained_glass_pane` `minecraft:brain_coral` `minecraft:brain_coral_fan` `minecraft:brain_coral_wall_fan` `minecraft:brick_slab` `minecraft:brick_stairs` `minecraft:brick_wall` `minecraft:brown_stained_glass_pane` `minecraft:bubble_coral` `minecraft:bubble_coral_fan` `minecraft:bubble_coral_wall_fan` `minecraft:campfire` `minecraft:chain` `minecraft:chest` `minecraft:cobbled_deepslate_slab` `minecraft:cobbled_deepslate_stairs` `minecraft:cobbled_deepslate_wall` `minecraft:cobblestone_slab` `minecraft:cobblestone_stairs` `minecraft:cobblestone_wall` `minecraft:conduit` `minecraft:crimson_fence` `minecraft:crimson_sign` `minecraft:crimson_slab` `minecraft:crimson_stairs` `minecraft:crimson_trapdoor` `minecraft:crimson_wall_sign` `minecraft:cut_copper_slab` `minecraft:cut_copper_stairs` `minecraft:cut_red_sandstone_slab` `minecraft:cut_sandstone_slab` `minecraft:cyan_stained_glass_pane` `minecraft:dark_oak_fence` `minecraft:dark_oak_sign` `minecraft:dark_oak_slab` `minecraft:dark_oak_stairs` `minecraft:dark_oak_trapdoor` `minecraft:dark_oak_wall_sign` `minecraft:dark_prismarine_slab` `minecraft:dark_prismarine_stairs` `minecraft:dead_brain_coral` `minecraft:dead_brain_coral_fan` `minecraft:dead_brain_coral_wall_fan` `minecraft:dead_bubble_coral` `minecraft:dead_bubble_coral_fan` `minecraft:dead_bubble_coral_wall_fan` `minecraft:dead_fire_coral` `minecraft:dead_fire_coral_fan` `minecraft:dead_fire_coral_wall_fan` `minecraft:dead_horn_coral` `minecraft:dead_horn_coral_fan` `minecraft:dead_horn_coral_wall_fan` `minecraft:dead_tube_coral` `minecraft:dead_tube_coral_fan` `minecraft:dead_tube_coral_wall_fan` `minecraft:deepslate_brick_slab` `minecraft:deepslate_brick_stairs` `minecraft:deepslate_brick_wall` `minecraft:deepslate_tile_slab` `minecraft:deepslate_tile_stairs` `minecraft:deepslate_tile_wall` `minecraft:diorite_slab` `minecraft:diorite_stairs` `minecraft:diorite_wall` `minecraft:end_stone_brick_slab` `minecraft:end_stone_brick_stairs` `minecraft:end_stone_brick_wall` `minecraft:ender_chest` `minecraft:exposed_cut_copper_slab` `minecraft:exposed_cut_copper_stairs` `minecraft:fire_coral` `minecraft:fire_coral_fan` `minecraft:fire_coral_wall_fan` `minecraft:glass_pane` `minecraft:granite_slab` `minecraft:granite_stairs` `minecraft:granite_wall` `minecraft:gray_stained_glass_pane` `minecraft:green_stained_glass_pane` `minecraft:horn_coral` `minecraft:horn_coral_fan` `minecraft:horn_coral_wall_fan` `minecraft:iron_bars` `minecraft:iron_trapdoor` `minecraft:jungle_fence` `minecraft:jungle_sign` `minecraft:jungle_slab` `minecraft:jungle_stairs` `minecraft:jungle_trapdoor` `minecraft:jungle_wall_sign` `minecraft:ladder` `minecraft:lantern` `minecraft:light_blue_stained_glass_pane` `minecraft:light_gray_stained_glass_pane` `minecraft:lime_stained_glass_pane` `minecraft:magenta_stained_glass_pane` `minecraft:mossy_cobblestone_slab` `minecraft:mossy_cobblestone_stairs` `minecraft:mossy_cobblestone_wall` `minecraft:mossy_stone_brick_slab` `minecraft:mossy_stone_brick_stairs` `minecraft:mossy_stone_brick_wall` `minecraft:nether_brick_fence` `minecraft:nether_brick_slab` `minecraft:nether_brick_stairs` `minecraft:nether_brick_wall` `minecraft:oak_fence` `minecraft:oak_sign` `minecraft:oak_slab` `minecraft:oak_stairs` `minecraft:oak_trapdoor` `minecraft:oak_wall_sign` `minecraft:orange_stained_glass_pane` `minecraft:oxidized_cut_copper_slab` `minecraft:oxidized_cut_copper_stairs` `minecraft:petrified_oak_slab` `minecraft:pink_stained_glass_pane` `minecraft:polished_andesite_slab` `minecraft:polished_andesite_stairs` `minecraft:polished_blackstone_brick_slab` `minecraft:polished_blackstone_brick_stairs` `minecraft:polished_blackstone_brick_wall` `minecraft:polished_blackstone_slab` `minecraft:polished_blackstone_stairs` `minecraft:polished_blackstone_wall` `minecraft:polished_deepslate_slab` `minecraft:polished_deepslate_stairs` `minecraft:polished_deepslate_wall` `minecraft:polished_diorite_slab` `minecraft:polished_diorite_stairs` `minecraft:polished_granite_slab` `minecraft:polished_granite_stairs` `minecraft:prismarine_brick_slab` `minecraft:prismarine_brick_stairs` `minecraft:prismarine_slab` `minecraft:prismarine_stairs` `minecraft:prismarine_wall` `minecraft:purple_stained_glass_pane` `minecraft:purpur_slab` `minecraft:purpur_stairs` `minecraft:quartz_slab` `minecraft:quartz_stairs` `minecraft:red_nether_brick_slab` `minecraft:red_nether_brick_stairs` `minecraft:red_nether_brick_wall` `minecraft:red_sandstone_slab` `minecraft:red_sandstone_stairs` `minecraft:red_sandstone_wall` `minecraft:red_stained_glass_pane` `minecraft:sandstone_slab` `minecraft:sandstone_stairs` `minecraft:sandstone_wall` `minecraft:scaffolding` `minecraft:sea_pickle` `minecraft:smooth_quartz_slab` `minecraft:smooth_quartz_stairs` `minecraft:smooth_red_sandstone_slab` `minecraft:smooth_red_sandstone_stairs` `minecraft:smooth_sandstone_slab` `minecraft:smooth_sandstone_stairs` `minecraft:smooth_stone_slab` `minecraft:soul_lantern` `minecraft:spruce_fence` `minecraft:spruce_sign` `minecraft:spruce_slab` `minecraft:spruce_stairs` `minecraft:spruce_trapdoor` `minecraft:spruce_wall_sign` `minecraft:stone_brick_slab` `minecraft:stone_brick_stairs` `minecraft:stone_brick_wall` `minecraft:stone_slab` `minecraft:stone_stairs` `minecraft:trapped_chest` `minecraft:tube_coral` `minecraft:tube_coral_fan` `minecraft:tube_coral_wall_fan` `minecraft:warped_fence` `minecraft:warped_sign` `minecraft:warped_slab` `minecraft:warped_stairs` `minecraft:warped_trapdoor` `minecraft:warped_wall_sign` `minecraft:waxed_cut_copper_slab` `minecraft:waxed_cut_copper_stairs` `minecraft:waxed_exposed_cut_copper_slab` `minecraft:waxed_exposed_cut_copper_stairs` `minecraft:waxed_oxidized_cut_copper_slab` `minecraft:waxed_oxidized_cut_copper_stairs` `minecraft:waxed_weathered_cut_copper_slab` `minecraft:waxed_weathered_cut_copper_stairs` `minecraft:weathered_cut_copper_slab` `minecraft:weathered_cut_copper_stairs` `minecraft:white_stained_glass_pane` `minecraft:yellow_stained_glass_pane` |
  ---@type "false"|"true"
  waterlogged = nil,

  ---Determines whether something is on the west side of the block.
  ---***
  ---> | State | Valid Blocks |
  ---> | :---- | :----------- |
  ---> | `"false"` `"true"` | `minecraft:acacia_fence` `minecraft:birch_fence` `minecraft:black_stained_glass_pane` `minecraft:blue_stained_glass_pane` `minecraft:brown_mushroom_block` `minecraft:brown_stained_glass_pane` `minecraft:chorus_plant` `minecraft:crimson_fence` `minecraft:cyan_stained_glass_pane` `minecraft:dark_oak_fence` `minecraft:fire` `minecraft:glass_pane` `minecraft:gray_stained_glass_pane` `minecraft:green_stained_glass_pane` `minecraft:iron_bars` `minecraft:jungle_fence` `minecraft:light_blue_stained_glass_pane` `minecraft:light_gray_stained_glass_pane` `minecraft:lime_stained_glass_pane` `minecraft:magenta_stained_glass_pane` `minecraft:mushroom_stem` `minecraft:nether_brick_fence` `minecraft:oak_fence` `minecraft:orange_stained_glass_pane` `minecraft:pink_stained_glass_pane` `minecraft:purple_stained_glass_pane` `minecraft:red_mushroom_block` `minecraft:red_stained_glass_pane` `minecraft:spruce_fence` `minecraft:tripwire` `minecraft:vine` `minecraft:warped_fence` `minecraft:white_stained_glass_pane` `minecraft:yellow_stained_glass_pane` |
  ---> | `"none"` `"side"` `"up"` | `minecraft:redstone_wire` |
  ---> | `"low"` `"none"` `"tall"` | `minecraft:andesite_wall` `minecraft:blackstone_wall` `minecraft:brick_wall` `minecraft:cobbled_deepslate_wall` `minecraft:cobblestone_wall` `minecraft:deepslate_brick_wall` `minecraft:deepslate_tile_wall` `minecraft:diorite_wall` `minecraft:end_stone_brick_wall` `minecraft:granite_wall` `minecraft:mossy_cobblestone_wall` `minecraft:mossy_stone_brick_wall` `minecraft:nether_brick_wall` `minecraft:polished_blackstone_brick_wall` `minecraft:polished_blackstone_wall` `minecraft:polished_deepslate_wall` `minecraft:prismarine_wall` `minecraft:red_nether_brick_wall` `minecraft:red_sandstone_wall` `minecraft:sandstone_wall` `minecraft:stone_brick_wall` |
  ---@type "false"|"true"|"none"|"side"|"up"|"low"|"tall"
  west = nil
}


---A `table` containing sound group properties
---@class BlockStateSoundGroup
---@field pitch number
---@field volume number
---@field hit string
---@field fall string
---@field plate string
---@field step string
---@field break string

---A `table` containing the blockstate of a block.
---@class BlockState
---Meant for internal use. Has no purpose in Lua.
---@deprecated
---@field ["figura$block_state"] userdata
---@field name BlockID
---@field properties BlockStateProperties
local BlockState = {}

---Returns if this block can emit redstone power.
---@return boolean
function BlockState.emitsRedstonePower() end

---Returns the blast resistance of this block.
---@return number
function BlockState.getBlastResistance() end

---Returns a table with all the block tags this block is included in.
---@return string[]
function BlockState.getBlockTags() end

---Returns a table of vectors, each vector corresponding to a "box" of the block's collision.  
---`{minX, minY, minZ, maxX, maxY, maxZ}`
---@return Vector6[]
function BlockState.getCollisionShape() end

---Returns what the client thinks this block would output from a comparator.
---
---Note: This is only what the client *thinks*, this means that certain blocks, like containers, may
---not give the actual output that a comparator would give.
---@return NibbleInt
function BlockState.getComparatorOutput() end

---Returns the tile entity data if it exists.  
---@todo Aliases for tile entity data // GS: You're crazy if you actually do it.
---@return table
function BlockState.getEntityData() end

---Returns the hardness of this block.
---@return number
function BlockState.getHardness() end

---Returns the multiplier to jump velocity this block applies to entities jumping on it.
---@return number
function BlockState.getJumpVelocityMultiplier() end

---Returns the light level this block produces
---@return NibbleInt
function BlockState.getLuminance() end

---Returns the map color of the block's material as an integear.
---@return number
function BlockState.getMapColor() end

---Returns the name of the block material.  
---This does not return a readable string, instead it returns a field id for the material.
---
---Material IDs are auto-completed and come with a description of what they are.
---@return BlockMaterial
function BlockState.getMaterial() end

---Returns how much light is blocked by this block.
---@return NibbleInt
function BlockState.getOpacity() end

---Returns a table of vectors, each vector corresponding to a "box" of the block's visual outline.  
---`{minX, minY, minZ, maxX, maxY, maxZ}`
---@return Vector6[]
function BlockState.getOutlineShape() end

---Returns how slippery this block is.
---@return number
function BlockState.getSlipperiness() end

---Returns a table, listing each sound a blockstate may make, also includes base pitch and volume.
---@return BlockStateSoundGroup
function BlockState.getSoundGroup() end

---Returns the multiplier to velocity this block applies to entities walking on it.
---@return number
function BlockState.getVelocityMultiplier() end

---Returns if the block is a block entity.  
---Block entities store extra data such as inventory or advanced states.
---@return boolean
function BlockState.hasBlockEntity() end

---Returns if this block glows even in the absence of light.
---@return boolean
function BlockState.hasEmissiveLighting() end

---Returns if entities can collide with this block.
---@return boolean
function BlockState.isCollidable() end

---Returns if the block's collision is a single 1x1x1 cube or not.
---@return boolean
function BlockState.isFullCube() end

---Returns if this block cannot be seen through.
---@return boolean
function BlockState.isOpaque() end

---Returns if the block is considered solid.
---
---Entities suffocate in solid blocks and can spawn on them.
---@return boolean
function BlockState.isSolidBlock() end

---Returns if this block is considered translucent by Minecraft.
---@return boolean
function BlockState.isTranslucent() end

---Sets the position of the block.
---@param pos VectorPos
function BlockState.setPos(pos) end

---Returns a string of this BlockState with the same syntax as `/setblock`.
---@return string
function BlockState.toStateString() end

--================================================================================================--
--=====  FUNCTIONS  ==============================================================================--
--================================================================================================--

---Contains function related to creating blockstates
block_state = {}

---Creates a new `BlockState`.
---@param block string|BlockState
---@param pos? VectorPos
---@return BlockState
function block_state.createBlock(block, pos) end
