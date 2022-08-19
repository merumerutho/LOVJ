-- timer.lua
--
-- Internal timer settings

timer = {}

timer.CONSOLE_UPDATE_INTERVAL = 1
timer.TARGET_FPS = 60

function timer.init()
	timer.DeltaT = {}
	timer.DeltaT.console = 0
	timer.InitialTime = love.timer.getTime()
	timer.T = love.timer.getTime()
end


function timer.update()
	timer.T = love.timer.getTime() - timer.InitialTime
end


function timer.consoleSwInterrupt()
	if timer.T - timer.DeltaT.console >= timer.CONSOLE_UPDATE_INTERVAL then
		timer.DeltaT.console = timer.T
		return true
	end
	return false
end

return timer