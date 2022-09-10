-- timer.lua
--
-- Internal timer settings

timer = {}

timer.CONSOLE_UPDATE_INTERVAL = 1
timer.TARGET_FPS = 60

local spf = 1 / timer.TARGET_FPS

function timer.init()
	timer.DeltaT = {}
	timer.DeltaT.console = 0
	timer.DeltaT.fps = 0
	timer.DeltaT.oneSec = 0
	timer.InitialTime = love.timer.getTime()
	timer.T = love.timer.getTime()
end


function timer.update()
	timer.T = love.timer.getTime() - timer.InitialTime
end


function timer.consoleTimer()
	if timer.T - timer.DeltaT.console >= timer.CONSOLE_UPDATE_INTERVAL then
		timer.DeltaT.console = timer.T
		return true
	end
	return false
end

function timer.fpsTimer()
	if timer.T - timer.DeltaT.fps >= spf then
		timer.DeltaT.fps = timer.T
		return true
	end
	return false
end

function timer.oneSecondTimer()
	if timer.T - timer.DeltaT.oneSec > 1 then
		timer.DeltaT.oneSec = timer.T
		return true
	end
	return false
end

return timer