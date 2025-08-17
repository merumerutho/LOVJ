-- cfg_parameter_feedback.lua
--
-- Configuration for OSC parameter feedback and discovery system
--

local cfg_parameter_feedback = {}

-- Parameter feedback settings
cfg_parameter_feedback.enabled = true
cfg_parameter_feedback.onDemandDiscovery = true  -- Discovery only when requested (no automatic scanning)

-- Discovery protocol settings
cfg_parameter_feedback.discovery = {
    enabled = true,
    welcomeOnConnect = true,
    updateTickTimeout = 30.0,  -- seconds (renamed from heartbeatTimeout)
    maxClients = 10,
    onDemandOnly = true  -- Parameters are discovered only when requested, not continuously
}

-- Categories available for discovery (all supported, discovered on-demand)
cfg_parameter_feedback.discoveryCategories = {
    "global",
    "patch", 
    "shader",
    "system"
}

-- Parameter value constraints and metadata
cfg_parameter_feedback.parameterConstraints = {
    -- Global parameters
    ["/lovj/global/bpm"] = {
        min = 60,
        max = 200,
        step = 1,
        unit = "bpm",
        description = "Global beats per minute"
    },
    ["/lovj/global/selectedPatch"] = {
        min = 1,
        max = 12,
        step = 1,
        unit = "slot",
        description = "Currently selected patch slot"
    },
    ["/lovj/global/volume"] = {
        min = 0.0,
        max = 1.0,
        step = 0.01,
        unit = "gain",
        description = "Master volume level"
    },
    
    -- System parameters
    ["/lovj/system/fullscreen"] = {
        valueType = "bool",
        description = "Fullscreen mode toggle"
    },
    ["/lovj/system/shaders"] = {
        valueType = "bool", 
        description = "Shader system enable/disable"
    },
    ["/lovj/system/upscaling"] = {
        valueType = "enum",
        possibleValues = {"nearest", "linear"},
        description = "Display upscaling mode"
    }
}

-- Pattern-based parameter constraints for dynamic parameters
cfg_parameter_feedback.parameterPatterns = {
    -- Patch parameters (apply to all patch slots)
    {
        pattern = "^/lovj/patch/(%d+)/param/(%d+)$",
        constraints = {
            min = 0.0,
            max = 1.0,
            step = 0.01,
            unit = "normalized",
            description = function(slot, paramId)
                return "Patch " .. slot .. " parameter ID " .. paramId
            end
        }
    },
    
    -- Shader parameters
    {
        pattern = "^/lovj/shader/(%d+)/(%d+)/param/(.+)$",
        constraints = {
            min = 0.0,
            max = 1.0,
            step = 0.01,
            unit = "normalized", 
            description = function(slot, layer, paramName)
                return "Shader parameter for patch " .. slot .. " layer " .. layer .. ": " .. paramName
            end
        }
    },
    
    -- Patch graphics resources
    {
        pattern = "^/lovj/patch/(%d+)/graphics/(.+)$",
        constraints = {
            valueType = "string",
            description = function(slot, resourceName)
                return "Graphics resource for patch " .. slot .. ": " .. resourceName
            end
        }
    }
}

-- Parameter feedback filters (what to send to clients)
cfg_parameter_feedback.feedbackFilters = {
    -- Send all parameter changes by default
    sendAllChanges = true,
    
    -- Rate limiting for high-frequency parameters
    rateLimiting = {
        enabled = true,
        defaultInterval = 0.05,  -- 50ms minimum between updates
        specialIntervals = {
            ["/lovj/global/bpm"] = 0.1,  -- 100ms for BPM
            ["/lovj/system/.*"] = 0.2    -- 200ms for system parameters
        }
    },
    
    -- Filter by value change threshold
    changeThreshold = {
        enabled = true,
        defaultThreshold = 0.01,  -- 1% change for float values
        specialThresholds = {
            ["/lovj/global/bpm"] = 1.0,  -- 1 BPM change
            ["/lovj/.*bool.*"] = 0       -- Any change for boolean values
        }
    }
}

-- Custom parameter discovery handlers
cfg_parameter_feedback.customDiscoveryHandlers = {
    -- Custom handler for patch-specific discovery
    patches = function()
        local customParameters = {}
        
        -- Add patch-specific parameters based on currently loaded patches
        if patches then
            for slot = 1, 12 do
                local patch = patches[slot]
                if patch and patch.name then
                    -- Add patch name parameter
                    customParameters["/lovj/patch/" .. slot .. "/name"] = {
                        valueType = "string",
                        currentValue = patch.name,
                        description = "Name of patch in slot " .. slot,
                        writable = false
                    }
                    
                    -- Add patch enabled state
                    customParameters["/lovj/patch/" .. slot .. "/enabled"] = {
                        valueType = "bool",
                        currentValue = patch.enabled or true,
                        description = "Enable/disable patch in slot " .. slot
                    }
                end
            end
        end
        
        return customParameters
    end,
    
    -- Custom handler for shader discovery
    shaders = function()
        local customParameters = {}
        
        -- Add available shader list
        if shaderSystem and shaderSystem.availableShaders then
            customParameters["/lovj/shaders/available"] = {
                valueType = "stringArray",
                currentValue = shaderSystem.availableShaders,
                description = "List of available shaders",
                writable = false
            }
        end
        
        return customParameters
    end
}

-- Logging settings for parameter feedback
cfg_parameter_feedback.logging = {
    enabled = true,
    logDiscoveryRequests = true,
    logParameterUpdates = false,  -- Can be verbose
    logClientConnections = true
}

return cfg_parameter_feedback