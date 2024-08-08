-- Regular requirements
require("lib/utils/tableExtensions")
debug = require("debug")
lick = require("lib/lick")
requirements = require("lib/utils/require")
version = require("lib/cfg/cfg_version")

--
log = lovjRequire("lib/utils/logging")
logging.setLogLevel({ logging.LOG_ERROR,
					  logging.LOG_INFO })

screen = lovjRequire("lib/screen")
timer = lovjRequire("lib/timer")
ResourceList = lovjRequire("lib/resources")
controls = lovjRequire("lib/controls")
connections = lovjRequire("lib/connections")
dispatcher = lovjRequire("lib/dispatcher")
spout = lovjRequire("lib/spout")

cfgPatches = lovjRequire("lib/cfg/cfg_patches")
cfgShaders = lovjRequire("lib/cfg/cfg_shaders")
cfgTimers = lovjRequire("lib/cfg/cfg_timers")

drawingUtils = lovjRequire("lib/utils/drawing")

-- Set title with LOVJ version
love.window.setTitle("LOVJ v" ..  version)

local downMixCanvas

--- @public love.load
--- this function is called upon startup
function love.load()
	screen.init()  -- Init screen
	cfgTimers.init()  -- Init timers

	-- Set two running patches
	patchSlots = {}
	for i=1,#cfgPatches.defaultPatch do
		table.insert(patchSlots, {name = cfgPatches.defaultPatch[i]})
	end
	for i=1, #patchSlots do
		patchSlots[i].patch = lovjRequire(patchSlots[i].name, lick.PATCH_RESET)
	end

	-- global setting resources
	globalSettings = ResourceList:newResource()

	-- Initialize patches
	for i, slot in ipairs(patchSlots) do
		slot.shaderext = ResourceList:newResource()
		cfgShaders.initShaderExt(i)  -- Assign Shaders globals
        slot.patch.init(i, globalSettings, slot.shaderext)  -- Init actual patch for this patch slot
    end

	connections.init()  -- Init socket
	spout.init()

	downMixCanvas = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
end


--- @public love.draw
--- this function is called upon each draw cycle
function love.draw()
	
	-- Clear downmix canvas
	drawingUtils.clearCanvas(downMixCanvas)

	-- Clear main screen
	drawingUtils.clearCanvas(nil)

	local scaleX, scaleY
	-- Set upscale
	if screen.isUpscalingHiRes() then
		love.graphics.scale(screen.Scaling.RatioX, screen.Scaling.RatioY)
		scaleX, scaleY = screen.Scaling.X, screen.Scaling.Y
	else
		scaleX, scaleY = 1, 1
	end

	-- Draw all patches stacked on top of each other
	for i=1, #patchSlots do
		local canvas = patchSlots[i].patch.draw()  -- this function may change currently set canvas
		-- draw canvas to downmix
		downMixCanvas = drawingUtils.drawCanvasToCanvas(canvas, downMixCanvas, 0, 0, 0, scaleX, scaleY)
		-- clean canvas after using it
		drawingUtils.clearCanvas(canvas)
	end
	
	-- Spout
	spout.SendCanvas(downMixCanvas, screen.InternalRes.W, screen.InternalRes.H)
	
	-- draw downmix to main screen
	drawingUtils.drawCanvasToCanvas(downMixCanvas, nil, 0, 0, 0, screen.Scaling.X, screen.Scaling.Y)
end


--- @public love.update
--- this function is called upon each update cycle
function love.update()
	cfgTimers.update()  -- update timers

	-- calculate and log fps
	local fps = love.timer.getFPS()
	if cfgTimers.consoleTimer:Activated() then
		logInfo("FPS: " .. fps)
	end

	controls.handleGeneralControls()  -- evaluate general controls
	local response = connections.sendRequests()
	dispatcher.update(response)  -- TODO: implement dispatcher method

	for i=1, #patchSlots do
		patchSlots[i].patch.update()  -- call current patch update method
	end
end