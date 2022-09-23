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
    -- if trigger 0->1, save atkInst
    if not self:isTriggerActive() and trg then
        self.trigger.atkInst = timer.T
    end
    -- if trigger 1->0, save rlsInst
    if self:isTriggerActive() and not trg then
        self.trigger.oldRlsInst = self.trigger.rlsInst
        self.trigger.rlsInst = timer.T
    end
end


return Automation