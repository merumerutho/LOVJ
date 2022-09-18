local Patch = require "lib/patch"
local palettes = require "lib/utils/palettes"
local kp = require "lib/utils/keypress"

-- import pico8 palette
local PALETTE

patch = Patch:new()

--- @private init_params initialize patch parameters
local function init_params()
	g = resources.graphics
	p = resources.parameters

    -- insert here your patch parameters
end

--- @public patchControls evaluate user keyboard controls
function patch.patchControls()
	p = resources.parameters

    -- insert here your patch controls
end


--- @public init init routine
function patch.init()
	PALETTE = palettes.PICO8

	patch:setCanvases()

	init_params()

	patch:assignDefaultDraw()
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
	love.graphics.draw(patch.canvases.main, 0, 0, 0, screen.Scaling.X, screen.Scaling.Y)
	-- remove shader
	if cfg_shaders.enabled then cfg_shaders.applyShader() end
	love.graphics.draw(patch.canvases.cmd, 0, 0, 0, screen.Scaling.X, screen.Scaling.Y)
end


function patch.update()
	-- apply keyboard patch controls
	if not cmd.isOpen then patch.patchControls() end
	return
end

return patch