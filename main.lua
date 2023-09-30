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

-- Set title with LOVJ version
love.window.setTitle("LOVJ v" ..  version)

--- @public love.load
--- this function is called upon startup
function love.load()
	screen.init()  -- Init screen
	cfg_timers.init()  -- Init timers

	-- Set two running patches
	patchSlots = {{name = cfg_patches.defaultPatch[1]},
				  {name = cfg_patches.defaultPatch[2]}}
	for i=1, #patchSlots do
		patchSlots[i].patch = lovjRequire(patchSlots[i].name, lick.PATCH_RESET)
	end

	-- global setting resources
	globalSettings = ResourceList:newResource()

	-- Initialize each patch
	for i, slot in ipairs(patchSlots) do
        slot.patch.init(i, slot.name)  -- Init actual patch for this patch slot
		slot.shaderext = ResourceList:newResource()
		cfg_shaders.initShaderExt(i)  -- Assign Shaders globals
    end



	connections.init()  -- Init socket
end


--- @public love.draw
--- this function is called upon each draw cycle
function love.draw()
	-- if in high res upscaling mode, then apply scaling function here
	if screen.isUpscalingHiRes() then
		love.graphics.scale(screen.Scaling.RatioX, screen.Scaling.RatioY)
	end

	-- Draw all patches stacked on top of each other
	for i=1, #patchSlots do
		local canvas = patchSlots[i].patch.draw()  								-- Get canvas from current patch
		love.graphics.setCanvas()												-- Reset canvas
		love.graphics.draw(canvas, 0, 0, 0, screen.Scaling.X, screen.Scaling.Y) -- Draw
	end

end


--- @public love.update
--- this function is called upon each update cycle
function love.update()
	cfg_timers.update()  -- update timers

	-- calculate and log fps
	local fps = love.timer.getFPS()
	if cfg_timers.consoleTimer:Activated() then
		logInfo("FPS: " .. fps)
	end

	controls.handleGeneralControls()  -- evaluate general controls
	dispatcher.update(connections.sendRequests())  -- TODO: implement dispatcher method

	for i=1, #patchSlots do
		patchSlots[i].patch.update()  -- call current patch update method
	end
end