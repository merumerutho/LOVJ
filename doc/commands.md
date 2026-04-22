# Command System

[Back to index](index.md)

The command system (`lib/command_system.lua`) provides a protocol-agnostic way to define and execute actions. Commands can be triggered from [keyboard](keyboard.md), [MIDI](midi.md), [OSC](osc.md), or the [Studio GUI](studio.md).

## Architecture

```
Input sources           Command System              Side effects
  Keyboard ──┐
  MIDI ──────┤──→ queueCommand() ──→ processCommands() ──→ patch/shader/clock
  OSC ───────┤                                               state changes
  Studio WS ─┘
```

Commands are registered at startup in `cfg/cfg_commands.lua`, then queued and executed on the main thread each frame.

## Registering Commands

```lua
CommandSystem.registerCommand("myCommand", {
    description = "Do something useful",
    category = "patch",
    parameters = {
        {name = "slot", type = "int", min = 1, max = 12, required = true},
        {name = "value", type = "float", min = 0, max = 1, required = true},
    },
    execute = function(slot, value)
        -- implementation
    end
})
```

### Parameter Types

| Type | Validation |
|------|-----------|
| `int` | Must be a number, floored. Optional `min`/`max`. |
| `float` | Must be a number. Optional `min`/`max`. |
| `bool` | Must be boolean or number. |
| `string` | Must be a string. Optional `maxLen`. |

## Executing Commands

```lua
CommandSystem.queueCommand("myCommand", {1, 0.75})  -- queue for next frame
CommandSystem.processCommands()                       -- execute all queued (called in main loop)
```

## Command Catalog

### Global

| Command | Parameters | Description |
|---------|-----------|-------------|
| `setSelectedPatch` | `slot:int` | Set the active patch slot |
| `setBPM` | `bpm:float` | Set global BPM |
| `tapBPM` | — | Tap-tempo beat |
| `resetPhase` | — | Reset clock phase to downbeat |

### System

| Command | Parameters | Description |
|---------|-----------|-------------|
| `toggleFullscreen` | `enable:bool?` | Toggle or set fullscreen |
| `toggleShaders` | `enable:bool` | Enable/disable shader processing |
| `changeUpscaling` | — | Cycle upscaling mode |
| `systemReset` | `confirm:bool` | Restart application |

### Patch

| Command | Parameters | Description |
|---------|-----------|-------------|
| `loadPatch` | `slot:int`, `patchName:string` | Load a patch into a slot |
| `resetPatch` | `slot:int` | Re-init a patch |
| `setPatchParameter` | `slot:int`, `paramId:int`, `value:float` | Set parameter by ID |
| `setPatchParameterByName` | `slot:int`, `paramName:string`, `value:float` | Set parameter by name |
| `loadSavestate` | `slot:int`, `savestateId:int` | Load a savestate |
| `saveSavestate` | `slot:int`, `savestateId:int` | Save current state |
| `setPatchGraphics` | `slot:int`, `paramName:string`, `value` | Set graphics resource |
| `setPatchGlobal` | `slot:int`, `paramName:string`, `value` | Set global setting |

### Shader

| Command | Parameters | Description |
|---------|-----------|-------------|
| `selectShader` | `slot:int`, `layer:int`, `shaderId:int` | Select shader for a layer |
| `setShaderParameter` | `slot:int`, `layer:int`, `paramName:string`, `value:float` | Set shader param |
| `cycleShader` | `slot:int`, `layer:int` | Cycle to next shader |

## Related

- [Keyboard Mapping](keyboard.md) — bind keys to commands
- [MIDI](midi.md) — bind MIDI messages to commands
- [OSC](osc.md) — bind OSC addresses to commands
