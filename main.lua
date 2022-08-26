debug = require "debug"

lick = require "lib/lick"
res = require "lib/resources"
screen = require "lib/screen"
timer = require "lib/timer"
resources = require "lib/resources"
controls = require "lib/controls"
connections = require "lib/connections"
dispatcher = require "lib/dispatcher"

cfg_patches = require "lib/cfg/cfg_patches"
cfg_shaders = require "lib/cfg/cfg_shaders"

local defaultPatch = cfg_patches.defaultPatch
patch = require(defaultPatch)
lick.updateCurrentlyLoadedPatch( defaultPatch .. ".lua")

local fps = 0
-- lick reset enable
lick.reset = true

--  hot reload
function love.load()
	-- Init screen
	screen.init()
	-- Init timer
	timer.init()
	-- Init resources
	resources.Init()
	-- Init Patch
	patch.init()
	-- Init socket
	connections.Init()
	-- Init Shaders globals
	cfg_shaders.assignGlobals()

end


-- Main draw cycle, called once every frame (depends on vsync)
function love.draw()
	-- set scaling
	love.graphics.scale(screen.Scaling.X, screen.Scaling.Y)
	-- draw patch
	patch.draw()
	-- calculate fps
	fps = love.timer.getFPS()
end


-- Main update cycle, executed as fast as possible
function love.update()
	timer.update()  -- update timer
	-- Console management
	if timer.consoleSwInterrupt() then
		print("FPS:", fps)
	end

	controls.handleGeneralControls()  -- evaluate general controls

	local response_data = connections.SendRequests()  -- request data from UDP connections
	dispatcher.update(response_data)  -- TODO implement this
	patch.update()
end