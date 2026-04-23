# LFO & Envelope

[Back to index](../index.md)

Signal generators for modulation and animation. Both inherit from a common `Signals` base class that provides trigger/gate management.

## Base Class: Signals

Manages attack/release instants from a boolean gate signal.

```lua
local Signals = lovjRequire("lib/signals/signals")
local sig = Signals:new()

sig:UpdateTrigger(gateOn)  -- call each frame with true/false
sig:isTriggerActive()      -- true while gate is held
```

Internally tracks `atkInst` (attack instant) and `rlsInst` (release instant) for envelope timing.

## LFO

Free-running oscillator with multiple waveforms.

```lua
local Lfo = lovjRequire("lib/signals/lfo")
local lfo = Lfo:new(frequency, phase)
```

### Waveforms

All waveforms return values in **[-1, 1]** and are gated by the trigger state (output is 0 when trigger is inactive).

| Method | Shape |
|--------|-------|
| `Sine(t)` | Smooth sine wave |
| `Square(t)` | Hard square wave |
| `Triangle(t)` | Linear triangle |
| `RampUp(t)` | Ascending sawtooth |
| `RampDown(t)` | Descending sawtooth |
| `Pulse(t, pw)` | Pulse with adjustable width (0-1) |
| `RandomSH(t)` | Random sample-and-hold (new value each half-cycle) |

```lua
lfo:UpdateFreq(2.0)            -- change frequency
local val = lfo:Sine(t)        -- evaluate at time t
```

### Shape Registry

Shapes are registered by name in `Lfo.shapes`. The [modulator](../state/modulators.md) system looks them up via `Lfo.shapeNames`. To add a custom shape without modifying core code:

```lua
local Lfo = lovjRequire("lib/signals/lfo")

Lfo.registerShape("MyShape", function(self, t)
    local ph = math.fmod(self.frequency * (t + self.phase), 1)
    local y = -- your waveform math here, return [-1, 1]
    return y * SMath.b2n(self:isTriggerActive())
end)
```

Built-in shapes: `Sine`, `Square`, `Triangle`, `RampUp`, `RampDown`, `SmoothRampUp`, `SmoothRampDown`, `Pulse`, `RandomSH`.

## Envelope

Linear ADSR (Attack-Decay-Sustain-Release) envelope.

```lua
local Envelope = lovjRequire("lib/signals/envelope")
local env = Envelope:new(attackTime, decayTime, sustainLevel, releaseTime)
```

### Output

Returns values in **[0, 1]**.

| Method | Description |
|--------|-------------|
| `Calculate(t)` | Composite ADSR output — use this one |
| `Attack(t)` | Attack phase only |
| `Decay(t, rlsCall)` | Decay phase only |
| `Sustain(t)` | Sustain phase only |
| `Release(t)` | Release phase only |

### Triggering

```lua
env:UpdateTrigger(gateOn)  -- true = gate on (attack), false = gate off (release)
local value = env:Calculate(t)
```

The envelope retriggers on each 0→1 gate transition.

## Usage in Patches

```lua
local lfo = Lfo:new(1, 0)
local env = Envelope:new(0.1, 0.2, 0.5, 0.3)

function patch.update()
    patch:mainUpdate()
    local t = cfg_timers.globalTimer.T
    lfo:UpdateTrigger(true)
    env:UpdateTrigger(someTriggerCondition)
end

function patch.draw()
    local t = cfg_timers.globalTimer.T
    local wobble = lfo:Sine(t) * 20
    local brightness = env:Calculate(t)
    -- use wobble and brightness in drawing
end
```

## Easing Curves

26 built-in easing curves are available for shaping transitions, morph interpolation, and sequencer per-step easing. See [Easing & Interpolation](easing.md) for the full catalog and API.

## Related

- [Modulators](../state/modulators.md) — bind LFOs/envelopes to parameters automatically
- [Easing & Interpolation](easing.md) — shaping curves for transitions
