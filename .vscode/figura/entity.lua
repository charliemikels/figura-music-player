--================================================================================================--
--=====  CLASSES  ================================================================================--
--================================================================================================--

---A Minecraft dimension identifier.
---
---Only the default Minecraft dimensions are auto-completed.  
---You can use any dimension from any mod, even if it does not auto-complete.
---@alias DimensionID
---| "minecraft:overworld"
---| "minecraft:the_nether"
---| "minecraft:the_end"

---An equipment slot.
---@alias EquipmentSlot
---| 1 #Main Hand
---| 2 #Off Hand
---| 3 #Feet
---| 4 #Legs
---| 5 #Chest
---| 6 #Head

---A Minecraft entity identifier.
---
---Only the default Minecraft entities are auto-completed.  
---You can use any entity from any mod, even if it does not auto-complete.
---@alias EntityID
---| "minecraft:axolotl" #Axolotl
---| "minecraft:bat" #Bat
---| "minecraft:bee" #Bee
---| "minecraft:blaze" #Blaze
---| "minecraft:cat" #Cat
---| "minecraft:cave_spider" #Cave Spider
---| "minecraft:chicken" #Chicken
---| "minecraft:cod" #Cod
---| "minecraft:cow" #Cow
---| "minecraft:creeper" #Creeper
---| "minecraft:dolphin" #Dolphin
---| "minecraft:donkey" #Donkey
---| "minecraft:drowned" #Drowned
---| "minecraft:elder_guardian" #Elder Guardian
---| "minecraft:ender_dragon" #Ender Dragon
---| "minecraft:enderman" #Enderman
---| "minecraft:endermite" #Endermite
---| "minecraft:evoker" #Evoker
---| "minecraft:fox" #Fox
---| "minecraft:ghast" #Ghast
---| "minecraft:giant" #Giant
---| "minecraft:glow_squid" #Glow Squid
---| "minecraft:goat" #Goat
---| "minecraft:guardian" #Guardian
---| "minecraft:hoglin" #Hoglin
---| "minecraft:horse" #Horse
---| "minecraft:husk" #Husk
---| "minecraft:illusioner" #Illusioner
---| "minecraft:iron_golem" #Iron Golem
---| "minecraft:llama" #Llama
---| "minecraft:magma_cube" #Magma Cube
---| "minecraft:mooshroom" #Mooshroom
---| "minecraft:mule" #Mule
---| "minecraft:ocelot" #Ocelot
---| "minecraft:panda" #Panda
---| "minecraft:parrot" #Parrot
---| "minecraft:phantom" #Phantom
---| "minecraft:pig" #Pig
---| "minecraft:piglin_brute" #Piglin Brute
---| "minecraft:piglin" #Piglin
---| "minecraft:pillager" #Pillager
---| "minecraft:polar_bear" #Polar Bear
---| "minecraft:pufferfish" #Pufferfish
---| "minecraft:rabbit" #Rabbit
---| "minecraft:ravager" #Ravager
---| "minecraft:salmon" #Salmon
---| "minecraft:sheep" #Sheep
---| "minecraft:shulker" #Shulker
---| "minecraft:silverfish" #Silverfish
---| "minecraft:skeleton_horse" #Skeleton Horse
---| "minecraft:skeleton" #Skeleton
---| "minecraft:slime" #Slime
---| "minecraft:snow_golem" #Snow Golem
---| "minecraft:spider" #Spider
---| "minecraft:squid" #Squid
---| "minecraft:stray" #Stray
---| "minecraft:strider" #Strider
---| "minecraft:trader_llama" #Trader Llama
---| "minecraft:tropical_fish" #Tropical Fish
---| "minecraft:turtle" #Turtle
---| "minecraft:vex" #Vex
---| "minecraft:villager" #Villager
---| "minecraft:vindicator" #Vindicator
---| "minecraft:wandering_trader" #Wandering Trader
---| "minecraft:witch" #Witch
---| "minecraft:wither_skeleton" #Wither Skeleton
---| "minecraft:wither" #Wither
---| "minecraft:wolf" #Wolf
---| "minecraft:zoglin" #Zoglin
---| "minecraft:zombie_horse" #Zombie Horse
---| "minecraft:zombie_villager" #Zombie Villager
---| "minecraft:zombie" #Zombie
---| "minecraft:zombified_piglin" #Zombified Piglin

---An entity animation.
---@alias EntityAnimation
---| "STANDING" #All: Default animation.
---| "FALL_FLYING" #Player: Using elytra.
---| "SLEEPING" #Player: Is sleeping in a bed.
---| "SWIMMING" #Player: Sprint swimming.
---| "SPIN_ATTACK" #Player: Flying with trident.
---| "CROUCHING" #Player: Sneaking.
---| "DYING" #Player: Falling over death animation.

---A damage source name.
---
---Only the default Minecraft damage sources are auto-completed.  
---You can use any damage source, even if it does not auto-complete.
---@alias DamageSource
---| "anvil" #Anvil
---| "arrow" #Arrow
---| "badRespawnPoint" #Exploding bed or respawn
---| "cactus" #Contact with cactus
---| "cramming" #Entity cramming
---| "dragonBreath" #Dragon Breath (Unused, the dragon breath attack does magic damage.)
---| "drown" #Drowning
---| "dryout" #Squid air suffocation
---| "even_more_magic" #Unused
---| "explosion" #Explosion
---| "explosion.player" #Explosion caused by something else
---| "fall" #Falling
---| "fallingBlock" #Hit by falling block
---| "fallingStalactite" #Hit by a falling stalactite
---| "fireworks" #Firework explosion
---| "flyIntoWall" #Elytra gliding too fast into a wall
---| "freeze" #Freezing in powder snow
---| "generic" #Unknown damage
---| "hotFloor" #Magma block
---| "indirectMagic" #Indirectly hit with magic
---| "inFire" #Standing in a fire block
---| "inWall" #Suffocation
---| "lava" #Swimming in lava
---| "lightingBolt" #Struck by lightning
---| "magic" #Directly hit with magic
---| "mob" #Attacked by an entity
---| "onFire" #Burning
---| "outOfWorld" #Void or /kill
---| "player" #Attacked by a player
---| "stalagmite" #Falling on a stalagmite
---| "starve" #Starvation
---| "sting" #Bee Sting
---| "sweetBerryBush" #Contact with sweet berry bush
---| "thorns" #Thorns enchantment
---| "thrown" #Thrown projectile
---| "trident" #Trident
---| "wither" #Wither effect
---| "witherSkull" #Wither skull projectile

---A Minecraft status effect identifier.
---
---Only the default Minecraft status effects are auto-completed.  
---You can use any status effect from any mod, even if it does not auto-complete.
---@alias StatusEffectID
---| "minecraft:absorption" #Absorption
---| "minecraft:bad_omen" #Bad Omen
---| "minecraft:blindness" #Blindness
---| "minecraft:conduit_power" #Conduit Power
---| "minecraft:dolphins_grace" #Dolphin's Grace
---| "minecraft:fire_resistance" #Fire Resistance
---| "minecraft:glowing" #Glowing
---| "minecraft:haste" #Haste
---| "minecraft:health_boost" #Health Boost
---| "minecraft:hero_of_the_village" #Hero of the Village
---| "minecraft:hunger" #Hunger
---| "minecraft:instant_health" #Instant Health
---| "minecraft:instant_damage" #Instant Damage
---| "minecraft:invisibility" #Invisibility
---| "minecraft:jump_boost" #Jump Boost
---| "minecraft:levitation" #Levitation
---| "minecraft:luck" #Luck
---| "minecraft:mining_fatigue" #Mining Fatigue
---| "minecraft:nausea" #Nausea
---| "minecraft:night_vision" #Night Vision
---| "minecraft:poison" #Poison
---| "minecraft:regeneration" #Regeneration
---| "minecraft:resistance" #Resistance
---| "minecraft:saturation" #Saturation
---| "minecraft:slow_falling" #Slow Falling
---| "minecraft:slowness" #Slowness
---| "minecraft:speed" #Speed
---| "minecraft:strength" #Strength
---| "minecraft:unluck" #Bad Luck
---| "minecraft:water_breathing" #Water Breathing
---| "minecraft:weakness" #Weakness
---| "minecraft:wither" #Wither

---@alias PlayerGamemode
---| "SURVIVAL"
---| "CREATIVE"
---| "ADVENTURE"
---| "SPECTATOR"

---A `table` containing the duration and amplifier of a status effect.
---@class StatusEffect
---@field amplifier number #The effect's level.
---@field duration number #The amount of ticks remaining.

---A hand slot.
---@alias HandSlot
---| 1 #Main Hand
---| 2 #Off Hand

---String literal of Hand
---@alias HandString
---| "MAIN_HAND"
---| "OFF_HAND"

---A non-living entity.
---@class Entity
local Entity = {}

---Returns the ticks of air this entity has left.
---@return number
function Entity.getAir() end

---Returns the remaining air of this entity as a percentage. (`0..1`)
---@return number
function Entity.getAirPercentage() end

---Returns the currently playing animation of this entity.
---@return EntityAnimation string
function Entity.getAnimation() end

---Returns the size of this entity's bounding box in blocks.
---@return Vector3
function Entity.getBoundingBox() end

---Returns the item in this entity's given equipment slot.
---
---Note: An empty slot will still return an `ItemStack` of air.
---@param slot EquipmentSlot
---@return ItemStack
function Entity.getEquipmentItem(slot) end

---Returns the height from the base of this entity to their eye level in blocks.
---@return number
function Entity.getEyeHeight() end

---Returns the world coords of the entity's eyes.
---@return VectorPos
function Entity.getEyeY() end

---Returns how long this entity will be on fire for.  
---If this number is negative, it is how long the entity is immune to being set on fire.
---@return number
function Entity.getFireTicks() end

---Returns the amount of ticks this entity has been frozen in deep snow for.
---
---Note: Always returns `0` if playing on 1.16.
---@return number
function Entity.getFrozenTicks() end

---Returns the normalized direction that this entity is looking in.
---@return VectorPos
function Entity.getLookDir() end

---Returns the maximum air this entity can have.
---@return number
function Entity.getMaxAir() end

---Returns this entity's display name.
---
---Note: Returns the entity's translated name if it has no custom name.
---@return string
function Entity.getName() end

---Returns an NBT value from this entity using the given SNBT path.
---
---`List`, `Compound`, `Byte_Array`, `Int_Array`, `Long_Array` tags return a `table`.  
---`Byte`, `Short`, `Int`, `Long`, `Float`, and `Double` tags return a `number`.  
---`String` tags return a `string`.
---@param nbtpath string
---@return string|number|table
function Entity.getNbtValue(nbtpath) end

---Returns the position of this entity.
---@param delta? number
---@return VectorPos
function Entity.getPos(delta) end

---Returns the rotation of this entity.
---
---Note: When used on the local player, the yaw will build up past the normal limits when in first
---person.
---@param delta? number
---@return VectorAng
function Entity.getRot(delta) end

---Returns the position of the block this entity is looking at.  
---Returns `nil` if not looking at any blocks.
---@param targetLiquid boolean
---@return VectorPos?
function Entity.getTargetedBlockPos(targetLiquid) end

---Returns the entity identifier of this entity.
---@return EntityID string
function Entity.getType() end

---Returns the UUID4 of this entity.
---@return string
function Entity.getUUID() end

---Returns the entity that this entity is riding.
---@return (Entity|LivingEntity|Player)?
function Entity.getVehicle() end

---Returns the velocity of this entity.
---@return VectorPos
function Entity.getVelocity() end

---Returns the dimension identifier of the world this entity is in.
---@return DimensionID string
function Entity.getWorldName() end

---Returns if the entity has a Figura avatar.
---@return boolean
function Entity.hasAvatar() end

---Returns if the entity is glowing.
---@return boolean
function Entity.isGlowing() end

---Returns if the entity is a Hamburger.
---@return boolean
---function Entity.isHamburger() end

---Returns if the entity is touching lava.
---@return boolean
function Entity.isInLava() end

---Returns if the entity has contact with rain.
---@return boolean
function Entity.isInRain() end

---Returns if the entity is invisible.
---@return boolean
function Entity.isInvisible() end

---Returns if this entity is standing on solid ground.
---@return boolean
function Entity.isOnGround() end

---Returns if the entity has the silent NBT tag.
---@return boolean
function Entity.isSilent() end

---Returns if the entity is sneaking.
---@return boolean
function Entity.isSneaking() end

---Returns if this entity is sneaky.
---@return boolean
function Entity.isSneaky() end

---Returns is the entity is sprinting.
---@return boolean
function Entity.isSprinting() end

---Returns if the entity has contact with water or waterlogged blocks.
---@return boolean
function Entity.isTouchingWater() end

---Returns if the entity is fully submerged in water.
---@return boolean
function Entity.isUnderwater() end

---Returns if this entity is being rained on or in water.
---@return boolean
function Entity.isWet() end


---LivingEntity ⇐ Entity
---***
---A living entity.
---@class LivingEntity : Entity
local LivingEntity = {}

---Returns which hand is active.  
---Active hand is determined by the last hand to use an item.  
---Returns nil if no item has been used.
---@return HandString?
function LivingEntity.getActiveHand() end

---Returns the item that is currently being used.
---@return ItemStack
function LivingEntity.getActiveItem() end

---Returns the total armor value of this entity.
---
---Note: Some entities have natural armor that is added on top of the armor they are wearing.
---@return number
function LivingEntity.getArmor() end

---Returns the yaw of this entity's body.
---@param delta? number
---@return number
function LivingEntity.getBodyYaw(delta) end

---Returns how long this entity has been dead for in ticks.  
---An entity is deleted after being dead for 20 ticks.
---@return number
function LivingEntity.getDeathTime() end

---Returns the current health of this entity.
---@return number
function LivingEntity.getHealth() end

---Returns the current health of this entity as a percentage. (`0..1`)
---@return number
function LivingEntity.getHealthPercentage() end

---Returns the max health of this entity.
---@return number
function LivingEntity.getMaxHealth() end

---Returns the duration and amplifier of the given status effect on this entity.  
---Returns `nil` if the given status effect does not exist on this entity.
---@param effect StatusEffectID
---@return StatusEffect
function LivingEntity.getStatusEffect(effect) end

---Returns a list of all status effects on this entity.
---@return StatusEffectID[]
function LivingEntity.getStatusEffectTypes() end

---Returns the amount of stingers stuck in this entity.
---@return number
function LivingEntity.getStingerCount() end

---Returns the amount of arrows stuck in this entity.
---@return number
function LivingEntity.getStuckArrowCount() end

---Returns if the entity is climbing.
---@return boolean
function LivingEntity.isClimbing() end

---Returns if this entity is left-handed.
---@return boolean
function LivingEntity.isLeftHanded() end

---Returns if this entity is using an item.
---@return boolean
function LivingEntity.isUsingItem() end


---Player ⇐ LivingEntity ⇐ Entity
---***
---A player entity.
---@class Player : LivingEntity
local Player = {}

---Returns the current level of this entity.
---@return number
function Player.getExperienceLevel() end

---Returns the progress between this entity's current level and next level as a percentage. (`0..1`)
---@return number
function Player.getExperienceProgress() end

---Returns the amount of hunger this entity has.
---@return number
function Player.getFood() end

---Returns the player's gamemode as a string.
---@return PlayerGamemode
function Player.getGamemode() end

---Returns an item held in this entity's hands.
---Returns `nil` if the slot is empty.
---@param slot HandSlot
---@return ItemStack?
function Player.getHeldItem(slot) end

---Returns the vanilla model type, either "default" or "slim".
---@return "default"|"slim"
function Player.getModelType() end

---Returns the amount of saturation this entity has.
---@return number
function Player.getSaturation() end

---Returns the cross-script value stored in the player at the specified key.
---@param key string
---@return any
function Player.getStoredValue(key) end

---Returns the table of the entity under the crosshair.
---
---Note: This only works if the `Player` is the player running the current instance of the script.
---@return (Entity|LivingEntity|Player)?
function Player.getTargetedEntity() end

---Returns if the player is flying via creative flight.
---@return boolean
function Player.isFlying() end

---Returns the last source of damage this entity has taken.
---
---Note: Does not work unless the server is running Figura. (LAN or Integrated server.)
---@return DamageSource string
function Player.lastDamageSource() end


--================================================================================================--
--=====  FUNCTIONS  ==============================================================================--
--================================================================================================--

---The player linked to this script.
---
---Note: This table is unreadable until `player_init()` has run.
---@type Player
player = {}

---Stores the value in the player executing the script at the specified key.
---@param key string
---@param value any
function storeValue(key, value) end
