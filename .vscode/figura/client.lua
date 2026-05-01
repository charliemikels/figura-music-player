--================================================================================================--
--=====  FUNCTIONS  ==============================================================================--
--================================================================================================--

---Contains functions allowing access to client variables.
---Only accessable with the host script.
---For all other players running your script, it will return nil. (except for isHost())
client={}

---Returns whether the first given version is ahead or behind the second given version.  
---Both parameters must be valid semantic versions.
---* `-1` if `version < compareTo`
---* `0` if `version == compareTo`
---* `1` if `version > compareTo`
---@param version string
---@param compareTo string
---@return number
function client.checkVersion(version, compareTo) end

---Clears the title and subtitle text.
function client.clearTitle() end

---Returns the most recently shown actionbar text.  
---This persists through worlds.
---
---Note: This will cause a VM error if no action bar text has been shown since the game started.
---@return string
function client.getActionBar() end

---Returns the namespaced ID of the currently active shader.  
---Returns nil if no shader is active.
---@return string
function client.getActiveShader() end

---Returns the currently allocated memory in bytes.
---@return number
function client.getAllocatedMemory() end

---Returns the chunk count debug line from the debug screen.
---
---Note: This is not actually the count, this is the entire debug line containing that information
---and may look similar to the example below.  
---`"C: 497/15000 (s) D: 12, pC: 000, pU: 00, aB: 12"`
---@return string
function client.getChunksCount() end

---Returns if the crosshair is enabled or not.
---@return boolean
function client.getCrosshairEnabled() end

---Returns the offset of the crosshair.  
---Returns nil if it hasn't been set yet.
---@return Vector2
function client.getCrosshairPos() end

---Returns the entity count debug line from the debug screen.
---
---Note: This is not actually the count, this is the entire debug line containing that information
---and may look similar to the example below.  
---`"E: 17/83, B: 0, SD: 12"`
---@return string
function client.getEntityCount() end

---Returns the current FOV.
---@return number
function client.getFOV() end

---Returns the frame count debug line from the debug screen.
---
---Note: This is not actually the FPS, this is the entire debug line containing that information
---and may look similar to the example below.  
---`"67 fps T: 120 vsyncfancy fancy-clouds B: 2"`
---@return string
function client.getFPS() end

---Returns the GUI scale as set in Minecraft's settings.  
---Auto is `0`.
---@return number
function client.getGUIScale() end

---Returns if there are any Iris Shaders active.
---@return boolean
function client.getIrisShadersEnabled() end

---Returns the version of Java currently running.
---@return string
function client.getJavaVersion() end

---Returns the maximum allowed allocated memory in bytes.
---@return number
function client.getMaxMemory() end

---Returns the currently used memory in bytes.
---@return number
function client.getMemoryInUse() end

---Returns the position of the mouse from the top left corner in pixels.
---@return Vector2
function client.getMousePos() end

---Returns the most recent direction the scroll wheel has scrolled.  
---Calling this function resets the scroll wheel's direction back to neutral.
---* Neutral: `0`
---* Up: `1`
---* Down: `-1`
---@return number
function client.getMouseScroll() end

---Returns the name of the currently open GUI.
---
---Note: This is *not* the ID of the GUI, it is the display name. This can be changed on certain
---blocks by renaming them in an anvil.
---@return string
function client.getOpenScreen() end

---Returns the number of particles as a string.
---@return string
function client.getParticleCount() end

---Returns the GUI scale.
---This might not be the same as the GUI scale set in Minecraft's settings due to a small window or
---the GUI scale being set to `Auto`.
---@return number
function client.getScaleFactor() end

---Returns the size of the window scaled by the GUI scale.
---@return Vector2
function client.getScaledWindowSize() end

---Returns the brand of the server.
---@return string
function client.getServerBrand() end

---Returns the sound count debug line from the debug screen.
---
---Note: This is not actually the count, this is (almost) the entire debug line containing that
---information and may look similar to the example below.  
---`"Sounds: 1/247 + 0/8"`
---@return string
function client.getSoundCount() end

---Returns the most recently shown subtitle.  
---
---Note: This will cause a VM error if no subtitle has been shown since the game started or since
---`.clearTitle()` was last called.
---@return string
function client.getSubtitle() end

---Returns the amount of miliseconds since the Unix Epoch.
---@return number
function client.getSystemTime() end

---Returns the most recently shown title.  
---
---Note: This will cause a VM error if no title has been shown since the game started or since
---`.clearTitle()` was last called.
---@return string
function client.getTitle() end

---Returns the version number of Minecraft as a string.
---@return string
function client.getVersion() end

---Returns the "type" of Minecraft currently running.  
---This is usually the currently running mod loader.
---@return string
function client.getVersionType() end

---Returns the size of the Minecraft window in pixels
---@return Vector2
function client.getWindowSize() end

---Returns if the game instance running the script is the player with the avatar.
---@return boolean
function client.isHost() end

---Returns if the hud is visible or not using the F1 key.
---@return boolean
function client.isHudEnabled() end

---Returns if the singleplayer world is paused.  
---Multiplayer games cannot be paused.
---@return boolean
function client.isPaused() end

---Returns if the Minecraft window is focused.
---@return boolean
function client.isWindowFocused() end

---Sets the text of the actionbar and shows it.
---@param text string
function client.setActionbar(text) end

---Sets the visibility of the crosshair.
---@param bool boolean
function client.setCrosshairEnabled(bool) end

---Moves the crosshair by the given offset.
---
---This does not change the player's aim direction.
---@param offset Vector2
function client.setCrosshairPos(offset) end

---Sets if the mouse is forced to be unlocked during normal gameplay.
---
---Locking the mouse in some GUIs closes them.
---@param bool boolean
function client.setMouseUnlocked(bool) end

---Sets the subtitle of the title. Does not show the title or subtitle.
---@param text string
function client.setSubtitle(text) end

---Set the text of the title and shows the title and subtitle.
---@param text string
function client.setTitle(text) end

---Sets the fade durations for the title/subtitle.
---@param fadeIn number
---@param hold number
---@param fadeOut number
function client.setTitleTimes(fadeIn, hold, fadeOut) end
