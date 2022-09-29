amath = require "lib/automations/automation_math"
cfg_timers = require "lib/cfg/cfg_timers"

local Automation = {}
Automation.__index = Automation

--- @public new create Automation object
function Automation:new()
    local self = setmetatable({}, Automation)

    self.trigger = { atkInst = 0, rlsInst = 0 }  -- input trigger
    self.output = nil  -- output control

    return self
end

--- @public isTriggerActive check if the trigger is currently enabled
function Automation:isTriggerActive()
    return (self.trigger.atkInst > self.trigger.rlsInst)
end

--- @public UpdateTrigger update periodically the trigger
function Automation:UpdateTrigger(trg)
    local globalTimer = cfg_timers.globalTimer

    -- if trigger 0->1, save atkInst
    if not self:isTriggerActive() and trg then
        self.trigger.atkInst = globalTimer.T
    end
    -- if trigger 1->0, save rlsInst
    if self:isTriggerActive() and not trg then
        self.trigger.oldRlsInst = self.trigger.rlsInst
        self.trigger.rlsInst = globalTimer.T
    end
end


return Automation