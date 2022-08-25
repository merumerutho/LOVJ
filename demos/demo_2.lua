available_palettes = require "lib/palettes"
screen = require "lib/screen"
-- import pico8 palette
PALETTE = available_palettes.PICO8

patch = {}
patch.methods = {}

-- Fill screen with background color
function patch.methods.fill_bg(x, y, r, g, b, a)
	r = PALETTE[1][1] / 255
	g = PALETTE[1][2] / 255
	b = PALETTE[1][3] / 255
	a = 1
	return r,g,b,a
end


function patch.patchControls()
	p = params[1]
	
	-- INCREASE
	if love.keyboard.isDown("up") then
		-- Param "a"
		if love.keyboard.isDown("a") then
			p[1] = p[1] + .1
		end
		-- Param "b"
		if love.keyboard.isDown("b") then
			p[2] = p[2] + .1
		end
	end
	
	-- DECREASE
	if love.keyboard.isDown("down") then
		-- Param "a"
		if love.keyboard.isDown("a") then
			p[1] = p[1] - .1 
		end
		-- Param "b"
		if love.keyboard.isDown("b") then
			p[2] = p[2] - .1
		end
	end
	
	-- Hanger
	if love.keyboard.isDown("x") then
		hang = true
	else
		hang = false
	end
	
	-- Reset
	if love.keyboard.isDown("r") then
		timer.InitialTime = love.timer.getTime()
    patch.init()
	end
	
	return p
end


function patch.addBall(ball_list, sx, sy)
	ball = {}
  -- ball starting position
	ball.x = sx
	ball.y = sy
  -- ball z-depth (radius)
	ball.z = math.random()
  -- ball color
	ball.c = patch.palette[math.random(16)]
  -- ball direction is binary
	ball.dx = (-1) ^ (1+math.random(2))
	ball.dy = (-1) ^ (1+math.random(2))
  -- ball speed 
	ball.ax = ball.dx * ((math.random()) * 0.5 + 0.05)
	ball.ay = ball.dy * ((math.random()) * 0.5 + 0.05 - ball.dx * ball.ax / 10)
  	ball.az = (math.abs(ball.ax) + math.abs(ball.ay))
  	-- readjust ay
  	ball.ax = (ball.ax / ball.dx - ball.dy * ball.ay / 10) * ball.dx
  	-- add ball to list
	table.insert(patch.ballList, ball)
end



function patch.ballTrajectory(k, b)
  b.x = b.x + b.ax
  b.y = b.y + b.ay
  b.z = b.z + 0.05 * b.az
  
  if b.z < 0 then b.z = 0 end
  if (b.x < -b.z or 
      b.x > screen.InternalRes.w + b.z or
      b.y < -b.z or
      b.y > screen.InternalRes.H + b.z) then
      
      table.remove(patch.ballList, k)
      patch.addBall(ball_list, screen.InternalRes.W / 2, screen.InternalRes.H / 2)
  end
end


function patch.init()
  
	patch.hang = false
	patch.palette = PALETTE

	patch.img = false
	patch.img_data = love.image.newImageData(screen.InternalRes.W, screen.InternalRes.H)
	
  	-- balls
  	patch.nBalls = 500
  	patch.ballList = {}
  	-- generate balls
  	for i = 1, patch.nBalls do
    	patch.addBall(patch.ballList, screen.InternalRes.W / 2, screen.InternalRes.H / 2)
  	end
end


function patch.drawBall(img, b)
  	local border_col = patch.palette[math.random(16)]
  	love.graphics.setColor(border_col[1] / 255, border_col[2] / 255, border_col[3] / 255, 1)
  	love.graphics.circle("line", b.x, b.y, (b.z / 2) ^ 1.6, (b.z * 2) + 6)
  	-- filled circle
  	love.graphics.setColor(b.c[1] / 255, b.c[2] / 255, b.c[3] / 255, 1)
	love.graphics.circle("fill", b.x, b.y, (b.z / 2) ^ 1.6, (b.z * 2) + 6)
end


function patch.draw()
	--p = params[1]
	-- clear picture
	if not patch.hang then
		patch.img_data:mapPixel(patch.methods.fill_bg)
	end
  
  	-- draw balls
  	for k,b in pairs(patch.ballList) do
    	patch.drawBall(patch.img_data, b)
  	end
	
end


function patch.update()
	-- update parameters with patch controls
	patch.patchControls()
  	-- update balls
  	for k, b in pairs(patch.ballList) do
		patch.ballTrajectory(k, b)
  	end
  	-- re-order balls
  	patch.orderZ(patch.ballList)
end


function patch.orderZ(l)
  for i = 1, #l do
    local j = i
    while j > 1 and l[j - 1].z > l[j].z do
      l[j], l[j - 1] = l[j - 1], l[j]
      j = j - 1
    end
  end
end

--- @public defaultDraw assigned to draw method by default
patch.defaultDraw = patch.draw

return patch