palettes = require "lib/utils/palettes"
kp = require "lib/utils/keypress"

local hang
local BG_SPRITE_SIZE = 8

patch = {}

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

--- @private patchControls evaluate user keyboard controls
local function patchControls()
	p = resources.parameters
	-- Hanger
	if kp.isDown("x") then hang = true else hang = false end
end


--- @public init init routine
function patch.init()
	PALETTE = palettes.PICO8
	hang = false

	patch.canvases = {}
	patch.canvases.main = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)

	init_params()
end

--- @private draw_bg draw background graphics
local function draw_bg()
	g = resources.graphics
	p = resources.parameters

	local idx = (math.floor(timer.T * p:get("bgSpeed") ) % (patch.graphics.bg.image:getWidth() / BG_SPRITE_SIZE) ) + 1
	for x = -patch.graphics.bg.size.x, screen.InternalRes.W, patch.graphics.bg.size.x do
		for y = -patch.graphics.bg.size.y, screen.InternalRes.H, patch.graphics.bg.size.y do
			local lx = x + (timer.T*20)% BG_SPRITE_SIZE
			local ly = y + (timer.T*10)% BG_SPRITE_SIZE
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
	love.graphics.setColor(1,1,1,1)

	local shader
	if cfg_shaders.enabled then shader = cfg_shaders.selectShader() end

	-- set canvas
	love.graphics.setCanvas(patch.canvases.main)
	-- clear main canvas
	patch.canvases.main:renderTo(function()
									love.graphics.clear(1,1,1,1)
								end )

	-- draw picture
	draw_bg()

	-- remove canvas
	love.graphics.setCanvas()
	-- apply shader
	if cfg_shaders.enabled then cfg_shaders.applyShader(shader) end
	-- render graphics
	love.graphics.draw(patch.canvases.main, 0, 0, 0, (1 / screen.Scaling.X), (1 / screen.Scaling.Y))
	-- remove shader
	if cfg_shaders.enabled then cfg_shaders.applyShader() end
end


function patch.update()
	-- apply keyboard patch controls
	if not cmd.isOpen then patchControls() end
	return
end

--- @public defaultDraw assigned to draw method by default
patch.defaultDraw = patch.draw

return patch