local Patch = lovjRequire("lib/patch")
local palettes = lovjRequire("lib/utils/palettes")
local kp = lovjRequire("lib/utils/keypress")
local Timer = lovjRequire("lib/timer")
local cfg_timers = lovjRequire("cfg/cfg_timers")
local cfg_screen = lovjRequire("cfg/cfg_screen")
local Lfo = lovjRequire("lib/signals/lfo")

local patch = Patch:new()

local PALETTE

--- @private init_params initialize patch parameters
local function init_params()
	local g = patch.resources.graphics
	local p = patch.resources.parameters

	p:setName(1, "numBranches")			p:set("numBranches", 40)
	p:setName(2, "ampModulator")		p:set("ampModulator", 10)
	p:setName(3, "timeFactor")			p:set("timeFactor", 0)
	p:setName(4, "triangleCenterAmp")	p:set("triangleCenterAmp", 10)
	p:setName(5, "beta")				p:set("beta", 0.5)
	p:setName(6, "rBase")				p:set("rBase", 50)

end

--- @public patchControls evaluate user keyboard controls
function patch.patchControls()
	local p = patch.resources.parameters
	-- Hanger
	if kp.isDown("x") then patch.hang = true else patch.hang = false end
end

function patch:setCanvases()
	Patch.setCanvases(patch)  -- call parent function
	-- patch-specific execution (window canvas)
	if cfg_screen.UPSCALE_MODE == cfg_screen.LOW_RES then
		patch.canvases.balls = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
		patch.canvases.bg = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
	else
		patch.canvases.balls = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
		patch.canvases.bg = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
	end
end


--- @public init init routine
function patch.init(slot)
	Patch.init(patch, slot)
	PALETTE = palettes.PICO8
	patch:setCanvases()

	init_params()

	patch.push = Lfo:new(0.1, 0)
end

--- @private draw_bg draw background graphics
local function draw_scene()
	local t = cfg_timers.globalTimer.T

	local g = patch.resources.graphics
	local p = patch.resources.parameters

	local cx = screen.InternalRes.W/2
	local cy = screen.InternalRes.H/2

	love.graphics.setColor(1,1,1,1)

	local m = 50

	-- background

	for x = -screen.InternalRes.W / m, screen.InternalRes.W, screen.InternalRes.W / m do
		for y = -screen.InternalRes.H / m, screen.InternalRes.H, screen.InternalRes.H / m do
			local xx = (x-cx)*(x-cx)
			local yy = (y-cy)*(y-cy)
			love.graphics.setColor(1,1,1, 0.25*math.sin((xx+t*1000)/screen.InternalRes.W + (yy+t*1000)/screen.InternalRes.H))
			 love.graphics.rectangle("fill",
									x,
									y,
									screen.InternalRes.W / m,
									screen.InternalRes.H / m)
		end
	end

	local n = p:get("numBranches")
	local ampMod = p:get("ampModulator")
	local timeFactor = p:get("timeFactor")
	local triangleCenterAmp = p:get("triangleCenterAmp")
	local beta = p:get("beta")
	local rBase = p:get("rBase")

	-- triangle geometry
	for theta = 0, 2*math.pi, (2*math.pi)/n do
		love.graphics.setColor(1,1,1,.5)
		local radius = 75 + 50*math.sin(t + math.sin(t)) + 50 * math.sin(theta*3+t)
		local a = {math.cos(theta+t), math.sin(theta+t)}
		local b = {math.cos(theta+beta+t), math.sin(theta+beta+t)}
		love.graphics.polygon("fill", cx + radius*a[1], cy+radius*a[2],
				cx + (radius)*a[1], cy+(radius)*a[2],
				cx + (radius*2)*b[1], cy+(radius*2)*b[2],
				cx + (radius*1.5)*b[1], cy+(radius*1.5)*b[2],
				cx + (radius) * a[1], cy + (radius) * a[2],
				cx-triangleCenterAmp*math.sin(theta + timeFactor*t), cy+triangleCenterAmp*math.cos(theta + timeFactor*t))

		love.graphics.setColor(1,1,1,.2)
		love.graphics.polygon("fill", cx + (radius*0.5)*b[1], cy+(radius*0.5)*b[2],
				cx + (radius*0.5)*b[1], cy+(radius*0.5)*b[2],
				cx + (radius)*a[1], cy+(radius)*a[2],
				cx + (radius*.75)*a[1], cy+(radius*.75)*a[2],
				cx + (radius*0.5) * b[1], cy + (radius*0.5) * b[2],
				cx, cy)

	end

	-- pulsating circle
	love.graphics.setColor(0,0,0,1)
	for radius = 0, 20 do
		love.graphics.circle("line", cx, cy, radius + ((t*300)%200))
	end

end

--- @public patch.draw draw routine
function patch.draw()
	patch:drawSetup(patch.hang)

	-- clear main canvas
	patch.canvases.main:renderTo(function()
									love.graphics.clear(0,0,0,1)
								end )

	-- draw picture
	draw_scene()


	return patch:drawExec()
end


function patch.update()
	local t = cfg_timers.globalTimer.T
	local p = patch.resources.parameters

	if kp.keypressOnRelease("up") and kp.isDown("n") then p:set("numBranches", p:get("numBranches")+1) end
	if kp.keypressOnRelease("down") and kp.isDown("n") then p:set("numBranches", p:get("numBranches")-1) end

	if kp.isDown("up") and kp.isDown("a") then p:set("ampModulator", p:get("ampModulator")+0.01) end
	if kp.isDown("down") and kp.isDown("a") then p:set("ampModulator", p:get("ampModulator")-0.01) end

	if kp.isDown("up") and kp.isDown("t") then p:set("timeFactor", p:get("timeFactor")+0.01) end
	if kp.isDown("down") and kp.isDown("t") then p:set("timeFactor", p:get("timeFactor")-0.01) end

	if kp.isDown("up") and kp.isDown("c") then p:set("triangleCenterAmp", p:get("triangleCenterAmp")+0.1) end
	if kp.isDown("down") and kp.isDown("c") then p:set("triangleCenterAmp", p:get("triangleCenterAmp")-0.1) end

	if kp.isDown("up") and kp.isDown("b") then p:set("beta", p:get("beta")+0.01) end
	if kp.isDown("down") and kp.isDown("b") then p:set("beta", p:get("beta")-0.01) end

	if kp.isDown("up") and kp.isDown("r") then p:set("rBase", p:get("rBase")+1) end
	if kp.isDown("down") and kp.isDown("r") then p:set("rBase", p:get("rBase")-1) end

	p:set("timeFactor", math.max(0, p:get("timeFactor")))

	patch.push:UpdateTrigger(true)

	patch:mainUpdate()
end


function patch.commands(s)



end

return patch