-- interpolator.lua
--
-- Value interpolator driven by easing curves. Transitions a numeric
-- value from A to B over a duration, shaped by any easing function.
--
-- Supports two time domains:
--   "time"  — wall-clock seconds (cfg_timers.globalTimer.T)
--   "beats" — beat position (clock.beat)
--
-- Usage:
--   local Interpolator = lovjRequire("lib/signals/interpolator")
--   local Easing = lovjRequire("lib/signals/easing")
--
--   local fade = Interpolator:new({ easing = Easing.smoothstep })
--   fade:set(0)
--   fade:goto(1.0, 2.0)                -- 0 -> 1 over 2 seconds
--   fade:goto(0.5, 4, "beats")         -- -> 0.5 over 4 beats
--
--   -- in update loop:
--   fade:update()
--   local v = fade:value()
--

local Easing   = lovjRequire("lib/signals/easing")
local cfg_timers = lovjRequire("cfg/cfg_timers")
local clock    = lovjRequire("lib/clock")

local Interpolator = {}
Interpolator.__index = Interpolator


function Interpolator:new(opts)
    opts = opts or {}
    local self = setmetatable({}, Interpolator)

    self.easingFn   = opts.easing or Easing.linear
    self.easingName = opts.easingName or "linear"
    self.startVal   = tonumber(opts.value) or 0
    self.endVal     = self.startVal
    self.current    = self.startVal
    self.startTime  = 0
    self.duration   = 0
    self.mode       = "time"
    self.active     = false

    return self
end


--- Set value immediately (cancels any in-progress transition).
function Interpolator:set(value)
    self.current  = value
    self.startVal = value
    self.endVal   = value
    self.active   = false
end


--- Begin a transition to `target` over `duration`.
--- mode: "time" (seconds, default) or "beats".
function Interpolator:goto(target, duration, mode)
    self.startVal  = self.current
    self.endVal    = target
    self.duration  = duration or 1.0
    self.mode      = mode or "time"
    self.active    = true

    if self.mode == "beats" then
        self.startTime = clock.beat
    else
        self.startTime = cfg_timers.globalTimer.T
    end
end


--- Change the easing function (can be swapped mid-transition).
function Interpolator:setEasing(fn, name)
    if type(fn) == "string" then
        self.easingFn   = Easing.byName(fn)
        self.easingName = fn
    else
        self.easingFn   = fn
        self.easingName = name or "custom"
    end
end


--- Advance the interpolation. Call once per frame.
function Interpolator:update()
    if not self.active then return self.current end

    local now
    if self.mode == "beats" then
        now = clock.beat
    else
        now = cfg_timers.globalTimer.T
    end

    local elapsed = now - self.startTime
    local t = (self.duration > 0) and (elapsed / self.duration) or 1

    if t >= 1 then
        t = 1
        self.active = false
    end

    local shaped = self.easingFn(t)
    self.current = self.startVal + (self.endVal - self.startVal) * shaped
    return self.current
end


--- Current value (does NOT advance; call update() first).
function Interpolator:value()
    return self.current
end


--- True while a transition is in progress.
function Interpolator:isActive()
    return self.active
end


--- Serialisable snapshot.
function Interpolator:getState()
    return {
        current    = self.current,
        startVal   = self.startVal,
        endVal     = self.endVal,
        duration   = self.duration,
        mode       = self.mode,
        easingName = self.easingName,
        active     = self.active,
    }
end


return Interpolator
