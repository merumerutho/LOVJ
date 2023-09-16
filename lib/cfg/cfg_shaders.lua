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


--- @public toggleShaders enable / disable shaders
function cfg_shaders.toggleShaders()
    cfg_shaders.enabled = not cfg_shaders.enabled
end


function cfg_shaders.assignGlobals(slot)
	local s = patchSlots[slot].resources.shaderext

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

	patchSlots[slot].resources.shaderext = s
end


--- @public selectShader select the shader to apply
function cfg_shaders.selectPPShader(patchSlot, curShader, shaderext)
    local s = shaderext
	local sh_object
	local shader
	
    -- select shader
	local newShader = cfg_shaders.PostProcessShaders[1 + s:get("shaderSlot" .. patchSlot)]
	-- if shader changed, create new shader
	if newShader.name ~= curShader.name then
		shader = {name = newShader.name, object = love.graphics.newShader(newShader.value)}
	else
		shader = curShader
	end

	-- send parameters
	if string.find(shader.name, "swirl") then
		shader.object:send("_time", cfg_timers.globalTimer.T)
	end
	if string.find(shader.name, "warp") then
		shader.object:send("_warpParameter", s:get("_warpParameter"))
	end
	if string.find(shader.name, "kaleido") then
		shader.object:send("_segmentParameter", s:get("_segmentParameter"))
	end
	if string.find(shader.name, "gaussianblur") then
		shader.object:send("_blurOffset", s:get("_blurOffset"))
	end
	if string.find(shader.name, "glitch") then
		shader.object:send("_glitchDisplace", s:get("_glitchDisplace"))
		shader.object:send("_glitchFreq", s:get("_glitchFreq"))
	end
	if string.find(shader.name, "pixelate") then
		shader.object:send("_pixres", s:get("_pixres"))
	end

	return shader
end


return cfg_shaders