-- lfo.lua
--
-- LFO class (has Signals as parent)
-- Defines a generic LFO with frequency and phase parameter
-- The same LFO may have multiple shapes depending on the output function called
--

local Signals = lovjRequire("lib/signals/signals")
local SMath = lovjRequire("lib/signals/signal_math")

local Lfo = {}
Lfo.__index = Lfo
setmetatable(Lfo, {__index = Signals})

function Lfo:new(f, p)
    local l = Signals:new()  -- inherit from Signals (parent)

    self = setmetatable(l, Lfo)

    self.parent = Signals:new()  -- maintain a copy of the parent for "super" methods

    self.frequency = f  -- frequency is defined in Hz
    self.phase = p  -- phase defined in [0-1] range

    self.prevTime = 0
    self.random = math.random()  -- used for rndSampleHold

    return self
end


function Lfo:Sine(t)
    local y = math.sin(2 * math.pi * ( self.frequency * t + self.phase) )
    return y * SMath.b2n(self:isTriggerActive())
end


function Lfo:Square(t)
    local y = SMath.sign(self:Sine(t))
    return y * SMath.b2n(self:isTriggerActive())
end


function Lfo:RampUp(t)
    local y = math.fmod(self.frequency * (t + self.phase), 1) * 2 - 1
    return y * SMath.b2n(self:isTriggerActive())
end


function Lfo:RampDown(t)
    local y = math.fmod(self.frequency * (-t - self.phase), 1) * 2 + 1
    return y * SMath.b2n(self:isTriggerActive())
end


function Lfo:Triangle(t)
	local y = (SMath.tri(self.frequency * t + self.phase)) * 2 - 1
	return y * SMath.b2n(self:isTriggerActive())
end


function Lfo:Pulse(t, pw)
	local y = SMath.pulse(self.frequency * t + self.phase, pw) * 2 - 1
	return y * SMath.b2n(self:isTriggerActive())
end


function Lfo:RandomSH(t)
    -- when the sine changes sign (pi multiples), propose new random value
    if SMath.sign(self:Sine(self.prevTime)) ~= SMath.sign(self:Sine(t)) then
        self.random = (math.random() * 2) - 1
    end
    self.prevTime = t
    return self.random * SMath.b2n(self:isTriggerActive())
end
	

return Lfo