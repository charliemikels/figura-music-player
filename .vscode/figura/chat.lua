--================================================================================================--
--=====  FUNCTIONS  ==============================================================================--
--================================================================================================--

---Contains functions relating to the chat.
chat = {}

---Retrieves a message from chat.  
---Messages are ordered from bottom to top, starting at 1.
---
---Returns `nil` if there is no message at the given location.
---@param num number
---@return string?
function chat.getMessage(num) end

---Returns if the chat is currently open.
---@return boolean
function chat.isOpen() end

---Sends a message as the current player.
---
---This only works on the host.
---@param str string
function chat.sendMessage(str) end

---Sets the command prefix to the given string.
---
---Create a function `onCommand(cmd)` to catch custom commands typed into chat.
---@param str? string
function chat.setFiguraCommandPrefix(str) end

---Returns the text from the message input field, or nil if its empty.
---@return string?
function chat.getInputText() end
