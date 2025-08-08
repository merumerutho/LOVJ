-- Regular requirements
require("lib/utils/tableExtensions")
debug = require("debug")
lick = require("lib/lick")
requirements = require("lib/utils/require")
version = require("cfg/cfg_version")

-- From here on, use lovjRequire
log = lovjRequire("lib/utils/logging")
logging.setLogLevel({ logging.LOG_ERROR, logging.LOG_INFO })

screen = lovjRequire("lib/screen")
timer = lovjRequire("lib/timer")
ResourceList = lovjRequire("lib/resources")
controls = lovjRequire("lib/controls")
connections = lovjRequire("lib/connections")
dispatcher = lovjRequire("lib/dispatcher")
bpmEstimator = lovjRequire("lib/bpm_estimator")

cfgControls = lovjRequire("cfg/cfg_controls")
cfgPatches = lovjRequire("cfg/cfg_patches")
cfgShaders = lovjRequire("cfg/cfg_shaders")
cfgTimers = lovjRequire("cfg/cfg_timers")
cfgSpout = lovjRequire("cfg/cfg_spout")
cfgApp = lovjRequire("cfg/cfg_app")
cfgScreen = lovjRequire("cfg/cfg_screen")

if (cfgSpout.enable and 
	love.system.getOS() == "Windows" and
	love.filesystem.getInfo("SpoutLibrary.dll") and
	love.filesystem.getInfo("SpoutWrapper.dll")) then
	spout_support = true
	spout = lovjRequire("lib/spout")
else
	spout_support = false
	spout = lovjRequire("lib/stubs/spout-stub")
end

drawingUtils = lovjRequire("lib/utils/drawing")

-- Set title with LOVJ version
love.window.setTitle(cfgApp.title .. " v" ..  version)
love.window.setIcon(love.image.newImageData(cfgApp.icon))

local downMixCanvas, dummyCanvas, spoutCanvas

-- Add sender "MAIN" 
local main_sender_cfg = cfgSpout.senders["main"]
table.insert(cfgSpout.senderHandles, spout.SpoutSender:new(nil, main_sender_cfg["name"], main_sender_cfg["width"], main_sender_cfg["height"]))

local receivers_cfg = cfgSpout.receivers
local receivers_obj = {}
for i = 1, #receivers_cfg do
	table.insert(receivers_obj, spout.SpoutReceiver:new(nil, receivers_cfg[i]))
end

bpm_est = bpmEstimator:new()

-- Override love.mousepressed(x,y,button)
function love.mousepressed(x, y, button)
  if button == 1 then -- left mouse button
	  bpm_est:trigger()
  end
end

--- @public love.load
--- this function is called upon startup
function love.load()
	if arg[#arg] == "-debug" then require("mobdebug").start() end
	screen.init()  -- Init screen
	cfgTimers.init()  -- Init timers
	cfgShaders.init()  -- Init shaders
  
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

	cfgControls.init()  -- Init controls
	connections.init()  -- Init socket
	
	downMixCanvas = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
	dummyCanvas = love.graphics.newCanvas(1,1)
  
	local main_spout_sender = cfgSpout.senderHandles[1]
	main_spout_sender:init() -- Initialize spout sender
	
	-- Initialize spout receivers
	for i = 1, #receivers_obj do
		receivers_obj[i]:init()
	end
  
end


--- @public love.draw
--- this function is called upon each draw cycle
function love.draw()
	love.graphics.setCanvas(dummyCanvas)
	-- Clear canvases
	drawingUtils.clearCanvas(downMixCanvas)
	drawingUtils.clearCanvas(nil)

	-- for receiver in receiver_list do local spoutReceivedImg = receiver:draw() end

	-- Draw all patches stacked on top of each other
	for i=1, #patchSlots do
		local canvas = patchSlots[i].patch.draw()  -- this function may change currently set canvas
		drawingUtils.drawCanvasToCanvas(canvas, downMixCanvas)  -- draw canvas to downmix
		canvas = drawingUtils.clearCanvas(canvas)  -- clean canvas after using it
	end

	-- draw downmix to main screen
	drawingUtils.drawCanvasToCanvas(downMixCanvas, nil, 0, 0, 0, screen.Scaling.WindowRatioX, screen.Scaling.WindowRatioY)

	-- Spout output is sent here
	local main_spout_sender = cfgSpout.senderHandles[1]
	main_spout_sender:SendCanvas(downMixCanvas, screen.Scaling.SpoutRatioX, screen.Scaling.SpoutRatioY)
  
	-- Force resetting canvas
	love.graphics.setCanvas()
end


--- @public love.update
--- this function is called upon each update cycle
function love.update()
	cfgTimers.update()  -- update timers

	-- Timer "callback"
	local fps = love.timer.getFPS()
	if cfgTimers.consoleTimer:Activated() then
		logInfo("FPS: " .. fps)
		for i=1, #receivers_obj do
			receivers_obj[i]:update() -- Update spout receivers
		end
	end

	controls.update()
	-- dispatcher.update(response)  -- TODO: implement dispatcher method

	for i=1, #patchSlots do
		patchSlots[i].patch.update()  -- call current patch update method
	end
end