local Patch = lovjRequire("lib/patch")
local palettes = lovjRequire("lib/utils/palettes")
local kp = lovjRequire("lib/utils/keypress")
local Timer = lovjRequire("lib/timer")
local cfg_timers = lovjRequire("cfg/cfg_timers")
local cfg_screen = lovjRequire("cfg/cfg_screen")
local Envelope = lovjRequire("lib/signals/envelope")
local Lfo = lovjRequire("lib/signals/lfo")

local PALETTE

-- aquamarine
local waveShaderCode = [[
	extern float _time;
	vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
	{
		float c = 1. - abs(sin(_time + texture_coords.y + texture_coords.x * 5));
		texture_coords.y = mod(texture_coords.x, c);
		c = 1. - abs(sin(_time + texture_coords.y + texture_coords.x * 5));
		texture_coords.x = mod(texture_coords.y, c);
		c = 1. - abs(sin(_time + texture_coords.y + texture_coords.x * 5));

        return vec4(.2 + .01 * sin(c+ _time), c * .8, .65 + .02 * sin(c*_time),1.);
	}
]]


local patch = Patch:new()

--- @private init_params initialize patch parameters
local function init_params()
	local g = patch.resources.graphics
	local p = patch.resources.parameters
	g:setName(1, "bg")				g:set("bg", "data/demo_6/bg.png")
	p:setName(1, "bgSpeed")			p:set("bgSpeed", 10)
	patch.resources.parameters = p
	patch.resources.graphics = g
end

--- @public patchControls evaluate user keyboard controls
function patch.patchControls()
	local p = patch.resources.parameters
	-- Hanger
	if kp.isDown("x") then patch.hang = true else patch.hang = false end
end


--- @public setCanvases (re)set canvases for this patch
function patch:setCanvases()
	Patch.setCanvases(patch)  -- call parent function
	-- patch-specific execution (window canvas)
	if cfg_screen.UPSCALE_MODE == cfg_screen.LOW_RES then
		patch.canvases.toShade = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
	else
		patch.canvases.toShade = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
	end
end


--- @public init init routine
function patch.init(slot)
	Patch.init(patch, slot)
	PALETTE = palettes.PICO8

	patch:setCanvases()

	init_params()

	patch.bpm = 120
	patch.timers = {}
	patch.timers.bpm = Timer:new(60 / patch.bpm )  -- 60 are seconds in 1 minute, 4 are sub-beats

end


--- @public patch.draw draw routine
function patch.draw()
	local t = cfg_timers.globalTimer.T

	patch:drawSetup(hang)

	local c = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
	love.graphics.setCanvas(c)
	love.graphics.setColor(1,1,1,1)

	local shader
	if cfgShaders.enabled then
		shader = love.graphics.newShader(waveShaderCode)
		love.graphics.setShader(shader)
		shader:send("_time", t)
	end

	love.graphics.setCanvas(patch.canvases.main)
	love.graphics.draw(c)
	love.graphics.setShader()

	love.graphics.setColor(1,1,1,1)

	local cx, cy = screen.InternalRes.W / 2, screen.InternalRes.H / 2

	local amp = .7 + .3 * math.abs(math.sin(2*math.pi * t / 2))
	love.graphics.setColor(1,1,1,0.8)

	for j = -2, 2 do
		for i = 1, 10 do
			love.graphics.circle("fill",
					cx + amp * (50 + 10*(math.sin(2*math.pi*(t+j/5)))) * math.cos(2*math.pi*i/10 + t + j/4),
					cy + amp * (30*j + 10) * math.sin(2*math.pi*i/10 + t + j/4),
					math.abs(math.sin(i / 2 + t)) * 5 + 2)
--			love.graphics.setColor(0,0,0,1)
--			love.graphics.circle("line",
--					cx + (40 + 10*(math.sin(2*math.pi*(t+j/5)))) * math.cos(2*math.pi*i/10 + t + j/4),
--					20*j + cy + 10 * math.sin(2*math.pi*i/10 + t + j/4),
--					7)
		end
	end

	local n = 16
	love.graphics.setColor(1,1,1,.7)
	for i = 0, n do
		love.graphics.circle("fill",
				cx + (100 + 10 * math.sin(2*math.pi*(t*2 + 4*i / n))) * math.cos(2*math.pi*(t/4 + i/n)),
				cy + (100 + 10 * math.sin(2*math.pi*(t*2 + 4*i / n))) * math.sin(2*math.pi*(t/4 + i/n)),
				7)
	end

	love.graphics.setColor(1,1,1,1)

	return patch:drawExec()
end


function patch.update()
	patch:mainUpdate()
	patch.timers.bpm:update()

	--patch.env:UpdateTrigger(patch.timers.bpm:Activated())
	--patch.lfo:UpdateTrigger(true)

end


function patch.commands(s)

end

return patch