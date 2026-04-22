# LOVJ Documentation

LOVJ is a LOVE2D-based VJing framework for live music performances. It provides a patch-based architecture for creating, sequencing, and mixing video effects with real-time controls, GLSL shader support, and a web-based control surface (LOVJ Deck).

## Getting Started

- [Installation & Running](getting-started/getting-started.md) — setup, dependencies, launching LOVJ
- [Creating a Patch](getting-started/creating-patches.md) — anatomy of a patch, lifecycle, resource management
- [Writing Shaders](getting-started/shaders.md) — GLSL post-process pipeline, `@param` annotations

## Architecture

- [Project Structure](architecture/project-structure.md) — file tree, naming conventions, module loading
- [Runtime & Main Loop](architecture/runtime.md) — initialization sequence, frame loop, live-coding
- [Configuration](architecture/configuration.md) — all `cfg/` modules and their purpose
- [Resource System](architecture/resources.md) — parameters, graphics, globals, shader extensions

## Signal Processing

- [Clock & Transport](signals/clock.md) — BPM, beats, bars, phase, tap-tempo
- [LFO & Envelope](signals/signals.md) — oscillators, ADSR, trigger system
- [Easing & Interpolation](signals/easing.md) — shaping curves, animated transitions

## Sequencing

- [Step Sequencer](sequencing/sequencer.md) — channels, p-locks, polyrhythm, targets
- [Scene Sequencer](sequencing/scene-sequencer.md) — scene caching, beat-quantized transitions

## Control Protocols

- [Command System](controls/commands.md) — registration, validation, command catalog
- [Keyboard Mapping](controls/keyboard.md) — key combos, argument resolvers
- [MIDI](controls/midi.md) — CC/note/program routing, value transforms
- [OSC](controls/osc.md) — address patterns, parameter discovery, feedback

## LOVJ Deck (Web Control Surface)

- [LOVJ Deck Overview](studio/studio.md) — layout, components, color language, state management
- [WebSocket Protocol](studio/studio-protocol.md) — message types, request/response patterns

## Graphics

- [Screen & Resolution](graphics/screen.md) — internal/external resolution, upscaling, fullscreen
- [Feedback Buffers](graphics/feedback.md) — ping-pong echo effects
- [Patch Rendering Pipeline](graphics/rendering.md) — canvas flow, shader layers, composition

## State Management

- [Savestates](state/savestates.md) — save/load parameter snapshots
- [Modulators](state/modulators.md) — LFO/envelope binding to parameters
