debug = require("debug")
lick = require("lib/lick")
requirements = require("lib/utils/require")
log = lovjRequire("lib/utils/logging")

logging.setLogLevel({ logging.LOG_ERROR,
					  logging.LOG_INFO })

screen = lovjRequire("lib/screen")
timer = lovjRequire("lib/timer")
resources = lovjRequire("lib/resources")
controls = lovjRequire("lib/controls")
connections = lovjRequire("lib/connections")
dispatcher = lovjRequire("lib/dispatcher")

cfg_patches = lovjRequire("lib/cfg/cfg_patches")
cfg_shaders = lovjRequire("lib/cfg/cfg_shaders")
cfg_automations = lovjRequire("lib/cfg/cfg_automations")
cfg_timers = lovjRequire("lib/cfg/cfg_timers")

local defaultPatch = cfg_patches.defaultPatch
patch = lovjRequire(defaultPatch)

local test

local fps
-- lick reset enable
lick.reset = true

--  hot reload
function love.load()
	-- Init screen
	screen.init()
	-- Init resources
	resources.init()
	-- Init timers
	cfg_timers.init()
	-- Init Patch
	patch.init()
	-- Init socket
	connections.init()
	-- Init Shaders globals
	cfg_shaders.assignGlobals()
end


-- Main draw cycle, called once every frame (depends on vsync)
function love.draw()

	-- if in high res upscaling mode, then apply scale function here
	if screen.isUpscalingHiRes() then
		love.graphics.scale(screen.Scaling.RatioX, screen.Scaling.RatioY)
	end

	-- draw patch
	patch.draw()

	-- calculate fps
	fps = love.timer.getFPS()
end


-- Main update cycle, executed as fast as possible
function love.update()
	local fpsTimer = cfg_timers.fpsTimer

	cfg_timers.update()  -- update timers
	-- Console management
	if cfg_timers.consoleTimer:Activated() then
		print("FPS:", fps)
	end

	controls.handleGeneralControls()  -- evaluate general controls

	local response_data = connections.sendRequests()  -- request data from UDP connections
	dispatcher.update(response_data)  -- TODO implement this
	patch.update()
end