--================================================================================================--
--=====  CLASSES  ================================================================================--
--================================================================================================--

---The sides of a cube.
---@alias CubeSide
---| "NORTH"
---| "SOUTH"
---| "EAST"
---| "WEST"
---| "UP"
---| "DOWN"
---| "ALL"

---A parent type that the part will rotate with.
---@alias ParentType
---| "None" #Rotate with the origin of the player.
---| "WORLD" #Rotate with the world.
---| "Model" #Rotate with the entire model.
---| "Head" #Rotate with the player's head.
---| "Torso" #Rotate with the player's body.
---| "LeftArm" #Rotate with the player's left arm.
---| "RightArm" #Rotate with the player's right arm.
---| "LeftLeg" #Rotate with the player's left leg.
---| "RightLeg" #Rotate with the player's right leg.
---| "LeftItemOrigin" #Rotate with the player's left held item.
---| "RightItemOrigin" #Rotate with the player's right held item.
---| "LeftElytraOrigin" #Rotate with the player's left elytra wing's origin.
---| "RightElytraOrigin" #Rotate with the player's right elytra wing's origin.
---| "LeftParrotOrigin" #Rotate with the player's left parrot spot.
---| "RightParrotOrigin" #Rotate with the player's right parrot spot.
---| "LeftElytra" #Rotate with the player's left elytra wing.
---| "RightElytra" #Rotate with the player's right elytra wing.
---| "Camera" #Rotate to always face the camera.

---The possible types of a CustomModelPart
---@alias CustomModelPartType
---| "CUBE"
---| "GROUP"
---| "MESH"

---@alias Shader
---| "None" #Do not use a shader.
---| "EndPortal" #Use the end portal shader.
---| "Glint" #Use the enchantment glint.

---@alias TextureType
---| "Custom" #The custom texture suplied with the avatar.
---| "Skin" #Your Minecraft skin.
---| "Cape" #Your cape, or Steve if you dont have a cape.
---| "Elytra" #Your elytra texture (NOT the cape-provided elytra!) (vanilla probably dont even use it at all)
---| "Resource" #Any loaded texture including resource packs! or missing texture if not found.

---A basic model part with very few options for modifying it.
---@class BasicModelPart
local BasicModelPart = {}

---Returns if the part is enabled or not.  
---Returns `nil` if the part has not been toggled with `.setEnabled()` yet.
---
---If the function returns `nil` assume the part is enabled.
---@return boolean?
function BasicModelPart.getEnabled() end

---Returns the position offset of the part.  
---Returns `nil` if the part has not been moved with `.setPos()` yet.
---
---If the function returns `nil` assume the part is at `0,0,0`
---@return VectorPos?
function BasicModelPart.getPos() end

---Returns the rotation offset of the part.  
---Returns `nil` if the part has not been moved with `.setRot()` yet.
---@return VectorAng?
function BasicModelPart.getRot() end

---Returns the scale of the part set by `.setScale()`.
---@return VectorPos?
function BasicModelPart.getScale() end

---Sets the visibility of the part.
---@param state boolean
function BasicModelPart.setEnabled(state) end

---Sets the position offset of the part.
---@param pos VectorPos
function BasicModelPart.setPos(pos) end

---Sets the rotation offset of the part.
---@param ang VectorAng
function BasicModelPart.setRot(ang) end

---Sets the scale of the part.
---@param pos VectorPos
function BasicModelPart.setScale(pos) end


---VanillaModelPart ⇐ BasicModelPart
---***
---A vanilla model part, has more options than a basic part.
---@class VanillaModelPart : BasicModelPart
local VanillaModelPart = {}

---Returns if the part is enabled before any `.setEnabled()` operations are applied.  
---Always seems to return `false`.
---@return boolean
function VanillaModelPart.getOriginEnabled() end

---Returns the part's original position before any `.setPos()` operations are applied.
---@return VectorPos
function VanillaModelPart.getOriginPos() end

---Returns the part's original angle *in radians*.  
---If you want the angle in degrees, use `math.deg()` or `<Vector>.toDeg()`.
---@return VectorAng
function VanillaModelPart.getOriginRot() end

---Returns if the part's skin customization setting is enabled.  
---Returns `nil` if the part does not have a setting.
---@return boolean?
function VanillaModelPart.isOptionEnabled() end

---The proxy for the `CustomModelPart` class.  
---This only exists to fix inheritance of `CustomModelPart`s inside `CustomModelPart`s.
---@class CustomModelPartProxy : BasicModelPart
---@field [string] CustomModelPart
local CustomModelPartProxy = {}

---@class CustomModelPart : CustomModelPartProxy
---CustomModelPart ⇐ BasicModelPart
---***
---A custom model part. These are the parts from the bbmodel file.
---`CustomModelPart`s can contain other `CustomModelPart`s.
---
---Note: Despite the list saying so, a `function` cannot be a `CustomModelPart`! It simply looks
---like that to allow any key to become a `CustomModelPart` if needed.
local CustomModelPart = {}

---Adds a new render task attached to this model part.
---
---Note: This function does not return the render task. Use `<CustomModelPart>.getRenderTask()`
---instead.
---@overload fun(type: "TEXT", name: string, value: string, emissive?: boolean, pos?: VectorPos, rot?: VectorAng, scale?: VectorPos)
---@overload fun(type: "ITEM", name: string, value: ItemStack|ItemID, renderMode: RenderMode, emissive?: boolean, pos?: VectorPos, rot?: VectorAng, scale?: VectorPos, renderLayer?: string)
---@overload fun(type: "BLOCK", name: string, value: BlockState|BlockID, emissive?: boolean, pos?: VectorPos, rot?: VectorAng, scale?: VectorPos, renderLayer?: string)
function CustomModelPart.addRenderTask(type, name, value, ...) end

---Remove ALL render tasks from this part.
function CustomModelPart.clearAllRenderTasks() end

---Returns the sum of all position keyframes at this time.
---@return VectorPos
function CustomModelPart.getAnimPos() end

---Returns the sum of all rotation keyfrmaes at this time.
---@return VectorAng
function CustomModelPart.getAnimRot() end

---Returns the sum of all scale keyframes at this time.
---@return Vector3
function CustomModelPart.getAnimScale() end

---Returns a table containing this part's children.
---@return CustomModelPart[]
function CustomModelPart.getChilderen() end

---Returns the current color of the part.  
---The default color is `<1,1,1>`.
---@return VectorColor
function CustomModelPart.getColor() end

---Returns if culling is enabled on the part.
---@return boolean
function CustomModelPart.getCullEnabled() end

---Returns if extra textures such as emissive textures are rendered.
---@return boolean
function CustomModelPart.getExtraTexEnabled() end

---Returns the light value set by `.setLight()`.  
---Returns `nil` if it hasn't been set yet.
---@return Vector2?
function CustomModelPart.getLight() end

---Returns if the part is only mimicing its parent part instead of having its origin connected to
---the parent part's origin.
---@return boolean
function CustomModelPart.getMimicMode() end

---Returns the name assigned in Blockbench of this part.
---@return string
function CustomModelPart.getName() end

---Returns the opacity of a part.
---
---Note: Opacity is a value from 0 to 1.
---@return number
function CustomModelPart.getOpacity() end

---Returns the overlay value set by `.setOverlay()`.
---Returns `nil` if it hasn't been set yet.
---@return Vector2?
function CustomModelPart.getOverlay() end

---Returns the parent type of the part.
---@return ParentType
function CustomModelPart.getParentType() end

---Returns the position offset of the part's pivot point.
---@return VectorPos
function CustomModelPart.getPivot() end

---Returns a render task table of the given name, if any
---@param name string
---@return (BlockTaskTable|ItemTaskTable|TextTaskTable)?
function CustomModelPart.getRenderTask(name) end

---Returns the *absolute* rotation of the part.
---
---Note: This does *not* return the rotation offset.
---@return VectorAng
function CustomModelPart.getRot() end

---Returns the shader of the part.
---@return Shader
function CustomModelPart.getShader() end

---Returns the type of texture that the part uses
---@return TextureType
function CustomModelPart.getTexture() end

---Returns the size of the part's texture.
---@return Vector2
function CustomModelPart.getTextureSize() end

---Returns the type of the part.
---@return CustomModelPartType
function CustomModelPart.getType() end

---Returns the UV offset of the part.
---
---Note: This does *not* return the actual UV of the part.
---@return VectorUV
function CustomModelPart.getUV() end

---Returns the UV data of the specified face.
---@param face CubeSide
---@return Vector4
function CustomModelPart.getUVData(face) end

---Takes a `Vector` with a direction relative to the part and returns a `Vector` with the direction
---in world-space.
---@param dir VectorPos
---@return VectorPos
function CustomModelPart.partToWorldDir(dir) end

---*Just a word of caution, this function is very complicated. Do not expect to get how it works
---right from the start.*
---
---Takes a `Vector` with a blockbench position, then:  
---* Makes a pivot `x` (which is *not* this part's pivot) at the center of the player's neck.
---* Offsets pivot `x` by this part's Lua position offset,
---* Rotates pivot `x`'s position around this part's `(Lua position offset + Lua pivot offset)`,
---* Adds the given blockbench position to the position of pivot `x`,
---* Rotates the new blockbench position around pivot `x` by the absolute rotation of this part.
---* Converts to an absolute world position and returns that position.
---@param pos VectorPos
---@return VectorPos
function CustomModelPart.partToWorldPos(pos) end

---Removes a render task from this part.
---@param name string
function CustomModelPart.removeRenderTask(name) end

---Sets the color of the model.
---
---Note: The color is set by *tinting* the model, use grayscale textures for best results.
---@param col VectorColor
function CustomModelPart.setColor(col) end

---Enable/disable the inner faces of the part.
---@param boolean boolean
function CustomModelPart.setCullEnabled(boolean) end

---Enable/disable extra texture rendering (ie emissive textures)
---@param boolean boolean
function CustomModelPart.setExtraTexEnabled(boolean) end

---Overrides the light level the part is rendered at.  
---Any value below 0 or above 15 will render the part invisible.  
---`nil` returns the part to normal.
---
---The first value of the vector controls block light, the second controls sky light.
---@param vector? Vector2
function CustomModelPart.setLight(vector) end

---Sets the mimic mode of the model.  
---If true, the model will *mimic* its parent as set by `.setParentType()` instead of having its
---origin connected to the parent part's origin.
---@param state boolean
function CustomModelPart.setMimicMode(state) end

---Sets the opacity of the part.
---
---Note: Opacity is a value from 0 to 1.
---@param num number
function CustomModelPart.setOpacity(num) end

---Overrides the overlay level the part is rendered at.  
---Any value below 0 or above 15 will render the part black.  
---`nil` returns the part to normal.
---
---The first value controls a white overlay, the second value controls the hurt overlay.
---@param vector? Vector2
function CustomModelPart.setOverlay(vector) end

---Sets the parent type of the part.
---@param parent ParentType
function CustomModelPart.setParentType(parent) end

---Sets the part's pivot point.
---@param vector VectorPos
function CustomModelPart.setPivot(vector) end

---Sets the render layer (custom shader) of the part.
---@param string string
function CustomModelPart.setRenderLayer(string) end

---Sets the *absolute* rotation of the part.
---
---Note: This does *not* set the rotation offset.
---@param ang VectorAng
function CustomModelPart.setRot(ang) end

---Sets the shader of the part.
---@param shader Shader
function CustomModelPart.setShader(shader) end

---Changes which texture is applied to the part.  
---`resource` is only needed if the texture type is set to `"Resource"`.
---@param type TextureType
---@param resource? string
function CustomModelPart.setTexture(type, resource) end

---Set the size of the part's texture.
---@param vector Vector2
function CustomModelPart.setTextureSize(vector) end

---Sets the UV offset of the part.
---
---Note: This does *not* set the actual UV of the part.
---@param uv VectorUV
function CustomModelPart.setUV(uv) end

---Sets the UV data of the given side.  
---UV's must be in BlockBench format.
---@param face CubeSide
---@param vector Vector4
function CustomModelPart.setUVData(face, vector) end

---Takes a `Vector` with a direction in world-space and returns a `Vector` with the direction
---relative to the part.
---
---Seems to act similar to `.partToWorldDir()`.
---@param dir VectorPos
---@return VectorPos
function CustomModelPart.worldToPartDir(dir) end

---Takes a `Vector` with a a blockbench position and returns a `Vector` with the world position
---relative to the player rotated by the part's rotation.
---@param pos VectorPos
---@return VectorPos
function CustomModelPart.worldToPartPos(pos) end


--================================================================================================--
--=====  FUNCTIONS  ==============================================================================--
--================================================================================================--

---The `table` containing the parts and folders from your blockbench model.
---
---If you want to get the Top hat on your model's head in this example...
---```
---Player
---├ Head
---│ └ TopHat
---└ Body
---  └ Belt
---```
---...then you need to use `model.Player.Head.TopHat` to access it.
---
---Note: Auto-completion does not know what folders and parts you have in your model at first, but
---will learn based on what folders and parts you access yourself.  
---If you want autocompletion for model paths, use
---[*Manuel-Underscore*'s Figura VSCode extension](https://marketplace.visualstudio.com/items?itemName=Manuel-Underscore.figura).  
---If you use the above extension, guessed parts will have a different icon from parts found in the
---model.
---@type table<string, CustomModelPart>
model = {}

---A `table` containing the vanilla playermodel.
vanilla_model = {
  ---@type VanillaModelPart
  HEAD = {},

  ---@type VanillaModelPart
  HAT = {},

  ---@type VanillaModelPart
  CAPE = {},

  ---@type VanillaModelPart
  TORSO = {},

  ---@type VanillaModelPart
  JACKET = {},

  ---@type VanillaModelPart
  LEFT_ARM = {},

  ---@type VanillaModelPart
  LEFT_SLEEVE = {},

  ---@type VanillaModelPart
  RIGHT_ARM = {},

  ---@type VanillaModelPart
  RIGHT_SLEEVE = {},

  ---@type VanillaModelPart
  LEFT_LEG = {},

  ---@type VanillaModelPart
  LEFT_PANTS_LEG = {},

  ---@type VanillaModelPart
  RIGHT_LEG = {},

  ---@type VanillaModelPart
  RIGHT_PANTS_LEG = {},

  ---@type VanillaModelPart
  LEFT_EAR = {},

  ---@type VanillaModelPart
  RIGHT_EAR = {}
}

---A `table` containing the armor model.
armor_model = {
  ---@type BasicModelPart
  HELMET = {},

  ---@type BasicModelPart
  HEAD_ITEM = {},

  ---@type BasicModelPart
  CHESTPLATE = {},

  ---@type BasicModelPart
  LEGGINGS = {},

  ---@type BasicModelPart
  BOOTS = {}
}

---A `table` containing the elytra model.
elytra_model = {
  ---@type BasicModelPart
  LEFT_WING = {},

  ---@type BasicModelPart
  RIGHT_WING = {}
}

---A `table` containing the held item models.
held_item_model = {
  ---@type BasicModelPart
  LEFT_HAND = {},

  ---@type BasicModelPart
  RIGHT_HAND = {}
}

---A `table` containing the parrot models.
parrot_model = {
  ---@type BasicModelPart
  LEFT_PARROT = {},

  ---@type BasicModelPart
  RIGHT_PARROT = {}
}

---A `table` containing the first person models.
first_person_model = {
	---@type BasicModelPart
	MAIN_HAND = {},

	---@type BasicModelPart
	OFF_HAND = {}
}

---A `table` containing the spyglass models.
spyglass_model = {
  ---@type BasicModelPart
  LEFT_SPYGLASS = {},

  ---@type BasicModelPart
  RIGHT_SPYGLASS = {}
}
