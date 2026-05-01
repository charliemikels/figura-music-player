--================================================================================================--
--=====  CLASSES  ================================================================================--
--================================================================================================--

---A camera that displays whatever is in front of it to the player's screen.
---@class Camera
local Camera = {}

---Returns the current pivot of the camera.
---@return VectorPos
function Camera.getPivot() end

---Returns the current position of the camera.
---@return VectorPos
function Camera.getPos() end

---Returns the current rotation of the camera.
---@return VectorAng
function Camera.getRot() end

---Sets the pivot point of the camera.
---@param pos VectorPos
function Camera.setPivot(pos) end

---Sets the position of the camera.
---@param pos VectorPos
function Camera.setPos(pos) end

---Sets the rotation of the camera.
---@param ang VectorAng
function Camera.setRot(ang) end


--================================================================================================--
--=====  FUNCTIONS  ==============================================================================--
--================================================================================================--

---A table containing the firstperson and thirdperson cameras.
camera = {
  ---The firstperson camera.
  FIRST_PERSON = Camera,

  ---The thirdperson camera.
  THIRD_PERSON = Camera
}
