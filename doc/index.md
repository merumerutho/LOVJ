# LOVJ Documentation

LOVJ is a LOVE2D-based VJing framework for live music performances. It provides a patch-based architecture for creating, sequencing, and mixing video effects with real-time controls, GLSL shader support, and a web-based control surface (LOVJ Deck).

## Getting Started

- [Installation & Running](getting-started.md) — setup, dependencies, launching LOVJ
- [Creating a Patch](creating-patches.md) — anatomy of a patch, lifecycle, resource management
- [Writing Shaders](shaders.md) — GLSL post-process pipeline, `@param` annotations

## Architecture

- [Project Structure](project-structure.md) — file tree, naming conventions, module loading
- [Runtime & Main Loop](runtime.md) — initialization sequence, frame loop, live-coding
- [Configuration](configuration.md) — all `cfg/` modules and their purpose
- [Resource System](resources.md) — parameters, graphics, globals, shader extensions

## Signal Processing

- [Clock & Transport](clock.md) — BPM, beats, bars, phase, tap-tempo
- [LFO & Envelope](signals.md) — oscillators, ADSR, trigger system
- [Easing & Interpolation](easing.md) — shaping curves, animated transitions

## Sequencing

- [Step Sequencer](sequencer.md) — channels, p-locks, polyrhythm, targets
- [Scene Sequencer](scene-sequencer.md) — scene caching, beat-quantized transitions

## Control Protocols

- [Command System](commands.md) — registration, validation, command catalog
- [Keyboard Mapping](keyboard.md) — key combos, argument resolvers
- [MIDI](midi.md) — CC/note/program routing, value transforms
- [OSC](osc.md) — address patterns, parameter discovery, feedback

## LOVJ Deck (Web Control Surface)

- [LOVJ Deck Overview](studio.md) — layout, components, color language, state management
- [WebSocket Protocol](studio-protocol.md) — message types, request/response patterns

## Graphics

- [Screen & Resolution](screen.md) — internal/external resolution, upscaling, fullscreen
- [Feedback Buffers](feedback.md) — ping-pong echo effects
- [Patch Rendering Pipeline](rendering.md) — canvas flow, shader layers, composition

## State Management

- [Savestates](savestates.md) — save/load parameter snapshots
- [Modulators](modulators.md) — LFO/envelope binding to parameters
