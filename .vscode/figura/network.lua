--================================================================================================--
--=====  FUNCTIONS  ==============================================================================--
--================================================================================================--

---A type of function that is run on all instances of a script if the host runs it.
---
---Pings are 5 bytes big without a value.
---
---A ping may also contain a value to send with the ping. This adds the following bytes based on the
---type of value:
---* Nil: 0 bytes (`nil`)
---* Boolean: 1 byte (`true/false`)
---* Integer: 4 bytes (`-2147483648`..`2147483647`)
---* Float: 4 bytes (`-3.4028236692094e+38`..`3.4028236692094e+38`)
---* String: 2 bytes + (`0`..`1000` characters) bytes
---* Table: 2 bytes + (Table contents) bytes
---
---You may only send up to 1024 bytes of pings a second, and only up to 32 pings a tick.
---@class PingFunction : function

---@alias PingSupported nil|boolean|number|string|table|Vector

---**THERE IS A MUCH BETTER WAY TO HANDLE PINGS. SEE THE `ping` TABLE FOR MORE INFORMATION.**
---***
---Contains functions that handle pings.
---@deprecated
network = {}

---Avoid deprecation errors in this file
---@diagnostic disable: deprecated

---**THERE IS A MUCH BETTER WAY TO HANDLE PINGS. SEE THE `ping` TABLE FOR MORE INFORMATION.**
---***
---Registers a ping that allows you to send information to all clients running this script.  
---This is mainly used to sync variables that do not sync normally. (`Keybind`s, `action_wheel`
---functions, NBT, etc.)  
---You may register up to *65535* pings in one script.
---
---All examples in this description will assume that the ping is called *"pingname"*.
---```
---network.registerPing("pingname")
---```
---The ping is linked to a function of the same name, this function is not defined by default
---and it will need to defined so it can be used:
---```
---function pingname(param) --(Param is optional!)
---    --code here
---end
---```
---You can call this function by using:
---```
---network.ping("pingname", param) --(Param is optional!)
---```
---
---Note: Pings are also sent to yourself and will run their function on your script as well.
---@param ping string
---@deprecated
function network.registerPing(ping) end

---**THERE IS A MUCH BETTER WAY TO HANDLE PINGS. SEE THE `ping` TABLE FOR MORE INFORMATION.**
---***
---Sends a ping out to all clients running this script.  
---Pings are 5 bytes big without a value.
---
---A ping may also contain a value to send with the ping. This adds the following bytes based on the
---type of value:
---* Nil: 0 bytes (`nil`)
---* Boolean: 1 byte (`true/false`)
---* Integer: 4 bytes (`-2147483648`..`2147483647`)
---* Float: 4 bytes (`-3.4028236692094e+38`..`3.4028236692094e+38`)
---* String: 2 bytes + (`0`..`1000` characters) bytes
---* Table: 2 bytes + (Table contents) bytes
---
---You may only send up to 1024 bytes of pings a second, and only up to 32 pings a tick.
---
---Note: Pings are also sent to yourself.
---@param ping string
---@param value? PingSupported
---@deprecated
function network.ping(ping, value) end

---@diagnostic enable: deprecated

---A table containing pings. You can create a new ping by defining a function here.
---
---Pings are mainly used to sync variables that do not sync normally. (`Keybind`s, `action_wheel`
---functions, NBT, etc.)  
---You may have up to 65,535 pings in one script.
---
---Note: Functions placed in this table are converted. A `PingFunction` of a given function will not
---be equal to the function it is made from.  
---This also means that calling the normal function will
---not call the `PingFunction` made from it.
---@type table<string, PingFunction>
ping = {}
