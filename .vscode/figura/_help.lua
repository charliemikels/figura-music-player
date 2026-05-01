--================================================================================================--
--=====  FUNCTIONS  ==============================================================================--
--================================================================================================--

---This table does not actually exist in figura.  
---This is only here to show off what this documentation can show you.
---***
---To see more help on a specific section of this documentation, index this like a normal lua
---`table`.
---
---If you do not see a description of the item to the side of the dropdown list,
---press `CTRL + SPACE` or whatever key(s) you have bound to `toggleSuggestionDetails`.
---
---If at any point the suggest menu closes, you can press `CTRL + SPACE` or whatever key(s) you have
---bound to `Trigger Suggest`.
help = {
  ---View the different literals for every alias in this documentation.
  ---
  ---Note: This page of the documentation uses a function format to expand the alias. See more at
  ---`help.format.func.expandedVariables`
  ["alias"] = {
    ---@return BiomeID string
    ["BiomeID"] = function() end,

    ---@return BlockID string
    ["BlockID"] = function() end,

    ---@return DimensionID string
    ["DimensionID"] = function() end,

    ---@return DamageSource string
    ["DamageSource"] = function() end,

    ---@return EquipmentSlot number
    ["EquipmentSlot"] = function() end,

    ---@return EntityID string
    ["EntityID"] = function() end,

    ---@return EntityAnimation string
    ["EntityAnimation"] = function() end,

    ---@return HandSlot number
    ["HandSlot"] = function() end,

    ---@return ItemID string
    ["ItemID"] = function() end,

    ---@return Key string
    ["Key"] = function() end,

    ---@return LightLevel number
    ["LightLevel"] = function() end,

    ---@return MoonPhase number
    ["MoonPhase"] = function() end,

    ---@return MinecraftKeybind string
    ["MinecraftKeybind"] = function() end,

    ---@return ParentType string
    ["ParentType"] = function() end,

    ---@return PingSupported type
    ["PingSupported"] = function() end,

    ---@return RedstonePower number
    ["RedstonePower"] = function() end,

    ---@return Shader string
    ["Shader"] = function() end,

    ---@return SlotNumber number
    ["SlotNumber"] = function() end,

    ---@return SlotSideNumber number
    ["SlotSideNumber"] = function() end,

    ---@return StatusEffectID string
    ["StatusEffectID"] = function() end
  },

  ---View the descriptions of every class in this documentation.  
  ---You can also attempt to index the classes to peek further into them.
  ["class"] = {
    ---@type ActionWheelSlot
    ActionWheelSlot = {},

    ---@type BasicModelPart
    BasicModelPart = {},

    ---@type BlockState
    BlockState = {},

    ---@type BlockStateProperties
    BlockStateProperties = {},

    ---@type Camera
    Camera = {},

    ---@type CustomModelPart
    CustomModelPart = {},

    ---@type CustomModelPartContainer
    CustomModelPartContainer = {},

    ---@type Entity
    Entity = {},

    ---@type EntityNameplate
    EntityNameplate = {},

    ---@type FiguraKeybind
    FiguraKeybind = {},

    ---@type FormatTable
    FormatTable = {},

    ---@type ItemStack
    ItemStack = {},

    ---@type LivingEntity
    LivingEntity = {},

    ---@type Nameplate
    Nameplate = {},

    ---@type Player
    Player = {},

    ---@type RegisteredKeybind
    RegisteredKeybind = {},

    ---@type StatusEffect
    StatusEffect = {},

    ---@type VanillaModelPart
    VanillaModelPart = {},

    ---@type Vector
    Vector = {},

    ---@type Vector6
    Vector6 = {},

    ---@type Vector5
    Vector5 = {},

    ---@type Vector4
    Vector4 = {},

    ---@type Vector3
    Vector3 = {},

    ---@type Vector2
    Vector2 = {},

    ---@type VectorAng
    VectorAng = {},

    ---@type VectorColor
    VectorColor = {},

    ---@type VectorHSV
    VectorHSV = {},

    ---@type VectorPos
    VectorPos = {},

    ---@type VectorUV
    VectorUV = {},

    ---@type World
    World = {}
  },

  ---View how the documentation is formatted for faster gathering of information.
  ["format"] = {
    ---The basic documentation format is below.  
    ---To see help on a specific part, index this help page with the name of the part below.
    ---***
    ---***
    ---> ```
    ---> scope name: type = value
    ---> ```
    ---> ***
    ---> description
    ["basic"] = {
      ---The "scope" can either be `global`, `local`, or `field`.
      ---
      ---A `global` scope means that this variable can be accessed from anywhere.  
      ---A `local` scope means this variable can only be accessed where it was created.
      ---A `field` scope means this variable is inside a `table`.
      ["scope"] = {},

      ---The "name" is how you access this variable in its scope.
      ["name"] = {},

      ---The "type" of the variable is the type of value it is holding (or has the potential of holding)
      ---and is not set in stone. The type of a variable can change at any time by simply giving it a
      ---value with a new type.
      ---
      ---The "type" can also be a class. See `help.format.class` for more information on how classes are
      ---formatted.
      ["type"] = {},

      ---The "value" of the variable is the value that the variable holds currently.
      ["value"] = {},

      ---The "description" simply describes the variable.
      ["description"] = {}
    },

    ---The class documentation format is below.  
    ---To see help on a specific part, index this help page with the name of the part below.
    ---
    ---Note: `table`s also use this format. However, "class" and "inheritance" do not appear.
    ---***
    ---***
    ---> ```
    ---> scope name: class {
    --->     field: type,
    --->     field: type,
    --->      . . .
    ---> }
    ---> ```
    ---> ***
    ---> inheritance
    ---> ***
    ---> description
    ["class"] = {
      ---The "scope" can either be `global`, `local`, or `field`.
      ---
      ---A `global` scope means that this variable can be accessed from anywhere.  
      ---A `local` scope means this variable can only be accessed where it was created.
      ---A `field` scope means this variable is inside a `table`.
      ["scope"] = {},

      ---The "name" is how you access this variable in its scope.
      ["name"] = {},

      ---The "class" is the class this variable takes the form of.  
      ---When a variable contains a class, it can be indexed with the fields of the class it contains
      ---like a table.
      ---
      ---Note: Despite classes sounding like their own type, they are actually just a `table` with set
      ---fields. However, most of Figura's classes are read-only and cannot be modified.
      ["class"] = {},

      ---The "fields" are the variables inside the class that you can use like a normal `table` index.  
      ---Some fields are functions and can be run to modify or get information from the object this
      ---class is connected to.
      ["field"] = {},

      ---The "type" of the field is the type of value it is holding.
      ---
      ---The "type" can also be another class.
      ["type"] = {},

      ---The "inheritance" is the chain of classes (starting with the class itself) that this class
      ---inherits fields from.  
      ---Inheritance allows a class to use fields from other classes as if the class itself contained
      ---them.
      ---
      ---Note: This does not appear on classes that do not inherit from other classes.
      ["inheritance"] = {},

      ---The "description" simply describes the class and what it is used for.
      ["description"] = {}
    },

    ---The class documentation format is below.  
    ---To see help on a specific part, index this help page with the name of the part below.
    ---
    ---Note: `table`s also use this format. However, "class" and "inheritance" do not appear.
    ---***
    ---***
    ---> ```
    ---> function name(param: type, param: type, ...)
    --->   -> return
    --->   2. return
    --->    . . .
    ---> ```
    ---> ***
    ---> definitionNotice
    ---> ***
    ---> description
    ---> 
    ---> expandedVariables
    ["func"] = {
      ---The "name" is how you access this function in its scope.
      ["name"] = {},

      ---The "params" are the the names of the values passed into the function. They give some info as
      ---to what the param does.
      ["param"] = {},

      ---The "type" of a param is the type of value this param accepts.
      ["type"] = {},

      ---A `...` (or "vararg") signifies an infinite number of comma seperated values.  
      ---A function will likely state what the "vararg" requires.
      ["..."] = {},

      ---The "return" value of a function. A function can have multiple return values.
      ["return"] = {},

      ---The "definition notice" is a notice that explains which definition a function uses if
      ---multiple show up.  
      ---Sometimes, when classes inherit, they overwrite functions they inherit to change how they
      ---work.
      ["definitionNotice"] = {},

      ---The "description" simply describes the function and what it is used for.
      ["description"] = {},

      ---The "expanded variables" expands any parameters or returns that use literals to show every
      ---literal value they can accept or return.
      ["expandedVariables"] = {}
    },

    ---Some other unexplained parts of the documentation format.  
    ---Index this help page to learn more...
    ["other"] = {
      ---Arrays are displayed like so:
      ---```
      ---type[]
      ---```
      ---An array is a numbermerically indexed `table` of the given type.
      ---
      ---Note: This help page contains an example of what it would look like if a variable was a
      ---string array at the very top.
      ---@type string[]
      array = {},

      ---Dictionaries are displayed like so:
      ---```
      ---table<key_type, value_type>
      ---```
      ---A dictionary is a `table` of values that is indexed by another (or the same) type of value.
      ---
      ---Note: This help page contains an example of what it would look like if a variable was a
      ---dictionary of booleans indexed by strings at the very top.
      ---@type table<string, boolean>
      dictionary = {},

      ---A "literal" is, quite literally, a *literal* value.  
      ---Literal values are used if a variable can only have specific values, such as specific strings
      ---or numbers.
      ---
      ---Note: This help page contains an example of what it would look like if a variable had a literal
      ---`string` value.
      ---@type '"This is a literal string"'
      literal = {},

      ---A variable can have multiple types. When this happens, the types will be seperated by a bar:
      ---```
      ---string|number|table
      ---```
      ---This can also happen with literals:
      ---```
      ---"string1"|"string2"|"string3"|1|42|300
      ---```
      ---When this happens, you will need to carefully check to make sure the variable is the type you
      ---want.
      ---
      ---Note: This help page contains an example of what it would look like if a variable could be a
      ---`string`, `number`, or `table`.
      ---@type string|number|table
      multiple_types = {}
    }
  },

  ---A table that libraries can put help topics in.
  ["library"] = {},

  ---Do you want to add your own documentation that other users can use?
  ---
  ---Index this help page for more information on how to document anything.
  ["owndoc"] = {
    ---You can create descriptions for any variable or function by using three dashes:
    ---```
    ------This is a description comment!  
    ------I use markdown for formatting!
    ------
    ------> Hello world!
    ---```
    ---Descriptions use [**Markdown**](https://www.markdownguide.org/basic-syntax) for formatting
    ---and will support (mostly) anything that Markdown does.
    ---
    ---Note: Code blocks will automatically be formatted in Lua, you do not need to specify this.
    ["s1_Descriptions"] = {},

    ---You can add a specific type to your variable by using the `@type type` comment:
    ---```
    ------@type string
    ---local string_variable = "Hello, World!"
    ---```
    ---The type will then be visible when hovered over.
    ---> ***
    ---> ```
    ---> local string_varaible: string = "Hello, World!"
    ---> ```
    ---> ***
    ["s2_Typing"] = {},

    ---Functions can also be documented using `@param name type`, `@vararg type`, and
    ---`@return type`.  
    ---If your function has multiple params or returns, then you need make multiple comments.
    ---
    ---You can use these comments like so:
    ---```
    ------This function does a thing with `a` and `b` specifically, then an infinite amount of
    ------numbers after that and then returns two values.
    ------@param a string
    ------@param b string
    ------@vararg number
    ------@return number
    ------@return boolean
    ---function does_a_thing(a, b, ...)
    ---  --does stuff
    ---  return ret1, ret2
    ---end
    ---```
    ---This function will then have its information visible when hovered over.
    ---> ```
    ---> function does_a_thing(a: string, b: string, ...)
    --->   -> number
    --->   2. boolean
    ---> ```
    ---> ***
    ---> This function does a thing with `a` and `b` specifically, then an infinite amount of
    ---> numbers after that and then returns two values.
    ["s3_Functions"] = {},

    ---You can view more information on the EmmyLua annotation style used in this documentation
    ---[**here**](https://github.com/sumneko/lua-language-server/wiki/EmmyLua-Annotations).
    ["s4_More"] = {}
  },

  ---This documentation comes packaged with a .vscode file that edits some of the settings in
  ---Sumneko's Lua Language Server to make it fit more for Figura's Lua style and allows you to read
  ---this documentation a little easier.
  ---
  ---The settings are explained in the `.\.vscode\settings.json` file, but are also explained here
  ---in case the explanations in the json file are not descriptive enough.
  ["settings"] = {
    ---View settings that change how the editor works.
    ["editor"] = {
      ---**Set to `"currentDocument"` by the settings.json**
      ---
      ---```json
      ---//(Supposedly) makes VSCode only search the current file for words to auto-complete.
      ---//Might not work... Who knows.
      ---```
      ---***
      ---Changes the editor to only suggest words found in the current file. This setting is very
      ---iffy and might not work sometimes, especially when regarding Lua-specific syntax.
      ---
      ---This is done because Figura scripts cannot interact with each other, therefore they have no
      ---reason to share information between themselves.
      ["wordBasedSuggestionsMode"] = {}
    },

    ---View settings that change how the Lua Language Server works.
    ["Lua"] = {
      ---View settings that change how completion works.
      ["completion"] = {
        ---**Set to `false` by the settings.json**
        ---
        ---```json
        ---//(Supposedly) disables auto-completing words from other files.
        ---//Might not work... Who knows.
        ---```
        ---***
        ---Changes the language server to only suggest words found in the current file. This setting
        ---is very iffy and might not work most of the time.
        ---
        ---This is done because Figura scripts cannot interact with each other, therefore they have
        ---no reason to share information between themselves.
        ["workspaceWord"] = {},

        ---**Set to `0` by the settings.json**
        ---
        ---```json
        ---//Removes some clutter from the documentation screen.
        ---```
        ---***
        ---Removes context lines from the documentation that will just cause more confusion than
        ---help since the functions in this documentation do not have a context and will cause
        ---strange "context leak".
        ["displayContext"] = {}
      },

      ---View settings that change how hints work.
      ["hint"] = {
        ---**Set to `true` by the settings.json**
        ---
        ---```json
        ---//Enables hint types, these show up next to a variable if the type of a variable is set or able to
        ---//be guessed by the language server.
        ---```
        ---***
        ---Enables hints, this feature allows you to keep track of how variables are working and
        ---what type of variables to expect from functions.
        ---Hints appear as a box to the right of variables and to the left of values:
        ---
        ---variable`:type`  
        ---`name:`"1234"
        ["enable"] = {},

        ---**Set to `true` by the settings.json**
        ---
        ---```json
        ---//Enables hint types, these show up next to a variable if the type of a variable is set or able to
        ---//be guessed by the language server.
        ---```
        ---***
        ---Allows hints to show up when using assignments on variables:
        ---
        ---var`:number` = math.sqrt(81)
        ["setType"] = {}
      },

      ---View settings that change how the runtime works.
      ["runtime"] = {
        ---**Set to `"Lua 5.2"` by the settings.json**
        ---
        ---```json
        ---//Sets the runtime version to the version used by Figura.
        ---```
        ---***
        ---Makes sure the language server is using the same version as Figura. This stops the user
        ---from accidentally using features that do not exist in Figura's version of Lua.
        ["version"] = {}
      },

      ---View settings that change how telemetry works.
      ["telemetry"] = {
        ---**Set to `false` by the settings.json**
        ---
        ---```json
        ---//Boring Telemetry stuff. You can enable it I guess?
        ---```
        ---***
        ---Disables telemetry, just in case you don't want someone using information from you
        ---without your permission.
        ["enable"] = {}
      },

      ---View settings that change how diagnostics work.
      ["diagnostics"] = {
        ---**Set to `-1` by the settings.json**
        ---
        ---```json
        ---//Stops the language server from re-diagnosing the whole model_files folder when you add or remove
        ---//a character in an unrelated file.
        ---```
        ---***
        ---Stops the language server from checking over every script file when you edit a single
        ---script file. Since script files do not have a way to relate to each other, there is no
        ---reason for diagnostics to check every other file anyways.
        ["workspaceDelay"] = {},

        ---**Set to the following by the settings.json:**
        ---```json
        ---[
        ---  "lowercase-global",
        ---  "trailing-space",
        ---  "unbalanced-assignments"
        ---]
        ---```
        ---
        ---```json
        ---//Disables some unneeded diagnostics that many will not care about.
        ---//Do not touch unless you know what you are doing.
        ---```
        ---***
        ---Disables specific diagnostics that do not matter to someone using Figura.  
        ---This specifically:
        ---* Disables warnings when using all-lowercase globals.
        ---* Disables warnings for trailing spaces.
        ---* Disables warnings when assignments are not balanced.
        ["disable"] = {},

        ---**Set to the following by the settings.json:**
        ---```json
        ---{
        ---  "unused-local": "Information",
        ---  "unused-vararg": "Information",
        ---  "redundant-parameter": "Information",
        ---  "redundant-value": "Information",
        ---  "redefined-local": "Information"
        ---}
        ---```
        ---
        ---```json
        ---//Changes the severity of some diagnostics to reflect their actual severity in Figura.
        ---//Do not touch unless you know what you are doing.
        ---```
        ---***
        ---Changes the severity of specific diagnostics to fit their true severity in Figura.
        ---This specifically:
        ---* Reveals that a local variable is being useless, to clean up code and allow errors to
        ---be seen if not already noticed.
        ---* Reveals that a vararg is not being used in the function that contains it.
        ---* Reveals that a parameter that was given is not asked for by the function.
        ---* Reveals that a value given in an assignment operation is going unused because there is
        ---no variable to take the value.
        ---* Reveals that a local value was explicitly defined again in the same scope for no
        ---reason.
        ["severity"] = {}
      },

      ---View settings that change how the workspace works.
      ["workspace"] = {
        ---**Set to the following by the settings.json:**
        ---```json
        ---[
        ---  "./.vscode/figura"
        ---]
        ---```
        ---
        ---```json
        ---//Enables the documentation.
        ---```
        ---***
        ---This enables the documentation for use inside your script files. Everything in this
        ---documentation will fail to show if this setting is not set to the value shown above.
        ["library"] = {}
      }
    }
  }
}
