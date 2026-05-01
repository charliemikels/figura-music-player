--================================================================================================--
--=====  FUNCTIONS  ==============================================================================--
--================================================================================================--

---Interpolates numbers or vectors between a and b.
---
---Will not accept a raw table as input.  
---Use vectors.of() to convert from raw table to vector table.
---@generic T : number|Vector
---@param a T
---@param b T
---@param delta number
---@return T
function math.lerp(a, b, delta) end

---Returns a value that never goes below min or above max.
---@param val number
---@param min number
---@param max number
---@return number
function math.clamp(val, min, max) end
