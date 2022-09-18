palettes = require "lib/utils/palettes"
kp = require "lib/utils/keypress"

-- import pico8 palette
local PALETTE = palettes.TIC80

patch = {}

--- @public setCanvases (re)set canvases for this patch
function patch.setCanvases()
	patch.canvases = {}
	if screen_settings.UPSCALE_MODE == screen_settings.LOW_RES then
		patch.canvases.main = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
	else
		patch.canvases.main = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
	end
end

--- @private init_params initialize patch parameters
local function init_params()
	g = resources.graphics
	p = resources.parameters

	p:setName(1, "speed")		p:set("speed", 100)

end

--- @private patchControls evaluate user keyboard controls
local function patchControls()
	p = resources.parameters

    -- insert here your patch controls
end


--- @public init init routine
function patch.init()

	patch.setCanvases()

	init_params()
end

--- @private draw_bg draw background graphics
local function draw_stuff()
	g = resources.graphics
	p = resources.parameters

	local w = screen.InternalRes.W
	local h = screen.InternalRes.H

	local gap = 0.225 * screen.InternalRes.H + 20 + 16*math.sin(timer.T/8)

	love.graphics.setColor(0,0,0,1)

	for x = 16, 16*16, 16 do
		local ly = gap - 8*32*16 / (x - timer.T * p:get("speed") % 16)
		love.graphics.line(0, ly, w, ly)
		love.graphics.line(0, h - ly, w, h - ly)
	end

	-- horizon must be always present
	local ly = gap - 8*32*16 / (16*16)
	love.graphics.line(0, ly, w, ly)
	love.graphics.line(0, h - ly, w, h - ly)

	local n = screen.InternalRes.W / 5
	local spacing = screen.InternalRes.W / 320 + 1

	for x = -n, n, spacing do
		love.graphics.line(w/2 - 4*x + 50*math.sin(timer.T/2), gap - 16,
							w/2 - 24*x + 50*math.sin(timer.T/2), -16)
		love.graphics.line(w/2 - 4*x + 50*math.sin(timer.T/2), h - gap + 16,
							w/2 - 24*x + 50*math.sin(timer.T/2), h + 16)
	end

	love.graphics.setColor(1,1,1,1)
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
end


function patch.update()
	-- apply keyboard patch controls
	if not cmd.isOpen then patchControls() end
	return
end

--- @public defaultDraw assigned to draw method by default
patch.defaultDraw = patch.draw

return patch