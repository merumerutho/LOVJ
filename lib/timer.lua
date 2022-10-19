-- timer.lua
--
-- Internal timer settings

local Timer = {}
Timer.__index = Timer

--- @public new Create a new timer object with optional reset time
function Timer:new(rst)
	local self = setmetatable({}, Timer)

	self.initTime = love.timer.getTime()  -- get time of initialization
	self.T = 0  -- initialize timer to 0
	self.delta = 0  -- delta to the reset time
	self.resetT = rst  -- the reset time
	self.hasReset = false  -- becomes true upon reset

	return self
end

--- @public setResetT Setter for reset time
function Timer:setResetT(value)
	self.resetT = value
end

--- @public checkResetT Check if reset time was reached. In such case, trigger the "hasReset" flag
function Timer:checkResetT()
	if self.resetT == nil then return false end
	self.hasReset = false
	if (self.T - self.delta) >= self.resetT then
		self.delta = self.T
		self.hasReset = true
	end
end

--- @public update Update current time count in the timer
function Timer:update()
	self.T = love.timer.getTime() - self.initTime
	self:checkResetT()
end

--- @public Activated return whether the timer trigger was activated or not
function Timer:Activated()
	return self.hasReset
end

--- @public reset Reset the timer to count from 0.
function Timer:reset()
	self.T = 0
	self.delta = 0
	self.initTime = love.timer.getTime()
end

--- @public dt Obtain the timer delta (difference between current time and previously counted time)
function Timer:dt()
	return love.timer.getDelta()
end


return Timer