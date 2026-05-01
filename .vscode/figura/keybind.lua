--================================================================================================--
--=====  CLASSES  ================================================================================--
--================================================================================================--

---A button on the keyboard or mouse.
---@alias Key
---| "0"
---| "1"
---| "2"
---| "3"
---| "4"
---| "5"
---| "6"
---| "7"
---| "8"
---| "9"
---| "A"
---| "B"
---| "C"
---| "D"
---| "E"
---| "F"
---| "G"
---| "H"
---| "I"
---| "J"
---| "K"
---| "L"
---| "M"
---| "N"
---| "O"
---| "P"
---| "Q"
---| "R"
---| "S"
---| "T"
---| "U"
---| "V"
---| "W"
---| "X"
---| "Y"
---| "Z"
---| "RIGHT"
---| "LEFT"
---| "DOWN"
---| "UP"
---| "F1"
---| "F2"
---| "F3"
---| "F4"
---| "F5"
---| "F6"
---| "F7"
---| "F8"
---| "F9"
---| "F10"
---| "F11"
---| "F12"
---| "F13"
---| "F14"
---| "F15"
---| "F16"
---| "F17"
---| "F18"
---| "F19"
---| "F20"
---| "F21"
---| "F22"
---| "F23"
---| "F24"
---| "F25"
---| "KP_0"
---| "KP_1"
---| "KP_2"
---| "KP_3"
---| "KP_4"
---| "KP_5"
---| "KP_6"
---| "KP_7"
---| "KP_8"
---| "KP_9"
---| "KP_MULTIPLY"
---| "KP_DIVIDE"
---| "KP_SUBTRACT"
---| "KP_ADD"
---| "KP_DECIMAL"
---| "KP_ENTER"
---| "KP_EQUAL"
---| "MOUSE_BUTTON_1"
---| "MOUSE_BUTTON_2"
---| "MOUSE_BUTTON_3"
---| "MOUSE_BUTTON_4"
---| "MOUSE_BUTTON_5"
---| "MOUSE_BUTTON_6"
---| "MOUSE_BUTTON_7"
---| "MOUSE_BUTTON_8"
---| "SPACE"
---| "APOSTROPHE"
---| "GRAVE_ACCENT"
---| "_"
---| "COMMA"
---| "MINUS"
---| "PERIOD"
---| "SLASH"
---| "SEMICOLON"
---| "EQUAL"
---| "BACKSLASH"
---| "LEFT_BRACKET"
---| "RIGHT_BRACKET"
---| "UNKNOWN"
---| "PAGE_UP"
---| "PAGE_DOWN"
---| "END"
---| "CAPS_LOCK"
---| "SCROLL_LOCK"
---| "NUM_LOCK"
---| "PAUSE"
---| "WORLD_1"
---| "WORLD_2"
---| "ESCAPE"
---| "ENTER"
---| "TAB"
---| "BACKSPACE"
---| "PRINT_SCREEN"
---| "LEFT_SHIFT"
---| "LEFT_CONTROL"
---| "LEFT_ALT"
---| "LEFT_SUPER"
---| "RIGHT_SHIFT"
---| "RIGHT_CONTROL"
---| "RIGHT_ALT"
---| "RIGHT_SUPER"
---| "MENU"
---| "INSERT"
---| "DELETE"
---| "HOME"

---A keybind registered by Minecraft or a mod.  
---This value is not limited to keybinds registered by Minecraft, any keybind registered by a mod
---will also work (but will not be auto-completed here.)
---@alias MinecraftKeybind
---| "key.jump" #Movement: Jump
---| "key.sneak" #Movement: Sneak
---| "key.sprint" #Movement: Sprint
---| "key.left" #Movement: Strafe Left
---| "key.right" #Movement: Strafe Right
---| "key.back" #Movement: Walk Backwards
---| "key.forward" #Movement: Walk Forwards
---| "key.attack" #Gameplay: Attack/Destroy
---| "key.pickItem" #Gameplay: Pick Block
---| "key.use" #Gameplay: Use Item/Place Block
---| "key.drop" #Inventory: Drop Selected Item
---| "key.hotbar.1" #Inventory: Hotbar Slot 1
---| "key.hotbar.2" #Inventory: Hotbar Slot 2
---| "key.hotbar.3" #Inventory: Hotbar Slot 3
---| "key.hotbar.4" #Inventory: Hotbar Slot 4
---| "key.hotbar.5" #Inventory: Hotbar Slot 5
---| "key.hotbar.6" #Inventory: Hotbar Slot 6
---| "key.hotbar.7" #Inventory: Hotbar Slot 7
---| "key.hotbar.8" #Inventory: Hotbar Slot 8
---| "key.hotbat.9" #Inventory: Hotbar Slot 9
---| "key.inventory" #Inventory: Open/Close Inventory
---| "key.swapOffHand" #Inventory: Swap Item With Offhand
---| "key.loadToolbarActivator" #Creative Mode: Load Hotbar Activator
---| "key.saveToolbarActivator" #Creative Mode: Save Hotbar Activator
---| "key.playerlist" #Multiplayer: List Players
---| "key.chat" #Multiplayer: Open Chat
---| "key.command" #Multiplayer: Open Command
---| "key.socialInteractions" #Multiplayer: Social Interactions Screen
---| "key.advancements" #Miscellaneous: advancements
---| "key.spectatorOutlines" #Miscellaneous: Highlight Players (Spectators)
---| "key.screenshot" #Miscellaneous: Take Screenshot
---| "key.smoothCamera" #Miscellaneous: Toggle Cinematic Camera
---| "key.fullscreen" #Miscellaneous: Toggle Fullscreen
---| "key.togglePerspective" #Miscellaneous: Toggle Perspective

---A keybind that is bound to a key.  
---You can use this to determine when you are pressing a key or registered control.
---@class Keybind
local Keybind = {}

---Returns if the key was pressed. Handled as if the key was being typed into a text box.
---
---When holding, `.wasPressed()` returns `true` for 1 tick, then returns `false` for 9 ticks, then
---returns `true` until the button is released (plus some undefined extra ticks based on how long
---the key was held.)
---@return boolean
function Keybind.wasPressed() end

---Returns if the key is being pressed this tick.
---@return boolean
function Keybind.isPressed() end

---Returns the current key bound to this keybind.
---@return Key
function Keybind.getKey() end

---Returns the name of the keybind.
---@return string
function Keybind.getName() end

---FiguraKeybind ⇐ Keybind
---***
---A custom keybind created by the script.  
---These binds can be changed by the player later in Figura's keybind menu.
---@class FiguraKeybind : Keybind
local FiguraKeybind = {}

---Rebinds the keybind to the given key.
---@param key Key
function FiguraKeybind.setKey(key) end

---Resets the half-second delay from wasPressed()
function FiguraKeybind.reset() end

---RegisteredKeybind ⇐ Keybind
---***
---A keybind registered by Minecraft or another mod.  
---These binds are changed Minecraft's controls menu.
---@class RegisteredKeybind : Keybind


--================================================================================================--
--=====  FUNCTIONS  ==============================================================================--
--================================================================================================--

---Contains functions for working with keybinds.
keybind = {}

---Returns a list of all valid keys.
---@return Key[]
function keybind.getKeyList() end

---Returns a list of all keybinds.
---@return Keybind[]
function keybind.getRegisteredKeyList() end

---Returns a value that represents a registered keybind.
---
---Any registered keybind by both Minecraft and mods can be used.
---@param bind MinecraftKeybind
---@return RegisteredKeybind
function keybind.getRegisteredKeybind(bind) end

---Returns a new named keybind that can be tracked.
---@param name string
---@param key Key
---@param persistent? boolean If set to true, keybind will be detected even if a gui is open such as chat/inventory.
---@return FiguraKeybind
function keybind.newKey(name, key, persistent) end
