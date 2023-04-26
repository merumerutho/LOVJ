-- cfg_shaders.lua
--
-- Configure and handle shader settings
--

local shaders = lovjRequire("lib/shaders")

local cfg_shaders = {}

cfg_shaders.enabled = true
--- @public shaders list of shaders
cfg_shaders.shaders = {	shaders.default,
                       	shaders.h_mirror,
                       	shaders.wh_mirror,
                       	shaders.w_mirror,
                       	shaders.warp,
                       	shaders.kaleido,
                       	shaders.diag_cut,
                       	shaders.blur,
						shaders.glitch }

--- @public toggleShaders enable / disable shaders
function toggleShaders()
    cfg_shaders.enabled = not cfg_shaders.enabled
end

function cfg_shaders.assignGlobals()
	g = resources.globals
	g:setName(1, "selected_shader")		g:set("selected_shader", 0)
	g:setName(2, "_warpParameter")		g:set("_warpParameter", 2)
	g:setName(3, "_segmentParameter")	g:set("_segmentParameter", 3)
	g:setName(4, "_chromaColor")		g:set("_chromaColor", {0,0,0,0})
	g:setName(5, "_chromaTolerance")	g:set("_chromaTolerance", {0.05, 0.1})
	g:setName(6, "_blurOffset")			g:set("_blurOffset", 0.01)
	g:setName(7, "_glitchOffset")		g:set("_glitchOffset", 0.00)
	g:setName(8, "_glitchSize")			g:set("_glitchSize", -2000)
end

--- @public selectShader select the shader to apply
function cfg_shaders.selectShader()
    g = resources.globals
    -- select shader
	local shader_script
	local shader
	shader_script = cfg_shaders.shaders[1 + g:get("selected_shader")]
	shader = love.graphics.newShader(shader_script)
	if shader_script == shaders.warp then
		shader:send("_warpParameter", g:get("_warpParameter"))
	end
	if shader_script == shaders.kaleido then
		shader:send("_segmentParameter", g:get("_segmentParameter"))
	end
	if shader_script == shaders.blur then
		shader:send("_blurOffset", g:get("_blurOffset"))
	end
	return shader
end

--- @public applyShader apply the shader to the graphics
function cfg_shaders.applyShader(shader)
	love.graphics.setShader(shader)
end

return cfg_shaders