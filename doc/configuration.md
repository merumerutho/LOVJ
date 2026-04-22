# Configuration

[Back to index](index.md)

All configuration lives in `cfg/` as Lua modules. They are loaded at startup and exposed as globals in `main.lua`.

## Module Reference

| Module | Global | Purpose |
|--------|--------|---------|
| `cfg_app.lua` | `cfgApp` | Application title and icon path |
| `cfg_bpm.lua` | — | Default BPM (`default_bpm = 128`) |
| `cfg_commands.lua` | `cfgCommands` | [Command](commands.md) registration |
| `cfg_globals.lua` | `cfgGlobals` | Global settings (max parameter count, shared values) |
| `cfg_kb_mapping.lua` | `cfgKbMapping` | [Keyboard](keyboard.md) → command bindings |
| `cfg_midi_mapping.lua` | — | [MIDI](midi.md) → command bindings |
| `cfg_osc_mapping.lua` | — | [OSC](osc.md) → command bindings |
| `cfg_patches.lua` | `cfgPatches` | Patch list and default patch |
| `cfg_screen.lua` | `cfgScreen` | Resolution and upscaling |
| `cfg_shaders.lua` | `cfgShaders` | [Shader](shaders.md) loading and parameters |
| `cfg_spout.lua` | `cfgSpout` | Spout video streaming |
| `cfg_studio.lua` | — | [Studio](studio.md) server ports and address |
| `cfg_timers.lua` | `cfgTimers` | Timer configuration |
| `cfg_version.lua` | `version` | Version string |

## Patches (`cfg_patches.lua`)

```lua
cfg_patches.defaultPatch = {"demos/demo23/source/demo_23"}  -- loaded at startup
cfg_patches.selectedPatch = 1                                -- active slot

cfg_patches.patches = {      -- available for loading via Studio/OSC/MIDI
    "demos/demo1/source/demo_1",
    "demos/demo2/source/demo_2",
    -- ...all 24 demos
}
```

The Studio GUI also scans `demos/` at runtime, so patches not in this list still appear if they follow the naming convention.

## Screen (`cfg_screen.lua`)

```lua
cfg_screen.INTERNAL_RES_WIDTH  = 640   -- render resolution
cfg_screen.INTERNAL_RES_HEIGHT = 320
cfg_screen.WINDOW_WIDTH        = 1280  -- window size
cfg_screen.WINDOW_HEIGHT       = 640
cfg_screen.LOW_RES  = 0
cfg_screen.HIGH_RES = 1
cfg_screen.UPSCALE_MODE = cfg_screen.LOW_RES  -- or HIGH_RES
```

See [Screen & Resolution](screen.md) for runtime behavior.

## Global Settings (`cfg_globals.lua`)

```lua
cfg_globals.SETTINGS_MAX_COUNT = 128  -- max parameters per Resource
cfg_globals.settings = {
    { name = "bpm", value = 128, description = "Global BPM" },
    -- additional shared settings
}
```

## Studio (`cfg_studio.lua`)

```lua
cfg_studio.enabled     = true
cfg_studio.bindAddress = "127.0.0.1"
cfg_studio.httpPort    = 8080       -- serves web GUI
cfg_studio.wsPort      = 8765       -- WebSocket protocol
cfg_studio.staticRoot  = "studio/dist"
```

Set `bindAddress = "0.0.0.0"` to allow access from other devices on the network.

## Shaders (`cfg_shaders.lua`)

Shaders are auto-discovered from `lib/shaders/source/postProcess/` and `lib/shaders/source/other/`. See [Writing Shaders](shaders.md) for the `@param` annotation system.
