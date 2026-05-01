--================================================================================================--
--=====  CLASSES  ================================================================================--
--================================================================================================--

---A list of up to 6 numbers that can mean anything.  
---You can either use the fields or index by a number to get a value from the vector.
---
---The following accessors correspond to the following numbers:
--->1: x, r, u, pitch  
--->2: y, g, v, yaw, volume  
--->3: z, b, roll  
--->4: w, a  
--->5: t  
--->6: h
---
---You can use a `table` with up to 6 values in place of a `Vector`.  
---The `table` can contain other `table`s to merge them.
---
---@class Vector
---@field [1] number
---@field [2] number
---@field [3] number
---@field [4] number
---@field [5] number
---@field [6] number
---@field x number
---@field y number
---@field z number
---@field w number
---@field t number
---@field h number
---@field pitch number
---@field yaw number
---@field roll number
---@field r number
---@field g number
---@field b number
---@field a number
---@field u number
---@field v number
---@field volume number
local Vector = {}

---Returns the (smallest) angle between this `Vector` and the given `Vector` in radians.
---@param vec Vector
---@return number
function Vector.angleTo(vec) end

---Converts a Vector to a table.  
---The table is created with numeric indexes.
---@return number[]
function Vector.asTable() end

---Returns the cross product of this `Vector` and the given `Vector`.
---@param vec Vector
---@return Vector
function Vector.cross(vec) end

---Gets the distance between this `Vector` and the given `Vector`.
---@param vec Vector
---@return number
function Vector.distanceTo(vec) end

---Returns the dot product of this `Vector` and the given `Vector`.
---@param vec Vector
---@return number
function Vector.dot(vec) end

---Gets the distance between `<0,0,0,0,0,0>` and this `Vector`.
---@return number
function Vector.getLength() end

---Returns a `Vector` which is a copy of this `Vector` but resized to have a length of 1.
---@return Vector
function Vector.normalized() end

---Returns the vector converted into degrees.
---@return Vector
function Vector.toDeg() end

---Returns the vector converted into radians.
---@return Vector
function Vector.toRad() end


---Vector6 ⇐ Vector
---***
---A list of six numbers that can mean anything.  
---You can either use the fields or index by a number to get a value from the vector.
---
---The following accessors correspond to the following numbers:
--->1: x, r, u, pitch  
--->2: y, g, v, yaw  
--->3: z, b, roll  
--->4: w, a  
--->5: t  
--->6: h
---
---You can use a `table` with up to 6 values in place of a `Vector6`.  
---The `table` can contain other `table`s to merge them.
---
---@class Vector6 : Vector


---Vector5 ⇐ Vector
---***
---A list of five numbers that can mean anything.  
---You can either use the fields or index by a number to get a value from the vector.
---
---The following accessors correspond to the following numbers:
--->1: x, r, u, pitch  
--->2: y, g, v, yaw  
--->3: z, b, roll  
--->4: w, a  
--->5: t
---
---You can use a `table` with up to 5 values in place of a `Vector5`.  
---The `table` can contain other `table`s to merge them.
---
---@class Vector5 : Vector


---Vector4 ⇐ Vector
---***
---A list of four numbers that can mean anything.  
---You can either use the fields or index by a number to get a value from the vector.
---
---The following accessors correspond to the following numbers:
--->1: x, r, u, pitch  
--->2: y, g, v, yaw  
--->3: z, b, roll  
--->4: w, a
---
---If you wish to get a number past the fourth, you will need to use
---different accessors or directly index it. (`Vector[#]`)
---
---You can use a `table` with up to 4 values in place of a `Vector4`.  
---The `table` can contain other `table`s to merge them.
---@class Vector4 : Vector


---Vector3 ⇐ Vector
---***
---A list of three numbers that can mean anything.  
---You can either use the fields or index by a number to get a value from the vector.
---
---The following accessors correspond to the following numbers:
--->1: x, r, u, pitch  
--->2: y, g, v, yaw  
--->3: z, b, roll
---
---If you wish to get a number past the third, you will need to use
---different accessors or directly index it. (`Vector[#]`)
---
---You can use a `table` with up to 3 values in place of a `Vector3`.  
---The `table` can contain other `table`s to merge them.
---@class Vector3 : Vector


---Vector2 ⇐ Vector
---***
---A list of two numbers that can mean anything.  
---You can either use the fields or index by a number to get a value from the vector.
---
---The following accessors correspond to the following numbers:
--->1: x, r, u, pitch  
--->2: y, g, v, yaw
---
---If you wish to get a number past the second, you will need to use
---different accessors or directly index it. (`Vector[#]`)
---
---You can use a `table` with up to 2 values in place of a `Vector2`.  
---The `table` can contain other `table`s to merge them.
---@class Vector2 : Vector


---VectorPos ⇐ Vector
---***
---A position in 3D space.  
---This can also be used for 3D scales.
---
---The following accessors correspond to the following numbers:
--->1: x  
--->2: y  
--->3: z
---
---If you wish to get a number past the third, you will need to use
---different accessors or directly index it. (`Vector[#]`)
---
---You can use a `table` with up to 3 values in place of a `VectorPos`.  
---The `table` can contain other `table`s to merge them.
---@class VectorPos : Vector


---VectorAng ⇐ Vector
---***
---A list of up to three Euler Angles: pitch, yaw, and (sometimes) roll.
---
---The following accessors correspond to the following numbers:
--->1: pitch  
--->2: yaw  
--->3: roll
---
---If you wish to get a number past the third, you will need to use
---different accessors or directly index it. (`Vector[#]`)
---
---You can use a `table` with up to 3 values in place of a `VectorAng`.  
---The `table` can contain other `table`s to merge them.
---@class VectorAng : Vector


---VectorColor ⇐ Vector
---***
---A color value. Stored in `Red, Green, Blue, Alpha` format.  
---Color vectors use numbers between 0 and 1.
---
---If your numbers are between 0 and 255, divide your numbers by 255.  
---Ex: To change `<100,237,76>` to fit in a color vector, change it to `<100/255,237/255,76/255>`.
---
---Note: Despite there being an `a` accessor, it is very rarely used. Assume it is not used unless
---otherwise specified.
---
---The following accessors correspond to the following numbers:
--->1: r  
--->2: g  
--->3: b  
--->4: a
---
---If you wish to get a number past the fourth, you will need to use
---different accessors or directly index it. (`Vector[#]`)
---
---You can use a `table` with up to 4 values in place of a `VectorColor`.  
---The `table` can contain other `table`s to merge them.
---@class VectorColor : Vector


---VectorHSV ⇐ VectorColor ⇐ Vector
---***
---A color value. Stored in `Hue, Saturation, Value, Alpha` format.  
---Color vectors use numbers between 0 and 1.
---
---If your hue is between 0-360, divide it by 360.  
---If your saturation or value are between 0 and 100, divide them by 100.  
---Ex: To change `<290,75,50>` to fit in a color vector, change it to `<290/360,75/100,50/100>`.
---
---Note: Despite there being an `a` accessor, it is very rarely used. Assume it is not used unless
---othewise specified.
---
---The following accessors correspond to the following numbers:
--->1: r (Hue)  
--->2: g (Saturation)  
--->3: b (Value)  
--->4: a
---
---If you wish to get a number past the fourth, you will need to use
---different accessors or directly index it. (`Vector[#]`)
---
---You can use a `table` with up to 4 values in place of a `VectorHue`.  
---The `table` can contain other `table`s to merge them.
---@class VectorHSV : VectorColor


---VectorUV ⇐ Vector
---***
---A UV position offset.  
---UV vectors use numbers between 0 and 1.  
---Ex: To convert a UV offset of 10 pixels right and 5 pixels down, use
---`10/image_width,5/image_height`  
---where `image_width` and `image_height` are the size of your texture in pixels.
---
---The following accessors correspond to the following numbers:
--->1: u  
--->2: v
---
---If you wish to get a number past the second, you will need to use
---different accessors or directly index it. (`Vector[#]`)
---
---You can use a `table` with up to 2 values in place of a `VectorUV`.  
---The `table` can contain other `table`s to merge them.
---@class VectorUV : Vector


--================================================================================================--
--=====  FUNCTIONS  ==============================================================================--
--================================================================================================--

---Contains functions for creating and modifying `Vector`s.
vectors = {}

---Returns an XYZ Euler representation of the rotation around (axis) by (angle) degrees.
---@param axis Vector3
---@param angle number
---@return VectorAng
function vectors.axisAngleToEuler(axis, angle) end

---Returns the XYZ Euler rotation from the given quaternion
---@param quaternion Vector4
---@return Vector3
function vectors.fromQuaternion(quaternion) end

---Creates a Vector with `x` amount of numbers.
---@param x 1|2|3|4|5|6
---@return Vector
function vectors.getVector(x) end

---Creates a Color Vector from an HSV vector.
---
---Note: The resulting color will not have `a` set.
---@param vec VectorHSV
---@return VectorColor
function vectors.hsvToRGB(vec) end

---Creates a Color Vector from a 24 bit integer.
---
---Note: The resulting color will not have `a` set.
---@param x integer
---@return VectorColor
function vectors.intToRGB(x) end

---Applies linear interpolation to two Vectors.  
---Returns a `Vector` that is between `Vector a` and `Vector b`,
---using `c` as the distance from `Vector a` to `Vector b`.
---
---Ex: A `c` of .5 will be in directly between the two `Vector`s
---and a `c` of .25 will be 25% of the way from `Vector a` to `Vector b`
---@param a Vector
---@param b Vector
---@param c number
---@return Vector
function vectors.lerp(a, b, c) end

---Creates a Vector from a table.
---@param t number[]
---@return Vector
---
function vectors.of(t) end

---Creates an HSV Vector from a Color Vector.
---@param vec VectorColor
---@return VectorHSV
function vectors.rgbToHSV(vec) end

---Creates a number from a Color Vector.
---@param vec VectorColor
---@return integer
function vectors.rgbToINT(vec) end

---Return a vector after it has been rotated around the given axis by `angle` degrees.
---@param vector Vector
---@param axis Vector
---@param angle number
---@return Vector
function vectors.rotateAroundAxis(vector, axis, angle) end

---Returns a vector after it is rotated by the given quaternion.  
---The vectors given must be in radians.  
---The output will also be in radians.
---@param vector VectorAng
---@param quaternion Vector4
---@return VectorAng
function vectors.rotateWithQuaternion(vector, quaternion) end

---Returns a quaternion from the given XYZ Euler rotation.
---@param vector Vector3
---@return Vector4
function vectors.toQuaternion(vector) end

---Creates a Position Vector from a block coordinate.
---
---You can use this function to place a `NO_PARENT` part at an exact block coordinate.
---@param vec VectorPos
---@return VectorPos
function vectors.worldToPart(vec) end

---Same as `<CustomModelPart>.worldToPartPos()` but tied with the camera instead.
---@param offset VectorPos
---@return VectorPos
function vectors.worldToCameraPos(offset) end

---Returns the position on the screen where a given world position is.
---
---The first two values are the X and Y position of the coordinate on the screen. (From `-1` to `1`)  
---The third value is some value that is `>1` when the coordinate is in front of the screen and `<1`
---when behind the screen.  
---The fourth value is the distance of the coordinate from the camera.
---@param pos VectorPos
---@return Vector4
function vectors.worldToScreenSpace(pos) end
