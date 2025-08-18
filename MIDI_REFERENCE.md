# LOVJ MIDI Integration Guide

## Quick Setup

### 1. Install MIDI Library
Download lovemidi DLL from [SiENcE/lovemidi](https://github.com/SiENcE/lovemidi):
- For 32-bit Love2D: Download `luamidi.dll_32`, rename to `luamidi.dll`
- For 64-bit Love2D: Download `luamidi.dll_64`, rename to `luamidi.dll`
- Place in LOVJ project root (same location as `SpoutLibrary.dll`)

### 2. Enable MIDI
Edit `cfg/cfg_midi_mapping.lua`:
```lua
cfg_midi_mapping.connections = {
    {
        id = "controller1",
        device = 0,  -- First MIDI device
        enabled = true  -- Enable this connection
    }
}
```

### 3. Test Connection
Run LOVJ - check console for MIDI device detection:
```
MIDIThread [controller1]: Found 2 MIDI input devices
MIDIThread [controller1]: Device 0: USB MIDI Controller
MIDIThread [controller1]: Device 1: MIDI Keyboard
```

## Device Auto-Detection

### Enable Auto-Detection
```lua
cfg_midi_mapping.autoDetect = {
    enabled = true,
    devicePatterns = {
        "controller",  -- Matches "USB MIDI Controller"
        "launchpad",   -- Matches "Novation Launchpad"
        "apc",         -- Matches "Akai APC40"
        "keyboard"     -- Matches "MIDI Keyboard"
    }
}
```

### Device Matching Methods
```lua
-- Method 1: By index
device = 0  -- Use first MIDI device

-- Method 2: By name search (case-insensitive)
device = "controller"  -- Matches any device with "controller" in name
device = "launchpad"   -- Matches "Novation Launchpad Mini"
```


## Common Mappings

### Control Changes (Knobs/Faders)
```lua
cfg_midi_mapping.ccMappings = {
    -- Patch parameters
    [20] = {
        command = "setPatchParameter",
        args = {"1", "brightness", "$value"},
        transform = {"midiNormalize"}  -- 0-127 → 0-1
    },
    
    -- Global controls
    [7] = {
        command = "setGlobalVolume",
        args = {"$value"},
        transform = {"midiNormalize"}
    },
    
    -- BPM control
    [74] = {
        command = "setBPM", 
        args = {"$value"},
        transform = {"ccToBPM"}  -- 0-127 → 60-180 BPM
    }
}
```

### Note Triggers (Pads/Keys)
```lua
cfg_midi_mapping.noteMappings = {
    -- Patch selection
    [60] = {  -- Middle C
        command = "setSelectedPatch",
        args = {"1"},
        type = "noteOn"
    },
    
    -- Trigger with velocity
    [36] = {  -- Kick pad
        command = "triggerBeat",
        args = {"kick", "$velocity"},
        type = "noteOn",
        transform = {"midiNormalize"}
    }
}
```

### Program Changes (Patch Select)
```lua
cfg_midi_mapping.programMappings = {
    [0] = {
        command = "loadPatch",
        args = {"1", "demo1"}
    },
    [1] = {
        command = "selectShader", 
        args = {"1", "0", "blur"}
    }
}
```

## Device-Specific Mappings

### Per-Device Configuration
```lua
-- Format: "deviceId_channel_ccNumber"
["controller1_1_20"] = {  -- Device controller1, Channel 1, CC 20
    command = "setPatchParameter",
    args = {"1", "brightness", "$value"}
},

["keyboard_1_1"] = {      -- Device keyboard, Channel 1, CC 1
    command = "setGlobalVolume", 
    args = {"$value"}
}
```

## Value Transformations

### Built-in Transforms
```lua
cfg_midi_mapping.transformations = {
    midiNormalize = function(value) return value / 127.0 end,
    ccToSlot = function(value) return math.floor((value/127) * 7) + 1 end,
    ccToBPM = function(value) return 60 + (value/127) * 120 end,
    booleanValue = function(value) return value ~= 0 end
}
```

### Custom Transforms
```lua
-- Add your own transformations
cfg_midi_mapping.transformations.myCustom = function(value)
    return math.sin(value / 127 * math.pi)  -- Sine wave mapping
end
```

## Troubleshooting

### No MIDI Devices Found
- Check that MIDI controller is connected and powered
- Verify `luamidi.dll` is in project root
- Install Visual Studio 2012 Runtime if needed

### MIDI Not Responding
- Check `enabled = true` in connection config
- Verify device name/index in console output
- Ensure MIDI controller is sending on expected channel


## Advanced Usage

### Multiple Controllers
```lua
cfg_midi_mapping.connections = {
    {id = "main", device = "Controller", enabled = true},
    {id = "keys", device = "Keyboard", enabled = true}
}
```

### Dynamic Mappings
```lua
-- Runtime mapping changes via command system
CommandSystem.queueCommand("addMIDIMapping", {
    "cc", "controller1", 1, 50, "setPatchParameter", {"2", "speed", "$value"}
})
```