-- bpm_estimator.lua
--
-- BPM estimator based on mouse click timing

local BPMEstimator = {}
BPMEstimator.__index = BPMEstimator

--- @public new Create a new BPM estimator object
function BPMEstimator:new()
    local self = setmetatable({}, BPMEstimator)
    
    self.click_times = {}  -- stores last 8 click timestamps
    self.max_clicks = 8    -- maximum number of clicks to track
    self.estimated_bpm = 0 -- current BPM estimation
    
    return self
end

--- @public trigger Handle event to update BPM estimation
function BPMEstimator:trigger()
    local current_time = love.timer.getTime()
    
    -- Add current click time to the array
    table.insert(self.click_times, current_time)
    
    -- Keep only the last 8 clicks
    if #self.click_times > self.max_clicks then
        table.remove(self.click_times, 1)
    end
    
    -- Calculate BPM if we have at least 2 clicks
    if #self.click_times >= 2 then
        self:calculateBPM()
    end
end

--- @private calculateBPM Calculate BPM based on stored click intervals
function BPMEstimator:calculateBPM()
    local intervals = {}
    
    -- Calculate intervals between consecutive clicks
    for i = 2, #self.click_times do
        local interval = self.click_times[i] - self.click_times[i-1]
        table.insert(intervals, interval)
    end
    
    -- Calculate average interval
    local total_interval = 0
    for _, interval in ipairs(intervals) do
        total_interval = total_interval + interval
    end
    
    local avg_interval = total_interval / #intervals
    
    -- Convert to BPM (beats per minute)
    -- 60 seconds / average interval in seconds = beats per minute
    self.estimated_bpm = 60 / avg_interval
end

--- @public getBPM Get the current BPM estimation
function BPMEstimator:getBPM()
    return math.floor(self.estimated_bpm + 0.5) -- round to nearest integer
end

--- @public reset Reset the BPM estimator
function BPMEstimator:reset()
    self.click_times = {}
    self.estimated_bpm = 0
end

--- @public getClickCount Get number of clicks recorded
function BPMEstimator:getClickCount()
    return #self.click_times
end

--- @public setBPM Manually set the BPM (for OSC control)
function BPMEstimator:setBPM(bpm)
    if bpm and bpm > 0 then
        self.estimated_bpm = bpm
    end
end

return BPMEstimator