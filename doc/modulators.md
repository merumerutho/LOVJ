# Modulators

[Back to index](index.md)

The modulator system (`lib/modulator.lua`) binds [LFO and envelope](signals.md) signals to patch parameters, providing continuous automated modulation.

## Overview

Modulators are a global registry that runs on every frame. Each modulator:
1. Evaluates its signal source (LFO waveform or ADSR envelope)
2. Maps the output to a `[min, max]` range
3. Writes the result to the target patch parameter

Modulators survive patch reloads and are included in [savestates](savestates.md).

## Creating Modulators

### LFO Modulator

```lua
local id = modulator.create({
    type      = "lfo",
    shape     = "Sine",        -- Sine, Square, Triangle, RampUp, RampDown, Pulse, RandomSH
    frequency = 1.0,           -- Hz
    phase     = 0,             -- 0-1
    min       = 0.0,           -- output minimum
    max       = 1.0,           -- output maximum
    target    = {
        slot  = 1,             -- patch slot
        param = "speed",       -- parameter name
    },
})
```

### Envelope Modulator

```lua
local id = modulator.create({
    type         = "envelope",
    attack       = 0.1,        -- seconds
    decay        = 0.2,
    sustain      = 0.5,        -- level (0-1)
    release      = 0.3,
    triggerBeats = 4,          -- retrigger every N beats
    gateRatio    = 0.5,        -- gate on for this fraction of the trigger period
    min          = 0.0,
    max          = 1.0,
    target       = { slot = 1, param = "intensity" },
})
```

## API

| Function | Description |
|----------|-------------|
| `modulator.create(config)` | Create and return ID |
| `modulator.update(id, changes)` | Partial update (e.g. change frequency) |
| `modulator.delete(id)` | Remove modulator |
| `modulator.getAll()` | Get array of all modulators (serializable) |
| `modulator.getModulatedSet()` | Set of `"slot:param"` strings currently modulated |
| `modulator.tick()` | Evaluate all modulators (called once per frame) |
| `modulator.restoreAll(data)` | Bulk restore from snapshot |

## Available LFO Shapes

`modulator.LFO_SHAPES` is derived from the LFO shape registry (`Lfo.shapeNames`). Built-in shapes: `Sine`, `Square`, `Triangle`, `RampUp`, `RampDown`, `SmoothRampUp`, `SmoothRampDown`, `Pulse`, `RandomSH`. Custom shapes can be added via `Lfo.registerShape()` — see [LFO & Envelope](signals.md).

## Modulator Type Registry

Modulator types are registered via `Modulator.registerType(name, handler)`. Each handler is a table with:

| Method | Signature | Purpose |
|--------|-----------|---------|
| `init` | `(config, entry)` | Populate type-specific fields on creation |
| `update` | `(entry, changes)` | Apply partial config changes |
| `eval` | `(entry, t) → [0,1]` | Compute output factor |
| `serialize` | `(entry) → table` | Extract serializable fields |

Built-in types: `"lfo"`, `"envelope"`. To add a custom type:

```lua
local Modulator = lovjRequire("lib/modulator")

Modulator.registerType("myType", {
    init = function(config, entry)
        entry.myField = config.myField or 1.0
    end,
    update = function(entry, changes)
        if changes.myField then entry.myField = tonumber(changes.myField) end
    end,
    eval = function(entry, t)
        return -- your signal math, return value in [min, max]
    end,
    serialize = function(entry)
        return { myField = entry.myField }
    end,
})
```

## Multiplicative Modulation

Modulators operate as multiplicative factors on the parameter's base value. The base value is what the user sets via sliders, keyboard, or sequencer. The modulator's output (after easing) scales it:

```
effective_value = baseValue * modulator_output
```

This means a modulator outputting 1.0 leaves the parameter unchanged, 0.5 halves it, and 0.0 silences it. The user controls the "ceiling" via the slider; the modulator shapes how much of that ceiling is used over time

## Studio GUI

The **Modulators** tab provides:
- Create new LFO or Envelope modulators
- Select target parameter from the current patch's schema
- Adjust all modulator parameters with sliders
- Delete modulators

Parameters that are currently modulated show a visual indicator in the **Parameters** tab.

## Modulated Parameter Indicator

The Studio protocol marks parameters as `modulated: true` in the schema when a modulator targets them. This allows the GUI to show which parameters are under modulation control.

## Related

- [LFO & Envelope](signals.md) — signal generators used by modulators
- [Step Sequencer](sequencer.md) — discrete step automation (complementary to continuous modulation)
- [Savestates](savestates.md) — modulator state is preserved
- [Resource System](resources.md) — parameters being modulated
