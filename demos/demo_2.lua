local Patch = lovjRequire ("lib/patch")
local palettes = lovjRequire ("lib/utils/palettes")
local screen = lovjRequire ("lib/screen")
local Timer = lovjRequire ("lib/timer")
local cfg_timers = lovjRequire ("cfg/cfg_timers")

local PALETTE = palettes.PICO8

local patch = Patch:new()

--- @private patchControls handle controls for current patch
function patch.patchControls()
	-- Hanger
	if love.keyboard.isDown("x") then patch.hang = true else patch.hang = false end
	-- Reset
	if love.keyboard.isDown("r") then patch.init(patch.slot) end
end


local function addBall(sx, sy)
	local ball = {}
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
	local dt = cfg_timers.globalTimer:dt() -- keep it fps independent

	b.x = b.x + b.ax 		* dt * 50
	b.y = b.y + b.ay 		* dt * 50
	b.z = b.z + 0.05 * b.az * dt * 50
  
  if b.z < 0 then b.z = 0 end
  if (b.x < -b.z or 
      b.x > screen.InternalRes.W + b.z or
      b.y < -b.z or
      b.y > screen.InternalRes.H + b.z) then
      
      table.remove(patch.ballList, k)
      addBall(screen.InternalRes.W / 2, screen.InternalRes.H / 2)
  end
end


--- @private init_params Initialize parameters for this patch
local function init_params()
	local p = patch.resources.parameters
	return p
end


function patch.init(slot)
	Patch.init(patch, slot)
	patch.hang = false
	patch:setCanvases()
	
	patch.resources.parameters = init_params()
	
  	-- balls
  	patch.nBalls = 200
  	patch.ballList = {}
  	-- generate balls
  	for i = 1, patch.nBalls do
    	addBall(screen.InternalRes.W / 2, screen.InternalRes.H / 2)
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
	patch:drawSetup()
  	-- draw balls
  	for k,b in pairs(patch.ballList) do
    	drawBall(b)
  	end
	return patch:drawExec()
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
	patch:mainUpdate()

	-- update balls
	for k, b in pairs(patch.ballList) do
		ballTrajectory(k, b)
	end
	-- re-order balls
	orderZ(patch.ballList)

end


function patch.commands(s)

end

return patch