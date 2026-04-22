# Step Sequencer

[Back to index](index.md)

The step sequencer (`lib/sequencer.lua`) provides Elektron-style parameter automation with per-step p-locks and polyrhythmic channels.

## Overview

A global `Sequencer` instance (`globalSequencer`) is created in `main.lua`. Channels can be added and configured through the [Studio GUI](studio.md), [OSC](osc.md), or [MIDI](midi.md).

Each channel targets a specific parameter and has its own step count and clock divider, enabling polyrhythmic patterns.

## Creating Channels

```lua
globalSequencer:channel("myChannel", {
    slot   = 1,           -- patch slot to control
    param  = "speed",     -- parameter name
    steps  = 16,          -- number of steps
    divider = 4,          -- clock divider (4 = 1/16th notes)
    mode   = "hold",      -- "hold" (latch) or "snap" (pulse)
    default = 0.5,        -- value when no p-lock is set
})
```

## P-Locks (Parameter Locks)

Each step can hold a locked parameter value:

```lua
globalSequencer:plock(step, "myChannel", 0.75)   -- set value at step
globalSequencer:clearPlock(step, "myChannel")     -- remove lock
globalSequencer:clearChannel("myChannel")         -- clear all locks
```

When the sequencer lands on a step with a p-lock, it writes that value to the target parameter. Steps without locks use the channel's `default` value (in `"hold"` mode) or leave the parameter unchanged (in `"snap"` mode).

## Target Types

Channels can target different destinations:

| Target | Format | Description |
|--------|--------|-------------|
| Patch parameter | `{slot, param}` | Write to `patchSlots[slot].patch.resources.parameters` |
| Function | `{fn = function}` | Call arbitrary function with the value |
| Modulator field | `{modulator, field}` | Control a modulator's property |
| Shader parameter | `{resource = "shaderext", slot, param}` | Write to shader extension |

## Transport

```lua
globalSequencer:play()     -- start playback
globalSequencer:stop()     -- stop
globalSequencer:toggle()   -- play/stop toggle
globalSequencer:realign()  -- reset all channels to step 1
```

Playback is driven by the global [clock](clock.md). Each frame, `globalSequencer:tick()` advances channels based on beat position and applies p-lock values.

## Channel Configuration

```lua
globalSequencer:setChannelSteps("myChannel", 12)    -- change step count
globalSequencer:setChannelDivider("myChannel", 8)   -- change divider
globalSequencer:removeChannel("myChannel")           -- delete channel
```

## State Serialization

```lua
local state = globalSequencer:getState()
-- Returns: { playing, channels: [{name, steps, divider, mode, target, plocks, currentStep}] }
```

## Related

- [Clock & Transport](clock.md) — drives sequencer timing
- [Scene Sequencer](scene-sequencer.md) — meta-level scene triggering
- [Modulators](modulators.md) — continuous parameter modulation
- [Studio Overview](studio.md) — Sequencer tab in web GUI
