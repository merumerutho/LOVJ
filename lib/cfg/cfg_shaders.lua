-- cfg_shaders.lua
--
-- Configure and handle shader settings
--

local cfg_timers = lovjRequire("lib/cfg/cfg_timers")
local logging = lovjRequire("lib/utils/logging")
local resources = lovjRequire("lib/resources")

local cfg_shaders = {}

--- @public enabled boolean to enable or disable shaders
cfg_shaders.enabled = true

--- @public getShaderByName function to search shader based on its name
function getShaderByName(partial_name, list)
	if list == nil then list = cfg_shaders.PostProcessShaders end
	for i=1,#list do
		if list[i] ~= nil then
			if string.find(list[i].name, partial_name) then return list[i].value end
		end
	end
end

--- @public PostProcessShaders list of shaders extracted from "lib/shaders/postProcess/" folder
cfg_shaders.PostProcessShaders = {}
local input_files = love.filesystem.getDirectoryItems("lib/shaders/postProcess/")
for i=1, #input_files do
	local shader = {}
	shader.name = input_files[i]
	shader.value = love.filesystem.read("lib/shaders/postProcess/" .. input_files[i])
	-- Get index from filename (e.g. "0_default.glsl" => 0)
	shader.idx = tonumber(string.match(input_files[i], "%d+"))
	cfg_shaders.PostProcessShaders[shader.idx+1] = shader  -- order by index
end


--- @private default The default shader
local default = getShaderByName("default")
--if not default then logging.logError("Could not load default.glsl shader") end
--- @public CurrentShaders current shaders used for post processing canvas
cfg_shaders.CurrentShaders = 	 { default,
								   default,
								   default }


--- @public toggleShaders enable / disable shaders
function cfg_shaders.toggleShaders()
    cfg_shaders.enabled = not cfg_shaders.enabled
end


function cfg_shaders.assignGlobals()
	local s = resources.shaderext
	s:setName(1, "shaderSlot1")			s:set("shaderSlot1", 0)
	s:setName(2, "shaderSlot2")			s:set("shaderSlot2", 0)
	s:setName(3, "shaderSlot3")			s:set("shaderSlot3", 0)

	s:setName(4, "_warpParameter")		s:set("_warpParameter", 2)
	s:setName(5, "_segmentParameter")	s:set("_segmentParameter", 3)
	s:setName(6, "_chromaColor")		s:set("_chromaColor", {0,0,0,0})
	s:setName(7, "_chromaTolerance")	s:set("_chromaTolerance", {0.05, 0.1})
	s:setName(8, "_blurOffset")			s:set("_blurOffset", 0.01)
	s:setName(9, "_glitchOffset")		s:set("_glitchOffset", 0.00)
	s:setName(10, "_glitchSize")		s:set("_glitchSize", -2000)
	s:setName(11, "_glitchDisplace")	s:set("_glitchDisplace", 0)
	s:setName(12, "_glitchFreq")		s:set("_glitchFreq", 1)
	s:setName(13, "_swirlmodx")			s:set("_swirlmodx", 1)
	s:setName(14, "_swirlmody")			s:set("_swirlmody", 1)
	s:setName(15, "_pixres")			s:set("_pixres", 64)

end


--- @public selectShader select the shader to apply
function cfg_shaders.selectPPShader(i)
    local s = resources.shaderext

    -- select shader
	local sh_object = cfg_shaders.PostProcessShaders[1 + s:get("shaderSlot" .. i)]
	local shader = love.graphics.newShader(sh_object.value)

	-- send parameters
	if string.find(sh_object.name, "swirl") then
		shader:send("_time", cfg_timers.globalTimer.T)
	end
	if string.find(sh_object.name, "warp") then
		shader:send("_warpParameter", s:get("_warpParameter"))
	end
	if string.find(sh_object.name, "kaleido") then
		shader:send("_segmentParameter", s:get("_segmentParameter"))
	end
	if string.find(sh_object.name, "gaussianblur") then
		shader:send("_blurOffset", s:get("_blurOffset"))
	end
	if string.find(sh_object.name, "glitch") then
		shader:send("_glitchDisplace", s:get("_glitchDisplace"))
		shader:send("_glitchFreq", s:get("_glitchFreq"))
	end
	if string.find(sh_object.name, "pixelate") then
		shader:send("_pixres", s:get("_pixres"))
	end

	return shader
end


--- @public applyShader apply the shader to the graphics
function cfg_shaders.applyShader(shader)
	love.graphics.setShader(shader)
end

return cfg_shaders