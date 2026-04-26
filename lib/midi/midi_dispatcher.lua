local MIDIDispatcher = {}

local MIDI_THREAD_FILE = "lib/midi/midi_thread.lua"

local CommandSystem = lovjRequire("lib/command_system")
local MappingStore = lovjRequire("lib/midi/midi_mappings_store")
local MidiLearn -- lazy-loaded to avoid circular init

local activeMIDIChannels = {}
local activeMIDIThreads = {}

local midiActivityCallback = nil

function MIDIDispatcher.registerMIDIChannel(channelName)
    if not activeMIDIChannels[channelName] then
        activeMIDIChannels[channelName] = love.thread.getChannel(channelName)
        logInfo("MIDIDispatcher: Registered MIDI channel " .. channelName)
    end
end

function MIDIDispatcher.unregisterMIDIChannel(channelName)
    activeMIDIChannels[channelName] = nil
    logInfo("MIDIDispatcher: Unregistered MIDI channel " .. channelName)
end

function MIDIDispatcher.setActivityCallback(fn)
    midiActivityCallback = fn
end

local function parseMIDIMessage(rawMsg)
    local parts = {}
    for part in rawMsg:gmatch("%S+") do
        table.insert(parts, part)
    end
    if #parts < 3 then return nil end
    return parts[1], tonumber(parts[2]), tonumber(parts[3]), tonumber(parts[4]) or 0
end

local function applyTransformations(value, transformNames)
    if not transformNames then return value end
    local transforms = MappingStore.getTransformations()
    for _, name in ipairs(transformNames) do
        local fn = transforms[name]
        if fn then value = fn(value) end
    end
    return value
end

local function substituteArguments(argTemplate, msgType, channel, data1, data2, deviceId)
    local result = {}
    for _, template in ipairs(argTemplate) do
        if type(template) == "string" then
            if template == "$device" then
                table.insert(result, deviceId)
            elseif template == "$channel" then
                table.insert(result, channel)
            elseif template == "$type" then
                table.insert(result, msgType)
            elseif template == "$data1" then
                table.insert(result, data1)
            elseif template == "$data2" then
                table.insert(result, data2)
            elseif template == "$value" then
                table.insert(result, data2)
            elseif template == "$note" then
                table.insert(result, data1)
            elseif template == "$velocity" then
                table.insert(result, data2)
            elseif template == "$cc" then
                table.insert(result, data1)
            elseif template == "$program" then
                table.insert(result, data1)
            else
                table.insert(result, template)
            end
        else
            table.insert(result, template)
        end
    end
    return result
end

local function executeMapping(mapping, msgType, channel, data1, data2, deviceId)
    if mapping.type and mapping.type ~= msgType then return false end

    local transformedValue = data2
    if mapping.transform then
        for _, name in ipairs(mapping.transform) do
            transformedValue = applyTransformations(transformedValue, {name})
        end
    end

    local args = substituteArguments(mapping.args, msgType, channel, data1, transformedValue, deviceId)
    return CommandSystem.queueCommand(mapping.command, args)
end

local function tryCCMapping(channel, ccNumber, value, deviceId)
    local ccKey = deviceId .. "_" .. channel .. "_" .. ccNumber
    local mapping = MappingStore.lookupCC(ccKey) or MappingStore.lookupCC(ccNumber)
    if not mapping then return false end
    return executeMapping(mapping, "cc", channel, ccNumber, value, deviceId)
end

local function tryNoteMapping(msgType, channel, note, velocity, deviceId)
    local noteKey = deviceId .. "_" .. channel .. "_" .. note
    local mapping = MappingStore.lookupNote(noteKey) or MappingStore.lookupNote(note)
    if not mapping then return false end
    return executeMapping(mapping, msgType, channel, note, velocity, deviceId)
end

local function tryProgramMapping(channel, program, deviceId)
    local progKey = deviceId .. "_" .. channel .. "_" .. program
    local mapping = MappingStore.lookupProgram(progKey) or MappingStore.lookupProgram(program)
    if not mapping then return false end
    return executeMapping(mapping, "program", channel, program, 0, deviceId)
end

local function routeMIDIMessage(msgType, channel, data1, data2, deviceId)
    if msgType == "cc" then
        return tryCCMapping(channel, data1, data2, deviceId)
    elseif msgType == "noteOn" or msgType == "noteOff" then
        return tryNoteMapping(msgType, channel, data1, data2, deviceId)
    elseif msgType == "program" then
        return tryProgramMapping(channel, data1, deviceId)
    end
    return false
end

function MIDIDispatcher.update()
    if not MidiLearn then
        MidiLearn = require("lib/midi/midi_learn")
    end

    for channelName, channel in pairs(activeMIDIChannels) do
        while true do
            local rawMIDIMsg = channel:pop()
            if not rawMIDIMsg then break end

            local deviceId = channelName:match("midiChannel_(.+)")
            local msgType, midiChannel, data1, data2 = parseMIDIMessage(rawMIDIMsg)
            if msgType then
                if midiActivityCallback then
                    midiActivityCallback(deviceId, msgType, midiChannel, data1, data2)
                end

                if MidiLearn.isListening() then
                    MidiLearn.onCapture(msgType, midiChannel, data1, deviceId)
                else
                    local routed = routeMIDIMessage(msgType, midiChannel, data1, data2, deviceId)
                    if not routed then
                        logInfo("MIDIDispatcher: No mapping for " .. msgType .. " ch:" .. midiChannel .. " d1:" .. data1 .. " d2:" .. data2)
                    end
                end
            else
                logInfo("MIDIDispatcher: Invalid MIDI message format: " .. rawMIDIMsg)
            end
        end
    end
end

function MIDIDispatcher.init()
    MappingStore.init()
    logInfo("MIDIDispatcher: Initialized")

    local connections = MappingStore.getConnections()
    for _, conn in ipairs(connections) do
        if conn.enabled then
            MIDIDispatcher.startMIDIThread(conn)
        end
    end
end

function MIDIDispatcher.startMIDIThread(connectionConfig)
    local midiThread = love.thread.newThread(MIDI_THREAD_FILE)
    midiThread:start(connectionConfig.id, connectionConfig)
    activeMIDIThreads[connectionConfig.id] = midiThread
    logInfo("MIDIDispatcher: Started MIDI thread for " .. connectionConfig.id .. " device: " .. (connectionConfig.device or "default"))
end

function MIDIDispatcher.stopMIDIThread(connectionId)
    local thread = activeMIDIThreads[connectionId]
    if thread then
        thread:release()
        activeMIDIThreads[connectionId] = nil
        logInfo("MIDIDispatcher: Stopped MIDI thread for " .. connectionId)
    end
end

function MIDIDispatcher.stopAllMIDIThreads()
    for connectionId, thread in pairs(activeMIDIThreads) do
        thread:release()
        logInfo("MIDIDispatcher: Stopped MIDI thread for " .. connectionId)
    end
    activeMIDIThreads = {}
    activeMIDIChannels = {}
end

function MIDIDispatcher.getStatus()
    return {
        activeChannels = table.count(activeMIDIChannels),
        activeThreads = table.count(activeMIDIThreads)
    }
end

return MIDIDispatcher
