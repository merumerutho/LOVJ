-- Regular requirements
require("lib/utils/tableExtensions")
debug = require("debug")
lick = require("lib/lick")
requirements = require("lib/utils/require")
version = require("lib/cfg/cfg_version")

--
log = lovjRequire("lib/utils/logging")
-- TODO: move the table to cfg_logging
logging.setLogLevel({ logging.LOG_ERROR,
					  logging.LOG_INFO })

screen = lovjRequire("lib/screen")
timer = lovjRequire("lib/timer")
ResourceList = lovjRequire("lib/resources")
controls = lovjRequire("lib/controls")
connections = lovjRequire("lib/connections")
dispatcher = lovjRequire("lib/dispatcher")

cfg_patches = lovjRequire("lib/cfg/cfg_patches")
cfg_shaders = lovjRequire("lib/cfg/cfg_shaders")
cfg_automations = lovjRequire("lib/cfg/cfg_automations")
cfg_timers = lovjRequire("lib/cfg/cfg_timers")

runningPatches = {{name = cfg_patches.defaultPatch[1]}, {name = cfg_patches.defaultPatch[2]}}
for i=1, #runningPatches do
    runningPatches[i].patch = lovjRequire(runningPatches[i].name, lick.PATCH_RESET)
end

-- Set title with LOVJ version
love.window.setTitle("LOVJ v" ..  version)

--- @public love.load love load function callback
function love.load()
	screen.init()  -- Init screen
	cfg_timers.init()  -- Init timers
	for i=1, #runningPatches do
        runningPatches[i].resources = ResourceList:new()  -- Init resources
        runningPatches[i].patch.init(runningPatches[i].resources)  -- Init Patches
		cfg_shaders.assignGlobals(i)  -- Init Shaders globals
    end
	selectedPatch = 1 -- set selectedPatch to 1st patch (background)
	controls.init()
	connections.init()  -- Init socket
	
end


--- @public love.draw love draw function callback
function love.draw()
	-- if in high res upscaling mode, then apply scale function here
	if screen.isUpscalingHiRes() then
		love.graphics.scale(screen.Scaling.RatioX, screen.Scaling.RatioY)
	end

	-- For all patches...
	for i=1, #runningPatches do
		local canvas = runningPatches[i].patch.draw()  							-- Get canvas from current patch
		cfg_shaders.applyShader() 												-- Remove shader
		love.graphics.setCanvas()												-- Reset canvas
		love.graphics.draw(canvas, 0, 0, 0, screen.Scaling.X, screen.Scaling.Y) -- Draw
	end

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

	for i=1, #runningPatches do
		runningPatches[i].patch.update()  -- call current patch update method
	end
end