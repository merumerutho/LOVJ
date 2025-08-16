-- dispatcher.lua
--
-- OSC Message Dispatcher for LOVJ
-- Routes incoming OSC messages to appropriate LOVJ functions based on hierarchical addressing
-- Manages OSCThread instances and processes messages asynchronously
--

local oscConfig = lovjRequire("cfg/cfg_osc_handlers")
local cfgControls = lovjRequire("cfg/cfg_controls")
local cfgShaders = lovjRequire("cfg/cfg_shaders")
local rtmgr = lovjRequire("lib/realtimemgr")

local dispatcher = {}

-- Table to store dynamically registered OSC channels from OSCThread instances
local activeOSCChannels = {}

-- Table to store the latest OSC values for feedback to OSC clients
local currentOSCValues = {}

-- OSC Action Handlers
local oscActions = {}

-- Global Actions
oscActions.global = {
    setSelectedPatch = function(value)
        local patchNum = math.floor(value)
        if patchNum >= 1 and patchNum <= #patchSlots then
            cfgControls.selectedPatch = patchNum
            logInfo("OSC: Selected patch " .. patchNum)
        end
    end,
    setBPM = function(value)
        if bpm_est then
            bpm_est:setBPM(value)
            logInfo("OSC: Set BPM to " .. value)
        end
    end
}

-- System Actions  
oscActions.system = {
    toggleFullscreen = function(value)
        if value then
            screen.toggleFullscreen()
            logInfo("OSC: Toggled fullscreen")
        end
    end,
    toggleShaders = function(value)
        cfgShaders.enabled = value
        logInfo("OSC: Shaders " .. (value and "enabled" or "disabled"))
    end,
    changeUpscaling = function(value)
        screen.changeUpscaling()
        logInfo("OSC: Changed upscaling mode")
    end,
    reset = function(value)
        if value then
            love.event.quit("restart")
            logInfo("OSC: System reset")
        end
    end
}

-- Patch Actions
oscActions.patch = {
    loadPatch = function(patchSlot, patchName)
        if patchSlot >= 1 and patchSlot <= #patchSlots then
            rtmgr.loadPatch(patchName, patchSlot)
            logInfo("OSC: Loaded patch " .. patchName .. " in slot " .. patchSlot)
        end
    end,
    resetPatch = function(patchSlot)
        if patchSlot >= 1 and patchSlot <= #patchSlots then
            patchSlots[patchSlot].patch.init(patchSlot)
            logInfo("OSC: Reset patch in slot " .. patchSlot)
        end
    end,
    setParameter = function(patchSlot, paramName, value)
        if patchSlot >= 1 and patchSlot <= #patchSlots then
            local patch = patchSlots[patchSlot].patch
            if patch.resources and patch.resources.parameters then
                patch.resources.parameters:set(paramName, value)
                logInfo("OSC: Set " .. paramName .. " = " .. value .. " in patch " .. patchSlot)
            end
        end
    end,
    loadSavestate = function(patchSlot, stateNum)
        if patchSlot >= 1 and patchSlot <= #patchSlots and stateNum >= 1 and stateNum <= 12 then
            rtmgr.loadResources(patchSlots[patchSlot].name, stateNum, patchSlot)
            logInfo("OSC: Loaded savestate " .. stateNum .. " for patch " .. patchSlot)
        end
    end,
    saveSavestate = function(patchSlot, stateNum)
        if patchSlot >= 1 and patchSlot <= #patchSlots and stateNum >= 1 and stateNum <= 12 then
            rtmgr.saveResources(patchSlots[patchSlot].name, stateNum, patchSlot)
            logInfo("OSC: Saved savestate " .. stateNum .. " for patch " .. patchSlot)
        end
    end,
    setGraphics = function(patchSlot, resourceName, value)
        if patchSlot >= 1 and patchSlot <= #patchSlots then
            local patch = patchSlots[patchSlot].patch
            if patch.resources and patch.resources.graphics then
                patch.resources.graphics:set(resourceName, value)
                logInfo("OSC: Set graphics " .. resourceName .. " = " .. tostring(value) .. " in patch " .. patchSlot)
            end
        end
    end,
    setGlobal = function(patchSlot, globalName, value)
        if patchSlot >= 1 and patchSlot <= #patchSlots then
            local patch = patchSlots[patchSlot].patch
            if patch.resources and patch.resources.globals then
                patch.resources.globals:set(globalName, value)
                logInfo("OSC: Set global " .. globalName .. " = " .. tostring(value) .. " in patch " .. patchSlot)
            end
        end
    end
}

-- Shader Actions
oscActions.shader = {
    selectShader = function(patchSlot, layer, shaderIndex)
        if patchSlot >= 1 and patchSlot <= #patchSlots and layer >= 1 and layer <= 3 then
            local patch = patchSlots[patchSlot].patch
            if patch.shaderext then
                patch.shaderext:set("shaderSlot" .. layer, shaderIndex)
                logInfo("OSC: Set shader slot " .. layer .. " to " .. shaderIndex .. " in patch " .. patchSlot)
            end
        end
    end,
    setShaderParameter = function(patchSlot, layer, paramName, value)
        if patchSlot >= 1 and patchSlot <= #patchSlots then
            local patch = patchSlots[patchSlot].patch
            if patch.shaderext then
                local fullParamName = "shader" .. layer .. "_" .. paramName
                patch.shaderext:set(fullParamName, value)
                logInfo("OSC: Set shader param " .. fullParamName .. " = " .. value .. " in patch " .. patchSlot)
            end
        end
    end
}

-- Function to register a new OSC channel from an OSCThread
function dispatcher.registerOSCChannel(oscChannelName)
    if not activeOSCChannels[oscChannelName] then
        activeOSCChannels[oscChannelName] = love.thread.getChannel(oscChannelName)
        logInfo("OSC: Registered OSC channel " .. oscChannelName)
    end
end

-- Function to unregister an OSC channel when OSCThread disconnects
function dispatcher.unregisterOSCChannel(oscChannelName)
    activeOSCChannels[oscChannelName] = nil
    logInfo("OSC: Unregistered OSC channel " .. oscChannelName)
end

-- Parse OSC address and extract components
local function parseOSCAddress(address)
    local parts = {}
    for part in address:gmatch("[^/]+") do
        table.insert(parts, part)
    end
    return parts
end

-- Match address against patterns
local function matchPattern(address, patterns)
    for pattern, config in pairs(patterns) do
        local matches = {address:match(pattern)}
        if #matches > 0 then
            return config, matches
        end
    end
    return nil
end

-- Validate and convert OSC value
local function validateValue(value, valueType, range)
    local validator = oscConfig.validation[valueType]
    if validator then
        return validator(value, range)
    end
    return value
end

-- Route OSC message to appropriate handler
local function routeOSCMessage(address, value)
    -- Try exact handlers first
    local handler = oscConfig.handlers[address]
    if handler then
        local validatedValue = validateValue(value, handler.type, handler.range)
        local action = oscActions[handler.target][handler.action]
        if action then
            action(validatedValue)
            currentOSCValues[address] = validatedValue
            return true
        end
    end
    
    -- Try patch patterns
    local config, matches = matchPattern(address, oscConfig.patchPatterns)
    if config then
        local patchSlot = tonumber(matches[1])
        local validatedValue = validateValue(value, config.type, config.range)
        local action = oscActions[config.target][config.action]
        if action then
            if config.action == "setParameter" or config.action == "setGraphics" or config.action == "setGlobal" then
                action(patchSlot, matches[2], validatedValue)
            else
                action(patchSlot, validatedValue)
            end
            currentOSCValues[address] = validatedValue
            return true
        end
    end
    
    -- Try shader patterns
    local config, matches = matchPattern(address, oscConfig.shaderPatterns)
    if config then
        local patchSlot = tonumber(matches[1])
        local layer = tonumber(matches[2])
        local validatedValue = validateValue(value, config.type, config.range)
        local action = oscActions[config.target][config.action]
        if action then
            if config.action == "setShaderParameter" then
                action(patchSlot, layer, matches[3], validatedValue)
            else
                action(patchSlot, layer, validatedValue)
            end
            currentOSCValues[address] = validatedValue
            return true
        end
    end
    
    return false
end

-- Parse simple OSC message format: "address value"
local function parseOSCMessage(rawMsg)
    local address, valueStr = rawMsg:match("([^ ]+) (.+)")
    if address and valueStr then
        local value = tonumber(valueStr)
        if not value then
            value = valueStr -- Keep as string if not numeric
        end
        return address, value
    end
    return nil
end

-- Main update function to process OSC messages from all active OSCThread instances
function dispatcher.update()
    for oscChannelName, oscChannel in pairs(activeOSCChannels) do
        while true do
            local rawOSCMsg = oscChannel:pop()
            if not rawOSCMsg then break end
            
            local oscAddress, oscValue = parseOSCMessage(rawOSCMsg)
            if oscAddress and oscValue ~= nil then
                local routed = routeOSCMessage(oscAddress, oscValue)
                if not routed then
                    logInfo("OSC: No handler for address: " .. oscAddress)
                end
            else
                logInfo("OSC: Invalid OSC message format: " .. rawOSCMsg)
            end
        end
    end
    
    -- Send OSC feedback to any listening OSC clients
    local oscFeedbackChannel = love.thread.getChannel("oscFeedback")
    if next(currentOSCValues) then
        oscFeedbackChannel:push(currentOSCValues)
    end
end

-- Initialize OSC dispatcher
function dispatcher.init()
    logInfo("OSC Dispatcher initialized")
    -- Start OSC threads for enabled connections
    for _, conn in ipairs(oscConfig.connections) do
        if conn.enabled then
            dispatcher.startOSCThread(conn)
        end
    end
end

-- Start OSC thread for a connection
function dispatcher.startOSCThread(connectionConfig)
    local oscThread = love.thread.newThread("lib/OSCThread.lua")
    oscThread:start(connectionConfig.id, connectionConfig)
    logInfo("Started OSC thread for " .. connectionConfig.id .. " on " .. connectionConfig.address .. ":" .. connectionConfig.port)
end

return dispatcher