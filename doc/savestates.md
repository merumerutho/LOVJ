# Savestates

[Back to index](index.md)

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
saveMgr.loadResources(patchName, savestateId, slot)
```

Reads a JSON file and restores parameters, graphics, shader extensions, and modulators for the given slot.

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

These are used by the [scene sequencer](scene-sequencer.md) for beat-quantized state transitions.

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

Available via [keyboard](keyboard.md), [MIDI](midi.md), [OSC](osc.md), and [Studio GUI](studio.md).

## Related

- [Scene Sequencer](scene-sequencer.md) — automate savestate recall on beats
- [Resource System](resources.md) — what's being saved
- [Modulators](modulators.md) — modulator state included in savestates
