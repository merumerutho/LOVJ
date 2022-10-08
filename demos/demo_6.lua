local Patch = lovjRequire("lib/patch")
local palettes = lovjRequire("lib/utils/palettes")
local kp = lovjRequire("lib/utils/keypress")
local Timer = lovjRequire("lib/timer")
local cfg_timers = lovjRequire("lib/cfg/cfg_timers")


local BG_SPRITE_SIZE = 8

patch = Patch:new()

--- @private get_bg get background graphics based on resources
local function get_bg()
	patch.graphics = {}
	patch.graphics.bg = {}
	patch.graphics.bg.image = love.graphics.newImage(g:get("bg"))
	patch.graphics.bg.size = {x = BG_SPRITE_SIZE, y = BG_SPRITE_SIZE}
	patch.graphics.bg.frames = {}
	for i=0,patch.graphics.bg.image:getWidth() / BG_SPRITE_SIZE do
		table.insert(patch.graphics.bg.frames, love.graphics.newQuad(	i*BG_SPRITE_SIZE,			-- x
																		0,							-- y
																		BG_SPRITE_SIZE,				-- width
																		BG_SPRITE_SIZE,				-- height
																		patch.graphics.bg.image))	-- img
	end
end

--- @private init_params initialize patch parameters
local function init_params()
	g = resources.graphics
	p = resources.parameters
	g:setName(1, "bg")				g:set("bg", "data/demo_6/bg.png")
	get_bg()
	p:setName(1, "bgSpeed")			p:set("bgSpeed", 10)
end

--- @public patchControls evaluate user keyboard controls
function patch.patchControls()
	p = resources.parameters
	-- Hanger
	if kp.isDown("x") then patch.hang = true else patch.hang = false end
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

	local idx = (math.floor(t * p:get("bgSpeed") ) % (patch.graphics.bg.image:getWidth() / BG_SPRITE_SIZE) ) + 1
	for x = -patch.graphics.bg.size.x, screen.InternalRes.W, patch.graphics.bg.size.x do
		for y = -patch.graphics.bg.size.y, screen.InternalRes.H, patch.graphics.bg.size.y do
			local lx = x + (t*20)% BG_SPRITE_SIZE
			local ly = y + (t*10)% BG_SPRITE_SIZE
			local rx = (lx - screen.InternalRes.W / 2)
			local ry = (ly - screen.InternalRes.H / 2)
			local rIdx = math.floor((idx + math.sqrt((rx*rx) + (ry*ry)) / 10)
									% (patch.graphics.bg.image:getWidth() / BG_SPRITE_SIZE )) + 1
			love.graphics.draw(patch.graphics.bg.image, patch.graphics.bg.frames[rIdx], lx, ly)
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
	patch:mainUpdate()
end

return patch