-- command_system.lua
--
-- Generic command execution system for LOVJ
-- Protocol-agnostic command definitions and execution
--

local CommandSystem = {}

-- Command registry - all available commands
CommandSystem.commands = {}

-- Command queue for thread-safe execution
CommandSystem.commandQueue = {}
CommandSystem.maxQueueSize = 1000

-- Command validation functions
local validators = {
    int = function(value, min, max)
        if type(value) ~= "number" then return false end
        if min and value < min then return false end
        if max and value > max then return false end
        return math.floor(value) == value
    end,
    
    float = function(value, min, max)
        if type(value) ~= "number" then return false end
        if min and value < min then return false end
        if max and value > max then return false end
        return true
    end,
    
    bool = function(value)
        return type(value) == "boolean" or type(value) == "number"
    end,
    
    string = function(value, maxLen)
        if type(value) ~= "string" then return false end
        if maxLen and #value > maxLen then return false end
        return true
    end
}

-- Register a new command
function CommandSystem.registerCommand(name, config)
    if not name or not config then
        logError("CommandSystem: Invalid command registration")
        return false
    end
    
    if not config.execute or type(config.execute) ~= "function" then
        logError("CommandSystem: Command '" .. name .. "' must have execute function")
        return false
    end
    
    CommandSystem.commands[name] = {
        execute = config.execute,
        description = config.description or "No description",
        parameters = config.parameters or {},
        category = config.category or "general"
    }
    
    logInfo("CommandSystem: Registered command '" .. name .. "'")
    return true
end

-- Validate command parameters
local function validateParameters(command, args)
    if not command.parameters then return true end
    
    for i, param in ipairs(command.parameters) do
        local value = args[i]
        local validator = validators[param.type]
        
        if param.required and value == nil then
            return false, "Missing required parameter: " .. param.name
        end
        
        if value ~= nil and validator then
            local valid = validator(value, param.min, param.max)
            if not valid then
                return false, "Invalid parameter '" .. param.name .. "': " .. tostring(value)
            end
        end
    end
    
    return true
end

-- Queue a command for execution
function CommandSystem.queueCommand(commandName, args)
    if #CommandSystem.commandQueue >= CommandSystem.maxQueueSize then
        logError("CommandSystem: Command queue full, dropping command: " .. commandName)
        return false
    end
    
    local command = CommandSystem.commands[commandName]
    if not command then
        logError("CommandSystem: Unknown command: " .. commandName)
        return false
    end
    
    -- Validate parameters
    local valid, error = validateParameters(command, args)
    if not valid then
        logError("CommandSystem: Parameter validation failed for '" .. commandName .. "': " .. error)
        return false
    end
    
    -- Queue the command
    table.insert(CommandSystem.commandQueue, {
        name = commandName,
        args = args,
        timestamp = love.timer.getTime()
    })
    
    return true
end

-- Execute all queued commands (called from main thread)
function CommandSystem.processCommands()
    while #CommandSystem.commandQueue > 0 do
        local queuedCommand = table.remove(CommandSystem.commandQueue, 1)
        local command = CommandSystem.commands[queuedCommand.name]
        
        if command then
            local success, result = pcall(command.execute, unpack(queuedCommand.args))
            if not success then
                logError("CommandSystem: Failed to execute '" .. queuedCommand.name .. "': " .. tostring(result))
            end
        end
    end
end

-- Get list of all available commands
function CommandSystem.getCommands()
    return CommandSystem.commands
end

-- Get command info
function CommandSystem.getCommandInfo(name)
    return CommandSystem.commands[name]
end

-- Clear command queue (emergency reset)
function CommandSystem.clearQueue()
    CommandSystem.commandQueue = {}
    logInfo("CommandSystem: Command queue cleared")
end

return CommandSystem