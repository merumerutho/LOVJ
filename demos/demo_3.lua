available_palettes = require "lib/palettes"
screen = require "lib/screen"
-- import pico8 palette
PALETTE = available_palettes.PICO8

patch = {}
patch.methods = {}


function patch.patchControls()
	local p = params[1]
	if love.keyboard.isDown("lctrl") then
    if love.keyboard.isDown("a") then
      p[1] = 1
    else
      p[1] = 0
    end
    
    -- Hanger
    if love.keyboard.isDown("x") then
      hang = true
    else
      hang = false
    end
  end
	
	-- Reset
	if love.keyboard.isDown("r") then
		timer.InitialTime = love.timer.getTime()
    patch.init()
	end
	
	return p
end


function patch.newBall()
	b = {}
	b.n = 6 + math.random(16)
	b.s = math.random()
	b.cs = patch.bs + math.random()
	b.w = math.abs(8*math.sin(timer.t/10))
	b.c = patch.palette[math.random(16)]
	b.rp = math.random()
	-- insert to list
	table.insert(patch.ballList, b)
end



function patch.ballUpdate(k, b)
  local p = params[1]
  b.w = b.w + b.s + b.w * p[1]/10
  if b.w > screen.inner.w/2*math.sqrt(2) then
    table.remove(patch.ballList, k)
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
	patch.nBalls = 200
	patch.bs = 1/100
	
	math.randomseed(timer.t)
	
	patch.ballList = {}
	-- generate balls
	for i=1, patch.nBalls do
		patch.newBall(patch.ballList)
	end
	patch.count = patch.nBalls
end


function patch.drawBall(b)
  -- local p = params[1]
	for a = 0, b.n do
		local x = screen.inner.w/2 + 20*math.cos(2*math.pi* timer.t/6.2) - b.w * math.cos(2*math.pi*(timer.t/2*b.cs + a / b.n + b.rp))
		local y = screen.inner.h/2 + 25*math.sin(2*math.pi* timer.t/5.5) - b.w * math.sin(2*math.pi*(timer.t/2*b.cs + a / b.n + b.rp))
		local r = (b.w / 30)*(b.w / 30)
		-- filled circle
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.circle("line", x, y, r, (r*2)+6)
		-- filled circle
		love.graphics.setColor(b.c[1]/255, b.c[2]/255, b.c[3]/255, 1)
		love.graphics.circle("fill", x, y, r, (r*2)+6)
	end
end


function patch.draw()
	--local p = params[1]
	-- draw balls
	for k,b in pairs(patch.ballList) do
		patch.drawBall(b)
	end
end


function patch.update(new_params)
  params = new_params
	-- update parameters with patch controls
	patch.patchControls()
  -- update balls
  for k,b in pairs(patch.ballList) do
    patch.ballUpdate(k,b)
  end
end

return patch