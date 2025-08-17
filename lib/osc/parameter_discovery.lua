-- parameter_discovery.lua
--
-- OSC Parameter Discovery System for LOVJ
-- Provides automatic parameter enumeration and feedback to external controllers
--

local ParameterDiscovery = {}

-- Dependencies
local resources = lovjRequire("lib/resources")
local feedbackConfig = lovjRequire("cfg/cfg_parameter_feedback")
local cfg_bpm = lovjRequire("cfg/cfg_bpm")

-- Parameter discovery state
ParameterDiscovery.discoveredParameters = {}
ParameterDiscovery.parameterCache = {}
ParameterDiscovery.lastUpdateTime = 0
ParameterDiscovery.updateInterval = feedbackConfig.updateInterval or 1.0  -- Update every second

-- Parameter categories for better organization
ParameterDiscovery.categories = {
    GLOBAL = "global",
    PATCH = "patch", 
    SHADER = "shader",
    SYSTEM = "system"
}

-- Parameter value types
ParameterDiscovery.valueTypes = {
    FLOAT = "float",
    INT = "int", 
    BOOL = "bool",
    STRING = "string",
    ENUM = "enum"
}

-- Initialize parameter discovery system
function ParameterDiscovery.init()
    logInfo("ParameterDiscovery: Initializing parameter discovery system")
    ParameterDiscovery.discoveredParameters = {}
    ParameterDiscovery.parameterCache = {}
    ParameterDiscovery.lastUpdateTime = 0
end

-- Register a parameter for discovery
function ParameterDiscovery.registerParameter(oscAddress, paramInfo)
    if not oscAddress or not paramInfo then
        logError("ParameterDiscovery: Invalid parameter registration")
        return false
    end
    
    local parameter = {
        address = oscAddress,
        category = paramInfo.category or ParameterDiscovery.categories.GLOBAL,
        valueType = paramInfo.valueType or ParameterDiscovery.valueTypes.FLOAT,
        currentValue = paramInfo.currentValue or 0,
        defaultValue = paramInfo.defaultValue or 0,
        minValue = paramInfo.minValue,
        maxValue = paramInfo.maxValue,
        possibleValues = paramInfo.possibleValues, -- For enums
        description = paramInfo.description or "",
        readable = paramInfo.readable ~= false, -- Default true
        writable = paramInfo.writable ~= false, -- Default true
        lastChanged = love.timer.getTime()
    }
    
    ParameterDiscovery.discoveredParameters[oscAddress] = parameter
    return true
end

-- Unregister a parameter
function ParameterDiscovery.unregisterParameter(oscAddress)
    ParameterDiscovery.discoveredParameters[oscAddress] = nil
    ParameterDiscovery.parameterCache[oscAddress] = nil
end

-- Update parameter value (called when parameters change)
function ParameterDiscovery.updateParameterValue(oscAddress, newValue)
    local parameter = ParameterDiscovery.discoveredParameters[oscAddress]
    if parameter then
        parameter.currentValue = newValue
        parameter.lastChanged = love.timer.getTime()
        return true
    end
    return false
end

-- Get all parameters for a specific category
function ParameterDiscovery.getParametersByCategory(category)
    local categoryParams = {}
    for address, param in pairs(ParameterDiscovery.discoveredParameters) do
        if param.category == category then
            categoryParams[address] = param
        end
    end
    return categoryParams
end

-- Get all available parameters
function ParameterDiscovery.getAllParameters()
    return ParameterDiscovery.discoveredParameters
end

-- Get parameter info by address
function ParameterDiscovery.getParameter(oscAddress)
    return ParameterDiscovery.discoveredParameters[oscAddress]
end

-- Discover parameters from current LOVJ state (called on-demand)
function ParameterDiscovery.discoverParameters()
    -- Clear existing discovered parameters to get fresh state
    ParameterDiscovery.discoveredParameters = {}
    
    -- Discover global parameters
    ParameterDiscovery.discoverGlobalParameters()
    
    -- Discover patch parameters
    ParameterDiscovery.discoverPatchParameters()
    
    -- Discover shader parameters  
    ParameterDiscovery.discoverShaderParameters()
    
    -- Discover system parameters
    ParameterDiscovery.discoverSystemParameters()
    
    logInfo("ParameterDiscovery: Discovered " .. table.getn(ParameterDiscovery.discoveredParameters) .. " parameters on request")
end

-- Discover global parameters
function ParameterDiscovery.discoverGlobalParameters()
    --- TODO
    
end

-- Discover patch parameters
function ParameterDiscovery.discoverPatchParameters()
    if not patches then return end
    
    for slot = 1, 12 do
        local patch = patches[slot]
        if patch and patch.resources then
            -- Discover patch-specific parameters
            for i = 1, #patch.resources.parameters do
                local paramName = patch.resources.parameters:getName(i)
                if paramName and paramName ~= ("resource" .. i) then -- Skip default names
                    local oscAddress = "/lovj/patch/" .. slot .. "/param/" .. i
                    ParameterDiscovery.registerParameter(oscAddress, {
                        category = ParameterDiscovery.categories.PATCH,
                        valueType = ParameterDiscovery.valueTypes.FLOAT,
                        currentValue = patch.resources.parameters:getByIdx(i),
                        defaultValue = 0,
                        minValue = 0,
                        maxValue = 1,
                        paramId = i,
                        paramName = paramName,
                        description = "Patch " .. slot .. " parameter " .. i .. ": " .. paramName
                    })
                end
            end
            
            -- Discover graphics resources
            for i = 1, #patch.resources.graphics do
                local resourceName = patch.resources.graphics:getName(i)
                if resourceName and resourceName ~= ("resource" .. i) then
                    local oscAddress = "/lovj/patch/" .. slot .. "/graphics/" .. resourceName
                    ParameterDiscovery.registerParameter(oscAddress, {
                        category = ParameterDiscovery.categories.PATCH,
                        valueType = ParameterDiscovery.valueTypes.STRING,
                        currentValue = patch.resources.graphics:get(resourceName) or "",
                        defaultValue = "",
                        description = "Patch " .. slot .. " graphics resource: " .. resourceName,
                        writable = true
                    })
                end
            end
        end
    end
end

-- Discover shader parameters
function ParameterDiscovery.discoverShaderParameters()
    if not shaderSystem or not shaderSystem.shaders then return end
    
    -- Iterate through available shaders
    for shaderName, shaderData in pairs(shaderSystem.shaders) do
        if shaderData.parameters then
            for paramName, paramInfo in pairs(shaderData.parameters) do
                local oscAddress = "/lovj/shader/global/param/" .. shaderName .. "_" .. paramName
                ParameterDiscovery.registerParameter(oscAddress, {
                    category = ParameterDiscovery.categories.SHADER,
                    valueType = ParameterDiscovery.valueTypes.FLOAT,
                    currentValue = paramInfo.value or paramInfo.default or 0,
                    defaultValue = paramInfo.default or 0,
                    minValue = paramInfo.min,
                    maxValue = paramInfo.max,
                    description = "Shader parameter: " .. shaderName .. " " .. paramName
                })
            end
        end
    end
    
    -- Patch-specific shader parameters
    for slot = 1, 12 do
        for layer = 0, 3 do -- Assuming max 4 shader layers
            local oscAddress = "/lovj/shader/" .. slot .. "/" .. layer .. "/select"
            ParameterDiscovery.registerParameter(oscAddress, {
                category = ParameterDiscovery.categories.SHADER,
                valueType = ParameterDiscovery.valueTypes.STRING,
                currentValue = "",
                defaultValue = "",
                description = "Selected shader for patch " .. slot .. " layer " .. layer
            })
        end
    end
end

-- Discover system parameters
function ParameterDiscovery.discoverSystemParameters()
    -- Fullscreen toggle
    ParameterDiscovery.registerParameter("/lovj/system/fullscreen", {
        category = ParameterDiscovery.categories.SYSTEM,
        valueType = ParameterDiscovery.valueTypes.BOOL,
        currentValue = love.window.getFullscreen(),
        defaultValue = false,
        description = "Fullscreen mode toggle"
    })
    
    -- Shader system toggle
    ParameterDiscovery.registerParameter("/lovj/system/shaders", {
        category = ParameterDiscovery.categories.SYSTEM,
        valueType = ParameterDiscovery.valueTypes.BOOL,
        currentValue = shadersEnabled or true,
        defaultValue = true,
        description = "Shader system enable/disable"
    })
    
    -- Upscaling mode
    ParameterDiscovery.registerParameter("/lovj/system/upscaling", {
        category = ParameterDiscovery.categories.SYSTEM,
        valueType = ParameterDiscovery.valueTypes.ENUM,
        currentValue = upscalingMode or "linear",
        defaultValue = "linear",
        possibleValues = {"nearest", "linear"},
        description = "Display upscaling mode"
    })
end

-- Generate parameter discovery response for OSC
function ParameterDiscovery.generateDiscoveryResponse(category)
    local response = {}
    local params = category and ParameterDiscovery.getParametersByCategory(category) or ParameterDiscovery.getAllParameters()
    
    for address, param in pairs(params) do
        table.insert(response, {
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
        })
    end
    
    return response
end

return ParameterDiscovery