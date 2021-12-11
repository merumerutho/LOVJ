print()

patch = require "demos/demo_1"

lick = require "lib/lick"
params = require "lib/params"
screen = require "lib/screen"
timer = require "lib/timer"
controls = require "lib/controls"
socket = require "lib/socket"

-- lick reset enable
lick.reset = true

hot_reload = ""

function love.load()
	
	-- Init screen
	screen.init()
	-- Init timer
	timer.init()
	-- Init parameters
	p = params.init({a=0.5, b=1})
	-- Init Patch
	patch.init()
	-- Init socket
	socket.init()
	
end


-- Main draw cycle, called once every frame (depends on vsync)
function love.draw()
	-- set scaling
	love.graphics.scale(screen.scale.x, screen.scale.y)
	-- draw patch
	patch.draw()
	-- calculate fps
	fps = 1/(love.timer.getAverageDelta())
end


-- Main update cycle, executed as fast as possible
function love.update()
	-- update timer
	timer.update()
	
	-- update parameters by user controls
	p = controls.updateByKeys(p)
	
	-- Get info from socket
	info = socket.update()
	
	-- Console management
	if timer.consoleCheck() then
		print("FPS:", fps)
		print("Packets received:", info)
	end
	
	patch.update()
end