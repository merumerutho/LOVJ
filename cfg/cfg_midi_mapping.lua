-- cfg_midi_mapping.lua
--
-- MIDI-specific mapping configuration
-- Maps MIDI messages to generic commands
--

local cfg_midi_mapping = {}

-- MIDI connection settings
cfg_midi_mapping.connections = {
    {
        id = "controller1",
        device = 0,  -- MIDI device index or name (e.g., "MIDI Controller")
        enabled = false  -- Set to true when MIDI controller is available
    },
    {
        id = "keyboard",
        device = "keyboard",  -- Search for device with "keyboard" in name
        enabled = false
    }
}

-- Control Change (CC) mappings
-- Key format: "deviceId_channel_ccNumber" or just "ccNumber" for global
cfg_midi_mapping.ccMappings = {
    -- Global CC mappings (apply to any device/channel)
    [1] = {
        command = "setSelectedPatch",
        args = {"$value"},
        transform = {"ccToSlot"}  -- Transform CC value to patch slot
    },
    [7] = {
        command = "setGlobalVolume", 
        args = {"$value"},
        transform = {"midiNormalize"}  -- Convert 0-127 to 0-1
    },
    [74] = {
        command = "setBPM",
        args = {"$value"},
        transform = {"ccToBPM"}  -- Transform CC to BPM range
    },
    
    -- Device-specific CC mappings
    ["controller1_1_20"] = {
        command = "setPatchParameter",
        args = {"1", "brightness", "$value"},
        transform = {"midiNormalize"}
    },
    ["controller1_1_21"] = {
        command = "setPatchParameter", 
        args = {"1", "contrast", "$value"},
        transform = {"midiNormalize"}
    },
    ["controller1_1_22"] = {
        command = "setPatchParameter",
        args = {"2", "speed", "$value"},
        transform = {"midiNormalize"}
    },
    
    -- Shader parameter control
    ["controller1_1_30"] = {
        command = "setShaderParameter",
        args = {"1", "0", "intensity", "$value"},
        transform = {"midiNormalize"}
    },
    ["controller1_1_31"] = {
        command = "setShaderParameter",
        args = {"1", "0", "frequency", "$value"},
        transform = {"midiNormalize"}
    }
}

-- Note mappings (Note On/Off)
-- Key format: "deviceId_channel_noteNumber" or just "noteNumber" for global
cfg_midi_mapping.noteMappings = {
    -- Global note mappings
    [60] = { -- Middle C
        command = "togglePatch",
        args = {"1"},
        type = "noteOn"  -- Only respond to Note On
    },
    [61] = { -- C#
        command = "togglePatch", 
        args = {"2"},
        type = "noteOn"
    },
    [62] = { -- D
        command = "resetPatch",
        args = {"1"},
        type = "noteOn"
    },
    
    -- Velocity-sensitive mappings
    [64] = { -- E
        command = "setPatchParameter",
        args = {"1", "trigger", "$velocity"},
        type = "noteOn",
        transform = {"midiNormalize"}
    },
    
    -- Device-specific note mappings
    ["controller1_1_36"] = { -- Kick drum pad
        command = "triggerBeat",
        args = {"kick", "$velocity"},
        type = "noteOn",
        transform = {"midiNormalize"}
    },
    ["controller1_1_38"] = { -- Snare drum pad
        command = "triggerBeat",
        args = {"snare", "$velocity"},
        type = "noteOn",
        transform = {"midiNormalize"}
    }
}

-- Program Change mappings
-- Key format: "deviceId_channel_programNumber" or just "programNumber" for global
cfg_midi_mapping.programMappings = {
    -- Global program changes
    [0] = {
        command = "loadPatch",
        args = {"1", "demo1"}
    },
    [1] = {
        command = "loadPatch",
        args = {"1", "demo2"}
    },
    [2] = {
        command = "loadPatch",
        args = {"2", "demo1"}
    },
    
    -- Device-specific program changes
    ["controller1_1_10"] = {
        command = "selectShader",
        args = {"1", "0", "blur"}
    },
    ["controller1_1_11"] = {
        command = "selectShader",
        args = {"1", "0", "distortion"}
    }
}

-- Value transformations
cfg_midi_mapping.transformations = {
    -- Convert MIDI 0-127 range to 0-1
    midiNormalize = function(value)
        return value / 127.0
    end,
    
    -- Convert 0/non-zero to boolean
    booleanValue = function(value)
        return value ~= 0
    end,
    
    -- Convert CC value to patch slot (1-8)
    ccToSlot = function(value)
        return math.floor((value / 127) * 7) + 1
    end,
    
    -- Convert CC value to BPM range (60-180)
    ccToBPM = function(value)
        return 60 + (value / 127) * 120
    end,
    
    -- Convert MIDI note to frequency
    noteToFreq = function(note)
        return 440 * math.pow(2, (note - 69) / 12)
    end,
    
    -- Map CC to shader selection (0-127 to shader index)
    ccToShader = function(value)
        local shaderCount = 8  -- Adjust based on available shaders
        return math.floor((value / 127) * (shaderCount - 1))
    end
}

-- MIDI device auto-detection settings
cfg_midi_mapping.autoDetect = {
    enabled = true,
    devicePatterns = {
        "controller",  -- Match devices with "controller" in name
        "keyboard",    -- Match devices with "keyboard" in name
        "midi",        -- Match devices with "midi" in name
        "launchpad",   -- Match Novation Launchpad devices
        "apc"          -- Match Akai APC devices
    }
}

-- MIDI learning mode settings
cfg_midi_mapping.learning = {
    enabled = false,  -- Set to true to enable MIDI learn mode
    timeout = 5000,   -- Learning timeout in milliseconds
    excludeChannels = {10}  -- Exclude drum channel from learning
}

return cfg_midi_mapping