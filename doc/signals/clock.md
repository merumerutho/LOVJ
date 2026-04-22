# Clock & Transport

[Back to index](../index.md)

The global clock (`lib/clock.lua`) is LOVJ's master timing source. All [sequencers](../sequencing/sequencer.md), [modulators](../state/modulators.md), and beat-synced features derive their position from it.

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `bpm` | number | Current beats per minute |
| `beat` | number | Continuous beat position (fractional) |
| `bar` | number | Current bar number (1 bar = `beatsPerBar` beats) |
| `beatPhase` | number | Position within bar (0 to `beatsPerBar`) |
| `subBeat` | number | Fractional part of current beat (0 to 1) |
| `step16` | number | Current 1/16th note step (1 to 16) |
| `step` | number | Monotonically increasing step counter |
| `beatsPerBar` | number | Beats per bar (default 4) |

## API

```lua
clock.init(bpm)          -- Initialize (optional BPM, defaults to cfg_bpm)
clock.setBPM(bpm)        -- Set BPM (preserves phase)
clock.tap()              -- Tap-tempo (averages last 8 taps)
clock.resetPhase()       -- Align beat 0 to current time
clock.nudge(dt)          -- Shift phase by dt seconds
clock.beatDuration()     -- Seconds per beat
clock.stepDuration(div)  -- Seconds per step (div=4 for 1/16th notes)
clock.update()           -- Advance all fields (called once per frame)
```

## Tap Tempo

`clock.tap()` is bound to mouse left-click by default. It averages the intervals of the last 8 taps to estimate BPM. The [Studio GUI](../studio/studio.md) also provides a tap tempo button and BPM input.

## Phase Reset

`clock.resetPhase()` aligns beat 0 to the current moment. Use this to sync LOVJ to a live performance downbeat. Available via:

- Keyboard: configurable in [keyboard mapping](../controls/keyboard.md)
- Studio GUI: "Reset Phase" button in the Project Bar
- OSC/MIDI: via the `resetPhase` [command](../controls/commands.md)

## Usage in Patches

Patches typically use `cfg_timers.globalTimer.T` for continuous time and `clock.beat` / `clock.beatPhase` for beat-synced animation:

```lua
local t = cfg_timers.globalTimer.T       -- continuous seconds
local flash = clock.subBeat < 0.1        -- flash on each beat
local bar = math.floor(clock.beatPhase)  -- current beat within bar
```

## Related

- [Step Sequencer](../sequencing/sequencer.md) — uses clock for step advancement
- [Scene Sequencer](../sequencing/scene-sequencer.md) — beat-quantized scene transitions
- [Modulators](../state/modulators.md) — envelope triggers can sync to beats
