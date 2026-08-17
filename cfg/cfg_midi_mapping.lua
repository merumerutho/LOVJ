local machine = require("lib/machine")

local cfg_midi_mapping = {}

cfg_midi_mapping.connections = {}

cfg_midi_mapping.ccMappings = {}
cfg_midi_mapping.noteMappings = {}
cfg_midi_mapping.programMappings = {}

cfg_midi_mapping.transformations = {
    midiNormalize = function(value)
        return value / 127.0
    end,

    booleanValue = function(value)
        return value ~= 0
    end,

    ccToSlot = function(value)
        return math.floor((value / 127) * 7) + 1
    end,

    ccToBPM = function(value)
        return 60 + (value / 127) * 120
    end,

    noteToFreq = function(note)
        return 440 * math.pow(2, (note - 69) / 12)
    end,

    ccToShader = function(value)
        local shaderCount = 8
        return math.floor((value / 127) * (shaderCount - 1))
    end
}

cfg_midi_mapping.autoDetect = {
    enabled = true,
    devicePatterns = {
        "controller",
        "keyboard",
        "midi",
        "launchpad",
        "apc"
    }
}

return machine.apply("cfg_midi_mapping", cfg_midi_mapping)
