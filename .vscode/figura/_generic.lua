--================================================================================================--
--=====  FUNCTIONS  ==============================================================================--
--================================================================================================--

---Logs a value to Minecraft's chat and log output.  
---If `jsonEncode` is true, it will try to encode the log into json text.
---@param value any
---@param jsonEncode? boolean
function log(value, jsonEncode) end

---Logs a value to Minecraft's chat and log output.  
---If `jsonEncode` is true, it will try to encode the log into json text.
---
---Alias of `log`.
---@param value any
---@param jsonEncode? boolean
function print(value, jsonEncode) end

---Logs the contents of the given `table` to Minecraft's chat and log output.  
---Attempting to log anything other than a pure `table` will log nothing.  
---If the second parameter is true, the contents of nested tables will also be outputed.
---
---Note: This will not log a `Vector`, use `log` instead.
---@param tbl table
---@param showNested? boolean
function logTableContent(tbl, showNested) end

---Logs the contents of the given `table` to Minecraft's chat and log output.  
---Attempting to log anything other than a pure `table` will log nothing.  
---If the second parameter is true, the contents of nested tables will also be outputed.
---
---Alias of `logTableContent`
---@param tbl table
---@param showNested? boolean
function logTable(tbl, showNested) end


---Converts a string into a Lua function where the contents of the string become the function's body.
---
---Returns a string containing any compile errors if conversion failed.
---@param body string
---@return string|function
function loadstring(body) end


---@alias Type type
---| '"vector"'

---Returns the type of its only argument, coded as a string. The possible results of this function
---are `"nil"` (a string, not the value `nil`), `"number"`, `"string"`, `"boolean"`, `"table"`,
---`"function"`, `"thread"`, `"userdata"`, and `"vector"`.
---
---[View documents](command:extension.lua.doc?["en-us/52/manual.html/pdf-type"])
---@param v any
---@return Type type
function type(v) end


---**THIS FUNCTION DOES NOT EXIST UNTIL YOU CREATE IT!**  
---You should not run this function, Figura will run it for you.
---
---Use the below code to create this function:
---```
---function tick()
---  --code here
---end
---```
---***
---This function runs its contents every Minecraft tick.
---
---Since almost all Minecraft data changes every tick, you should check that data in this function
---if you want it to change every tick.  
---Some examples of code that could be placed here are:
---* Getting the health of the player,
---* Getting what the player is holding,
---* Checking the player's animation,
---* Checking a block in the world,
---* Updating tick timers,
---* Sending pings.
---
---Some things will appear too choppy if they are placed in this function, see the `render` function
---if you want your code to run more often than the `tick` function.
---
---Notes:
---* This function *can* be defined multiple times. This is unlike vanilla Lua where redefining
---a function will overwrite it.
---* Figura will run the contents of every instance of this function.
---* Try to define this function as few times as possible, this feature only exists to make combining
---different scripts easier.
function tick() end

---`delta`:  
---&emsp; The distance between the last tick and next tick this frame sits on.  
---&emsp; This is a value `0..1`.
---***
---**THIS FUNCTION DOES NOT EXIST UNTIL YOU CREATE IT!**  
---You should not run this function, Figura will run it for you.
---
---Use the below code to create this function:
---```
---function render(delta)
---  --code here
---end
---```
---***
---This function runs its contents every frame that this script's avatar is visible.  
---This will only run on the player if they are in third person or can see any part of their
---avatar that is connected to them (Not `NO_PARENT`) in first person.
---
---It is very ineffecient to run code here. Only run code that should change every frame.  
---A few simple examples of code that could be placed here are:
---* Moving/rotating/scaling parts smoothly,
---* Getting the positions of parts.
---
---You should not get Minecraft data every frame as it only changes every tick.
---
---
---Notes:
---* This function *can* be defined multiple times. This is unlike vanilla Lua where redefining
---a function will overwrite it.
---* Figura will run the contents of every instance of this function.
---* Try to define this function as few times as possible, this feature only exists to make combining
---different scripts easier.
---@param delta number
function render(delta) end

---`delta`:  
---&emsp; The distance between the last tick and next tick this frame sits on.  
---&emsp; This is a value `0..1`.
---***
---**THIS FUNCTION DOES NOT EXIST UNTIL YOU CREATE IT!**  
---You should not run this function, Figura will run it for you.
---
---Use the below code to create this function:
---```
---function world_render(delta)
---  --code here
---end
---```
---***
---This function runs its contents every frame, but will continue to run even if your model is not rendering.
---
---Notes:
---* This function *can* be defined multiple times. This is unlike vanilla Lua where redefining
---a function will overwrite it.
---* Figura will run the contents of every instance of this function.
---* Try to define this function as few times as possible, this feature only exists to make combining
---different scripts easier.
---@param delta number
function world_render(delta) end

---**THIS FUNCTION DOES NOT EXIST UNTIL YOU CREATE IT!**  
---You should not run this function, Figura will run it for you.
---
---Use the below code to create this function:
---```
---function player_init()
---  --code here
---end
---```
---***
---This function runs its contents *once* when `player` becomes available.
---
---Notes:
---* This function *can* be defined multiple times. This is unlike vanilla Lua where redefining
---a function will overwrite it.
---* Figura will run the contents of every instance of this function.
---* Try to define this function as few times as possible, this feature only exists to make combining
---different scripts easier.
function player_init() end

---`cmd`:  
---&emsp; Contains the *full* message (including the prefix) used to trigger this function.  
---***
---**THIS FUNCTION DOES NOT EXIST UNTIL YOU CREATE IT!**  
---You should not run this function, Figura will run it for you.
---
---Use the below code to create this function:
---```
---function onCommand(cmd)
---  --code here
---end
---```
---***
---This function runs its contents *once* when the player enters a message starting with the command
---prefix as defined by `chat.setFiguraCommandPrefix`.
---
---Notes:
---* This function *can* be defined multiple times. This is unlike vanilla Lua where redefining
---a function will overwrite it.
---* Figura will run the contents of every instance of this function.
---* Try to define this function as few times as possible, this feature only exists to make combining
---different scripts easier.
---@param cmd string
function onCommand(cmd) end

---**THIS FUNCTION DOES NOT EXIST UNTIL YOU CREATE IT!**  
---You should not run this function, Figura will run it for you.
---
---Use the below code to create this function:
---```
---function onDamage(amount, source)
---  --code here
---end
---```
---***
---Runs every time you take damage.
---
---Notes:
---* This function *can* be defined multiple times. This is unlike vanilla Lua where redefining
---a function will overwrite it.
---* Figura will run the contents of every instance of this function.
---* Try to define this function as few times as possible, this feature only exists to make combining
---different scripts easier.
---@param amount number The amount of damage you would have taken before armor/resistance calculations.
---@param source string
function onDamage(amount, source) end
