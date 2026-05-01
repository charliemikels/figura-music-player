--================================================================================================--
--=====  CLASSES  ================================================================================--
--================================================================================================--

---@alias RaycastShapeHandling
---| "COLLIDER" #The shape entities collide with
---| "OUTLINE" #The block outline when looked at
---| "VISUAL" #What Minecraft believes is the sight-blocking shape

---@alias RaycastFluidHandling
---| "NONE" #Do not raycast fluids
---| "SOURCE_ONLY" #Only raycast fluid sources
---| "ANY" #Raycast any fluid

---A predicate that tests for a block.
---
---Return `true` to stop raycasting and return the current block.  
---Return `false` to continue and ignore the current block.
---@alias BlockPredicate fun(block: BlockState, pos: VectorPos): boolean

---A predicate that tests for an entity.
---
---Return `true` to stop raycasting and return the current entity.  
---Return `false` to continue and ignore the current entity.
---@alias EntityPredicate fun(entity: Entity|LivingEntity|Player): boolean

--================================================================================================--
--=====  FUNCTIONS  ==============================================================================--
--================================================================================================--

---Contains generic functions related to rendering. Also contains some raycasting.
renderer = {}

---Returns the camera position of the player executing the script.
---@return VectorPos
function renderer.getCameraPos() end

---Returns the camera rotation.
---@return VectorAng
function renderer.getCameraRot() end

---Returns if fire can be rendered on the avatar.  
---Returns `nil` if it has not been set by `.setRenderFire()`.
---@return boolean?
function renderer.getRenderFire() end

---Returns if your player head shows your Figura HEAD/SKULL (true) or your vanilla head (false).
---@return boolean
function renderer.getRenderPlayerHead() end

---Returns the radius of the player's shadow.  
---Returns `nil` if the size has not been set by `.setShadowSize()`.
---@return number?
function renderer.getShadowSize() end

---Returns the length in pixels of a string or Raw JSON Text.
---@param text string
---@return integer
function renderer.getTextWidth(text) end

---Returns if the camera is in front of or behind the player.
---@return boolean
function renderer.isCameraBackwards() end

---Returns if the model is being viewed in first-person.  
---This will always return false for other clients since they cannot see your first-person model.
---@return boolean
function renderer.isFirstPerson() end

---Returns if your mount is enabled.
---@return boolean
function renderer.isMountEnabled() end

---Returns if your mount's shadow is enabled.
---@return boolean
function renderer.isMountShadowEnabled() end

---Casts a ray from startPos to endPos, looking at the blocks on the way.  
---If the ray never hits anything, then the function returns nil.
---@param startPos VectorPos
---@param endPos VectorPos
---@param shapeHandling RaycastShapeHandling
---@param fluidHandling RaycastFluidHandling
---@param predicate? BlockPredicate
---@return {state: BlockState, pos: VectorPos}?
function renderer.raycastBlocks(startPos, endPos, shapeHandling, fluidHandling, predicate) end

---Casts a ray from startPos to endPos, returning the first entity it sees on the way.  
---If the ray never hits anything, then the function returns nil.
---@param startPos VectorPos
---@param endPos VectorPos
---@param predicate? EntityPredicate
---@return {entity:Entity|LivingEntity|Player, pos:VectorPos}?
function renderer.raycastEntities(startPos, endPos, predicate) end

---Toggle the render of the entity you are riding.
---@param enabled boolean
function renderer.setMountEnabled(enabled) end

---Toggle the shadow of the entity you are riding.
---@param enabled boolean
function renderer.setMountShadowEnabled(enabled) end

---Toggle the rendering of fire on your avatar.  
---Set to `nil` to reset to default.
---@param enabled? boolean
function renderer.setRenderFire(enabled) end

---Toggle whether your playerhead renders your avatar's HEAD/SKULL or your vanilla skin.
---@param enabled boolean
function renderer.setRenderPlayerHead(enabled) end

---Sets the radius of the player's shadow.  
---Set the radius to `nil` to reset the shadow.
---@param radius number?
function renderer.setShadowSize(radius) end

---Shows the animation of you swinging your arm.  
---Set `offhand` to swing the offhand arm instead.
---
---Note: This is automatically synced to other players.
---@param offhand? boolean
function renderer.swingArm(offhand) end
