--================================================================================================--
--=====  CLASSES  ================================================================================--
--================================================================================================--

---A space with the player's name visible in it.
---@class Nameplate
local Nameplate = {}

---Returns whatever was passed through `.setEnabled()` last.
---@return boolean?
function Nameplate.getEnabled() end

---Returns whatever was passed through `.setPos()` last.
---@return VectorPos?
function Nameplate.getPos() end

---Returns whatever was passed through `.setScale()` last.
---@return VectorPos?
function Nameplate.getScale() end

---Returns the text in the nameplate.  
---Returns `nil` if the text has not been set by `.setText()`.
---@return string?
function Nameplate.getText() end

---Does nothing...  
---For a version that does something, check the ENTITY nameplate.
---@param bool? boolean
function Nameplate.setEnabled(bool) end

---Does nothing...  
---For a version that does something, check the ENTITY nameplate.
---@param vec3? VectorPos
function Nameplate.setPos(vec3) end

---Does nothing...  
---For a version that does something, check the ENTITY nameplate.
---@param vec3? VectorPos
function Nameplate.setScale(vec3) end

---Sets the text of the nameplate.  
---All text is placed to the left of the Figura mark.  
---Set to `nil` to reset to default.
---
---Can use [Raw JSON Text](https://minecraft.fandom.com/wiki/Raw_JSON_text_format) formatting.
---@param str? string
function Nameplate.setText(str) end

---EntityNameplate ⇐ Nameplate
---***
---Contains nameplate functions specific to the ENTITY nameplate.
---@class EntityNameplate : Nameplate
local EntityNameplate = {}

---Returns if the nameplate is visible.  
---Returns `nil` if it has not been set by `.setEnabled()`.
---@return boolean?
function EntityNameplate.getEnabled() end

---Returns the position offset of the nameplate in blocks.  
---Returns `nil` if the position offset has not been set by `.setPos()`.
---
---Note: This value might not be accurate if the player's entity is scaled.
---@return VectorPos?
function EntityNameplate.getPos() end

---Returns the scale of the nameplate.  
---Returns nil if the scale has not been set by `.setScale()`.
---@return VectorPos?
function EntityNameplate.getScale() end

---Sets if the nameplate is visible.  
---Set to `nil` to reset to default.
---@param bool? boolean
function EntityNameplate.setEnabled(bool) end

---Sets the position offset of the nameplate in blocks.  
---Set to `nil` to reset to default.
---
---Note: This value is not accurate if the player's entity is scaled.
---@param vec3? VectorPos
function EntityNameplate.setPos(vec3) end

---Sets the scale of the nameplate.  
---Set to `nil` to reset to default.
---@param vec3? VectorPos
function EntityNameplate.setScale(vec3) end

--================================================================================================--
--=====  FUNCTIONS  ==============================================================================--
--================================================================================================--

---Contains the player's nameplates.
---
---`CHAT` is the player's name in chat.  
---`ENTITY` is the nameplate above their head.  
---`LIST` is the player's name in the player list.
nameplate = {
  ---@type Nameplate
  CHAT = {},

  ---@type EntityNameplate
  ENTITY = {},

  ---@type Nameplate
  LIST = {}
}
