debug = require("debug")
lick = require("lib/lick")
requirements = require("lib/utils/require")
version = require("lib/cfg/cfg_version")

log = lovjRequire("lib/utils/logging")
screen = lovjRequire("lib/screen")

-- TODO: move the table to cfg_logging
logging.setLogLevel({ logging.LOG_ERROR,
					  logging.LOG_INFO })

timer = lovjRequire("lib/timer")
resources = lovjRequire("lib/resources")
controls = lovjRequire("lib/controls")
connections = lovjRequire("lib/connections")
dispatcher = lovjRequire("lib/dispatcher")

cfg_patches = lovjRequire("lib/cfg/cfg_patches")
cfg_shaders = lovjRequire("lib/cfg/cfg_shaders")
cfg_automations = lovjRequire("lib/cfg/cfg_automations")
cfg_timers = lovjRequire("lib/cfg/cfg_timers")

currentPatchName = cfg_patches.defaultPatch
patch = lovjRequire(currentPatchName, lick.PATCH_RESET)

-- Set title with LOVJ version
love.window.setTitle("LOVJ v" ..  version)

local fps

--- @public love.load love load function callback
function love.load()
	screen.init()  -- Init screen
	resources.init()  -- Init resources
	cfg_timers.init()  -- Init timers
	patch.init()  -- Init Patch
	connections.init()  -- Init socket
	cfg_shaders.assignGlobals()  -- Init Shaders globals
end


--- @public love.draw love draw function callback
function love.draw()
	-- if in high res upscaling mode, then apply scale function here
	if screen.isUpscalingHiRes() then
		love.graphics.scale(screen.Scaling.RatioX, screen.Scaling.RatioY)
	end

	patch.draw()  -- call current patch draw method
end


--- @public love.update love update function callback
function love.update()
	cfg_timers.update()  -- update timers

	-- calculate and log fps
	local fps = love.timer.getFPS()
	if cfg_timers.consoleTimer:Activated() then
		logInfo("FPS: " .. fps)
	end

	controls.handleGeneralControls()  -- evaluate general controls

	dispatcher.update(connections.sendRequests())  -- TODO: implement dispatcher method

	patch.update()  -- call current patch update method
end