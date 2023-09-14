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

--- @public PostProcessShaders list of shaders extracted from "lib/shaders/postProcess/" folder
cfg_shaders.PostProcessShaders = {}
local input_files = love.filesystem.getDirectoryItems("lib/shaders/postProcess/")
for i=1, #input_files do
	-- match pattern as '{idx}_{name}.glsl'
	local idx, name = string.match(input_files[i], "(%d+)_(.*).glsl")
	idx = tonumber(idx)
	cfg_shaders.PostProcessShaders[idx+1] = {}
	cfg_shaders.PostProcessShaders[idx+1].name = name
	cfg_shaders.PostProcessShaders[idx+1].value = love.filesystem.read("lib/shaders/postProcess/" .. input_files[i])
end


--- @public OtherShaders list of shaders extracted from "lib/shaders/other" folder
cfg_shaders.OtherShaders = {}
input_files = love.filesystem.getDirectoryItems("lib/shaders/other")
for i=1,#input_files do
	local name = string.match(input_files[i], "(.*).glsl")
	cfg_shaders.OtherShaders[i] = {}
	cfg_shaders.OtherShaders[i].name = name
	cfg_shaders.OtherShaders[i].value = love.filesystem.read("lib/shaders/other/" .. input_files[i])
end


--- @private default The default shader
local default = table.getValueByName("default", cfg_shaders.PostProcessShaders)
--- @public CurrentShaders current shaders used for post processing canvas
cfg_shaders.CurrentShaders = 	 { default,
								   default,
								   default }


--- @public toggleShaders enable / disable shaders
function cfg_shaders.toggleShaders()
    cfg_shaders.enabled = not cfg_shaders.enabled
end


function cfg_shaders.assignGlobals(slot)
	local s = runningPatches[slot].resources.shaderext
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
function cfg_shaders.selectPPShader(patchSlot, shaderext)
    local s = shaderext

    -- select shader
	local sh_object = cfg_shaders.PostProcessShaders[1 + s:get("shaderSlot" .. patchSlot)]
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