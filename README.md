<center><img src="https://raw.githubusercontent.com/merumerutho/LOVJ/main/data/app/LOVJ.png" width=500 /></center>

# LOVJ - LOVE2D VJing Framework

## Overview

LOVJ is a framework based on LOVE2D, designed as a live-coding and interactive VJing environment for live music performances. It provides a patch-based architecture for creating, sequencing, and mixing video effects with real-time controls, GLSL shader support, and a web-based control surface (LOVJ Deck).

## Features

- **Patch-based architecture** — modular video patches that can be loaded, layered, and mixed across multiple slots
- **Live-coding** — hot-reload on file save with syntax checking and rollback on failure
- **GLSL shaders** — up to 10 post-process layers per slot with `@param` annotations for automatic parameter binding
- **BPM-synced signals** — LFOs, envelopes, and easing curves locked to a global transport clock
- **Step sequencer** — Elektron-style parameter locks with per-step easing, polyrhythmic channels, and morph transitions
- **Scene sequencer** — beat-quantized transitions between saved parameter states
- **Modulator engine** — bind LFOs and envelopes to any parameter with min/max range and waveshaping
- **Savestate system** — save/recall parameter snapshots with smooth easing transitions
- **Feedback buffers** — ping-pong echo effects with rotation, zoom, and tint
- **LOVJ Deck** — web-based control surface with parameter editing, sequencer faders, shader management, and beat visualization
- **MIDI support** — CC, note, and program change mapping to any command
- **OSC networking** — bidirectional control with parameter discovery
- **Spout integration** — stream video to and from other applications (Windows)

## Prerequisites

- [LOVE2D](https://love2d.org/) version 11.4 or higher
- [Node.js](https://nodejs.org/) 18+ (only for building the LOVJ Deck GUI)

## Quick Start

```sh
git clone --recurse-submodules https://github.com/merumerutho/LOVJ.git
cd LOVJ
love .
```

To build the LOVJ Deck web GUI:

```sh
cd studio && npm install && npm run build
```

For Spout support (Windows):

```sh
installSpout.bat
```

## Documentation

Full documentation is in [`doc/`](doc/index.md), covering:

- [Getting Started](doc/getting-started/getting-started.md) — installation, dependencies, first run
- [Creating Patches](doc/getting-started/creating-patches.md) — patch anatomy, lifecycle, drawing
- [Writing Shaders](doc/getting-started/shaders.md) — GLSL pipeline, `@param` annotations
- [Clock & BPM](doc/signals/clock.md) — transport, syncRate, tap-tempo
- [Signals](doc/signals/signals.md) — LFO, envelope, easing curves
- [Sequencer](doc/sequencing/sequencer.md) — step sequencer, p-locks, morph easing
- [Keyboard / MIDI / OSC](doc/controls/keyboard.md) — input mapping and control protocols
- [LOVJ Deck](doc/studio/studio.md) — web control surface
- [Rendering Pipeline](doc/graphics/rendering.md) — canvas flow, shader layers
- [Savestates](doc/state/savestates.md) — save/load with morph transitions

## Contributing

Contributions are welcome! Please feel free to open an issue or submit a pull request.

## License

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [lick](https://github.com/usysrc/lick) — original live-coding library (rewritten for LOVJ)
- [json.lua](https://github.com/rxi/json.lua) — JSON library
- [Spout](https://spout.zeal.co/) — video sharing library
- [SiENcE/lovemidi](https://github.com/SiENcE/lovemidi) — MIDI library for LOVE2D
