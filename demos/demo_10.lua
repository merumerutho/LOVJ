local Patch = lovjRequire("lib/patch")
local palettes = lovjRequire("lib/utils/palettes")
local kp = lovjRequire("lib/utils/keypress")
local Envelope = lovjRequire("lib/automations/envelope")
local Lfo = lovjRequire("lib/automations/lfo")
local Timer = lovjRequire("lib/timer")
local cfg_timers = lovjRequire("lib/cfg/cfg_timers")

-- declare palette
local PALETTE

local shader_code = [[
	extern float time;
	vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
	{
        vec2 c =  texture_coords;
        float i = abs(cos(time - c.y)) - (mod(c.x, c.y));
        return vec4(i, 0.1, i, 1);
	}
]]

patch = Patch:new()

--- @private init_params initialize patch parameters
local function init_params()
	g = resources.graphics
	p = resources.parameters

    -- insert here your patch parameters
end

--- @public patchControls evaluate user keyboard controls
function patch.patchControls()
	p = resources.parameters

    -- insert here your patch controls
end


--- @public init init routine
function patch.init()
	PALETTE = palettes.PICO8

	patch:setCanvases()

	init_params()

	patch:assignDefaultDraw()
end

--- @private draw_bg draw background graphics
local function draw_stuff()
	g = resources.graphics
	p = resources.parameters

	local t = cfg_timers.globalTimer.T

	local c = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
	love.graphics.setCanvas(c)

	local shader
	if cfg_shaders.enabled then
		shader = love.graphics.newShader(shader_code)
		love.graphics.setShader(shader)
		shader:send("time", t)
	end

	love.graphics.setCanvas(patch.canvases.main)
	love.graphics.draw(c)




end

--- @public patch.draw draw routine
function patch.draw()
	patch:drawSetup()

	-- draw picture
	draw_stuff()

	patch:drawExec()
end


function patch.update()
	patch:mainUpdate()
end

return patch