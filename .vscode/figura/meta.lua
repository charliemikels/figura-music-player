--================================================================================================--
--=====  FUNCTIONS  ==============================================================================--
--================================================================================================--

---Contains functions involving Figura's more technical parts such as limits, the version, and the
---current count of certain things.
meta = {}

---Returns the animation limit in this client's instance of the script.
---@return integer
function meta.getAnimationLimit() end

---Returns a number based on the current status of the Figura backend.
---@return
---| 2 #Disconnected
---| 3 #Connecting
---| 4 #Connected
function meta.getBackendStatus() end

---Returns if the player can use custom render layers (shaders).
---@return boolean
function meta.getCanHaveCustomRenderLayer() end

---Returns if the nameplate can be modified in this client's instance of the script.
---
---This is affected by the "Nameplate/Chat Name Changes" trust setting.
---@return boolean
function meta.getCanModifyNameplate() end

---Returns if the vanilla playermodel can be edited in this client's instance of the script.
---
---This is affected by the "Vanilla Avatar Changes" trust setting.
---@return boolean
function meta.getCanModifyVanilla() end

---Returns the complexity limit in this client's instance of the script.
---
---This is affected by the "Max Complexity" trust setting.
---@return integer
function meta.getComplexityLimit() end

---Returns the current animation complexity.
---@return integer
function meta.getCurrentAnimationCount() end

---Returns the current complexity of the avatar in this client's instance of the script.
---
---The complexity is the amount of verticies being rendered on the client's screen.
---@return integer
function meta.getCurrentComplexity() end

---Returns the amount of particles the avatar is creating per second in this client's instance of
---the script.
---@return integer
function meta.getCurrentParticleCount() end

---Returns the amount of render instructions the avatar is running in this client's instance of the
---script at this frame.
---
---The amount of render instructions is affected by whatever is running in the `render()` function.
---@return integer
function meta.getCurrentRenderCount() end

---Returns the amount of sounds the avatar is emitting per second in this client's instance of the
---script.
---@return integer
function meta.getCurrentSoundCount() end

---Returns the amount of tick instruction the avatar is running in this client's instance of the
---script at this tick.
---
---The amount of tick instructions is affected by whatever is running in the `tick()` function.
---@return integer
function meta.getCurrentTickCount() end

---Returns if the avatar is allowed to render offscreen in this client's instance of the script.
---
---This is affected by the "Offscreen Rendering" trust setting.
---@return boolean
function meta.getDoesRenderOffscreen() end

---Returns the current version of Figura in this client's instance of the script.
---@return string
function meta.getFiguraVersion() end

---Returns the init instruction limit in this client's instance of the script.
---
---This is affected by the "Max Init Instructions" trust setting.
---@return integer
function meta.getInitLimit() end

---Returns a number based on the current status of the model.
---@return
---| 1 #No model
---| 2 #Too big (>100KB)
---| 3 #Big (75KB -100KB)
---| 4 #Normal
function meta.getModelStatus() end

---Returns the particles-per-second limit in this client's instance of the script.
---
---This is affected by the "Maximum Particles Per Second" trust setting.
---@return integer
function meta.getParticleLimit() end

---Returns the render instruction limit in this client's instance of the script.
---
---This is affected by the "Max Render Instructions" trust setting.
---@return integer
function meta.getRenderLimit() end

---Returns a number based on the current status of the script.
---@return
---| 1 #No script
---| 2 #Errored
---| 4 #Normal
function meta.getScriptStatus() end

---Returns the sounds-per-second limit in this client's instance of the script.
---
---This is affected by the "Maximum Sounds Per Second" trust setting.
---@return integer
function meta.getSoundLimit() end

---Returns a number based on the current status of the texture.
---@return
---| 1 #No texture
---| 4 #Normal
function meta.getTextureStatus() end

---Returns the tick instruction limit in this client's instance of the script.
---
---This is affected by the "Max Tick Instructions" trust setting.
---@return integer
function meta.getTickLimit() end
