# Runtime & Main Loop

[Back to index](index.md)

## Initialization Sequence

`main.lua` runs in this order:

1. **Module loading** — core libraries and config modules are loaded via `lovjRequire()` and assigned as globals
2. **`love.load()`**:
   - `screen.init()` — set up resolution and window
   - `cfgTimers.init()` — create global timer
   - `cfgShaders.init()` — scan and parse GLSL files
   - `clock.init()` — start transport clock
   - Create `patchSlots` from `cfgPatches.defaultPatch`
   - Initialize `globalSettings` from `cfgGlobals`
   - For each slot: create `shaderext`, init shader extensions, init patch, wire param notifications, bind to lick for hot-reload
   - `cfgCommands.init()` — register all commands
   - `cfgKbMapping.init()` — bind keyboard controls
   - `dispatcher.init()` — start OSC/MIDI threads
   - `studioBridge.init()` — start HTTP + WebSocket servers
   - `studioProtocol.init()` — register protocol handler
   - Create `globalSequencer` and `globalSceneSequencer`

## Frame Loop

### `love.update(dt)`

```
clock.update()
cfgTimers.update()
modulator.tick()
globalSequencer:tick()
globalSceneSequencer:tick()
dispatcher.update()         -- process OSC/MIDI/commands
studioBridge.update()       -- pump WebSocket messages
studioProtocol.flush()      -- send buffered param changes (30 Hz)
lick.liveUpdate(patchSlots) -- hot-reload changed files, then call patch.update()
cfgShaders.updateTime(slot) -- push _time uniforms
```

### `love.draw()`

```
For each visible patch slot:
  patch.draw()              -- returns rendered canvas
  Apply post-process shaders (3 layers)
  Composite to screen
  Send to Spout (if enabled)
```

## Live-Coding

The `lick` library monitors source files for changes. When a file is modified:

1. The module is re-evaluated (full `REBUILD` strategy)
2. `patch.init()` is called on the new module
3. Param notification hooks are re-wired
4. The old module is replaced in `patchSlots`

Errors during reload are caught by the error handler and displayed as persistent banners. The last-good version of the patch continues running.

`Ctrl+Esc` dismisses error banners.

## Patch Slots

`patchSlots` is a global array. Each slot contains:

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Module path (e.g. `"demos/demo23/source/demo_23"`) |
| `patch` | table | The live patch instance |
| `shaderext` | Resource | Shader parameters and slot selections |
| `lickBinding` | handle | Hot-reload binding |
| `lickBindingPath` | string | Path being watched |

See also: [Resource System](resources.md), [Creating Patches](creating-patches.md)
