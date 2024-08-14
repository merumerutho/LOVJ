local Patch = lovjRequire ("lib/patch")
local screen = lovjRequire ("lib/screen")
local cfg_screen = lovjRequire("cfg/cfg_screen")
local cfg_timers = lovjRequire ("cfg/cfg_timers")

local patch = Patch:new()

local ROACH_WIDTH = 128
local ROACH_HEIGHT = 165
local NUM_FRAMES_ROACH = 35

local PALETTE

--- @private patchControls handle controls for current patch
function patch.patchControls()
	-- Hanger
	if love.keyboard.isDown("x") then patch.hang = true else patch.hang = false end
	-- Reset
	if love.keyboard.isDown("r") then patch.init(patch.slot) end
end

--- @private get_roach get roach :)
local function get_roach()
	local g = patch.resources.graphics
	patch.graphics.roach = {}
	patch.graphics.roach.image = love.graphics.newImage(g:get("roach"))
	patch.graphics.roach.size = {x = ROACH_WIDTH, y = ROACH_HEIGHT}
	patch.graphics.roach.frames = {}
	for i=0,patch.graphics.roach.image:getWidth() / ROACH_WIDTH do
		table.insert(patch.graphics.roach.frames, love.graphics.newQuad(i*ROACH_WIDTH,					-- x
																		0,								-- y
																		ROACH_WIDTH,					-- width
																		ROACH_HEIGHT,					-- height
																		patch.graphics.roach.image))	-- img
	end
end


--- @private init_params Initialize parameters for this patch
local function init_params()
	local g = patch.resources.graphics
	local p = patch.resources.parameters

	patch.graphics = {}

	g:setName(1, "roach")				g:set("roach", "data/graphics/cockroach.png")
	get_roach()

	g:setName(2, "love")				g:set("love", "data/graphics/love.png")

	p:setName(1, "windowSize") 			p:set("windowSize", 0.6)
	p:setName(2, "showRoach")			p:set("showRoach", true)
	p:setName(3, "showLove")			p:set("showLove", true)
	p:setName(4, "drawOutsideEllipse")	p:set("drawOutsideEllipse", true)
	p:setName(5, "flash")				p:set("flash", true)

	p:setName(6, "sceneCenterX")		p:set("sceneCenterX", screen.InternalRes.W/2)
	p:setName(7, "sceneCenterY")		p:set("sceneCenterY", screen.InternalRes.H/2)

	patch.resources.parameters = p
	patch.resources.graphics = g
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


function patch.init(slot)
	Patch.init(patch, slot)
	patch.hang = false
	patch:setCanvases()

	init_params()
end


function patch.draw()
	patch:drawSetup()

	local p = patch.resources.parameters
	local t = cfg_timers.globalTimer.T

	love.graphics.setCanvas(patch.canvases.main)

	-- background roaches stuff
	local n = 20
	local scaling = 0.1

	-- draw background
	for i = -1, n do
		for j = -1, n do
			love.graphics.draw(patch.graphics.roach.image,
								patch.graphics.roach.frames[math.floor(t*25 + j + i) % NUM_FRAMES_ROACH + 1],
								(screen.InternalRes.W / n)*i,
								(screen.InternalRes.H / n)*j,
								0,
								scaling,
								scaling)
		end
	end

	-- Hue rotation
	love.graphics.setColor(.5+.5*math.sin((2*math.pi)*t),.5+.5*math.sin((2*math.pi)*(t+.3333)),.5+.5*math.sin((2*math.pi)*(t+.6666)),1)

	-- Draw main roach
	if p:get("showRoach") then
		love.graphics.draw(patch.graphics.roach.image,
							patch.graphics.roach.frames[math.floor(t*25) % NUM_FRAMES_ROACH + 1],
							screen.InternalRes.W/2+ROACH_WIDTH*0.75/2,
							10,
							0,
							-0.75,
							0.75)
	end

	-- remove canvas
	love.graphics.setCanvas()
	-- reset color
	love.graphics.setColor(1,1,1,1)

	return patch:drawExec()
end


function patch.update()
	patch:mainUpdate()
end


function patch.commands(s)

end

return patch