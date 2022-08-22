available_palettes = require "lib/palettes"
screen = require "lib/screen"
kp = require "lib/utils/keypress"

-- import pico8 palette
PALETTE = available_palettes.PICO8

patch = {}
patch.methods = {}

function patch.patchControls()
	local p = resources.parameters
	if kp.isDown("lctrl") then
		-- Accelerator
		if kp.isDown("a") then rSet(p, 1, 1) else rSet(p, 1, 0) end

		-- Hanger (TODO implement)
		if kp.isDown("x") then hang = true else hang = false end
  	end
	
	-- Reset
	if kp.isDown("r") then
		timer.InitialTime = love.timer.getTime()
    	patch.init()
	end

end


function patch.newBall()
	ball = {}
	ball.n = 6 + math.random(16)
	ball.s = math.random()
	ball.cs = patch.bs + math.random()
	ball.w = math.abs(8 * math.sin(timer.T / 10))
	ball.c = patch.palette[math.random(16)]
	ball.rp = math.random()
	-- insert to list
	table.insert(patch.ballList, ball)
end


function patch.ballUpdate(idx, ball)
  local p = resources.parameters
  ball.w = ball.w + ball.s + ball.w * rGet(p, 1) / 10
  if ball.w > screen.InternalRes.W / 2 * math.sqrt(2) then
    table.remove(patch.ballList, idx)
    patch.count = patch.count - 1
    -- re-add ball
    patch.newBall()
  end
  while patch.count > patch.nBalls do
    table.remove(patch.ballList, 1)
  end
end


function patch.init()
	patch.hang = false
	patch.palette = PALETTE
	-- balls
	patch.nBalls = 100
	patch.bs = 1 / 100

	math.randomseed(timer.T)

	patch.ballList = {}
	-- generate balls
	for i = 1, patch.nBalls do
		patch.newBall(patch.ballList)
	end
	patch.count = patch.nBalls
end


function patch.drawBall(b)
	for a = 0, b.n do
		local x = (screen.InternalRes.W / 2) + (20 * math.cos(2 * math.pi * timer.T / 6.2)) - b.w * math.cos(2 * math.pi * (timer.T / 2 * b.cs + a / b.n + b.rp))
		local y = (screen.InternalRes.H / 2) + (25 * math.sin(2 * math.pi * timer.T / 5.5)) - b.w * math.sin(2 * math.pi * (timer.T / 2 * b.cs + a / b.n + b.rp))
		local r = (b.w / 30) * (b.w / 30)
		-- filled circle
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.circle("line", x, y, r, (r * 2) + 6)
		-- filled circle
		love.graphics.setColor(b.c[1] / 255, b.c[2] / 255, b.c[3] / 255, 1)
		love.graphics.circle("fill", x, y, r, (r * 2) + 6)
	end
end


function patch.draw()
	-- draw balls
	for k, b in pairs(patch.ballList) do
		patch.drawBall(b)
	end
end


function patch.update(new_params)
  params = new_params
	-- update parameters with patch controls
	patch.patchControls()
  -- update balls
  for k, b in pairs(patch.ballList) do
    patch.ballUpdate(k, b)
  end
end

return patch