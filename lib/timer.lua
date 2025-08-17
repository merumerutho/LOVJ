-- timer.lua
--
-- Internal timer settings

local Timer = {}
Timer.__index = Timer

--- @public new Create a new timer object with optional reset time
function Timer:new(reset_time)
	local self = setmetatable({}, Timer)

	self.init_tme = love.timer.getTime()  -- get time of initialization
	self.T = 0  -- initialize timer to 0
	self.delta = 0  -- delta to the reset time
	self.reset_t = reset_time  -- the reset time
	self.has_reset = false  -- becomes true upon reset

	return self
end

--- @public set_reset_t Setter for reset time
function Timer:set_reset_t(value)
	self.reset_t = value
end

--- @public check_reset_t Check if reset time was reached. In such case, trigger the "has_reset" flag
function Timer:check_reset_t()
	if self.reset_t == nil then return false end
	self.has_reset = false
	if (self.T - self.delta) >= self.reset_t then
		self.delta = self.T
		self.has_reset = true
	end
end

--- @public update Update current time count in the timer
function Timer:update()
	self.T = love.timer.getTime() - self.init_tme
	self:check_reset_t()
end

--- @public activated return whether the timer trigger was activated or not
function Timer:activated()
	return self.has_reset
end

--- @public reset Reset the timer to count from 0.
function Timer:reset()
	self.T = 0
	self.delta = 0
	self.init_tme = love.timer.getTime()
end

--- @public dt Obtain the timer delta (difference between current time and previously counted time)
function Timer:dt()
	return love.timer.getDelta()
end


return Timer