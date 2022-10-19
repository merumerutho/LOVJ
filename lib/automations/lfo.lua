-- lfo.lua
--
-- LFO class (has Automation as parent)
-- Defines a generic LFO with frequency and phase parameter
-- The same LFO may have multiple shapes depending on the output function called
--

local Automation = lovjRequire("lib/automations/automation")
local amath = lovjRequire("lib/automations/automation_math")

local Lfo = {}
Lfo.__index = Lfo
setmetatable(Lfo, {__index = Automation})

function Lfo:new(f, p)
    local l = Automation:new()  -- inherit from Automation (parent)

    self = setmetatable(l, Lfo)

    self.parent = Automation:new()  -- maintain a copy of the parent for "super" methods

    self.frequency = f  -- frequency is defined in Hz
    self.phase = p  -- phase defined in [0-1] range

    self.prevTime = 0
    self.random = math.random()  -- used for rndSampleHold

    return self
end


function Lfo:Sine(t)
    local y = math.sin(2 * math.pi * ( self.frequency * t + self.phase) )
    return y * amath.b2n(self:isTriggerActive())
end


function Lfo:Square(t)
    local y = amath.sign(self:Sine(t))
    return y * amath.b2n(self:isTriggerActive())
end


function Lfo:RampUp(t)
    -- *2-1 is applied since fmod returns a number in [0, 1]
    local y = math.fmod(self.frequency * (t + self.phase), 1) * 2 - 1
    return y * amath.b2n(self:isTriggerActive())
end


function Lfo:RampDown(t)
    local y = math.fmod(self.frequency * (-t - self.phase), 1) * 2 + 1
    return y * amath.b2n(self:isTriggerActive())
end


function Lfo:SampleHold(t)
    -- if sine would have changed sign, recalculate random value to hold
    if amath.sign(self:Sine(self.prevTime)) ~= amath.sign(self:Sine(t)) then
        self.random = (math.random() * 2) - 1
    end
    self.prevTime = t
    return self.random * amath.b2n(self:isTriggerActive())
end

return Lfo