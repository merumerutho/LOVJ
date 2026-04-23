-- modulator.lua
--
-- Global modulator registry with a type-handler pattern.
-- Each modulator type (lfo, envelope, ...) is a self-describing handler
-- registered in Modulator.types. Adding a new type requires no changes
-- to the core dispatch — just register a handler table.
--
-- Handler interface:
--   init(config, entry)       — populate type-specific fields on entry
--   update(entry, changes)    — apply partial config changes
--   eval(entry, t)            — return raw signal [0, 1]
--   serialize(entry)          — return serializable type-specific fields
--

local Lfo = lovjRequire("lib/signals/lfo")
local Envelope = lovjRequire("lib/signals/envelope")
local Easing = lovjRequire("lib/signals/easing")
local cfg_timers = lovjRequire("cfg/cfg_timers")
local clock_mod = lovjRequire("lib/clock")

local Modulator = {}

Modulator.nextId = 1
Modulator.list = {}
Modulator.types = {}


--- Register a modulator type handler.
function Modulator.registerType(name, handler)
    Modulator.types[name] = handler
end


--- @private resolve a target to its Resource object and param index.
local function resolveTarget(m)
    local slot = m.target.slot
    local param = m.target.param
    local resType = m.target.resource or "parameters"
    if not param or param == "" or param == "---" then return nil, -1 end
    if not patchSlots or not patchSlots[slot] then return nil, -1 end

    local res
    if resType == "shaderext" then
        res = patchSlots[slot].shaderext
    else
        local patch = patchSlots[slot].patch
        if patch and patch.resources then
            res = patch.resources.parameters
        end
    end

    if not res then return nil, -1 end
    return res, res:getIdxByName(param)
end


local function writeTarget(m, factor)
    local res, idx = resolveTarget(m)
    if not res or idx == -1 then return end
    local base = res:getBaseByIdx(idx)
    if base == nil then return end
    res:setModulatedByIdx(idx, base * factor)
end


--- Create a new modulator and return its id.
function Modulator.create(config)
    if not config then return nil, "missing config" end
    local target = config.target or { slot = 1, param = "---" }
    if not target.slot then target.slot = 1 end
    if not target.param then target.param = "---" end
    if not target.resource then target.resource = "parameters" end
    config.target = target

    local mtype = config.type or "lfo"
    local handler = Modulator.types[mtype]
    if not handler then return nil, "unknown type: " .. tostring(mtype) end

    local mn = tonumber(config.min) or 0.0
    local mx = tonumber(config.max) or 1.0
    local id = config.id or Modulator.nextId
    if config.id then
        if id >= Modulator.nextId then Modulator.nextId = id + 1 end
    else
        Modulator.nextId = Modulator.nextId + 1
    end

    local easingName = config.easing or "linear"

    local entry = {
        id       = id,
        type     = mtype,
        min      = mn,
        max      = mx,
        easing   = easingName,
        easingFn = Easing.byName(easingName),
        target   = { slot = target.slot, param = target.param, resource = target.resource },
    }

    local ok, err = handler.init(config, entry)
    if ok == false then return nil, err end

    Modulator.list[id] = entry
    logInfo("Modulator " .. id .. " (" .. mtype .. ") -> slot " ..
            target.slot .. "/" .. target.param)
    return id
end


--- Update an existing modulator's config (partial update).
function Modulator.update(id, changes)
    local m = Modulator.list[id]
    if not m then return false, "no modulator with id " .. tostring(id) end

    if changes.min then m.min = tonumber(changes.min) or m.min end
    if changes.max then m.max = tonumber(changes.max) or m.max end
    if changes.easing then
        m.easing = changes.easing
        m.easingFn = Easing.byName(changes.easing)
    end
    if changes.target then
        if changes.target.slot     then m.target.slot     = changes.target.slot end
        if changes.target.param    then m.target.param    = changes.target.param end
        if changes.target.resource then m.target.resource = changes.target.resource end
    end

    local handler = Modulator.types[m.type]
    if handler and handler.update then
        handler.update(m, changes)
    end

    return true
end


function Modulator.delete(id)
    if not Modulator.list[id] then return false end
    Modulator.list[id] = nil
    logInfo("Modulator " .. id .. " deleted")
    return true
end


--- Serialisable snapshot of all modulators.
function Modulator.getAll()
    local out = {}
    for _, m in pairs(Modulator.list) do
        local entry = {
            id     = m.id,
            type   = m.type,
            min    = m.min,
            max    = m.max,
            easing = m.easing,
            target = { slot = m.target.slot, param = m.target.param, resource = m.target.resource or "parameters" },
        }
        local handler = Modulator.types[m.type]
        if handler and handler.serialize then
            local extra = handler.serialize(m)
            for k, v in pairs(extra) do entry[k] = v end
        end
        table.insert(out, entry)
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end


function Modulator.getModulatedSet()
    local set = {}
    for _, m in pairs(Modulator.list) do
        local param = m.target.param
        local res = m.target.resource or "parameters"
        if param and param ~= "" and param ~= "---" then
            set[res .. ":" .. m.target.slot .. ":" .. param] = true
        end
    end
    return set
end


--- Tick all modulators. Called once per frame.
function Modulator.tick()
    local t = cfg_timers.globalTimer.T

    -- Reset all targeted params to base before applying modulation
    local resetDone = {}
    for _, m in pairs(Modulator.list) do
        local res, idx = resolveTarget(m)
        if res and idx ~= -1 then
            local key = tostring(res) .. ":" .. idx
            if not resetDone[key] then
                local base = res:getBaseByIdx(idx)
                if base ~= nil and res:getByIdx(idx) ~= base then
                    res:setModulatedByIdx(idx, base)
                end
                resetDone[key] = true
            end
        end
    end

    -- Evaluate and apply each modulator
    for _, m in pairs(Modulator.list) do
        local handler = Modulator.types[m.type]
        if handler and handler.eval then
            local factor = handler.eval(m, t)
            if factor then writeTarget(m, factor) end
        end
    end
end


--- Bulk-restore modulators from serialised data.
function Modulator.restoreAll(data)
    if not data then return end

    local incoming = {}
    for _, mdata in ipairs(data) do incoming[mdata.id] = mdata end

    local toDelete = {}
    for id in pairs(Modulator.list) do
        if incoming[id] then
            Modulator.update(id, incoming[id])
            incoming[id] = nil
        else
            table.insert(toDelete, id)
        end
    end

    for _, id in ipairs(toDelete) do Modulator.delete(id) end
    for _, mdata in pairs(incoming) do Modulator.create(mdata) end
end


--------------------------------------------------------------------
-- Built-in type: LFO
--------------------------------------------------------------------

Modulator.registerType("lfo", {
    init = function(config, entry)
        local shape = config.shape or "Sine"
        if not Lfo.shapes[shape] then
            return false, "unknown shape: " .. tostring(shape)
        end
        entry.shape        = shape
        entry.frequency    = tonumber(config.frequency) or 1.0
        entry.phase        = tonumber(config.phase) or 0.0
        entry.beatSync     = config.beatSync or false
        entry.beatDivision = tonumber(config.beatDivision) or 4
        entry.lfo          = Lfo:new(entry.frequency, entry.phase)
        entry.lfo:UpdateTrigger(true)
    end,

    update = function(entry, changes)
        if changes.shape and Lfo.shapes[changes.shape] then
            entry.shape = changes.shape
        end
        if changes.beatSync ~= nil then
            entry.beatSync = changes.beatSync and true or false
        end
        if changes.beatDivision then
            entry.beatDivision = tonumber(changes.beatDivision) or entry.beatDivision
        end
        if changes.frequency then
            entry.frequency = tonumber(changes.frequency) or entry.frequency
            entry.lfo:UpdateFreq(entry.frequency)
        end
        if changes.phase then
            entry.phase = tonumber(changes.phase) or entry.phase
            entry.lfo.phase = entry.phase
        end
    end,

    eval = function(entry, t)
        if entry.beatSync and entry.beatDivision > 0 then
            local hz = clock_mod.bpm / 60 / entry.beatDivision
            if hz ~= entry.frequency then
                entry.frequency = hz
                entry.lfo:UpdateFreq(hz)
            end
        end
        local raw = entry.lfo:eval(entry.shape, t)
        local norm = raw * 0.5 + 0.5
        norm = entry.easingFn(norm)
        return entry.min + (entry.max - entry.min) * norm
    end,

    serialize = function(entry)
        return {
            shape        = entry.shape,
            frequency    = entry.frequency,
            phase        = entry.phase,
            beatSync     = entry.beatSync,
            beatDivision = entry.beatDivision,
        }
    end,
})


--------------------------------------------------------------------
-- Built-in type: Envelope
--------------------------------------------------------------------

Modulator.registerType("envelope", {
    init = function(config, entry)
        entry.attack       = tonumber(config.attack)       or 0.1
        entry.decay        = tonumber(config.decay)        or 0.1
        entry.sustain      = tonumber(config.sustain)      or 0.7
        entry.release      = tonumber(config.release)      or 0.3
        entry.triggerBeats = tonumber(config.triggerBeats)  or 1.0
        entry.gateRatio    = tonumber(config.gateRatio)    or 0.5
        entry.envelope     = Envelope:new(entry.attack, entry.decay, entry.sustain, entry.release)
    end,

    update = function(entry, changes)
        if changes.attack  then entry.attack  = tonumber(changes.attack)  or entry.attack;  entry.envelope.atkTime = entry.attack end
        if changes.decay   then entry.decay   = tonumber(changes.decay)   or entry.decay;   entry.envelope.decTime = entry.decay end
        if changes.sustain then entry.sustain = tonumber(changes.sustain) or entry.sustain; entry.envelope.susLvl  = entry.sustain end
        if changes.release then entry.release = tonumber(changes.release) or entry.release; entry.envelope.rlsTime = entry.release end
        if changes.triggerBeats then entry.triggerBeats = tonumber(changes.triggerBeats) or entry.triggerBeats end
        if changes.gateRatio   then entry.gateRatio    = tonumber(changes.gateRatio)   or entry.gateRatio end
    end,

    eval = function(entry, t)
        local beatInCycle = clock_mod.beat % entry.triggerBeats
        local gateOn = beatInCycle < (entry.triggerBeats * entry.gateRatio)
        entry.envelope:UpdateTrigger(gateOn)
        local raw = entry.envelope:Calculate(t)
        raw = math.max(0, math.min(1, raw))
        raw = entry.easingFn(raw)
        return entry.min + (entry.max - entry.min) * raw
    end,

    serialize = function(entry)
        return {
            attack       = entry.attack,
            decay        = entry.decay,
            sustain      = entry.sustain,
            release      = entry.release,
            triggerBeats = entry.triggerBeats,
            gateRatio    = entry.gateRatio,
        }
    end,
})


--- Convenience: expose LFO shape names for the GUI.
Modulator.LFO_SHAPES = Lfo.shapeNames


--- Default creation configs for each modulator type.
--- The frontend uses these when spawning new modulators.
Modulator.typeDefaults = {
    lfo = {
        shape = "Sine", frequency = 1.0, phase = 0.0,
        beatSync = false, beatDivision = 4,
        min = 0.0, max = 1.0, easing = "linear",
    },
    envelope = {
        attack = 0.1, decay = 0.1, sustain = 0.7, release = 0.3,
        triggerBeats = 1.0, gateRatio = 0.5,
        min = 0.0, max = 1.0, easing = "linear",
    },
}

--- Per-field range constraints for modulator UI sliders.
Modulator.typeConstraints = {
    lfo = {
        phase = { min = 0, max = 1, step = 0.01 },
    },
    envelope = {
        attack       = { min = 0.001, max = 2,    step = 0.005 },
        decay        = { min = 0.001, max = 2,    step = 0.005 },
        sustain      = { min = 0,     max = 1,    step = 0.01 },
        release      = { min = 0.001, max = 2,    step = 0.005 },
        triggerBeats = { min = 0.25,  max = 8,    step = 0.25 },
        gateRatio    = { min = 0.05,  max = 0.95, step = 0.01 },
    },
}


return Modulator
