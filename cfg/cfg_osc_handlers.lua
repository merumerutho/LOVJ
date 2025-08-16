-- cfg_osc_handlers.lua
--
-- OSC message routing configuration for LOVJ
-- Maps OSC addresses to handler functions
--

local cfg_osc_handlers = {}

-- Handler function registry
cfg_osc_handlers.handlers = {}

-- Global Controls
cfg_osc_handlers.handlers["/lovj/global/selectedPatch"] = {
    target = "global",
    action = "setSelectedPatch",
    type = "int",
    range = {1, 12}
}

cfg_osc_handlers.handlers["/lovj/global/bpm"] = {
    target = "global", 
    action = "setBPM",
    type = "float",
    range = {60, 200}
}

-- System Controls
cfg_osc_handlers.handlers["/lovj/system/fullscreen"] = {
    target = "system",
    action = "toggleFullscreen", 
    type = "bool"
}

cfg_osc_handlers.handlers["/lovj/system/shaders/enabled"] = {
    target = "system",
    action = "toggleShaders",
    type = "bool"
}

cfg_osc_handlers.handlers["/lovj/system/upscaling"] = {
    target = "system", 
    action = "changeUpscaling",
    type = "int",
    range = {0, 3}
}

cfg_osc_handlers.handlers["/lovj/system/reset"] = {
    target = "system",
    action = "reset",
    type = "trigger"
}

-- Patch Control Patterns (will be dynamically expanded)
cfg_osc_handlers.patchPatterns = {
    ["/lovj/patch/%d+/load"] = {
        target = "patch",
        action = "loadPatch", 
        type = "string"
    },
    ["/lovj/patch/%d+/reset"] = {
        target = "patch",
        action = "resetPatch",
        type = "trigger"
    },
    ["/lovj/patch/%d+/parameters/(.+)"] = {
        target = "patch",
        action = "setParameter",
        type = "float"
    },
    ["/lovj/patch/%d+/savestate/load"] = {
        target = "patch", 
        action = "loadSavestate",
        type = "int",
        range = {1, 12}
    },
    ["/lovj/patch/%d+/savestate/save"] = {
        target = "patch",
        action = "saveSavestate", 
        type = "int",
        range = {1, 12}
    },
    ["/lovj/patch/%d+/graphics/(.+)"] = {
        target = "patch",
        action = "setGraphics",
        type = "variant"
    },
    ["/lovj/patch/%d+/globals/(.+)"] = {
        target = "patch", 
        action = "setGlobal",
        type = "variant"
    }
}

-- Shader Control Patterns
cfg_osc_handlers.shaderPatterns = {
    ["/lovj/shader/%d+/postprocess/%d+/select"] = {
        target = "shader",
        action = "selectShader",
        type = "int"
    },
    ["/lovj/shader/%d+/postprocess/%d+/(.+)"] = {
        target = "shader", 
        action = "setShaderParameter",
        type = "float"
    }
}

-- OSC Connection Configuration
-- Each connection spawns a dedicated OSCThread for receiving OSC messages
cfg_osc_handlers.connections = {
    {
        id = "main",
        address = "127.0.0.1",  -- IP address to bind OSC listener
        port = 8000,            -- UDP port for OSC messages
        enabled = true          -- Enable this OSC connection
    },
    {
        id = "secondary", 
        address = "127.0.0.1",  -- Second OSC input (disabled by default)
        port = 8001,
        enabled = false
    }
}

-- Validation ranges and defaults
cfg_osc_handlers.validation = {
    float = function(value, range)
        if not range then return value end
        return math.max(range[1], math.min(range[2], value))
    end,
    int = function(value, range)
        local val = math.floor(value)
        if not range then return val end
        return math.max(range[1], math.min(range[2], val))
    end,
    bool = function(value)
        return value > 0
    end,
    string = function(value)
        return tostring(value)
    end,
    trigger = function(value)
        return value > 0
    end
}

return cfg_osc_handlers