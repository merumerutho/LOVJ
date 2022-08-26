palettes = require "lib/palettes"
screen = require "lib/screen"
kp = require "lib/utils/keypress"

-- import pico8 palette
local PALETTE

patch = {}

function patch.patchControls()
	local p = resources.parameters
	if kp.isDown("lctrl") then
		-- Accelerator
		if kp.isDown("a") then p:setByIdx(1, 1) else p:setByIdx(1, 0) end
		-- Hanger (TODO implement)
		if kp.isDown("x") then hang = true else hang = false end
  	end
	-- Reset
	if kp.isDown("r") then
		timer.InitialTime = love.timer.getTime()
    	patch.init()
	end
end


local function newBall()
	ball = {}
	ball.n = 6 + math.random(16)
	ball.s = math.random()
	ball.cs = patch.bs + math.random()
	ball.w = math.abs(8 * math.sin(timer.T / 10))
	ball.c = palettes.getColor(PALETTE, math.random(16))
	ball.rp = math.random()
	-- insert to list
	table.insert(patch.ballList, ball)
end


local function ballUpdate(idx, ball)
  local p = resources.parameters
  ball.w = ball.w + ball.s + ball.w * p:getByIdx(1) / 10
  if ball.w > screen.InternalRes.W / 2 * math.sqrt(2) then
    table.remove(patch.ballList, idx)
    patch.count = patch.count - 1
    -- re-add ball
    newBall()
  end
  while patch.count > patch.nBalls do
    table.remove(patch.ballList, 1)
  end
end


function patch.init()
	PALETTE = palettes.PICO8
	patch.hang = false
	-- balls
	patch.nBalls = 100
	patch.bs = 1 / 100

	math.randomseed(timer.T)

	patch.ballList = {}
	-- generate balls
	for i = 1, patch.nBalls do
		newBall(patch.ballList)
	end
	patch.count = patch.nBalls
end


local function drawBall(b)
	for a = 0, b.n do
		local x = (screen.InternalRes.W / 2) + (20 * math.cos(2 * math.pi * timer.T / 6.2))
		local y = (screen.InternalRes.H / 2) + (25 * math.sin(2 * math.pi * timer.T / 5.5))
		x = x - b.w * math.cos(2 * math.pi * (timer.T / 2 * b.cs + a / b.n + b.rp))
		y = y - b.w * math.sin(2 * math.pi * (timer.T / 2 * b.cs + a / b.n + b.rp))
		local r = (b.w / 30) * (b.w / 30)
		-- filled circle
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.circle("line", x, y, r, (r * 2) + 6)
		-- filled circle
		love.graphics.setColor(b.c[1], b.c[2], b.c[3], 1)
		love.graphics.circle("fill", x, y, r, (r * 2) + 6)
	end
end


function patch.draw()
	-- draw balls
	for k, b in pairs(patch.ballList) do
		drawBall(b)
	end
end


function patch.update(new_params)
  params = new_params
	-- update parameters with patch controls
	patch.patchControls()
  -- update balls
  for k, b in pairs(patch.ballList) do
    ballUpdate(k, b)
  end
end

--- @public defaultDraw assigned to draw method by default
patch.defaultDraw = patch.draw

return patch