# Scene Sequencer

[Back to index](index.md)

The scene sequencer (`lib/scene_sequencer.lua`) is a meta-level sequencer that triggers patch/savestate loads on beat-quantized boundaries. It enables pre-programmed visual set transitions during live performances.

## Concepts

- **Scene**: A cached visual state — either a patch (fresh load) or a savestate (patch + parameter snapshot)
- **Channel**: Targets a patch slot, with its own step count and divider
- **Step**: Each step can hold a scene label; when the sequencer lands on it, that scene is loaded into the target slot

## Caching Scenes

Before a scene can be sequenced, it must be cached with a label:

```lua
-- Cache a patch (fresh load)
globalSceneSequencer:cachePatchScene("intro", "demos/demo23/source/demo_23")

-- Cache a savestate (patch + saved parameters)
globalSceneSequencer:cacheSavestateScene("verse1", "demo_20", 1)

-- Capture current live state of a slot
globalSceneSequencer:captureScene("snapshot", 1)
```

## Channels

Each channel targets a patch slot:

```lua
globalSceneSequencer:channel("main", {
    slot    = 1,      -- patch slot to control
    steps   = 4,      -- number of steps
    divider = 1,      -- clock divider (1 = whole bars)
})
```

## Assigning Scenes to Steps

```lua
globalSceneSequencer:setScene(1, "main", "intro")    -- step 1 loads "intro"
globalSceneSequencer:setScene(2, "main", "verse1")   -- step 2 loads "verse1"
globalSceneSequencer:clearScene(3, "main")            -- step 3 does nothing
```

## Transport

```lua
globalSceneSequencer:play()
globalSceneSequencer:stop()
globalSceneSequencer:toggle()
globalSceneSequencer:realign()
```

## Scene Types

| Type | On Trigger | Use Case |
|------|-----------|----------|
| `"patch"` | Loads patch fresh via `saveMgr.loadPatch()` | Switch to a different visual |
| `"savestate"` | Loads patch + applies saved parameters | Recall a tuned preset |
| `"capture"` | Restores a live snapshot | Return to a captured moment |

## Channel Configuration

```lua
globalSceneSequencer:setChannelSteps("main", 8)
globalSceneSequencer:setChannelDivider("main", 2)
globalSceneSequencer:removeChannel("main")
```

## State Serialization

```lua
local state = globalSceneSequencer:getState()
-- { playing, scenes: [{label, sceneType, patchPath}], channels: [...] }

local scenes = globalSceneSequencer:getSceneList()
-- Array of cached scenes with metadata
```

## Related

- [Clock & Transport](clock.md) — drives step timing
- [Step Sequencer](sequencer.md) — parameter-level automation
- [Savestates](savestates.md) — parameter snapshot persistence
- [Easing & Interpolation](easing.md) — crossfade transitions between scenes
