local Patch = lovjRequire ("lib/patch")
local palettes = lovjRequire ("lib/utils/palettes")
local screen = lovjRequire ("lib/screen")
local cfg_screen = lovjRequire("lib/cfg/cfg_screen")
local Timer = lovjRequire ("lib/timer")
local cfg_timers = lovjRequire ("lib/cfg/cfg_timers")
local shaders = lovjRequire("lib/shaders")
local Lfo = lovjRequire("lib/automations/lfo")

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

--- @public setCanvases (re)set canvases for this patch
function patch:setCanvases()
	Patch.setCanvases(patch)  -- call parent function
	-- patch-specific execution (window canvas)
	if cfg_screen.UPSCALE_MODE == cfg_screen.LOW_RES then
		patch.canvases.window = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
	else
		patch.canvases.window = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
	end
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

	-- Lfo
	patch.lfo = Lfo:new(0.1, 0) -- frequency = 1, phase = 0

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

	love.graphics.setCanvas(patch.canvases.window)
	-- draw balls
	for k,b in pairs(patch.ballList) do
		drawBall(b)
	end

	local t = cfg_timers.globalTimer.T
	local alpha_pulse = patch.lfo:Sine(t)

	love.graphics.setColor(1,1,1, 1-math.abs(alpha_pulse))
	love.graphics.circle("line", screen.InternalRes.W/2, screen.InternalRes.H/2,
							alpha_pulse * screen.InternalRes.W/2)
	love.graphics.setColor(1,1,1,1)

	local scalingX
	local scalingY

	if cfg_screen.UPSCALE_MODE == cfg_screen.LOW_RES then
		scalingX = 1
		scalingY = 1
	else
		scalingX = screen.Scaling.X
		scalingY = screen.Scaling.Y
	end

	if cfg_shaders.enabled then
		patch.shader_window = love.graphics.newShader(shaders.circleWindow) -- set/update circle window shader
		love.graphics.setShader(patch.shader_window) -- apply shader
		patch.canvases.main:renderTo(
			function()
				-- draw content of window buffer onto main buffer
				love.graphics.draw(patch.canvases.window,
						0, 0, 0, scalingX, scalingY)
				love.graphics.setShader() -- remove shader

			end)
	else
		love.graphics.setCanvas(patch.canvases.main)
		love.graphics.draw(patch.canvases.window, 0, 0, 0, scalingX, scalingY)
	end

	-- remove canvas
	love.graphics.setCanvas()
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

	patch.lfo:UpdateTrigger(true)

end


function patch.commands(s)

end

return patch