-- signals.lua
--
-- Signals class:
-- defines a generic signal as something with a beginning (trigger)
-- and an end (trigger release) dependent on a boolean condition.
-- The underlying function depends on the type of signal
--

SMath = lovjRequire("lib/signals/signal_math")
cfg_timers = lovjRequire("cfg/cfg_timers")

local Signals = {}
Signals.__index = Signals

--- @public new create Signals object
function Signals:new()
    local self = setmetatable({}, Signals)

    self.trigger = { atkInst = 0, rlsInst = 0 }  -- input triggers
    self.output = nil  -- output control

    return self
end

--- @public isTriggerActive check if the trigger is currently enabled
function Signals:isTriggerActive()
    return (self.trigger.atkInst > self.trigger.rlsInst)
end

--- @public UpdateTrigger periodically update the trigger
function Signals:UpdateTrigger(trg)
    local globalTimer = cfg_timers.globalTimer

    -- if trigger 0->1, this is the atkInst
    if not self:isTriggerActive() and trg then
        self.trigger.atkInst = globalTimer.T
    end
    -- if trigger 1->0, this is the rlsInst
    if self:isTriggerActive() and not trg then
        self.trigger.oldRlsInst = self.trigger.rlsInst
        self.trigger.rlsInst = globalTimer.T
    end
end


return Signals