-- osc_feedback.lua
--
-- OSC Parameter Feedback System for LOVJ
-- Sends parameter discovery information and current values to external controllers
--

local OSCFeedback = {}

-- Dependencies
local ParameterDiscovery = lovjRequire("lib/osc/parameter_discovery")
local oscMapping = lovjRequire("cfg/cfg_osc_mapping")
local feedbackConfig = lovjRequire("cfg/cfg_parameter_feedback")
local CommandSystem = lovjRequire("lib/command_system")

-- Feedback state
OSCFeedback.connectedClients = {}
OSCFeedback.feedbackChannel = nil
OSCFeedback.discoveryResponses = {}
OSCFeedback.parameterUpdateQueue = {}

-- OSC discovery protocol addresses
OSCFeedback.discoveryAddresses = {
    REQUEST_ALL = "/lovj/discovery/request/all",
    REQUEST_CATEGORY = "/lovj/discovery/request/category",
    RESPONSE_PARAMETER = "/lovj/discovery/response/parameter",
    RESPONSE_COMPLETE = "/lovj/discovery/response/complete",
    UPDATE_TICK = "/lovj/discovery/update_tick",
    PARAMETER_UPDATE = "/lovj/parameter/update"
}

-- Initialize OSC feedback system
function OSCFeedback.init()
    logInfo("OSCFeedback: Initializing OSC feedback system")
    
    -- Check if feedback system is enabled
    if not feedbackConfig.enabled then
        logInfo("OSCFeedback: Parameter feedback disabled in configuration")
        return
    end
    
    -- Get the feedback channel used by osc_thread.lua
    OSCFeedback.feedbackChannel = love.thread.getChannel("oscFeedback")
    
    -- Initialize parameter discovery
    ParameterDiscovery.init()
    
    -- Register discovery commands
    OSCFeedback.registerDiscoveryCommands()
    
    OSCFeedback.connectedClients = {}
    OSCFeedback.parameterUpdateQueue = {}
    
    logInfo("OSCFeedback: Parameter feedback system initialized")
end

-- Register a connected client for parameter feedback
function OSCFeedback.registerClient(clientIP, clientPort, capabilities)
    local clientId = clientIP .. ":" .. clientPort
    
    OSCFeedback.connectedClients[clientId] = {
        ip = clientIP,
        port = clientPort,
        capabilities = capabilities or {},
        lastUpdateTick = love.timer.getTime(),
        parametersRequested = false,
        subscribedCategories = {}
    }
    
    logInfo("OSCFeedback: Registered client " .. clientId)
    
    -- Send welcome message with available discovery endpoints
    OSCFeedback.sendDiscoveryWelcome(clientId)
end

-- Unregister a client
function OSCFeedback.unregisterClient(clientId)
    OSCFeedback.connectedClients[clientId] = nil
    logInfo("OSCFeedback: Unregistered client " .. clientId)
end

-- Send discovery welcome message to client
function OSCFeedback.sendDiscoveryWelcome(clientId)
    local client = OSCFeedback.connectedClients[clientId]
    if not client then return end
    
    local welcomeMessage = {
        ["/lovj/discovery/welcome"] = {
            version = "1.0",
            name = "LOVJ",
            description = "LOVJ Parameter Discovery Service",
            endpoints = {
                OSCFeedback.discoveryAddresses.REQUEST_ALL,
                OSCFeedback.discoveryAddresses.REQUEST_CATEGORY,
                OSCFeedback.discoveryAddresses.UPDATE_TICK
            }
        }
    }
    
    OSCFeedback.sendToClient(clientId, welcomeMessage)
end

-- Send parameter discovery response
function OSCFeedback.sendParameterDiscovery(clientId, category)
    local client = OSCFeedback.connectedClients[clientId]
    if not client then return end
    
    -- Discover parameters on-demand
    ParameterDiscovery.discoverParameters()
    
    local parameters = category and ParameterDiscovery.getParametersByCategory(category) or ParameterDiscovery.getAllParameters()
    
    -- Send each parameter as a separate message
    local parameterCount = 0
    for address, param in pairs(parameters) do
        local parameterMessage = {
            [OSCFeedback.discoveryAddresses.RESPONSE_PARAMETER] = {
                address = address,
                category = param.category,
                valueType = param.valueType,
                currentValue = param.currentValue,
                defaultValue = param.defaultValue,
                minValue = param.minValue,
                maxValue = param.maxValue,
                possibleValues = param.possibleValues,
                description = param.description,
                readable = param.readable,
                writable = param.writable
            }
        }
        
        OSCFeedback.sendToClient(clientId, parameterMessage)
        parameterCount = parameterCount + 1
    end
    
    -- Send completion message
    local completeMessage = {
        [OSCFeedback.discoveryAddresses.RESPONSE_COMPLETE] = {
            category = category or "all",
            parameterCount = parameterCount,
            timestamp = love.timer.getTime()
        }
    }
    
    OSCFeedback.sendToClient(clientId, completeMessage)
    
    -- Mark client as having requested parameters
    client.parametersRequested = true
    if category then
        table.insert(client.subscribedCategories, category)
    end
    
    logInfo("OSCFeedback: Sent " .. parameterCount .. " parameters to client " .. clientId)
end

-- Send parameter value update to subscribed clients
function OSCFeedback.sendParameterUpdate(oscAddress, newValue)
    -- Update parameter in discovery system
    ParameterDiscovery.updateParameterValue(oscAddress, newValue)
    
    -- Send update to all interested clients
    for clientId, client in pairs(OSCFeedback.connectedClients) do
        if client.parametersRequested then
            local param = ParameterDiscovery.getParameter(oscAddress)
            if param then
                -- Check if client is subscribed to this parameter's category
                local shouldSend = false
                if #client.subscribedCategories == 0 then
                    shouldSend = true -- Client requested all parameters
                else
                    for _, category in ipairs(client.subscribedCategories) do
                        if param.category == category then
                            shouldSend = true
                            break
                        end
                    end
                end
                
                if shouldSend then
                    local updateMessage = {
                        [OSCFeedback.discoveryAddresses.PARAMETER_UPDATE] = {
                            address = oscAddress,
                            value = newValue,
                            timestamp = love.timer.getTime()
                        }
                    }
                    
                    OSCFeedback.sendToClient(clientId, updateMessage)
                end
            end
        end
    end
end

-- Send OSC message to specific client
function OSCFeedback.sendToClient(clientId, messageTable)
    if OSCFeedback.feedbackChannel then
        OSCFeedback.feedbackChannel:push(messageTable)
    end
end

-- Send OSC message to all clients
function OSCFeedback.broadcastToClients(messageTable)
    for clientId, client in pairs(OSCFeedback.connectedClients) do
        OSCFeedback.sendToClient(clientId, messageTable)
    end
end

-- Handle update tick from client
function OSCFeedback.handleUpdateTick(clientIP, clientPort)
    local clientId = clientIP .. ":" .. clientPort
    local client = OSCFeedback.connectedClients[clientId]
    
    if not client then
        -- Auto-register new client
        OSCFeedback.registerClient(clientIP, clientPort)
        client = OSCFeedback.connectedClients[clientId]
    end
    
    if client then
        client.lastUpdateTick = love.timer.getTime()
        
        -- Send update tick response
        local updateTickResponse = {
            [OSCFeedback.discoveryAddresses.UPDATE_TICK] = {
                timestamp = love.timer.getTime(),
                status = "ok"
            }
        }
        
        OSCFeedback.sendToClient(clientId, updateTickResponse)
    end
end

-- Clean up disconnected clients
function OSCFeedback.cleanupDisconnectedClients()
    local currentTime = love.timer.getTime()
    local timeout = feedbackConfig.discovery.updateTickTimeout or 30.0
    
    for clientId, client in pairs(OSCFeedback.connectedClients) do
        if currentTime - client.lastUpdateTick > timeout then
            OSCFeedback.unregisterClient(clientId)
        end
    end
end

-- Register discovery commands in the command system
function OSCFeedback.registerDiscoveryCommands()
    -- Discovery request all parameters
    CommandSystem.registerCommand("requestAllParameters", {
        description = "Request discovery of all available parameters",
        category = "discovery",
        parameters = {
            {name = "clientIP", type = "string", required = true},
            {name = "clientPort", type = "int", required = true}
        },
        execute = function(clientIP, clientPort)
            local clientId = clientIP .. ":" .. clientPort
            OSCFeedback.registerClient(clientIP, clientPort)
            OSCFeedback.sendParameterDiscovery(clientId, nil)
        end
    })
    
    -- Discovery request by category
    CommandSystem.registerCommand("requestParametersByCategory", {
        description = "Request discovery of parameters by category",
        category = "discovery", 
        parameters = {
            {name = "clientIP", type = "string", required = true},
            {name = "clientPort", type = "int", required = true},
            {name = "category", type = "string", required = true}
        },
        execute = function(clientIP, clientPort, category)
            local clientId = clientIP .. ":" .. clientPort
            OSCFeedback.registerClient(clientIP, clientPort)
            OSCFeedback.sendParameterDiscovery(clientId, category)
        end
    })
    
    -- Update tick command
    CommandSystem.registerCommand("oscUpdateTick", {
        description = "Handle OSC client update tick",
        category = "discovery",
        parameters = {
            {name = "clientIP", type = "string", required = true},
            {name = "clientPort", type = "int", required = true}
        },
        execute = function(clientIP, clientPort)
            OSCFeedback.handleUpdateTick(clientIP, clientPort)
        end
    })
end

-- Update function
function OSCFeedback.update()
    -- Clean up disconnected clients
    OSCFeedback.cleanupDisconnectedClients()
end

-- Get feedback system status
function OSCFeedback.getStatus()
    return {
        connectedClients = table.getn(OSCFeedback.connectedClients),
        parametersDiscovered = table.getn(ParameterDiscovery.getAllParameters()),
        updateQueueLength = #OSCFeedback.parameterUpdateQueue
    }
end

return OSCFeedback