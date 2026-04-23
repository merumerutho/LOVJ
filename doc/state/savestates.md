# Savestates

[Back to index](../index.md)

Savestates persist patch parameter snapshots to disk as JSON files. They enable recalling specific parameter configurations during live performance.

## Storage

Savestates are saved to `savestates/` in the LOVE2D save directory:

```
savestates/
  demo_23_slot1.json
  demo_23_slot2.json
  demo_20_slot1.json
```

Filename format: `{patchName}_slot{id}.json`

## Contents

A savestate JSON file contains:

```json
{
  "parameters": { "speed": 0.5, "intensity": 0.8 },
  "graphics": { "background": "path/to/image.png" },
  "shaderext": { "shaderSlot1": 3, "blurzoom__zoom": 0.5 },
  "modulators": [ ... ]
}
```

It captures:
- All named patch parameters and their values
- Graphics resources
- Shader extension parameters (shader selections + shader params)
- Active [modulator](modulators.md) configurations

## API (`lib/savemgr.lua`)

### Save

```lua
saveMgr.saveResources(patchName, savestateId, slot)
```

Serializes current state of the given slot to a JSON file.

### Load

```lua
saveMgr.loadResources(patchName, savestateId, slot, opts)
```

Reads a JSON file and restores parameters, graphics, shader extensions, and modulators for the given slot. Parameters are matched by **name** (not index), so savestates remain valid even if a patch reorders or adds new parameters.

#### Morph transitions

When `saveMgr.morphEnabled` is `true` (the default), numeric parameters transition smoothly from their current values to the savestate values using an easing curve:

```lua
saveMgr.morphEnabled      = true        -- enable/disable globally
saveMgr.defaultMorphTime  = 500         -- transition time in ms
saveMgr.defaultMorphEasing = "sineInOut" -- easing curve name
```

Per-load overrides can be passed via `opts`:

```lua
saveMgr.loadResources(name, id, slot, { morphTime = 1000, morphEasing = "cubicOut" })
```

Setting `morphTime = 0` forces an instant load. Discrete values like shader slot indices always snap instantly regardless of morph settings.

The morph settings can be queried and changed at runtime via the Studio protocol (`getMorphSettings` / `setMorphSettings`), and are exposed in the LOVJ Deck savestates panel.

### Patch Loading

```lua
saveMgr.loadPatch(patchName, slot)
```

Loads a different patch into a slot (unrequires the old module if not shared by other slots).

### Scene Support

```lua
local data = saveMgr.loadSceneData(patchName, savestateId)  -- read without applying
local data = saveMgr.captureSlot(slot)                       -- snapshot current state
saveMgr.applyScene(data, slot)                                -- restore from snapshot
```

These are used by the [scene sequencer](../sequencing/scene-sequencer.md) for beat-quantized state transitions.

## Studio GUI

The **Savestates** tab shows:
- Savestates for the current patch
- Savestates from other patches (for cross-patch recall)
- Save-to-slot input for creating new savestates

## Commands

| Command | Description |
|---------|-------------|
| `saveSavestate` | Save current slot state to a savestate |
| `loadSavestate` | Load a savestate into a slot |

Available via [keyboard](../controls/keyboard.md), [MIDI](../controls/midi.md), [OSC](../controls/osc.md), and [Studio GUI](../studio/studio.md).

## Related

- [Scene Sequencer](../sequencing/scene-sequencer.md) — automate savestate recall on beats
- [Resource System](../architecture/resources.md) — what's being saved
- [Modulators](modulators.md) — modulator state included in savestates
