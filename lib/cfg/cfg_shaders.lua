-- cfg_shaders.lua
--
-- Configure and handle shader settings
--

local shaders = lovjRequire("lib/shaders")
local cfg_timers = lovjRequire("lib/cfg/cfg_timers")

local cfg_shaders = {}

cfg_shaders.enabled = true
--- @public shaders list of shaders
cfg_shaders.shaders =   {  shaders.default,
						   shaders.swirl,
						   shaders.glitch,
						   shaders.underwater,
						   shaders.w_mirror_water,
						   shaders.w_mirror,
						   shaders.h_mirror,
						   shaders.wh_mirror,
						   shaders.w_mirror,
						   shaders.warp,
						   shaders.kaleido,
						   shaders.diag_cut,
						   shaders.blur}

-- Post process shaders: at startup they are default
cfg_shaders.PostProcessShaders = {shaders.default,
								  shaders.default,
								  shaders.default}

--- @public toggleShaders enable / disable shaders
function toggleShaders()
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
end

--- @public selectShader select the shader to apply
function cfg_shaders.selectShader(i)
    local s = resources.shaderext
    -- select shader
	local shader_script
	local shader

	shader_script = cfg_shaders.shaders[1 + s:get("shaderSlot" .. i)]
	shader = love.graphics.newShader(shader_script)
	if shader_script == shaders.warp then
		shader:send("_warpParameter", s:get("_warpParameter"))
	end
	if shader_script == shaders.kaleido then
		shader:send("_segmentParameter", s:get("_segmentParameter"))
	end
	if shader_script == shaders.blur then
		shader:send("_blurOffset", s:get("_blurOffset"))
	end
	if shader_script == shaders.glitch then
		shader:send("_glitchDisplace", s:get("_glitchDisplace"))
		shader:send("_glitchFreq", s:get("_glitchFreq"))
	end
	return shader
end


--- @public applyShader apply the shader to the graphics
function cfg_shaders.applyShader(shader)
	love.graphics.setShader(shader)
end

return cfg_shaders