palettes = require "lib/utils/palettes"
kp = require "lib/utils/keypress"

-- import pico8 palette
local PALETTE

patch = {}

local function get_bg()
	patch.graphics = {}
	patch.graphics.bg = {}
	patch.graphics.bg.image = love.graphics.newImage(g:get("bg"))
	patch.graphics.bg.size = {x = 8, y = 8}
	patch.graphics.bg.frames = {}
	for i=0,3 do
		table.insert(patch.graphics.bg.frames, love.graphics.newQuad(i*8, 0, 8, 8, patch.graphics.bg.image))
	end
end


local function init_params()
	g = resources.graphics
	p = resources.parameters
	g:setName(1, "bg")				g:set("bg", "data/demo_6/bg.png")
	get_bg()
	p:setName(1, "bgSpeed")			p:set("bgSpeed", 3)
end


function patch.patchControls()
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


local function draw_bg()
	g = resources.graphics
	p = resources.parameters

	local idx = (math.floor(timer.T * p:get("bgSpeed") ) % (patch.graphics.bg.image:getWidth() / 8) ) + 1
	for x = 0, screen.InternalRes.W, patch.graphics.bg.size.x do
		for y = 0, screen.InternalRes.H, patch.graphics.bg.size.y do
			love.graphics.draw(patch.graphics.bg.image, patch.graphics.bg.frames[idx], x, y)
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
	if not cmd.isOpen then patch.patchControls() end
	return
end

--- @public defaultDraw assigned to draw method by default
patch.defaultDraw = patch.draw

return patch