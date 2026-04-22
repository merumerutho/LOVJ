-- sequencer.lua
--
-- Elektron-style step sequencer with p-locks, polyrhythm, and morph support.
--
-- Syncs to the global clock (lib/clock.lua) for BPM. Each channel has
-- its own step count and divider, so channels can run at different
-- lengths and subdivisions simultaneously (polyrhythms).
--
-- P-locks can optionally morph (interpolate) to their target value over
-- a duration, shaped by an easing curve.
--

local clock = lovjRequire("lib/clock")
local Easing = lovjRequire("lib/signals/easing")
local cfg_timers = lovjRequire("cfg/cfg_timers")

local Sequencer = {}
Sequencer.__index = Sequencer


--- Create a new sequencer (no global step count — that's per-channel).
function Sequencer:new()
    local self = setmetatable({}, Sequencer)
    self.channels     = {}   -- name -> channel
    self.channelOrder = {}   -- ordered names
    self.playing      = false
    self.startBeat    = 0
    return self
end


--- @private Resolve a target spec into a write function.
local function resolveTarget(target)
    if type(target) == "function" then return target end
    if target.fn then return target.fn end

    if target.slot and target.param then
        local resType = target.resource or "parameters"
        local slot  = target.slot
        local param = target.param
        return function(v)
            if not patchSlots or not patchSlots[slot] then return end
            local res
            if resType == "shaderext" then
                res = patchSlots[slot].shaderext
            else
                local patch = patchSlots[slot].patch
                if patch and patch.resources then
                    res = patch.resources[resType]
                end
            end
            if res then res:set(param, v) end
        end
    end

    if target.modulator and target.field then
        local mid   = target.modulator
        local field = target.field
        return function(v)
            local Modulator = require("lib/modulator")
            Modulator.update(mid, { [field] = v })
        end
    end

    return function() end
end


--- Add a channel. Each channel has its own step count and divider.
function Sequencer:channel(name, target)
    if self.channels[name] then
        self:removeChannel(name)
    end

    local numSteps = tonumber(target.steps) or 16
    local divider  = tonumber(target.divider) or 4

    local steps = {}
    for i = 1, numSteps do steps[i] = {} end

    local ch = {
        name        = name,
        target      = target,
        write       = resolveTarget(target),
        numSteps    = numSteps,
        divider     = divider,
        mode        = target.mode or "hold",
        default     = target.default,
        steps       = steps,
        currentStep = 0,
        lastValue   = nil,
        morph       = nil,
    }
    self.channels[name] = ch
    table.insert(self.channelOrder, name)
    return self
end


function Sequencer:removeChannel(name)
    self.channels[name] = nil
    for i = #self.channelOrder, 1, -1 do
        if self.channelOrder[i] == name then
            table.remove(self.channelOrder, i)
        end
    end
    return self
end


--- Set a p-lock on a channel's step.
--- opts (optional): {morphDuration, morphMode, morphEasing}
function Sequencer:plock(step, channelName, value, opts)
    local ch = self.channels[channelName]
    if ch and step >= 1 and step <= ch.numSteps then
        local stepData = ch.steps[step]
        stepData.value = value
        if opts then
            stepData.morphDuration = tonumber(opts.morphDuration) or nil
            stepData.morphMode     = opts.morphMode or nil
            stepData.morphEasing   = opts.morphEasing or nil
        end
    end
    return self
end


--- Clear a single p-lock.
function Sequencer:clearPlock(step, channelName)
    local ch = self.channels[channelName]
    if ch and step >= 1 and step <= ch.numSteps then
        ch.steps[step] = {}
    end
    return self
end


--- Clear all p-locks on a channel.
function Sequencer:clearChannel(channelName)
    local ch = self.channels[channelName]
    if ch then
        for i = 1, ch.numSteps do ch.steps[i] = {} end
        ch.morph = nil
    end
    return self
end


--- Resize a channel's step count.
function Sequencer:setChannelSteps(channelName, n)
    local ch = self.channels[channelName]
    if not ch then return self end
    ch.numSteps = n
    while #ch.steps < n do table.insert(ch.steps, {}) end
    while #ch.steps > n do table.remove(ch.steps) end
    return self
end


--- Change a channel's divider.
function Sequencer:setChannelDivider(channelName, div)
    local ch = self.channels[channelName]
    if ch then ch.divider = div end
    return self
end


function Sequencer:play()
    self.playing   = true
    self.startBeat = clock.beat
    for _, ch in pairs(self.channels) do
        ch.currentStep = 0
        ch.morph = nil
    end
    return self
end


function Sequencer:stop()
    self.playing = false
    for _, ch in pairs(self.channels) do
        ch.morph = nil
    end
    return self
end


function Sequencer:toggle()
    if self.playing then self:stop() else self:play() end
    return self
end


function Sequencer:realign()
    self.startBeat = clock.beat
    for _, ch in pairs(self.channels) do
        ch.currentStep = 0
        ch.morph = nil
    end
    return self
end


--- @private Start or hard-write a p-lock value on a channel.
--- Inactive steps (value == nil) let any in-progress morph keep running.
local function applyPlock(ch, stepData)
    local pval = stepData.value
    if pval == nil then
        if not ch.morph and ch.mode == "snap" and ch.default ~= nil then
            ch.write(ch.default)
            ch.lastValue = ch.default
        end
        return
    end

    local dur = stepData.morphDuration
    if dur and dur > 0 then
        local fromVal = ch.lastValue or pval
        local easingFn = Easing.byName(stepData.morphEasing or "linear")
        local mode = stepData.morphMode or "beats"
        local actualDur = (mode == "time") and (dur / 1000) or dur
        ch.morph = {
            fromVal   = fromVal,
            toVal     = pval,
            easingFn  = easingFn,
            mode      = mode,
            duration  = actualDur,
            startBeat = clock.beat,
            startTime = cfg_timers.globalTimer.T,
        }
    else
        ch.write(pval)
        ch.lastValue = pval
        ch.morph = nil
    end
end


--- @private Evaluate an active morph interpolation.
local function tickMorph(ch)
    local m = ch.morph
    if not m then return end

    local elapsed
    if m.mode == "beats" then
        elapsed = clock.beat - m.startBeat
    else
        elapsed = cfg_timers.globalTimer.T - m.startTime
    end

    local t = elapsed / m.duration
    if t >= 1 then
        ch.write(m.toVal)
        ch.lastValue = m.toVal
        ch.morph = nil
    else
        local shaped = m.easingFn(t)
        local value = m.fromVal + (m.toVal - m.fromVal) * shaped
        ch.write(value)
        ch.lastValue = value
    end
end


--- Advance all channels.
function Sequencer:tick()
    if not self.playing then return end

    local beatsSinceStart = clock.beat - self.startBeat

    for _, chName in ipairs(self.channelOrder) do
        local ch = self.channels[chName]
        local stepFloat = beatsSinceStart * ch.divider
        local newStep = math.floor(stepFloat) % ch.numSteps + 1

        if newStep ~= ch.currentStep then
            ch.currentStep = newStep
            applyPlock(ch, ch.steps[ch.currentStep])
        else
            tickMorph(ch)
        end
    end
end


--- Serialisable state for the GUI.
function Sequencer:getState()
    local channels = {}
    for _, name in ipairs(self.channelOrder) do
        local ch = self.channels[name]
        local steps = {}
        for i = 1, ch.numSteps do
            local s = ch.steps[i]
            local entry = { value = (s.value ~= nil) and s.value or false }
            if s.morphDuration then
                entry.morphDuration = s.morphDuration
                entry.morphMode = s.morphMode or "beats"
                entry.morphEasing = s.morphEasing or "linear"
            end
            steps[i] = entry
        end
        table.insert(channels, {
            name        = name,
            target      = ch.target,
            mode        = ch.mode,
            default     = ch.default,
            numSteps    = ch.numSteps,
            divider     = ch.divider,
            currentStep = ch.currentStep,
            steps       = steps,
            morphActive = ch.morph ~= nil,
        })
    end
    return {
        playing  = self.playing,
        channels = channels,
    }
end


return Sequencer
