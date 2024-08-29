local Patch = lovjRequire ("lib/patch")
local palettes = lovjRequire ("lib/utils/palettes")
local screen = lovjRequire ("lib/screen")
local cfg_screen = lovjRequire("cfg/cfg_screen")
local kp = lovjRequire("lib/utils/keypress")
local cfg_timers = lovjRequire ("cfg/cfg_timers")
local cfg_shaders = lovjRequire ("cfg/cfg_shaders")
local Lfo = lovjRequire("lib/signals/lfo")

local PALETTE = palettes.BW

local patch = Patch:new()

local LAIN_WIDTH = 140
local LAIN_HEIGHT = 175

--- @private patchControls handle controls for current patch
function patch.patchControls()
	-- Hanger
	if love.keyboard.isDown("x") then patch.hang = true else patch.hang = false end
	-- Reset
	if love.keyboard.isDown("r") then patch.init(patch.slot) end
end

--- @private get_bg get background graphics based on patch.resources
local function get_bg()
	local g = patch.resources.graphics
	patch.graphics.bg = {}
	patch.graphics.bg.love = love.graphics.newImage(g:get("love"))
	patch.graphics.bg.size = {x = patch.graphics.bg.love:getPixelWidth(), y = patch.graphics.bg.love:getPixelHeight()}
	patch.graphics.bg.frames = {}
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
	local t = cfg_timers.globalTimer.T
	local dt = cfg_timers.globalTimer:dt() -- keep it fps independent
	local p = patch.resources.parameters

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
		addBall(p:get("sceneCenterX"), p:get("sceneCenterY"))
	end
end


--- @private get_bg get background graphics based on patch.resources
local function get_lain()
	local g = patch.resources.graphics
	patch.graphics.lain = {}
	patch.graphics.lain.image = love.graphics.newImage(g:get("lain"))
	patch.graphics.lain.size = {x = LAIN_WIDTH, y = LAIN_HEIGHT}
	patch.graphics.lain.frames = {}
	for i=0,patch.graphics.lain.image:getWidth() / LAIN_WIDTH do
		table.insert(patch.graphics.lain.frames, love.graphics.newQuad(	i*LAIN_WIDTH,				-- x
																		0,							-- y
																		LAIN_WIDTH,					-- width
																		LAIN_HEIGHT,				-- height
																		patch.graphics.lain.image))	-- img
	end
end


--- @private init_params Initialize parameters for this patch
local function init_params()
	local g = patch.resources.graphics
	local p = patch.resources.parameters

	patch.graphics = {}

	g:setName(1, "lain")		g:set("lain", "data/demo_12/lain.png")
	get_lain()

	g:setName(2, "love")		g:set("love", "data/graphics/love.png")
	get_bg()

	p:setName(1, "windowSize") 			p:set("windowSize", 0.6)
	p:setName(2, "showLain")			p:set("showLain", true)
	p:setName(3, "showLove")			p:set("showLove", true)
	p:setName(4, "drawOutsideEllipse")	p:set("drawOutsideEllipse", true)
	p:setName(5, "flash")				p:set("flash", true)

	p:setName(6, "sceneCenterX")		p:set("sceneCenterX", screen.InternalRes.W/2)
	p:setName(7, "sceneCenterY")		p:set("sceneCenterY", screen.InternalRes.H/2)
end

--- @public setCanvases (re)set canvases for this patch
function patch:setCanvases()
	Patch.setCanvases(patch)  -- call parent function
	-- patch-specific execution (window canvas)
	if cfg_screen.UPSCALE_MODE == cfg_screen.LOW_RES then
		patch.canvases.window = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
		patch.canvases.lain = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
		patch.canvases.love = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
	else
		patch.canvases.window = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
		patch.canvases.lain = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
		patch.canvases.love = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
	end
end


function patch.init(slot)
	Patch.init(patch, slot)
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
	init_params()
end


local function drawBall(b)
	local t = cfg_timers.globalTimer.T
  	local border_col = palettes.getColor(PALETTE, 2)
	local radius = (b.z/2) ^ 1.6
  	love.graphics.setColor(	border_col[1] / 255,
							border_col[2] / 255,
							border_col[3] / 255,
							1)
  	love.graphics.circle("line", b.x, b.y, radius, (b.z * 2) + 6)
  	-- filled circle
  	love.graphics.setColor(	0.4 * b.lifetime * b.c[1] / 255,
							0.3 * b.lifetime * b.c[2] / 255,
							0.3 * b.lifetime * b.c[3] / 255,
							1)
	love.graphics.circle("fill", b.x, b.y, radius, (b.z * 2) + 6)
	love.graphics.setColor(1,1,1,1)
end


function patch.draw()
	patch:drawSetup()

	local p = patch.resources.parameters
	local t = cfg_timers.globalTimer.T

	local scx, scy = p:get("sceneCenterX"), p:get("sceneCenterY")

	love.graphics.setCanvas(patch.canvases.love)

	if p:get("showLove") then
		local nX = math.ceil(screen.InternalRes.W / patch.graphics.bg.size.x)
		local nY = math.ceil(screen.InternalRes.H / patch.graphics.bg.size.y)

		if math.floor(t*10) % 3 == 0 then
			love.graphics.setColor(1,1,1,0.3)
			for cx = -1, nX do
				for cy = -1, nY do
					local x = cx * patch.graphics.bg.size.x + ((2 * (cy % 2)-1) * (t*50)) % patch.graphics.bg.size.x
					local y = cy * patch.graphics.bg.size.y
					love.graphics.draw(patch.graphics.bg.love, x, y)
				end
			end
		end
	else
		love.graphics.clear()
	end

	love.graphics.setCanvas(patch.canvases.window)
	if math.floor(t*10) % 3 == 0 then
		love.graphics.draw(patch.canvases.love)
	end

	-- draw balls
	for k,b in pairs(patch.ballList) do
		drawBall(b)
	end

	local alpha_pulse = patch.lfo:Sine(t)

	love.graphics.setColor(1,1,1, 1-math.abs(alpha_pulse))
	love.graphics.circle("line", scx, scy,
							alpha_pulse * screen.InternalRes.W/2, 3+math.ceil(t*10 % 5))
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

	if cfg_shaders.enabled and math.floor(t*10) % 3 ~=0 or (not p:get("drawOutsideEllipse")) then
		patch.shader_window = love.graphics.newShader(table.getValueByName("circlewindow", cfg_shaders.OtherShaders)) -- set/update circle window shader
		love.graphics.setShader(patch.shader_window) -- apply shader
		patch.shader_window:send("_windowSize", p:get("windowSize"))
		patch.shader_window:send("_scx", scx / screen.InternalRes.W)
		patch.shader_window:send("_scy", scy / screen.InternalRes.H)
		patch.canvases.main:renderTo(
			function()
				-- draw content of window buffer onto main buffer
				love.graphics.draw(patch.canvases.window,
									0, 0, 0, scalingX, scalingY)
				love.graphics.setShader() -- remove shader
				love.graphics.setColor(1,1,1,math.abs(math.sin(t)))
				love.graphics.ellipse("line", scx, scy,
										screen.InternalRes.W * (1-p:get("windowSize")),
										screen.InternalRes.H * (1-p:get("windowSize")),
										math.ceil(3+32*(1-p:get("windowSize"))))
			end)
	else
		love.graphics.setCanvas(patch.canvases.main)
		love.graphics.draw(patch.canvases.window, 0, 0, 0, scalingX, scalingY)
	end

	-- force selection of main canvas
	love.graphics.setCanvas(patch.canvases.main)

	-- draw lain
	if p:get("showLain") then
		love.graphics.setColor(1,1,1,math.abs(math.sin(t*5)))
		love.graphics.draw(patch.graphics.lain.image, patch.graphics.lain.frames[math.floor(t*5) % 21 + 1],
				LAIN_WIDTH*0.75, 10, 0, -0.75, 0.75)

		love.graphics.draw(patch.graphics.lain.image, patch.graphics.lain.frames[math.floor(t*5) % 21 + 1],
				screen.InternalRes.W - LAIN_WIDTH*0.75, 10, 0, 0.75, 0.75)
	end

	-- remove canvas
	love.graphics.setCanvas()

	-- draw flash
	if math.floor(t*5) % 20 == 0 and p:get("flash") then
		love.graphics.rectangle("fill", 0, 0, screen.ExternalRes.W, screen.ExternalRes.H)
	end

	love.graphics.setColor(1,1,1,1)

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

	local p = patch.resources.parameters

	-- update balls
	for k, b in pairs(patch.ballList) do
		ballTrajectory(k, b)
	end
	
	-- re-order balls
	orderZ(patch.ballList)

	patch.lfo:UpdateTrigger(true)

	if kp.isDown("x") then
		if kp.isDown("up") then p:set("sceneCenterX", p:get("sceneCenterX")+1) end
		if kp.isDown("down") then p:set("sceneCenterX", p:get("sceneCenterX")-1) end
	elseif kp.isDown("y") then
		if kp.isDown("up") then p:set("sceneCenterY", p:get("sceneCenterY")+1) end
		if kp.isDown("down") then p:set("sceneCenterY", p:get("sceneCenterY")-1) end
	else
		if kp.isDown("up") then p:set("windowSize", p:get("windowSize")+.01) end
		if kp.isDown("down") then p:set("windowSize", p:get("windowSize")-.01) end
	end

	if kp.keypressOnRelease("q") then p:set("showLain", not p:get("showLain")) end
	if kp.keypressOnRelease("w") then p:set("showLove", not p:get("showLove")) end
	if kp.keypressOnRelease("e") then p:set("drawOutsideEllipse", not p:get("drawOutsideEllipse")) end
	if kp.keypressOnRelease("t") then p:set("flash", not p:get("flash")) end

	-- clamp colorInversion between 0 and 1
	p:set("windowSize", math.min(math.max(p:get("windowSize"), 0), 1) )

end


function patch.commands(s)

end

return patch