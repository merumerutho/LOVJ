local Automation = require "lib/automations/automation"
local amath = require "lib/automations/automation_math"

local Envelope = {}
Envelope.__index = Envelope
setmetatable(Envelope, {__index = Automation})

--- @public new create envelope object (ADSR)
function Envelope:new(atkTime, decTime, susLvl, rlsTime)
    local a = Automation:new()

    self = setmetatable(a, Envelope)

    self.parent = Automation:new()  -- maintain a copy of the parent for "super" methods

    self.atkTime = atkTime
    self.decTime = decTime
    self.susLvl = susLvl
    self.rlsTime = rlsTime

    return self
end

--- @public Attack calculate the attack value at time t
function Envelope:Attack(t)
    local Ta = self.atkTime
    local Tt = self.trigger.atkInst  -- instant of attack of the trigger
    t = t - Tt

    return (t/Ta) * amath.rect((t-Ta/2)/Ta)  -- see doc in section "envelope", chapter "attack"
end

--- @public Decay calculate the decay value at time t
function Envelope:Decay(t, rlsCall)
    rlsCall = rlsCall or false
    local Ta = self.atkTime
    local Td = self.decTime
    local s = self.susLvl
    local Tt = self.trigger.atkInst  -- instant of attack of the trigger

    t = (t-Ta-Tt)  -- apply delay of Ta
    local m = (1 - s)/Td  -- angular coefficient

    return (1-m*t) * amath.rect((t-Td/2)/Td) -- see doc in section "envelope", chapter "decay"
end

--- @public Sustain calculate the sustain value at time t
function Envelope:Sustain(t)
    local Ta = self.atkTime
    local Td = self.decTime
    local s = self.susLvl
    local Tt = self.trigger.atkInst  -- instant of attack of the trigger

    t = (t - Ta - Td - Tt)  -- apply delay of Ta + Td
    return (s) * amath.step(t)  -- see doc in section "envelope", chapter "sustain"
end

--- @public Release calculate the release value at time t
function Envelope:Release(t)
    local trg = self.trigger.rlsInst -- not a duration, but the instant of release
    local Tr = self.rlsTime  -- this is a duration, instead
    local y = self:Attack(trg) + self:Decay(trg) + self:Sustain(trg)
    local t = t - trg

    -- see doc in section "envelope", chapter "release"
    return (y - y/Tr * t) * amath.rect((t-Tr/2)/Tr)
end

--- @public Calculate calculate the overall envelope at time t
function Envelope:Calculate(t)
    -- consider envelope as sum of four concatenated components
    -- attack + decay + release + release
    local tr = self:isTriggerActive()
    return (self:Attack(t) + self:Decay(t) + self:Sustain(t)) * amath.b2n(tr) + self:Release(t) * amath.b2n(not tr)
end

return Envelope