# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Full documentation is in [`doc/`](doc/index.md).

## Project Overview

LOVJ is a LOVE2D-based VJing framework for live music performances. It provides a patch-based architecture for creating, sequencing, and mixing video effects with real-time controls, GLSL shader support, and a web-based Studio GUI.

## Quick Reference

### Running
```bash
love .
```
Requires LOVE2D 11.4+ in PATH.

### Building Studio GUI
```bash
cd studio && npm install && npm run build
```

### Spout (Windows video streaming)
```bash
installSpout.bat
```

## Architecture at a Glance

- **Entry point**: `main.lua` — init sequence, frame loop, patch slot management
- **Patches**: `lib/patch.lua` base class; demos in `demos/demo1–demo24/`
- **Config**: `cfg/` — patches, shaders, screen, keyboard/MIDI/OSC mappings, studio server
- **Signals**: `lib/signals/` — LFO, envelope, easing curves, interpolator
- **Sequencing**: `lib/sequencer.lua` (step sequencer), `lib/scene_sequencer.lua` (scene transitions)
- **Modulators**: `lib/modulator.lua` — bind LFOs/envelopes to parameters
- **Commands**: `lib/command_system.lua` + `cfg/cfg_commands.lua` — protocol-agnostic actions
- **Studio GUI**: `lib/studio/` (Lua backend) + `studio/` (Svelte frontend) — web control interface
- **Resources**: `lib/resources.lua` — named parameter storage with change notifications
- **Feedback**: `lib/feedback.lua` — ping-pong buffer for echo/trail effects
- **Live-coding**: `lib/lick.lua` + `lovjRequire()` — hot-reload on file save

## Key Globals (set in main.lua)

`screen`, `clock`, `timer`, `controls`, `dispatcher`, `errorHandler`, `ResourceList`, `modulator`, `Sequencer`, `SceneSequencer`, `globalSequencer`, `globalSceneSequencer`, `patchSlots`, `globalSettings`, `cfgPatches`, `cfgShaders`, `cfgTimers`, `cfgSpout`, `cfgScreen`, `cfgGlobals`, `cfgKbMapping`, `cfgCommands`, `studioBridge`, `studioProtocol`, `spout`, `drawingUtils`

## Dependencies

- LOVE2D 11.4+ (runtime)
- Spout (optional, Windows video streaming)
- Node.js 18+ (building Studio GUI only)
- lick (live-coding, bundled)
- json.lua (JSON, bundled)
