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
	love.graphics.setColor(1,1,1,1)

	love.graphics.setCanvas(patch.canvases.main)
	-- render graphics
	love.graphics.draw(patch.video.handle, 0, 0, 0, patch.video.scaleX, patch.video.scaleY)

	love.graphics.setCanvas()
	love.graphics.draw(patch.canvases.main, 0, 0, 0, (1 / screen.Scaling.X), (1 / screen.Scaling.Y))
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