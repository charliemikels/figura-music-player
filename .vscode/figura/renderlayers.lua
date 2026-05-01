---@meta

--================================================================================================--
--=====  CLASSES  ================================================================================--
--================================================================================================--

---@alias GL_BlendEquationMode
---|'32774' #GL_FUNC_ADD
---|'32778' #GL_FUNC_SUBTRACT
---|'32779' #GL_FUNC_REVERSE_SUBTRACT

---@alias GL_BlendingFactorSrc
---|'0' #GL_ZERO
---|'1' #GL_ONE
---|'768' #GL_SRC_COLOR
---|'769' #GL_ONE_MINUS_SRC_COLOR
---|'770' #GL_SRC_ALPHA
---|'771' #GL_ONE_MINUS_SRC_ALPHA
---|'772' #GL_DST_ALPHA
---|'773' #GL_ONE_MINUS_DST_ALPHA
---|'774' #GL_DST_COLOR
---|'775' #GL_ONE_MINUS_DST_COLOR
---|'776' #GL_SRC_ALPHA_SATURATE
---|'32769' #GL_CONSTANT_COLOR
---|'32770' #GL_ONE_MINUS_CONSTANT_COLOR
---|'32771' #GL_CONSTANT_ALPHA
---|'32772' #GL_ONE_MINUS_CONSTANT_ALPHA

---@alias GL_BlendingFactorDest GL_BlendingFactorSrc

---@alias GL_DepthFunction
---|'512' #GL_NEVER
---|'513' #GL_LESS
---|'514' #GL_EQUAL
---|'515' #GL_LEQUAL
---|'516' #GL_GREATER
---|'517' #GL_NOTEQUAL
---|'518' #GL_GEQUAL
---|'519' #GL_ALWAYS

---@alias GL_StencilFunction GL_DepthFunction

---@alias GL_StencilOp
---|'0' #GL_ZERO
---|'5386' #GL_INVERT
---|'7680' #GL_KEEP
---|'7681' #GL_REPLACE
---|'7682' #GL_INCR
---|'7683' #GL_DECR
---|'34055' #GL_INCR_WRAP
---|'34056' #GL_DECR_WRAP


---@alias GL_All GL_BlendEquationMode|GL_BlendingFactorDest|GL_StencilFunction|GL_StencilOp
---|'5376' #GL_CLEAR
---|'5377' #GL_AND
---|'5378' #GL_AND_REVERSE
---|'5379' #GL_COPY
---|'5380' #GL_AND_INVERTED
---|'5381' #GL_NOOP
---|'5382' #GL_XOR
---|'5383' #GL_OR
---|'5384' #GL_NOR
---|'5385' #GL_EQUIV
---|'5387' #GL_OR_REVERSE
---|'5388' #GL_COPY_INVERTED
---|'5389' #GL_OR_INVERTED
---|'5390' #GL_NAND
---|'5391' #GL_SET
---|'32775' #GL_MIN
---|'32776' #GL_MAX
---|'number'

---@alias GL_Texture
---|'"MY_TEXTURE"'
---|'"MY_TEXTURE_EMISSIVE"'
---|'"MAIN_FRAMEBUFFER"'
---|'"LAST_FRAMEBUFFER"'
---|'string'

---@alias CustomUniformID string
---@alias CClass
---|'string'
---|'"vec3"'

---@class RegisterRenderLayerParams
---@field vertexFormat ShaderFormat
---@field hasCrumbling boolean
---@field translucent boolean

---I only know of one... Does anyone know of any others?
---@alias ShaderFormat
---|'"POSITION_COLOR_TEXTURE_OVERLAY_LIGHT_NORMAL"'
---|'string'

---@alias StringifiedC string

--================================================================================================--
--=====  FUNCTIONS  ==============================================================================--
--================================================================================================--

renderlayers = {}

---Gets the priority of the chosen render layer, or nil if it doesn't exist
---@param renderlayerName string
---@return number
function renderlayers.getPriority(renderlayerName) end

---Returns true or false depending on if the shader exists yet
---@param shaderName string
---@return boolean
function renderlayers.isShaderReady(shaderName) end

---Registers a new render layer with the given name
---params is a table where you can set certain keys
------vertexFormat - needs to match with the format of any shader you want to use. Same default as in registerShader()
------hasCrumbling - don't know what this does, but it's true by default
------translucent - also don't know this one, but true by default
---startFunction and endFunction are two lua functions, called when you start rendering and when you stop rendering this layer.
---Functions which interact with openGL can only be called inside these
---@param renderLayerName string
---@param params RegisterRenderLayerParams
---@param startFunction fun()
---@param endFunction fun()
function renderlayers.registerRenderLayer(renderLayerName, params, startFunction, endFunction) end

---Registers a new custom shader with the given name
---@param shaderName string
---@param format ShaderFormat #Defaults to "POSITION_COLOR_TEXTURE_OVERLAY_LIGHT_NORMAL"
---@param vertexSource StringifiedC
---@param fragmentSource StringifiedC
---@param numSamplers number
---@param customUniforms table<CustomUniformID,CClass>
function renderlayers.registerShader(shaderName, format, vertexSource, fragmentSource, numSamplers, customUniforms) end

---Sets the priority of a render layer. Layers with lower priorities are rendered first. By default, all priorities are 0
---@param renderLayerName string
---@param value number
function renderlayers.setPriority(renderLayerName, value) end

---Sets the value of the specified uniform in the specified shader. If the shader does not exist yet, does nothing
---@param shaderName string
---@param uniformName CustomUniformID
---@param value any
function renderlayers.setUniform(shaderName, uniformName, value) end

--================================================================================================--
--=====  SHADER ONLY FUNCTIONS  ==================================================================--
--================================================================================================--

---Sets the GL blend equation
---@param equation GL_BlendEquationMode
function renderlayers.blendEquation(equation) end

---Sets the GL blend function
---@param src GL_BlendingFactorSrc
---@param dst GL_BlendingFactorDest
function renderlayers.blendFunc(src, dst) end

---Sets the GL blend function
---@param srcRGB GL_BlendingFactorSrc
---@param dstRGB GL_BlendingFactorDest
---@param srcAlpha GL_BlendingFactorSrc
---@param dstAlpha GL_BlendingFactorDest
function renderlayers.blendFuncSeperate(srcRGB, dstRGB, srcAlpha, dstAlpha) end

---Enables/disables the GL color mask
---@param boolean boolean
function renderlayers.colorMask(boolean) end

---A minecraft→specific function, resets the GL blend function to default
function renderlayers.defaultBlendFunc() end

---Sets the GL depth function
---@param func GL_DepthFunction
function renderlayers.depthFunc(func) end

---Enables/disables the GL depth mask
---@param boolean boolean
function renderlayers.depthMask(boolean) end

---Disables blending
function renderlayers.disableBlend() end

---Disables color logic operations
function renderlayers.disableColorLogicOp() end

---Disables culling
function renderlayers.disableCull() end

---Disables depth testing
function renderlayers.disableDepthTest() end

---Disables lightmap testing
function renderlayers.disableLightmap() end

---Disables overlay
function renderlayers.disableOverlay() end

---Disables GL scissors
function renderlayers.disableScissors() end

---Disables stencil testing
function renderlayers.disableStencil() end

---Enables blending
function renderlayers.enableBlend() end

---Enables color logic operations
function renderlayers.enableColorLogicOp() end

---Enables culling
function renderlayers.enableCull() end

---Enables depth testing
function renderlayers.enableDepthTest() end

---Enables lightmap testing
function renderlayers.enableLightmap() end

---Enables overlay
function renderlayers.enableOverlay() end

---Enables GL scissors with those values
---@param x number
---@param y number
---@param width number
---@param height number
function renderlayers.enableScissors(x, y, width, height) end

---Enables stencil testing
function renderlayers.enableStencil() end

---Sets the shader line width
---@param float number
function renderlayers.lineWidth(float) end

---Sets the GL color logic operation
---@param operation GL_All
function renderlayers.logicOp(operation) end

---Resets the rendering to default state
function renderlayers.restoreDefaults() end

---Sets the designated texture based on the name
---@param index number
---@param textureName GL_Texture
function renderlayers.setTexture(index, textureName) end

---Sets the GL stencil function
---@param func GL_StencilFunction
---@param ref number
---@param mask number
function renderlayers.stencilFunc(func, ref, mask) end

---Sets the GL stencil mask
---@param number number
function renderlayers.stencilMask(number) end

---Sets the GL stencil operations
---@param sfail GL_StencilOp
---@param dpfail GL_StencilOp
---@param dppass GL_StencilOp
function renderlayers.stencilOp(sfail, dpfail, dppass) end

---Uses the designated shader
---@param shaderName string
function renderlayers.useShader(shaderName) end

renderlayers.GL_ALWAYS=519
renderlayers.GL_AND=5377
renderlayers.GL_AND_INVERTED=5380
renderlayers.GL_AND_REVERSE=5378
renderlayers.GL_CLEAR=5376
renderlayers.GL_CONSTANT_ALPHA=32771
renderlayers.GL_CONSTANT_COLOR=32769
renderlayers.GL_COPY=5379
renderlayers.GL_COPY_INVERTED=5388
renderlayers.GL_DECR=7683
renderlayers.GL_DECR_WRAP=34056
renderlayers.GL_DST_ALPHA=772
renderlayers.GL_DST_COLOR=774
renderlayers.GL_EQUAL=514
renderlayers.GL_EQUIV=5385
renderlayers.GL_FUNC_ADD=32774
renderlayers.GL_FUNC_REVERSE_SUBTRACT=32779
renderlayers.GL_FUNC_SUBTRACT=32778
renderlayers.GL_GEQUAL=518
renderlayers.GL_GREATER=516
renderlayers.GL_INCR=7682
renderlayers.GL_INCR_WRAP=34055
renderlayers.GL_INVERT=5386
renderlayers.GL_KEEP=7680
renderlayers.GL_LEQUAL=515
renderlayers.GL_LESS=513
renderlayers.GL_MAX=32776
renderlayers.GL_MIN=32775
renderlayers.GL_NAND=5390
renderlayers.GL_NEVER=512
renderlayers.GL_NOR=5384
renderlayers.GL_NOOP=5381
renderlayers.GL_NOTEQUAL=517
renderlayers.GL_ONE=1
renderlayers.GL_ONE_MINUS_CONSTANT_ALPHA=32772
renderlayers.GL_ONE_MINUS_CONSTANT_COLOR=32770
renderlayers.GL_ONE_MINUS_DST_ALPHA=773
renderlayers.GL_ONE_MINUS_DST_COLOR=775
renderlayers.GL_ONE_MINUS_SRC_ALPHA=771
renderlayers.GL_ONE_MINUS_SRC_COLOR=769
renderlayers.GL_OR=5383
renderlayers.GL_OR_INVERTED=5389
renderlayers.GL_OR_REVERSE=5387
renderlayers.GL_REPLACE=7681
renderlayers.GL_SET=5391
renderlayers.GL_SRC_ALPHA=770
renderlayers.GL_SRC_ALPHA_SATURATE=776
renderlayers.GL_SRC_COLOR=768
renderlayers.GL_XOR=5382
renderlayers.GL_ZERO=0
