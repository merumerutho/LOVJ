-- midi_dispatcher.lua
--
-- MIDI-specific message dispatcher
-- Maps MIDI messages to generic commands and handles MIDI protocol details
-- Does not know about LOVJ application logic - only MIDI → Command translation
--

local MIDIDispatcher = {}

local MIDI_THREAD_FILE = "lib/midi/midi_thread.lua"

-- Dependencies
local CommandSystem = lovjRequire("lib/command_system")
local midiMapping = lovjRequire("cfg/cfg_midi_mapping")

-- Active MIDI channels from MIDIThread instances
local activeMIDIChannels = {}

-- Active MIDI threads for cleanup during resets
local activeMIDIThreads = {}

-- Register a new MIDI channel from a MIDIThread
function MIDIDispatcher.registerMIDIChannel(channelName)
    if not activeMIDIChannels[channelName] then
        activeMIDIChannels[channelName] = love.thread.getChannel(channelName)
        logInfo("MIDIDispatcher: Registered MIDI channel " .. channelName)
    end
end

-- Unregister a MIDI channel when MIDIThread disconnects
function MIDIDispatcher.unregisterMIDIChannel(channelName)
    activeMIDIChannels[channelName] = nil
    logInfo("MIDIDispatcher: Unregistered MIDI channel " .. channelName)
end

-- Parse MIDI message format: "type channel data1 [data2]"
local function parseMIDIMessage(rawMsg)
    local parts = {}
    for part in rawMsg:gmatch("%S+") do
        table.insert(parts, part)
    end
    
    if #parts < 3 then return nil end
    
    local msgType = parts[1]
    local channel = tonumber(parts[2])
    local data1 = tonumber(parts[3])
    local data2 = tonumber(parts[4]) or 0
    
    return msgType, channel, data1, data2
end

-- Apply value transformations
local function applyTransformations(value, transformNames)
    if not transformNames then return value end
    
    for _, transformName in ipairs(transformNames) do
        local transform = midiMapping.transformations[transformName]
        if transform then
            value = transform(value)
        end
    end
    
    return value
end

-- Substitute argument placeholders with actual values
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
                -- Use data2 for note velocity, data1 for CC value
                local value = (msgType == "noteOn" or msgType == "noteOff") and data2 or data1
                table.insert(result, value)
            elseif template == "$note" then
                table.insert(result, data1) -- Note number
            elseif template == "$velocity" then
                table.insert(result, data2) -- Note velocity
            elseif template == "$cc" then
                table.insert(result, data1) -- CC number
            elseif template == "$program" then
                table.insert(result, data1) -- Program number
            else
                table.insert(result, template)
            end
        else
            table.insert(result, template)
        end
    end
    
    return result
end

-- Try to match MIDI message against CC mappings
local function tryCCMapping(channel, ccNumber, value, deviceId)
    local ccKey = deviceId .. "_" .. channel .. "_" .. ccNumber
    local mapping = midiMapping.ccMappings[ccKey] or midiMapping.ccMappings[ccNumber]
    
    if not mapping then return false end
    
    -- Apply transformations
    local transformedValue = value
    if mapping.transform then
        for _, transformName in ipairs(mapping.transform) do
            transformedValue = applyTransformations(transformedValue, {transformName})
        end
    end
    
    -- Build command arguments
    local args = substituteArguments(mapping.args, "cc", channel, ccNumber, transformedValue, deviceId)
    
    -- Queue the command
    return CommandSystem.queueCommand(mapping.command, args)
end

-- Try to match MIDI message against note mappings
local function tryNoteMapping(msgType, channel, note, velocity, deviceId)
    local noteKey = deviceId .. "_" .. channel .. "_" .. note
    local mapping = midiMapping.noteMappings[noteKey] or midiMapping.noteMappings[note]
    
    if not mapping then return false end
    
    -- Check if this mapping applies to this message type
    if mapping.type and mapping.type ~= msgType then return false end
    
    -- Apply transformations
    local transformedVelocity = velocity
    if mapping.transform then
        for _, transformName in ipairs(mapping.transform) do
            transformedVelocity = applyTransformations(transformedVelocity, {transformName})
        end
    end
    
    -- Build command arguments
    local args = substituteArguments(mapping.args, msgType, channel, note, transformedVelocity, deviceId)
    
    -- Queue the command
    return CommandSystem.queueCommand(mapping.command, args)
end

-- Try to match MIDI message against program change mappings
local function tryProgramMapping(channel, program, deviceId)
    local progKey = deviceId .. "_" .. channel .. "_" .. program
    local mapping = midiMapping.programMappings[progKey] or midiMapping.programMappings[program]
    
    if not mapping then return false end
    
    -- Build command arguments
    local args = substituteArguments(mapping.args, "program", channel, program, 0, deviceId)
    
    -- Queue the command
    return CommandSystem.queueCommand(mapping.command, args)
end

-- Route MIDI message to appropriate command
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

-- Main update function to process MIDI messages
function MIDIDispatcher.update()
    -- Process incoming MIDI messages from all active channels
    for channelName, channel in pairs(activeMIDIChannels) do
        while true do
            local rawMIDIMsg = channel:pop()
            if not rawMIDIMsg then break end
            
            -- Extract device ID from channel name (format: midiChannel_deviceId)
            local deviceId = channelName:match("midiChannel_(.+)")
            
            local msgType, midiChannel, data1, data2 = parseMIDIMessage(rawMIDIMsg)
            if msgType then
                local routed = routeMIDIMessage(msgType, midiChannel, data1, data2, deviceId)
                if not routed then
                    logInfo("MIDIDispatcher: No mapping for " .. msgType .. " ch:" .. midiChannel .. " d1:" .. data1 .. " d2:" .. data2)
                end
            else
                logInfo("MIDIDispatcher: Invalid MIDI message format: " .. rawMIDIMsg)
            end
        end
    end
end

-- Initialize MIDI dispatcher and start threads
function MIDIDispatcher.init()
    logInfo("MIDIDispatcher: Initialized")
    
    -- Start MIDI threads for enabled connections
    for _, conn in ipairs(midiMapping.connections) do
        if conn.enabled then
            MIDIDispatcher.startMIDIThread(conn)
        end
    end
end

-- Start MIDI thread for a connection
function MIDIDispatcher.startMIDIThread(connectionConfig)
    local midiThread = love.thread.newThread(MIDI_THREAD_FILE)
    midiThread:start(connectionConfig.id, connectionConfig)
    
    -- Track the thread for cleanup
    activeMIDIThreads[connectionConfig.id] = midiThread
    
    logInfo("MIDIDispatcher: Started MIDI thread for " .. connectionConfig.id .. " device: " .. (connectionConfig.device or "default"))
end

-- Stop MIDI thread by connection ID
function MIDIDispatcher.stopMIDIThread(connectionId)
    local thread = activeMIDIThreads[connectionId]
    if thread then
        thread:release()
        activeMIDIThreads[connectionId] = nil
        logInfo("MIDIDispatcher: Stopped MIDI thread for " .. connectionId)
    end
end

-- Stop all MIDI threads (for cleanup during resets)
function MIDIDispatcher.stopAllMIDIThreads()
    for connectionId, thread in pairs(activeMIDIThreads) do
        thread:release()
        logInfo("MIDIDispatcher: Stopped MIDI thread for " .. connectionId)
    end
    activeMIDIThreads = {}
    activeMIDIChannels = {}
end

-- Get dispatcher status
function MIDIDispatcher.getStatus()
    return {
        activeChannels = table.getn(activeMIDIChannels),
        activeThreads = table.getn(activeMIDIThreads)
    }
end

return MIDIDispatcher