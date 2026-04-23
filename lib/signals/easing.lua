-- easing.lua
--
-- Pure shaping functions: f(t) -> y, where t is normalised [0,1].
-- Output is [0,1] for well-behaved curves; elastic/back variants
-- overshoot intentionally.
--
-- Each function can be passed directly to an Interpolator or used
-- standalone to shape any normalised parameter.
--

local pi  = math.pi
local sin  = math.sin
local cos  = math.cos
local pow  = math.pow or function(b, e) return b ^ e end
local abs  = math.abs
local floor = math.floor

local Easing = {}


-- ---- Helpers ----

local function clamp01(t)
    if t < 0 then return 0 end
    if t > 1 then return 1 end
    return t
end

Easing.clamp01 = clamp01

--- Build an InOut variant from any In function.
function Easing.makeInOut(easeIn)
    return function(t)
        if t < 0.5 then
            return 0.5 * easeIn(2 * t)
        end
        return 1 - 0.5 * easeIn(2 - 2 * t)
    end
end


-- ---- Linear ----

function Easing.linear(t) return t end


-- ---- Smoothstep family (polynomial S-curves) ----

function Easing.smoothstep(t)
    return t * t * (3 - 2 * t)
end

function Easing.smootherstep(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end


-- ---- Sine ----

function Easing.sineIn(t)
    return 1 - cos(t * pi * 0.5)
end

function Easing.sineOut(t)
    return sin(t * pi * 0.5)
end

function Easing.sineInOut(t)
    return 0.5 * (1 - cos(pi * t))
end


-- ---- Quadratic ----

function Easing.quadIn(t) return t * t end

function Easing.quadOut(t) return t * (2 - t) end

function Easing.quadInOut(t)
    if t < 0.5 then return 2 * t * t end
    return -1 + (4 - 2 * t) * t
end


-- ---- Cubic ----

function Easing.cubicIn(t) return t * t * t end

function Easing.cubicOut(t)
    local u = t - 1
    return u * u * u + 1
end

function Easing.cubicInOut(t)
    if t < 0.5 then return 4 * t * t * t end
    local u = 2 * t - 2
    return 0.5 * u * u * u + 1
end


-- ---- Quartic ----

function Easing.quartIn(t) return t * t * t * t end

function Easing.quartOut(t)
    local u = t - 1
    return 1 - u * u * u * u
end

function Easing.quartInOut(t)
    if t < 0.5 then return 8 * t * t * t * t end
    local u = t - 1
    return 1 - 8 * u * u * u * u
end


-- ---- Exponential ----

function Easing.expoIn(t)
    if t == 0 then return 0 end
    return 2 ^ (10 * (t - 1))
end

function Easing.expoOut(t)
    if t == 1 then return 1 end
    return 1 - 2 ^ (-10 * t)
end

function Easing.expoInOut(t)
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    if t < 0.5 then return 0.5 * 2 ^ (20 * t - 10) end
    return 1 - 0.5 * 2 ^ (-20 * t + 10)
end


-- ---- Back (anticipation overshoot) ----

local BACK_S = 1.70158

function Easing.backIn(t)
    return t * t * ((BACK_S + 1) * t - BACK_S)
end

function Easing.backOut(t)
    local u = t - 1
    return u * u * ((BACK_S + 1) * u + BACK_S) + 1
end

function Easing.backInOut(t)
    local s = BACK_S * 1.525
    if t < 0.5 then
        return 0.5 * (4 * t * t * ((s + 1) * 2 * t - s))
    end
    local u = 2 * t - 2
    return 0.5 * (u * u * ((s + 1) * u + s) + 2)
end


-- ---- Elastic (spring oscillation) ----

function Easing.elasticIn(t)
    if t == 0 or t == 1 then return t end
    return -(2 ^ (10 * t - 10)) * sin((t * 10 - 10.75) * (2 * pi) / 3)
end

function Easing.elasticOut(t)
    if t == 0 or t == 1 then return t end
    return 2 ^ (-10 * t) * sin((t * 10 - 0.75) * (2 * pi) / 3) + 1
end

function Easing.elasticInOut(t)
    if t == 0 or t == 1 then return t end
    if t < 0.5 then
        return -0.5 * 2 ^ (20 * t - 10) * sin((20 * t - 11.125) * (2 * pi) / 4.5)
    end
    return 0.5 * 2 ^ (-20 * t + 10) * sin((20 * t - 11.125) * (2 * pi) / 4.5) + 1
end


-- ---- Bounce ----

local function bounceOutRaw(t)
    if t < 1 / 2.75 then
        return 7.5625 * t * t
    elseif t < 2 / 2.75 then
        t = t - 1.5 / 2.75
        return 7.5625 * t * t + 0.75
    elseif t < 2.5 / 2.75 then
        t = t - 2.25 / 2.75
        return 7.5625 * t * t + 0.9375
    else
        t = t - 2.625 / 2.75
        return 7.5625 * t * t + 0.984375
    end
end

function Easing.bounceOut(t) return bounceOutRaw(t) end

function Easing.bounceIn(t) return 1 - bounceOutRaw(1 - t) end

function Easing.bounceInOut(t)
    if t < 0.5 then return 0.5 * (1 - bounceOutRaw(1 - 2 * t)) end
    return 0.5 * bounceOutRaw(2 * t - 1) + 0.5
end


-- ---- Step (quantised — useful for glitch/stutter transitions) ----

function Easing.steps(n)
    n = n or 4
    return function(t)
        return floor(t * n) / n
    end
end


-- ---- Power (generic, user-controlled exponent) ----

function Easing.powerIn(exp)
    return function(t) return t ^ exp end
end

function Easing.powerOut(exp)
    return function(t) return 1 - (1 - t) ^ exp end
end

function Easing.powerInOut(exp)
    return Easing.makeInOut(Easing.powerIn(exp))
end


-- ---- Lookup table: name -> function (for serialisation / GUI) ----

Easing.catalog = {
    linear       = Easing.linear,
    smoothstep   = Easing.smoothstep,
    smootherstep = Easing.smootherstep,
    sineIn       = Easing.sineIn,
    sineOut      = Easing.sineOut,
    sineInOut    = Easing.sineInOut,
    quadIn       = Easing.quadIn,
    quadOut      = Easing.quadOut,
    quadInOut    = Easing.quadInOut,
    cubicIn      = Easing.cubicIn,
    cubicOut     = Easing.cubicOut,
    cubicInOut   = Easing.cubicInOut,
    quartIn      = Easing.quartIn,
    quartOut     = Easing.quartOut,
    quartInOut   = Easing.quartInOut,
    expoIn       = Easing.expoIn,
    expoOut      = Easing.expoOut,
    expoInOut    = Easing.expoInOut,
    backIn       = Easing.backIn,
    backOut      = Easing.backOut,
    backInOut    = Easing.backInOut,
    elasticIn    = Easing.elasticIn,
    elasticOut   = Easing.elasticOut,
    elasticInOut = Easing.elasticInOut,
    bounceIn     = Easing.bounceIn,
    bounceOut    = Easing.bounceOut,
    bounceInOut  = Easing.bounceInOut,
}

Easing.names = {}
for name in pairs(Easing.catalog) do
    table.insert(Easing.names, name)
end
table.sort(Easing.names)


--- Resolve a name string to a function (returns linear if unknown).
function Easing.byName(name)
    return Easing.catalog[name] or Easing.linear
end


return Easing
