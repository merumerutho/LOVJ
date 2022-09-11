palettes = require "lib/utils/palettes"
kp = require "lib/utils/keypress"
videoutils = require "lib/utils/video"

-- import pico8 palette
local PALETTE

patch = {}

--- @private init_params initialize patch parameters
local function init_params()
	g = resources.graphics
	p = resources.parameters

    g:setName(1, "video")           g:set("video", "data/demo_7/demo.ogg")
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
	patch.canvases.video = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)

	init_params()

    patch.video = {}
    patch.video.handle = love.graphics.newVideo(g:get("video"))
    patch.video.pos = 0
	patch.video.scaleX = screen.InternalRes.W / patch.video.handle:getWidth()
	patch.video.scaleY = screen.InternalRes.H / patch.video.handle:getHeight()
    patch.video.handle:play()
end

--- @private draw_bg draw background graphics
local function draw_stuff()
	g = resources.graphics
	p = resources.parameters

end

--- @public patch.draw draw routine
function patch.draw()
	g = resources.globals
	love.graphics.setColor(1,1,1,1)

	-- clear screen to colour
	patch.canvases.main:renderTo(function()
		local col = {timer.T*0.2 % 1, timer.T * 0.4 % 1, timer.T*0.1 % 1}
		love.graphics.clear(col)
	end )

	-- select shader and apply chroma keying
	local shader, chroma
	if cfg_shaders.enabled then shader = cfg_shaders.selectShader() end
	if cfg_shaders.enabled then
		chroma = love.graphics.newShader(shaders.chromakey)
		chroma:send("_chromaColor", g:get("_chromaColor"))
		chroma:send("_chromaTolerance", g:get("_chromaTolerance"))
	end
	-- set canvas
	love.graphics.setCanvas(patch.canvases.video)

	-- render graphics
	love.graphics.draw(patch.video.handle, 0, 0, 0, patch.video.scaleX, patch.video.scaleY)
	-- apply chroma keying
	if cfg_shaders.enabled then cfg_shaders.applyShader(chroma) end
	-- set main canvas
	love.graphics.setCanvas(patch.canvases.main)
	-- draw video w/ chroma keying
	love.graphics.draw(patch.canvases.video, 0, 0, 0, (1 / screen.Scaling.X), (1 / screen.Scaling.Y))

	-- apply shader
	if cfg_shaders.enabled then cfg_shaders.applyShader(shader) end
	-- select draw canvas
	love.graphics.setCanvas()
	-- draw all
	love.graphics.draw(patch.canvases.main, 0, 0, 0, (1 / screen.Scaling.X), (1 / screen.Scaling.Y))
	-- remove shader
	if cfg_shaders.enabled then cfg_shaders.applyShader() end
end


function patch.update()
    -- apply keyboard patch controls
    if not cmd.isOpen then patchControls() end

    -- handle loop
    videoutils.handleLoop(patch.video)

end

--- @public defaultDraw assigned to draw method by default
patch.defaultDraw = patch.draw

return patch