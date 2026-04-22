# MIDI

[Back to index](index.md)

LOVJ routes MIDI messages to [commands](commands.md) through `lib/midi/midi_dispatcher.lua` using mappings defined in `cfg/cfg_midi_mapping.lua`.

## Connections

```lua
cfg_midi_mapping.connections = {
    { id = "controller1", device = "My MIDI Controller", enabled = true },
}
```

Each enabled connection spawns a background thread that reads MIDI input and forwards messages to the dispatcher.

## CC Mappings

```lua
cfg_midi_mapping.ccMappings = {
    ["1"] = {
        command = "setPatchParameterByName",
        args = {1, "speed"},
        transform = "midiNormalize",   -- 0-127 → 0.0-1.0
    },
    ["controller1_1_74"] = {           -- device_channel_cc
        command = "setBPM",
        transform = "ccToBPM",
    },
}
```

Key format: `"ccNumber"` (matches any device) or `"deviceId_channel_ccNumber"` (specific device).

## Note Mappings

```lua
cfg_midi_mapping.noteMappings = {
    ["60"] = {
        command = "loadPatch",
        args = {1, "demos/demo1/source/demo_1"},
        type = "noteOn",
    },
}
```

Key format: `"noteNumber"` or `"deviceId_channel_noteNumber"`. Types: `"noteOn"`, `"noteOff"`.

## Program Change Mappings

```lua
cfg_midi_mapping.programMappings = {
    ["0"] = { command = "setSelectedPatch", args = {1} },
}
```

## Value Transforms

Built-in transforms convert MIDI values to command arguments:

| Transform | Conversion |
|-----------|-----------|
| `midiNormalize` | 0-127 → 0.0-1.0 |
| `booleanValue` | 0 = false, >0 = true |
| `ccToSlot` | CC value → slot index |
| `ccToBPM` | CC value → BPM range |
| `noteToFreq` | Note number → frequency |
| `ccToShader` | CC value → shader index |

## Auto-Detection

```lua
cfg_midi_mapping.autoDetect = {
    enabled = true,
    devicePatterns = {"nanoKONTROL", "Launch"},
}
```

When enabled, the dispatcher attempts to connect to devices matching the given name patterns.

## Related

- [Command System](commands.md) — available commands
- [Keyboard Mapping](keyboard.md) — alternative input
- [OSC](osc.md) — network-based control
