local Patch = lovjRequire("lib/patch")
local palettes = lovjRequire("lib/utils/palettes")
local screen = lovjRequire("lib/screen")
local kp = lovjRequire("lib/utils/keypress")
local Timer = lovjRequire("lib/timer")
local cfg_timers = lovjRequire("cfg/cfg_timers")


-- import pico8 palette
local PALETTE = palettes.PICO8
local DEFAULT_ACCELERATION = 0.4

local patch = Patch:new()

--- @public patchControls handle controls for current patch
function patch.patchControls()
	local p = patch.resources.parameters
	local gr = patch.resources.graphics
	local gl = patch.resources.globals

	if kp.isDown("lctrl") then
		-- Accelerator
		if kp.isDown("a") then p:set("acceleration", DEFAULT_ACCELERATION+1) else p:set("acceleration", DEFAULT_ACCELERATION) end
  	end
	-- Reset
	if kp.isDown("r") then
    	patch.init(patch.slot, patch)
	end
	-- hang
	if kp.isDown("x") then patch.hang = true else patch.hang = false end

	return p, gr, gl
end

--- @private newBall spawn new ball in ballList
local function newBall()
	local t = cfg_timers.globalTimer.T
	local ball = {}
	ball.n = 6 + math.random(16)
	ball.s = math.random()
	ball.cs = patch.bs + math.random()
	ball.w = math.abs(8 * math.sin(t / 10))
	ball.c = palettes.getColor(PALETTE, math.random(16))
	ball.rp = math.random()
	-- insert to list
	table.insert(patch.ballList, ball)
end

--- @private ballUpdate update ball status and position in ballList
local function ballUpdate(idx, ball)
	local p = patch.resources.parameters
	local dt = cfg_timers.globalTimer:dt()

	ball.w = ball.w + (ball.s + ball.w * p:getByIdx(1) / 10 ) * dt * 50

	local largestSide = math.max(screen.InternalRes.W, screen.InternalRes.H)
	if ball.w > largestSide / 2 * math.sqrt(2) then
		table.remove(patch.ballList, idx)
		patch.count = patch.count - 1
		-- re-add ball
		newBall()
	end
	while patch.count > patch.nBalls do
		table.remove(patch.ballList, 1)
	end
end

--- @private init_params initialize patch parameters
local function init_params()
	local p = patch.resources.parameters
	p:setName(1, "acceleration")		p:set("acceleration", DEFAULT_ACCELERATION)
	return p
end

--- @public init initialization function for the patch
function patch.init(slot)
	Patch.init(patch, slot)
	PALETTE = palettes.PICO8
	patch:setCanvases()

	patch.resources.parameters = init_params()

	-- ball stuff
	patch.nBalls = 100
	patch.bs = 1 / 100
	patch.ballList = {}
	-- generate balls
	for i = 1, patch.nBalls do
		newBall(patch.ballList)
	end
	patch.count = patch.nBalls
end


local function drawBall(b)
	local t = cfg_timers.globalTimer.T
	for a = 0, b.n do
		local x = (screen.InternalRes.W / 2) + (20 * math.cos(2 * math.pi * t / 6.2))
		local y = (screen.InternalRes.H / 2) + (25 * math.sin(2 * math.pi * t / 5.5))
		x = x - b.w * math.cos(2 * math.pi * (t / 2 * b.cs + a / b.n + b.rp))
		y = y - b.w * math.sin(2 * math.pi * (t / 2 * b.cs + a / b.n + b.rp))
		local r = (b.w / 30) * (b.w / 30)
		-- filled circle
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.circle("line", x, y, r, (r * 2) + 6)
		-- filled circle
		love.graphics.setColor(b.c[1], b.c[2], b.c[3], 1)
		love.graphics.circle("fill", x, y, r, (r * 2) + 6)
		love.graphics.setColor(1,1,1,1)
	end
end


function patch.draw()
	patch:drawSetup()
	-- draw balls
	for k, b in pairs(patch.ballList) do
		drawBall(b)
	end
	return patch:drawExec()
end

--- @public update update patch function
function patch.update()
	patch:mainUpdate()

	-- update balls
	for k, b in pairs(patch.ballList) do
		ballUpdate(k, b)
	end

end


function patch.commands(s)

end

return patch