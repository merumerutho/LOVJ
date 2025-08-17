-- cfg_osc_mapping.lua
--
-- OSC-specific mapping configuration
-- Maps OSC addresses to generic commands
--

local cfg_osc_mapping = {}

-- OSC connection settings
cfg_osc_mapping.connections = {
    {
        id = "touchosc",
        address = "127.0.0.1",
        port = 8000,
        enabled = true
    },
    {
        id = "reaper",
        address = "127.0.0.1", 
        port = 8001,
        enabled = false
    }
}

-- Direct OSC address to command mappings
cfg_osc_mapping.directMappings = {
    -- Global commands
    ["/lovj/global/selectedPatch"] = {
        command = "setSelectedPatch",
        args = {"$1"}  -- $1 means use first OSC argument
    },
    ["/lovj/global/bpm"] = {
        command = "setBPM",
        args = {"$1"}
    },
    
    -- System commands
    ["/lovj/system/fullscreen"] = {
        command = "toggleFullscreen",
        args = {"$1"}
    },
    ["/lovj/system/shaders"] = {
        command = "toggleShaders", 
        args = {"$1"}
    },
    ["/lovj/system/upscaling"] = {
        command = "changeUpscaling",
        args = {}
    },
    ["/lovj/system/reset"] = {
        command = "systemReset",
        args = {"$1"}
    }
}

-- Pattern-based mappings using Lua patterns
cfg_osc_mapping.patternMappings = {
    -- Patch commands: /lovj/patch/<slot>/command
    {
        pattern = "^/lovj/patch/(%d+)/load$",
        command = "loadPatch",
        args = {"$1", "$2"}  -- $1 = slot from pattern, $2 = OSC argument
    },
    {
        pattern = "^/lovj/patch/(%d+)/reset$",
        command = "resetPatch", 
        args = {"$1"}
    },
    {
        pattern = "^/lovj/patch/(%d+)/param/(.+)$",
        command = "setPatchParameter",
        args = {"$1", "$2", "$3"}  -- slot, param name, value
    },
    {
        pattern = "^/lovj/patch/(%d+)/savestate/(%d+)/load$",
        command = "loadSavestate",
        args = {"$1", "$2"}
    },
    {
        pattern = "^/lovj/patch/(%d+)/savestate/(%d+)/save$",
        command = "saveSavestate",
        args = {"$1", "$2"}
    },
    {
        pattern = "^/lovj/patch/(%d+)/graphics/(.+)$",
        command = "setPatchGraphics",
        args = {"$1", "$2", "$3"}
    },
    {
        pattern = "^/lovj/patch/(%d+)/global/(.+)$",
        command = "setPatchGlobal",
        args = {"$1", "$2", "$3"}
    },
    
    -- Shader commands: /lovj/shader/<slot>/<layer>/command
    {
        pattern = "^/lovj/shader/(%d+)/(%d+)/select$",
        command = "selectShader",
        args = {"$1", "$2", "$3"}  -- slot, layer, shader ID
    },
    {
        pattern = "^/lovj/shader/(%d+)/(%d+)/param/(.+)$",
        command = "setShaderParameter",
        args = {"$1", "$2", "$3", "$4"}  -- slot, layer, param name, value
    }
}

-- Value transformations (optional)
cfg_osc_mapping.transformations = {
    -- Convert OSC floats to integers for slot numbers
    integerSlot = function(value)
        return math.floor(tonumber(value) or 1)
    end,
    
    -- Convert 0/1 to boolean
    booleanValue = function(value)
        return value ~= 0
    end,
    
    -- Normalize 0-127 MIDI range to 0-1
    midiNormalize = function(value)
        return value / 127.0
    end
}

-- Apply transformations to specific mappings
cfg_osc_mapping.directMappings["/lovj/global/selectedPatch"].transform = {"integerSlot"}
cfg_osc_mapping.directMappings["/lovj/system/fullscreen"].transform = {"booleanValue"}
cfg_osc_mapping.directMappings["/lovj/system/shaders"].transform = {"booleanValue"}

return cfg_osc_mapping