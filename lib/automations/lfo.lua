local Automation = require "lib/automations/automation"
local amath = require "lib/automations/automation_math"

Lfo = {}

Lfo.__idx = Lfo

function Lfo:new(l, f, p)
    l = {} or l
    l = Automation:new(l)  -- inherit from Automation (parent)
    l.parent = Automation:new(l)  -- maintain a copy of the parent for "super" methods

    l.frequency = f  -- frequency is defined in Hz
    l.phase = p  -- phase defined in [0-1] range

    l.prevTime = 0
    l.random = math.random()  -- used for rndSampleHold

    setmetatable(l, self)

    return l
end


function lfo:Sine(t)
    local y = math.sin(2 * math.pi * ( self.frequency * t + self.phase) )
    return y
end


function lfo:Square(t)
    local y = amath.sign(self:Sine(t))
    return y
end


function lfo:RampUp(t)
    -- *2-1 is applied since fmod returns a number in [0, 1]
    return math.fmod(self.frequency * (t + self.phase), 1) * 2 - 1
end


function lfo:RampDown(t)
    return math.fmod(self.frequency * (-t - self.phase), 1) * 2 + 1
end


function lfo:SampleHold(t)
    -- if sine would have changed sign, recalculate random value to hold
    if amath.sign(self:Sine(t)) ~= math.sign(self:Sine(t)) then
        self.random = math.random(-1, 1)
    end
    return self.random
end

return Lfo