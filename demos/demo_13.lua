local Patch = lovjRequire("lib/patch")
local palettes = lovjRequire("lib/utils/palettes")
local kp = lovjRequire("lib/utils/keypress")
local Timer = lovjRequire("lib/timer")
local cfg_timers = lovjRequire("lib/cfg/cfg_timers")

patch = Patch:new()

--- @private get_bg get background graphics based on resources
local function get_bg()
	patch.graphics = {}
	patch.graphics.bg = {}
	patch.graphics.bg.nasty = love.graphics.newImage(g:get("nasty"))
	patch.graphics.bg.hot = love.graphics.newImage(g:get("hot"))
	patch.graphics.bg.image = patch.graphics.bg.nasty
	patch.graphics.bg.size = {x = patch.graphics.bg.image:getPixelWidth(), y = patch.graphics.bg.image:getPixelHeight()}
	patch.graphics.bg.frames = {}
end

--- @private init_params initialize patch parameters
local function init_params()
	g = resources.graphics
	p = resources.parameters
	g:setName(1, "nasty")				g:set("nasty", "data/graphics/nasty.png")
	g:setName(2, "hot")					g:set("hot", "data/graphics/hot.png")
	get_bg()
	p:setName(1, "bgSpeed")				p:set("bgSpeed", 10)
	p:setName(2, "bgLayer1")			p:set("bgLayer1", 1)
	p:setName(3, "bgLayer2")			p:set("bgLayer2", 1)
	p:setName(4, "bgLayer3")			p:set("bgLayer3", 1)
end

--- @public patchControls evaluate user keyboard controls
function patch.patchControls()
	p = resources.parameters
	-- Hanger
	if kp.isDown("x") then patch.hang = true else patch.hang = false end

	if kp.keypressOnRelease("1") then p:set("bgLayer1", (1-p:get("bgLayer1"))) end
	if kp.keypressOnRelease("2") then p:set("bgLayer2", (1-p:get("bgLayer2"))) end
	if kp.keypressOnRelease("3") then p:set("bgLayer3", (1-p:get("bgLayer3"))) end
end


--- @public init init routine
function patch.init()
	PALETTE = palettes.PICO8

	patch:setCanvases()

	init_params()

	patch:assignDefaultDraw()
end

--- @private draw_bg draw background graphics
local function draw_bg()
	local t = cfg_timers.globalTimer.T

	g = resources.graphics
	p = resources.parameters

	cx = 0
	cy = 0

	local nX = math.ceil(screen.InternalRes.W / patch.graphics.bg.size.x)
	local nY = math.ceil(screen.InternalRes.H / patch.graphics.bg.size.y)

	love.graphics.setColor(0,0,0,1)
	love.graphics.rectangle("fill", 0, 0, screen.ExternalRes.W, screen.ExternalRes.H)
	love.graphics.setColor(1,1,1,1)

	for cx = -1, nX do
		for cy = -1, nY do
			local x = cx * patch.graphics.bg.size.x + ((2 * (cy % 2)-1) * (t*20)) % patch.graphics.bg.size.x
			local y = cy * patch.graphics.bg.size.y
			if p:get("bgLayer1") == 1 and math.floor(t*10) % 5 == 0 then
				love.graphics.setColor(1, (cy+1)/(nY+1), (cy+1)/(nY+1), 0.7)
				love.graphics.draw(patch.graphics.bg.image, x, y)
			end
			if p:get("bgLayer2") == 1 and math.floor(t*10) % 5 == 0 then
				love.graphics.setColor((cy+1)/(nY+1), 1, (cy+1)/(nY+1), 0.5)
				love.graphics.draw(patch.graphics.bg.image, x+1, y)
			end
			if p:get("bgLayer3") == 1 and math.floor(t*10) % 5 == 0 then
				love.graphics.setColor((cy+1)/(nY+1), (cy+1)/(nY+1), 1, 0.4)
				love.graphics.draw(patch.graphics.bg.image, x, y-1)
			end
		end
	end

end

--- @public patch.draw draw routine
function patch.draw()
	patch:drawSetup(hang)

	-- clear main canvas
	patch.canvases.main:renderTo(function()
									love.graphics.clear(1,1,1,1)
								end )

	-- draw picture
	draw_bg()

	patch:drawExec()
end


function patch.update()
	local t = cfg_timers.globalTimer.T

	if math.floor(t) % 2 == 0 then
		patch.graphics.bg.image = patch.graphics.bg.nasty
		patch.graphics.bg.size = {x = patch.graphics.bg.image:getPixelWidth(), y = patch.graphics.bg.image:getPixelHeight()}
	else
		patch.graphics.bg.image = patch.graphics.bg.hot
		patch.graphics.bg.size = {x = patch.graphics.bg.image:getPixelWidth(), y = patch.graphics.bg.image:getPixelHeight()}
	end

	patch:mainUpdate()
end


function patch.commands(s)

end

return patch