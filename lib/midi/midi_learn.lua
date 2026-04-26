local MappingStore = lovjRequire("lib/midi/midi_mappings_store")

local MidiLearn = {}

local state = "idle"
local learnTarget = nil
local captureCallback = nil

function MidiLearn.startLearn(target, onCaptured)
    state = "listening"
    learnTarget = target
    captureCallback = onCaptured
    local desc = target.targetType == "modulator"
        and ("mod" .. target.modulatorId .. ":" .. target.modulatorField)
        or ("slot" .. target.slot .. ":" .. target.paramName)
    logInfo("MidiLearn: Listening for MIDI input -> " .. desc)
end

function MidiLearn.cancelLearn()
    state = "idle"
    learnTarget = nil
    captureCallback = nil
    logInfo("MidiLearn: Cancelled")
end

function MidiLearn.isListening()
    return state == "listening"
end

function MidiLearn.getState()
    if state == "idle" then
        return { state = "idle" }
    end
    return {
        state = "listening",
        targetType = learnTarget and learnTarget.targetType or "param",
        slot = learnTarget and learnTarget.slot,
        paramName = learnTarget and learnTarget.paramName,
        modulatorId = learnTarget and learnTarget.modulatorId,
        modulatorField = learnTarget and learnTarget.modulatorField,
    }
end

function MidiLearn.onCapture(msgType, channel, data1, deviceId)
    if state ~= "listening" or not learnTarget then return end

    local midiType, midiKey
    if msgType == "cc" then
        midiType = "cc"
        midiKey = data1
    elseif msgType == "noteOn" then
        midiType = "note"
        midiKey = data1
    elseif msgType == "program" then
        midiType = "program"
        midiKey = data1
    else
        return
    end

    local transform = (midiType ~= "program") and {"midiNormalize"} or {}
    local mapping

    if learnTarget.targetType == "modulator" then
        local mid = learnTarget.modulatorId
        local field = learnTarget.modulatorField
        local placeholder = (midiType == "note") and "$velocity" or "$value"
        mapping = {
            midiType = midiType,
            midiKey = midiKey,
            command = "setModulatorParam",
            args = {mid, field, placeholder},
            transform = transform,
            type = (midiType == "note") and "noteOn" or nil,
            label = "mod" .. mid .. ":" .. field,
        }
    else
        local placeholder = (midiType == "note") and "$velocity" or "$value"
        mapping = {
            midiType = midiType,
            midiKey = midiKey,
            command = "setPatchParameterByName",
            args = {learnTarget.slot, learnTarget.paramName, placeholder},
            transform = transform,
            type = (midiType == "note") and "noteOn" or nil,
            label = "slot" .. learnTarget.slot .. ":" .. learnTarget.paramName,
        }
    end

    local id = MappingStore.add(mapping)
    mapping.id = id

    logInfo("MidiLearn: Captured " .. midiType .. " " .. midiKey .. " -> " .. mapping.label)

    local cb = captureCallback
    state = "idle"
    learnTarget = nil
    captureCallback = nil

    if cb then
        local ok, err = pcall(cb, mapping)
        if not ok then logError("MidiLearn callback error: " .. tostring(err)) end
    end
end

return MidiLearn
