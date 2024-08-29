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

	p:setName(1, "numBranches")			p:set("numBranches", 10)
	p:setName(2, "ampModulator")		p:set("ampModulator", 10)
	p:setName(3, "timeFactor")			p:set("timeFactor", 0)
	p:setName(4, "triangleCenterAmp")	p:set("triangleCenterAmp", 10)
	p:setName(5, "beta")				p:set("beta", 0.5)
	p:setName(6, "rBase")				p:set("rBase", 50)

	patch.resources.parameters = p
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

local function draw_eyeball(t, cx, cy)
	local ex = cx
	local ey = cy + 4 * math.sin(t)
	local px = ex + 5 * math.cos(t)
 	local py = ey + 5 * math.sin(t)
	local eye_amp = 1 + math.abs(math.sin(t))
	-- eyeball
	love.graphics.setColor(1,1,1,1)
	love.graphics.circle("fill", ex, ey, 12 + 5 *eye_amp)
	love.graphics.setColor(0,0,0,1)
	love.graphics.circle("line",ex,ey, 12 + 5*eye_amp)
	love.graphics.setColor(1,1,1,1)
	-- outer circles
	love.graphics.circle("line", ex, ey, 32 + 3 * math.sin(t/3)*eye_amp, 10)
	love.graphics.circle("line", ex, ey, 44 + 4 * math.sin(t)*eye_amp, 12)
	-- pupil
	love.graphics.setColor(0,0,0,1)
	love.graphics.ellipse("fill", px, py, 8, 3 + 3*eye_amp)
	love.graphics.setColor(1,1,1,1)
	love.graphics.circle("fill", px, py, 2 +eye_amp)

end

local function draw_bg(t, cx, cy)
	local p = patch.resources.parameters
	love.graphics.setColor(1,1,1,.5)

	local n = 300
	local f = 5
	local width = p:get("numBranches")

	for off = -150, 150, 50 do
		local amp = 15*math.sin((2*math.pi)*(t/4+off/100))
		for w = 0, width, 2 do
			for i = -n/2, n/2, 2 do
				love.graphics.points(
				cx + i + w + amp*math.cos((2*math.pi)*i/n*f),
				off + cy - i + w + amp * math.sin((2*math.pi)*(t/2 + i/n*f))
				)
			end
		end
	end
end


local function draw_static(t, cx, cy)
	local off = 0 -- -50
	local nStatics = 10
	local s_sigma = 500 + 200*math.sin(t)
	love.graphics.setColor(1,1,1,1)
	local points = {}
	for i = 0, nStatics-1 do
		table.insert(points, {})
	end

	local amp = 120 / nStatics

	for x = -150, 150, 10 do
		for i = 1, #points do
			ix = math.exp(-(x)^2/s_sigma)
			local y = 0
			y = y + math.max(math.min(math.tan( x*x*100*x*math.sin(t/100+i/#points+x)), amp), -amp)
			y = y + amp * math.sin((2*math.pi)*(t + i/20 + x/screen.InternalRes.W))

			table.insert(points[i], cx+x)
			table.insert(points[i], off + cy - nStatics/2 + i + y)
		end
	end

	for i = 0, nStatics-1 do
		alpha = math.abs(nStatics/2 - i) / nStatics
		love.graphics.setColor(1,1,1,(1-alpha) - .5)
		love.graphics.line(points[i+1])
	end
end

--- @private draw_bg draw background graphics
local function draw_scene()
	local t = cfg_timers.globalTimer.T

	g = patch.resources.graphics
	p = patch.resources.parameters

	local cx = screen.InternalRes.W/2
	local cy = screen.InternalRes.H/2

	draw_bg(t, cx, cy)

	draw_static(t, cx, cy)

	draw_eyeball(t, cx,cy)


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
	local p = patch.resources.parameters
	local t = cfg_timers.globalTimer.T

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