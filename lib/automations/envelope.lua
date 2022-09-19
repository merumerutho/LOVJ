local Automation = require "lib/automations/automation"

Envelope = {}

Envelope.__idx = Envelope

--- @private step calculate step function on variable x
local function step(x)
    return (x>0) and 1 or 0
end

--- @private rect calculate rect function on variable x
local function rect(x)
    return (math.abs(x)<1/2) and 1 or 0
end

--- @public new create envelope object
function Envelope:new(atkTime, decTime, susLvl)
    e = {}

    e = Automation:new(e)  -- inherit from Automation (parent)
    self.parent = Automation:new(e)  -- maintain a copy of the parent for "super" methods

    setmetatable(e, self)

    self.atkTime = atkTime
    self.decTime = decTime
    self.susLvl = susLvl

    return self
end

--- @public Attack calculate the attack value at time t
function Envelope:Attack(t)
    local Ta = self.atkTime
    return (t/Ta) * rect((t-Ta/2)/Ta)  -- see doc in section "envelope", chapter "attack"
end


function Envelope:Decay(t)
    local Ta = self.atkTime
    local Td = self.decTime
    local s = self.susLvl
    t = (t-Ta)  -- apply delay of Ta
    local m = (1 - s)/Td  -- angular coefficient
    return (1-(m*t)) * rect((t-Td/2)/Td)  -- see doc in section "envelope", chapter "decay"
end


function Envelope:Sustain(t)
    local Ta = self.atkTime
    local Td = self.decTime
    local s = self.susLvl
    t = (t - Ta - Td)  -- apply delay of Ta + Td
    return s * step(t)
end


function Envelope:CalculateEnvelope(t)
    -- consider envelope as sum of four concatenated components
    -- attack + decay + release + release
    return (self:Attack(t) + self:Decay(t) + self:Sustain(t)) -- + self:Release(t))
end


return Envelope