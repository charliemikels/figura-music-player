--================================================================================================--
--=====  CLASSES  ================================================================================--
--================================================================================================--

---An animation Loop Mode.
---
---Determines what an animation does when it reaches the end.
---@alias LoopMode
---| "ONCE" #Stop the animation with blending.
---| "HOLD" #Hold the animation on the last frame.
---| "LOOP" #Restart the animation.

---Animation play state.
---@alias PlayState
---| "PLAYING"  #Playing normally.
---| "STOPPED"  #Not currently running.
---| "PAUSED"   #Paused with `.pause()`.
---| "ENDED"    #Holding on last frame.
---| "STOPPING" #Blending to `"STOPPED"` state.
---| "STARTING" #Blending to `"PLAYING"` state.

---A Blockbench animation.
---@class Animation
local Animation = {}

---Stops the animation without using blending.
function Animation.cease() end

---Returns the blend time of the animation.
---@return number
function Animation.getBlendTime() end

---Returns the blend weight of the animation.
---@return number
function Animation.getBlendWeight() end

---Returns the length of the animation.
---@return number
function Animation.getLength() end

---Returns the loop delay of the animation.
---@return number
function Animation.getLoopDelay() end

---Returns the loop mode fo the animation.
---@return LoopMode
function Animation.getLoopMode() end

---Returns the name of the animation.
---@return string
function Animation.getName() end

---Returns if vanilla rotations are locked.
---@return boolean
function Animation.getReplace() end

---Returns the current state of the animation.
---@return PlayState
function Animation.getPlayState() end

---Returns the priority of the animation.
---@return integer
function Animation.getPriority() end

---Returns whether the animation overrides in blockbench or not.
---@return boolean
function Animation.getOverride() end

---Returns the current speed of the animation.
---@return number
function Animation.getSpeed() end

---Returns the start delay of the animation
---@return number
function Animation.getStartDelay() end

---Returns the start offset of the animation.
---@return number
function Animation.getStartOffset() end

---Returns if the animation is playing.
---@return boolean
function Animation.isPlaying() end

---Pauses the animation.  
---You can resume by using `.play()` or `.start()`.
function Animation.pause() end

---Starts/restarts the animation.
function Animation.play() end

---Sets the blend time of the animation in seconds.  
---Blending is done when an animation is starting or ending.
---@param time number
function Animation.setBlendTime(time) end

---Sets the blend weight of the animation.
---@param weight number
function Animation.setBlendWeight(weight) end

---Sets the length of the animation.
---@param length number
function Animation.setLength(length) end

---Sets the delay between each animation loop.
---@param delay number
function Animation.setLoopDelay(delay) end

---Sets the loop mode of the animation.
---@param mode LoopMode
function Animation.setLoopMode(mode) end

---If replace is enabled, the animation will stop vanilla rotations on parts that are part of the
---animation's timeline.  
---They will still be able to move.  
---
---Similar to how mimic parts work, but instead of only rotations, it is only for positions.
---@param bool boolean
function Animation.setReplace(bool) end

---Sets the current state of the animation.
---@param state PlayState
function Animation.setPlayState(state) end

---With override enabled, the animation will use the pivots defined in the animation editor instead
---of the ones defined in the default editor.
---@param bool boolean
function Animation.setOverride(bool) end

---Sets the priority of an animation over the others, you must put this value yourself.
---
---Priority determines how animations interact.  
---Animations with the same priority will blend together while animations of lower priority will not
---run at all if higher priority animation is running.
---@param priority integer
function Animation.setPriority(priority) end

---Sets the speed of the animation. (1 = 100%)
---@param speed number
function Animation.setSpeed(speed) end

---After calling play() or start(), delay playing the animation for the given amount of seconds.
---@param delay number
function Animation.setStartDelay(delay) end

---Offset the start of the animation by the given amount of seconds.
---@param offset number
function Animation.setStartOffset(offset) end

---Starts the animation if it isn't already playing.
function Animation.start() end

---Stops the animation, using blending to smoothly move back into place.
function Animation.stop() end

--================================================================================================--
--=====  FUNCTIONS  ==============================================================================--
--================================================================================================--

---@class AnimTableProxy
---@field [string] Animation

---A `table` containing functions relating to animations and the avatar's animations.
---@class AnimationTable : AnimTableProxy
animation = {}

---Stops ALL animations without using blending.
function animation.ceaseAll() end

---Returns a table with the name of each animation you have.
---@return string[]
function animation.listAnimations() end

---Stops ALL animations, using blending to smoothly move back into place.
function animation.stopAll() end
