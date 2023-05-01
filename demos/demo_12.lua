local Patch = lovjRequire ("lib/patch")
local palettes = lovjRequire ("lib/utils/palettes")
local screen = lovjRequire ("lib/screen")
local Timer = lovjRequire ("lib/timer")
local cfg_timers = lovjRequire ("lib/cfg/cfg_timers")

local PALETTE = palettes.BW

patch = Patch:new()

--- @private patchControls handle controls for current patch
function patch.patchControls()
	-- Hanger
	if love.keyboard.isDown("x") then patch.hang = true else patch.hang = false end
	-- Reset
	if love.keyboard.isDown("r") then patch.init() end
end


local function addBall(sx, sy)
	ball = {}
  -- ball starting position
	ball.x = sx
	ball.y = sy
  -- ball z-depth (radius)
	ball.z = math.random()
  -- ball color
	ball.c = palettes.getColor(PALETTE, 2)
  -- ball direction is binary
	ball.dx = (-1) ^ (1+math.random(2)) * 0.1
	ball.dy = (-1) ^ (1+math.random(2)) * 0.1
  -- ball speed 
	ball.ax = ball.dx * ((math.random())*3 + 0.05)
	ball.ay = ball.dy * ((math.random())*3 + 0.05 - ball.dx * ball.ax / 10)
  	ball.az = (math.abs(ball.ax) + math.abs(ball.ay))
  	-- readjust ay
  	ball.ax = (ball.ax / ball.dx - ball.dy * ball.ay / 10) * ball.dx
	ball.lifetime = 150+math.random(300)
  	-- add ball to list
	table.insert(patch.ballList, ball)
end


local function ballTrajectory(k, b)
	local dt = cfg_timers.globalTimer:dt() -- keep it fps independent

	b.x = b.x + b.ax 		 * dt * 50
	b.y = b.y + b.ay 		 * dt * 50
	b.z = b.z + 0.025 * b.az * dt * 50
  
	if b.z < 0 then b.z = 0 end

	-- Decrease lifetime
	b.lifetime = b.lifetime-1

	if (b.lifetime <= 0) then

		table.remove(patch.ballList, k)
		local cx = screen.InternalRes.W / 2 - screen.InternalRes.W/5 + math.random(2/5*screen.InternalRes.W)
		local cy = screen.InternalRes.H / 2 - screen.InternalRes.H/5 + math.random(2/5*screen.InternalRes.H)
		addBall(cx, cy)
	end
end


--- @private init_params Initialize parameters for this patch
local function init_params()
	p = resources.parameters
end


function patch.init()
	patch.hang = false
	patch:setCanvases()
	
  	-- balls
  	patch.nBalls = 500
  	patch.ballList = {}
  	-- generate balls
  	for i = 1, patch.nBalls do
		local cx = screen.InternalRes.W / 2 - screen.InternalRes.W/5 + math.random(2/5*screen.InternalRes.W)
		local cy = screen.InternalRes.H / 2 - screen.InternalRes.H/5 + math.random(2/5*screen.InternalRes.H)
		addBall(cx, cy)
  	end

	patch:assignDefaultDraw()
end


local function drawBall(b)
  	local border_col = palettes.getColor(PALETTE, 2)
  	love.graphics.setColor(	border_col[1] / 255,
							border_col[2] / 255,
							border_col[3] / 255,
							1)
  	love.graphics.circle("line", b.x, b.y, (b.z / 2) ^ 1.6, (b.z * 2) + 6)
  	-- filled circle
  	love.graphics.setColor(	0.3 * b.lifetime * b.c[1] / 255,
							0.3 * b.lifetime * b.c[2] / 255,
							0.3 * b.lifetime * b.c[3] / 255,
							1)
	love.graphics.circle("fill", b.x, b.y, (b.z / 2) ^ 1.6, (b.z * 2) + 6)
	love.graphics.setColor(1,1,1,1)
end


function patch.draw()
	patch:drawSetup()
  	-- draw balls
  	for k,b in pairs(patch.ballList) do
    	drawBall(b)
  	end
	patch:drawExec()
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