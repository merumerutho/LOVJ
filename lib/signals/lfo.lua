-- lfo.lua
--
-- LFO class with a shape registry.
-- Shapes are registered by name in Lfo.shapes. To add a new shape,
-- call Lfo.registerShape(name, fn) where fn(self, t) returns [-1, 1].
--

local Signals = lovjRequire("lib/signals/signals")
local SMath = lovjRequire("lib/signals/signal_math")

local Lfo = {}
Lfo.__index = Lfo
setmetatable(Lfo, {__index = Signals})

Lfo.shapes = {}
Lfo.shapeNames = {}


function Lfo.registerShape(name, fn)
    Lfo.shapes[name] = fn
    for i, n in ipairs(Lfo.shapeNames) do
        if n == name then return end
    end
    table.insert(Lfo.shapeNames, name)
end


function Lfo:eval(shapeName, t)
    local fn = Lfo.shapes[shapeName]
    if not fn then return 0 end
    return fn(self, t)
end


function Lfo:new(f, p)
    local l = Signals:new()
    self = setmetatable(l, Lfo)
    self.parent = Signals:new()
    self.frequency = f
    self.phase = p
    self.prevTime = 0
    self.random = math.random()
    return self
end


function Lfo:UpdateFreq(f)
    self.frequency = f
end


-- Built-in shapes (all return [-1, 1], gated by trigger state)

Lfo.registerShape("Sine", function(self, t)
    local y = math.sin(2 * math.pi * (self.frequency * t + self.phase))
    return y * SMath.b2n(self:isTriggerActive())
end)

Lfo.registerShape("Square", function(self, t)
    local y = SMath.sign(math.sin(2 * math.pi * (self.frequency * t + self.phase)))
    return y * SMath.b2n(self:isTriggerActive())
end)

Lfo.registerShape("Triangle", function(self, t)
    local y = (SMath.tri(self.frequency * t + self.phase)) * 2 - 1
    return y * SMath.b2n(self:isTriggerActive())
end)

Lfo.registerShape("RampUp", function(self, t)
    local y = math.fmod(self.frequency * (t + self.phase), 1) * 2 - 1
    return y * SMath.b2n(self:isTriggerActive())
end)

Lfo.registerShape("RampDown", function(self, t)
    local y = math.fmod(self.frequency * (-t - self.phase), 1) * 2 + 1
    return y * SMath.b2n(self:isTriggerActive())
end)

Lfo.registerShape("SmoothRampUp", function(self, t)
    local ph = math.fmod(self.frequency * (t + self.phase), 1)
    local knee = 0.8
    local y
    if ph < knee then
        y = ph / knee
    else
        local blend = (ph - knee) / (1 - knee)
        y = 1 - (1 - math.cos(blend * math.pi)) * 0.5
    end
    return (y * 2 - 1) * SMath.b2n(self:isTriggerActive())
end)

Lfo.registerShape("SmoothRampDown", function(self, t)
    local ph = math.fmod(self.frequency * (t + self.phase), 1)
    local knee = 0.8
    local y
    if ph < knee then
        y = 1 - ph / knee
    else
        local blend = (ph - knee) / (1 - knee)
        y = (1 - math.cos(blend * math.pi)) * 0.5
    end
    return (y * 2 - 1) * SMath.b2n(self:isTriggerActive())
end)

Lfo.registerShape("Pulse", function(self, t)
    local y = SMath.pulse(self.frequency * t + self.phase, 0.5) * 2 - 1
    return y * SMath.b2n(self:isTriggerActive())
end)

Lfo.registerShape("RandomSH", function(self, t)
    local curr = math.sin(2 * math.pi * (self.frequency * t + self.phase))
    local prev = math.sin(2 * math.pi * (self.frequency * self.prevTime + self.phase))
    if SMath.sign(prev) ~= SMath.sign(curr) then
        self.random = (math.random() * 2) - 1
    end
    self.prevTime = t
    return self.random * SMath.b2n(self:isTriggerActive())
end)


-- Keep the old method API for backward compatibility (patches using lfo:Sine(t) etc.)
function Lfo:Sine(t)       return Lfo.shapes.Sine(self, t) end
function Lfo:Square(t)     return Lfo.shapes.Square(self, t) end
function Lfo:Triangle(t)   return Lfo.shapes.Triangle(self, t) end
function Lfo:RampUp(t)     return Lfo.shapes.RampUp(self, t) end
function Lfo:RampDown(t)   return Lfo.shapes.RampDown(self, t) end
function Lfo:SmoothRampUp(t)   return Lfo.shapes.SmoothRampUp(self, t) end
function Lfo:SmoothRampDown(t) return Lfo.shapes.SmoothRampDown(self, t) end
function Lfo:Pulse(t, pw)  return Lfo.shapes.Pulse(self, t) end
function Lfo:RandomSH(t)   return Lfo.shapes.RandomSH(self, t) end


return Lfo
