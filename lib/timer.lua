-- timer.lua
--
-- Internal timer settings

local Timer = {}
Timer.__index = Timer


function Timer:new(rst)
	local self = setmetatable({}, Timer)

	self.initTime = love.timer.getTime()  -- get time of initialization
	self.T = 0  -- initialize timer to 0
	self.delta = 0  -- delta to the reset time
	self.resetT = rst  -- the reset time
	self.hasReset = false  -- becomes true upon reset

	return self
end


function Timer:setResetT(value)
	self.resetT = value
end


function Timer:checkResetT()
	if self.resetT == nil then return false end
	self.hasReset = false
	if (self.T - self.delta) >= self.resetT then
		self.delta = self.T
		self.hasReset = true
	end
end


function Timer:update()
	self.T = love.timer.getTime() - self.initTime
	self:checkResetT()
end


function Timer:Activated()
	return self.hasReset
end


function Timer:reset()
	self.T = 0
	self.delta = 0
	self.initTime = love.timer.getTime()
end


function Timer:dt()
	return love.timer.getDelta()
end


return Timer