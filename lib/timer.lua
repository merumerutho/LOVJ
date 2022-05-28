-- timer.lua
--
-- Internal timer settings

timer = {}

timer.CONSOLE_UPDATE_INTERVAL = 1
timer.TARGET_FPS = 60

function timer.init()
	timer.deltaT = {}
	timer.deltaT.console = 0
	timer.initial_time = love.timer.getTime()
	timer.t = love.timer.getTime()
end


function timer.update()
	timer.t = love.timer.getTime() - timer.initial_time
end


function timer.consoleTimer()
	if timer.t - timer.deltaT.console >= timer.CONSOLE_UPDATE_INTERVAL then
		timer.deltaT.console = timer.t
		return true
	end
	return false
end

return timer