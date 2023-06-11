local Patch = lovjRequire ("lib/patch")
local palettes = lovjRequire ("lib/utils/palettes")
local screen = lovjRequire ("lib/screen")
local cfg_screen = lovjRequire("lib/cfg/cfg_screen")
local kp = lovjRequire("lib/utils/keypress")
local cfg_timers = lovjRequire ("lib/cfg/cfg_timers")
local shaders = lovjRequire("lib/shaders")
local Lfo = lovjRequire("lib/automations/lfo")

local PALETTE = palettes.BW

patch = Patch:new()

local ROACH_WIDTH = 128
local ROACH_HEIGHT = 165
local NUM_FRAMES_ROACH = 35

--- @private patchControls handle controls for current patch
function patch.patchControls()
	-- Hanger
	if love.keyboard.isDown("x") then patch.hang = true else patch.hang = false end
	-- Reset
	if love.keyboard.isDown("r") then patch.init() end
end

--- @private get_roach get roach :)
local function get_roach()
	local g = resources.graphics
	patch.graphics.roach = {}
	patch.graphics.roach.image = love.graphics.newImage(g:get("roach"))
	patch.graphics.roach.size = {x = ROACH_WIDTH, y = ROACH_HEIGHT}
	patch.graphics.roach.frames = {}
	for i=0,patch.graphics.roach.image:getWidth() / ROACH_WIDTH do
		table.insert(patch.graphics.roach.frames, love.graphics.newQuad(	i*ROACH_WIDTH,				-- x
																		0,							-- y
																		ROACH_WIDTH,					-- width
																		ROACH_HEIGHT,				-- height
																		patch.graphics.roach.image))	-- img
	end
end


--- @private init_params Initialize parameters for this patch
local function init_params()
	local g = resources.graphics
	local p = resources.parameters

	patch.graphics = {}

	g:setName(1, "roach")		g:set("roach", "data/graphics/cockroach.png")
	get_roach()

	g:setName(2, "love")		g:set("love", "data/graphics/love.png")

	p:setName(1, "windowSize") 			p:set("windowSize", 0.6)
	p:setName(2, "showRoach")			p:set("showRoach", true)
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
		patch.canvases.roach = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
		patch.canvases.love = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
	else
		patch.canvases.window = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
		patch.canvases.roach = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
		patch.canvases.love = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
	end
end


function patch.init()
	patch.hang = false
	patch:setCanvases()
	
  	-- Lfo
	patch.lfo = Lfo:new(0.1, 0) -- frequency = 1, phase = 0

	patch:assignDefaultDraw()
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

	local p = resources.parameters
	local t = cfg_timers.globalTimer.T

	local scx, scy = p:get("sceneCenterX"), p:get("sceneCenterY")

	-- force selection of main canvas
	love.graphics.setCanvas(patch.canvases.main)

	local n = 20
	local scaling = 0.1
	local roachScaleW = scaling * ROACH_WIDTH
	local roachScaleH = scaling * ROACH_HEIGHT

	for i = -1, n do
		for j = -2, n do
			--love.graphics.setColor(.5+.5*math.sin(t),.5+.5*math.sin(t*3),.5+.5*math.sin(t*2),math.sin((2*math.pi)*(t+i/10+j/10)))
			love.graphics.draw(patch.graphics.roach.image, patch.graphics.roach.frames[math.floor(t*25 + j + i) % NUM_FRAMES_ROACH + 1],
					(screen.InternalRes.W / n)*i , (screen.InternalRes.H / n)*j, 0, scaling, scaling)
		end
	end

	love.graphics.setColor(.5+.5*math.sin((2*math.pi)*t),.5+.5*math.sin((2*math.pi)*(t+.3333)),.5+.5*math.sin((2*math.pi)*(t+.6666)),1)
	-- draw roach
	if p:get("showRoach") then
		love.graphics.draw(patch.graphics.roach.image, patch.graphics.roach.frames[math.floor(t*25) % NUM_FRAMES_ROACH + 1],
				screen.InternalRes.W/2+ROACH_WIDTH*0.75/2, 10, 0, -0.75, 0.75)

		--	love.graphics.draw(patch.graphics.roach.image, patch.graphics.roach.frames[math.floor(t*25) % NUM_FRAMES_ROACH + 1],
		--			screen.InternalRes.W - ROACH_WIDTH*0.75, 10, 0, 0.75, 0.75)
	end

	-- remove canvas
	love.graphics.setCanvas()

	love.graphics.setColor(1,1,1,1)

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
	local p = resources.parameters
	patch:mainUpdate()

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

	if kp.keypressOnRelease("q") then p:set("showRoach", not p:get("showRoach")) end
	if kp.keypressOnRelease("w") then p:set("showLove", not p:get("showLove")) end
	if kp.keypressOnRelease("e") then p:set("drawOutsideEllipse", not p:get("drawOutsideEllipse")) end
	if kp.keypressOnRelease("t") then p:set("flash", not p:get("flash")) end

	-- clamp colorInversion between 0 and 1
	p:set("windowSize", math.min(math.max(p:get("windowSize"), 0), 1) )

end


function patch.commands(s)

end

return patch