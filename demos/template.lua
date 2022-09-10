palettes = require "lib/utils/palettes"
kp = require "lib/utils/keypress"

-- import pico8 palette
local PALETTE

patch = {}

--- @private init_params initialize patch parameters
local function init_params()
	g = resources.graphics
	p = resources.parameters

    -- insert here your patch parameters
end

--- @private patchControls evaluate user keyboard controls
local function patchControls()
	p = resources.parameters

    -- insert here your patch controls
end


--- @public init init routine
function patch.init()
	PALETTE = palettes.PICO8

	patch.canvases = {}
	patch.canvases.main = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)

	init_params()
end

--- @private draw_bg draw background graphics
local function draw_stuff()
	g = resources.graphics
	p = resources.parameters

    -- insert here your draw routine
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
	draw_stuff()

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