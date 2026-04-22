# Easing & Interpolation

[Back to index](index.md)

## Easing Curves (`lib/signals/easing.lua`)

Pure shaping functions that map `t ∈ [0, 1]` to `y ∈ [0, 1]` (some curves overshoot briefly). Used by the [Interpolator](#interpolator) and available for direct use in patches.

### Available Curves

| Family | In | Out | InOut |
|--------|----|-----|-------|
| Linear | `linear` | — | — |
| Smooth | `smoothstep` | — | `smootherstep` |
| Sine | `sineIn` | `sineOut` | `sineInOut` |
| Quad | `quadIn` | `quadOut` | `quadInOut` |
| Cubic | `cubicIn` | `cubicOut` | `cubicInOut` |
| Quart | `quartIn` | `quartOut` | `quartInOut` |
| Expo | `expoIn` | `expoOut` | `expoInOut` |
| Back | `backIn` | `backOut` | `backInOut` |
| Elastic | `elasticIn` | `elasticOut` | `elasticInOut` |
| Bounce | `bounceIn` | `bounceOut` | `bounceInOut` |

### Generators

| Function | Description |
|----------|-------------|
| `steps(n)` | Returns a quantized step function with `n` steps |
| `powerIn(exp)` | Returns `t^exp` curve |
| `powerOut(exp)` | Returns inverse power curve |
| `powerInOut(exp)` | Returns symmetric power curve |
| `makeInOut(easeIn)` | Creates an InOut variant from any easeIn function |

### Lookup

```lua
local Easing = lovjRequire("lib/signals/easing")

local fn = Easing.byName("cubicInOut")  -- lookup by string name
local y = fn(0.5)                        -- evaluate

Easing.names    -- array of all curve names
Easing.catalog  -- name → function table
```

## Interpolator (`lib/signals/interpolator.lua`)

Smoothly transitions a numeric value from A to B over a duration, shaped by an easing curve.

### Constructor

```lua
local Interpolator = lovjRequire("lib/signals/interpolator")

local interp = Interpolator:new({
    easing = Easing.cubicInOut,   -- or:
    easingName = "cubicInOut",    -- looked up from catalog
    value = 0.0,                  -- initial value
})
```

### API

| Method | Description |
|--------|-------------|
| `set(value)` | Jump to value immediately, cancel any transition |
| `goto(target, duration, mode)` | Start transition. `mode`: `"time"` (seconds) or `"beats"` |
| `setEasing(fn, name)` | Change easing mid-flight |
| `update()` | Advance interpolation (call once per frame) |
| `value()` | Current interpolated value |
| `isActive()` | `true` while transitioning |
| `getState()` | Serializable snapshot |

### Example

```lua
local crossfade = Interpolator:new({ easingName = "sineInOut", value = 0 })

-- Trigger a 2-beat crossfade
crossfade:goto(1.0, 2, "beats")

-- In update loop:
crossfade:update()
local mix = crossfade:value()  -- 0 → 1 over 2 beats, shaped by sineInOut
```

### Beat-Synced Mode

When `mode = "beats"`, the interpolator uses `clock.beat` for timing instead of wall-clock seconds. This keeps transitions locked to the transport regardless of BPM changes.

## Related

- [LFO & Envelope](signals.md) — continuous modulation signals
- [Scene Sequencer](scene-sequencer.md) — interpolator can drive crossfade transitions
