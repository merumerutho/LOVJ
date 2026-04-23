# MIDI

[Back to index](../index.md)

LOVJ routes MIDI messages to [commands](commands.md) through `lib/midi/midi_dispatcher.lua` using mappings defined in `cfg/cfg_midi_mapping.lua`.

## Setup

Download lovemidi DLL from [SiENcE/lovemidi](https://github.com/SiENcE/lovemidi):
- For 64-bit LOVE2D: download `luamidi.dll_64`, rename to `luamidi.dll`
- Place in the LOVJ project root

## Connections

```lua
cfg_midi_mapping.connections = {
    { id = "controller1", device = 0, enabled = true },           -- by index
    { id = "keys", device = "MIDI Keyboard", enabled = true },    -- by name
}
```

Device can be an index (integer) or a name search string (case-insensitive partial match). Each enabled connection spawns a background thread that reads MIDI input and forwards messages to the dispatcher.

On startup, the console shows detected devices:

```
MIDIThread [controller1]: Found 2 MIDI input devices
MIDIThread [controller1]: Device 0: USB MIDI Controller
MIDIThread [controller1]: Device 1: MIDI Keyboard
```

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
| `ccToBPM` | CC value → BPM range (60-180) |
| `noteToFreq` | Note number → frequency |
| `ccToShader` | CC value → shader index |

Custom transforms can be added:

```lua
cfg_midi_mapping.transformations.myCustom = function(value)
    return math.sin(value / 127 * math.pi)
end
```

## Auto-Detection

```lua
cfg_midi_mapping.autoDetect = {
    enabled = true,
    devicePatterns = {"nanoKONTROL", "Launch", "APC"},
}
```

When enabled, the dispatcher attempts to connect to any device whose name matches one of the patterns (case-insensitive).

## Multiple Controllers

```lua
cfg_midi_mapping.connections = {
    { id = "main", device = "Controller", enabled = true },
    { id = "keys", device = "Keyboard", enabled = true },
}
```

Use device-specific key format to route different controllers to different commands:

```lua
["main_1_20"] = { command = "setPatchParameterByName", args = {1, "speed"} },
["keys_1_1"]  = { command = "setBPM", transform = "ccToBPM" },
```

## Troubleshooting

- **No MIDI devices found** — check that the controller is connected and `luamidi.dll` is in the project root. Install Visual Studio 2012 Runtime if needed.
- **MIDI not responding** — verify `enabled = true` in connection config. Check device name/index in console output. Ensure the controller is sending on the expected channel.

## Related

- [Command System](commands.md) — available commands
- [Keyboard Mapping](keyboard.md) — alternative input
- [OSC](osc.md) — network-based control
