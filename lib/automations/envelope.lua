local Automation = require "lib/automations/automation"

local Envelope = {}
Envelope.__index = Envelope
setmetatable(Envelope, {__index = Automation})

--- @private b2n boolean to number conversion
local function b2n(b)
    return b and 1 or 0
end

--- @private step calculate step function on variable x
local function step(x)
    return (x>0) and 1 or 0
end

--- @private rect calculate rect function on variable x
local function rect(x)
    return (math.abs(x)<1/2) and 1 or 0
end

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

    return (t/(Ta)) * rect((t-Ta/2)/Ta)  -- see doc in section "envelope", chapter "attack"
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

    return (1-m*t) * rect((t-Td/2)/Td) -- see doc in section "envelope", chapter "decay"
end

--- @public Sustain calculate the sustain value at time t
function Envelope:Sustain(t)
    local Ta = self.atkTime
    local Td = self.decTime
    local s = self.susLvl
    local Tt = self.trigger.atkInst  -- instant of attack of the trigger

    t = (t - Ta - Td - Tt)  -- apply delay of Ta + Td
    return s * step(t)  -- see doc in section "envelope", chapter "sustain"
end

--- @public Release calculate the release value at time t
function Envelope:Release(t)
    local trg = self.trigger.rlsInst -- not a duration, but the instant of release
    local Tr = self.rlsTime  -- this is a duration, instead
    local y = self:Attack(trg) + self:Decay(trg) + self:Sustain(trg)
    local t = t - trg

    return (y - y/Tr * t) * rect((t-Tr/2)/Tr)* b2n(not self:isTriggerActive()) -- see doc in section "envelope", chapter "release"
end

--- @public Calculate calculate the overall envelope at time t
function Envelope:Calculate(t)
    -- consider envelope as sum of four concatenated components
    -- attack + decay + release + release
    local y = (self:Attack(t) + self:Decay(t) + self:Sustain(t)) * b2n(self:isTriggerActive())
    if not self:isTriggerActive() then
        y = y + self:Release(t)
    end
    return y
end

return Envelope