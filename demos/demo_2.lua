palettes = require "lib/utils/palettes"
screen = require "lib/screen"

local PALETTE = palettes.PICO8

patch = {}
patch.methods = {}

-- Fill screen with background color
local function fill_bg(x, y, r, g, b, a)
	local col = palettes.getColor(PALETTE, 1)
	r, g, b = col[1], col[2], col[3]
	a = 1
	return r,g,b,a
end


function patch.patchControls()
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
	if love.keyboard.isDown("x") then patch.hang = true else patch.hang = false end
	
	-- Reset
	if love.keyboard.isDown("r") then
    	patch.init()
	end
end


local function addBall(ball_list, sx, sy)
	ball = {}
  -- ball starting position
	ball.x = sx
	ball.y = sy
  -- ball z-depth (radius)
	ball.z = math.random()
  -- ball color
	ball.c = palettes.getColor(PALETTE, math.random(16))
  -- ball direction is binary
	ball.dx = (-1) ^ (1+math.random(2))
	ball.dy = (-1) ^ (1+math.random(2))
  -- ball speed 
	ball.ax = ball.dx * ((math.random())*3 + 0.05)
	ball.ay = ball.dy * ((math.random())*3 + 0.05 - ball.dx * ball.ax / 10)
  	ball.az = (math.abs(ball.ax) + math.abs(ball.ay))
  	-- readjust ay
  	ball.ax = (ball.ax / ball.dx - ball.dy * ball.ay / 10) * ball.dx
  	-- add ball to list
	table.insert(patch.ballList, ball)
end


local function ballTrajectory(k, b)
  b.x = b.x + b.ax
  b.y = b.y + b.ay
  b.z = b.z + 0.05 * b.az
  
  if b.z < 0 then b.z = 0 end
  if (b.x < -b.z or 
      b.x > screen.InternalRes.W + b.z or
      b.y < -b.z or
      b.y > screen.InternalRes.H + b.z) then
      
      table.remove(patch.ballList, k)
      addBall(ball_list, screen.InternalRes.W / 2, screen.InternalRes.H / 2)
  end
end


function patch.init()
	patch.hang = false

	patch.canvases = {}
	patch.canvases.main = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
	
  	-- balls
  	patch.nBalls = 500
  	patch.ballList = {}
  	-- generate balls
  	for i = 1, patch.nBalls do
    	addBall(patch.ballList, screen.InternalRes.W / 2, screen.InternalRes.H / 2)
  	end
end


local function drawBall(b)
  	local border_col = palettes.getColor(PALETTE, math.random(16))
  	love.graphics.setColor(border_col[1] / 255, border_col[2] / 255, border_col[3] / 255, 1)
  	love.graphics.circle("line", b.x, b.y, (b.z / 2) ^ 1.6, (b.z * 2) + 6)
  	-- filled circle
  	love.graphics.setColor(b.c[1], b.c[2], b.c[3], 1)
	love.graphics.circle("fill", b.x, b.y, (b.z / 2) ^ 1.6, (b.z * 2) + 6)
	love.graphics.setColor(1,1,1,1)
end


function patch.draw()
	-- select shader
	local shader
	if cfg_shaders.enabled then shader = cfg_shaders.selectShader() end
	-- clear picture
	if not patch.hang then
		patch.canvases.main:renderTo(love.graphics.clear)
	end
	-- set canvas
	love.graphics.setCanvas(patch.canvases.main)


  	-- draw balls
  	for k,b in pairs(patch.ballList) do
    	drawBall(b)
  	end
	-- reset canvas
	love.graphics.setCanvas()

	-- apply shader
	if cfg_shaders.enabled then cfg_shaders.applyShader(shader) end
	-- render graphics
	love.graphics.draw(patch.canvases.main, 0, 0, 0, (1 / screen.Scaling.X), (1 / screen.Scaling.Y))
	-- remove shader
	if cfg_shaders.enabled then cfg_shaders.applyShader() end
end


local function orderZ(l)
  for i = 1, #l do
    local j = i
    while j > 1 and l[j - 1].z > l[j].z do
      l[j], l[j - 1] = l[j - 1], l[j]
      j = j - 1
    end
  end
end


function patch.update()
	-- update parameters with patch controls
	patch.patchControls()
	if timer.fpsInterrupt() then
		-- update balls
		for k, b in pairs(patch.ballList) do
			ballTrajectory(k, b)
		end
		-- re-order balls
		orderZ(patch.ballList)
	end
end

--- @public defaultDraw assigned to draw method by default
patch.defaultDraw = patch.draw

return patch