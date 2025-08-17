-- osc_dispatcher.lua
--
-- OSC-specific message dispatcher
-- Maps OSC messages to generic commands and handles OSC protocol details
-- Does not know about LOVJ application logic - only OSC → Command translation
--

local OSCDispatcher = {}

local OSC_THREAD_FILE = "lib/osc/osc_thread.lua"

-- Dependencies
local CommandSystem = require("lib/command_system")
local oscMapping = require("cfg/cfg_osc_mapping")

-- Active OSC channels from OSCThread instances
local activeOSCChannels = {}

-- Active OSC threads for cleanup during resets
local activeOSCThreads = {}

-- Register a new OSC channel from an OSCThread
function OSCDispatcher.registerOSCChannel(channelName)
    if not activeOSCChannels[channelName] then
        activeOSCChannels[channelName] = love.thread.getChannel(channelName)
        logInfo("OSCDispatcher: Registered OSC channel " .. channelName)
    end
end

-- Unregister an OSC channel when OSCThread disconnects
function OSCDispatcher.unregisterOSCChannel(channelName)
    activeOSCChannels[channelName] = nil
    logInfo("OSCDispatcher: Unregistered OSC channel " .. channelName)
end

-- Parse simple OSC message format: "address value1 value2 ..."
local function parseOSCMessage(rawMsg)
    local parts = {}
    for part in rawMsg:gmatch("%S+") do
        table.insert(parts, part)
    end
    
    if #parts < 1 then return nil end
    
    local address = parts[1]
    local args = {}
    
    -- Convert remaining parts to appropriate types
    for i = 2, #parts do
        local value = tonumber(parts[i])
        if value then
            table.insert(args, value)
        else
            table.insert(args, parts[i])  -- Keep as string
        end
    end
    
    return address, args
end

-- Apply value transformations
local function applyTransformations(value, transformNames)
    if not transformNames then return value end
    
    for _, transformName in ipairs(transformNames) do
        local transform = oscMapping.transformations[transformName]
        if transform then
            value = transform(value)
        end
    end
    
    return value
end

-- Substitute argument placeholders with actual values
local function substituteArguments(argTemplate, patternMatches, oscArgs)
    local result = {}
    
    for _, template in ipairs(argTemplate) do
        if type(template) == "string" and template:match("^%$(%d+)$") then
            local argIndex = tonumber(template:match("^%$(%d+)$"))
            
            if argIndex <= #patternMatches then
                -- Use pattern match (converted to number if possible)
                local value = tonumber(patternMatches[argIndex]) or patternMatches[argIndex]
                table.insert(result, value)
            elseif argIndex - #patternMatches <= #oscArgs then
                -- Use OSC argument
                local oscArgIndex = argIndex - #patternMatches
                table.insert(result, oscArgs[oscArgIndex])
            end
        else
            table.insert(result, template)
        end
    end
    
    return result
end

-- Try to match OSC address against direct mappings
local function tryDirectMapping(address, oscArgs)
    local mapping = oscMapping.directMappings[address]
    if not mapping then return false end
    
    -- Build command arguments
    local args = {}
    for i, argTemplate in ipairs(mapping.args) do
        if type(argTemplate) == "string" and argTemplate:match("^%$(%d+)$") then
            local argIndex = tonumber(argTemplate:match("^%$(%d+)$"))
            if argIndex <= #oscArgs then
                local value = oscArgs[argIndex]
                -- Apply transformations if specified
                if mapping.transform and mapping.transform[i] then
                    value = applyTransformations(value, {mapping.transform[i]})
                end
                table.insert(args, value)
            end
        else
            table.insert(args, argTemplate)
        end
    end
    
    -- Queue the command
    return CommandSystem.queueCommand(mapping.command, args)
end

-- Try to match OSC address against pattern mappings
local function tryPatternMapping(address, oscArgs)
    for _, mapping in ipairs(oscMapping.patternMappings) do
        local matches = {address:match(mapping.pattern)}
        if #matches > 0 then
            local args = substituteArguments(mapping.args, matches, oscArgs)
            return CommandSystem.queueCommand(mapping.command, args)
        end
    end
    return false
end

-- Route OSC message to appropriate command
local function routeOSCMessage(address, oscArgs)
    -- Try direct mapping first
    if tryDirectMapping(address, oscArgs) then
        return true
    end
    
    -- Try pattern mappings
    if tryPatternMapping(address, oscArgs) then
        return true
    end
    
    return false
end

-- Main update function to process OSC messages
function OSCDispatcher.update()
    -- Process incoming OSC messages from all active channels
    for channelName, channel in pairs(activeOSCChannels) do
        while true do
            local rawOSCMsg = channel:pop()
            if not rawOSCMsg then break end
            
            local address, args = parseOSCMessage(rawOSCMsg)
            if address then
                local routed = routeOSCMessage(address, args)
                if not routed then
                    logInfo("OSCDispatcher: No mapping for address: " .. address)
                end
            else
                logInfo("OSCDispatcher: Invalid OSC message format: " .. rawOSCMsg)
            end
        end
    end
end

-- Initialize OSC dispatcher and start threads
function OSCDispatcher.init()
    logInfo("OSCDispatcher: Initialized")
    
    -- Start OSC threads for enabled connections
    for _, conn in ipairs(oscMapping.connections) do
        if conn.enabled then
            OSCDispatcher.startOSCThread(conn)
        end
    end
end

-- Start OSC thread for a connection
function OSCDispatcher.startOSCThread(connectionConfig)
    local oscThread = love.thread.newThread(OSC_THREAD_FILE)
    oscThread:start(connectionConfig.id, connectionConfig)
    
    -- Track the thread for cleanup
    activeOSCThreads[connectionConfig.id] = oscThread
    
    logInfo("OSCDispatcher: Started OSC thread for " .. connectionConfig.id .. " on " .. connectionConfig.address .. ":" .. connectionConfig.port)
end

-- Stop OSC thread by connection ID
function OSCDispatcher.stopOSCThread(connectionId)
    local thread = activeOSCThreads[connectionId]
    if thread then
        thread:release()
        activeOSCThreads[connectionId] = nil
        logInfo("OSCDispatcher: Stopped OSC thread for " .. connectionId)
    end
end

-- Stop all OSC threads (for cleanup during resets)
function OSCDispatcher.stopAllOSCThreads()
    for connectionId, thread in pairs(activeOSCThreads) do
        thread:release()
        logInfo("OSCDispatcher: Stopped OSC thread for " .. connectionId)
    end
    activeOSCThreads = {}
    activeOSCChannels = {}
end

-- Get dispatcher status
function OSCDispatcher.getStatus()
    return {
        activeChannels = table.getn(activeOSCChannels),
        commandQueueLength = #CommandSystem.commandQueue
    }
end

return OSCDispatcher