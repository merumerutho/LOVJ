# LOVJ Deck

[Back to index](../index.md)

LOVJ Deck is a browser-based control surface built with Svelte 5, served directly by LOVJ over HTTP and communicating via WebSocket. It replaces a traditional settings panel with a layout designed for live performance — always-visible transport, parameters and modulators on the same screen, and collapsible sequencer/scene trays.

## Architecture

```
Browser (localhost:8080)          LOVJ (LOVE2D)
  Svelte App                       Main Thread
    ↕ WebSocket (port 8765)          ↕ Channels
  transport.js ←──────────────→  bridge.lua ←→ protocol.lua
                                     ↕
                                 bridge_thread.lua
                                   HTTP server (port 8080)
                                   WebSocket server (port 8765)
```

The worker thread (`bridge_thread.lua`) runs HTTP and WebSocket servers in a separate LOVE2D thread. Messages flow through `love.thread` channels to the main thread where `protocol.lua` handles them.

## Configuration

In `cfg/cfg_studio.lua`:

```lua
cfg_studio.enabled     = true
cfg_studio.bindAddress = "127.0.0.1"  -- "0.0.0.0" for network access
cfg_studio.httpPort    = 8080
cfg_studio.wsPort      = 8765
cfg_studio.staticRoot  = "studio/dist"
```

## Layout

LOVJ Deck uses a three-zone layout instead of tabs. All controls are reachable without switching views.

```
┌─────────────────────────────────────────────────────────────────┐
│ AppHeader (46px)  brand · conn · context · TAP · BPM · ▶ ■     │
├─────────────────────────────────────────────────────────────────┤
│ SlotSelector strip                                              │
├───────────────┬─────────────────────────────────────────────────┤
│ Sidebar 260px │ Main (scrollable)                               │
│               │   PARAMETERS (green accent)                     │
│ Patches grid  │     slider rows with inline modulator cards     │
│               │   SHADER PARAMETERS (cyan accent)               │
│ Shader layers │     slider rows with inline modulator cards     │
│  (dropdowns)  │                                                 │
│               ├─────────────────────────────────────────────────┤
│ Savestates    │ Bottom Tray (collapsible 32px / 280px)          │
│               │   [SEQUENCER ● PLAYING] [SCENES ● 2ch]  [HIDE] │
│ + LFO  + ENV  │   step grid / scene grid                       │
└───────────────┴─────────────────────────────────────────────────┘
```

### Header (always visible)

| Element | Purpose |
|---------|---------|
| Brand + LED | App name, green/red connection indicator |
| Reconnect | Force WebSocket reconnection |
| Context crumb | Current patch name, slot number, active modulator count |
| BPM input | Large monospace numeric input — always visible, always editable |
| TAP | Reset phase (tap tempo) |
| Play / Stop | Sequencer transport — green ▶, red ■ |

### Slot Strip (always visible)

Row of numbered slot buttons below the header. Shows which slot is active and the loaded patch name. Clicking a slot fetches its schema, shaders, and savestates.

### Sidebar

Fixed 260px left column with collapsible sections:

| Section | Component | Notes |
|---------|-----------|-------|
| **Patches** | `PatchesPanel` | Compact 2-column grid, no path text. Click to load into selected slot. |
| **Shader Layers** | `ShaderLayerSelector` | ON/OFF toggle + 3 layer dropdowns. Layer selection only — shader param sliders are in the main area. |
| **Savestates** | `SavestatePanel` | Save-to-slot input, grouped load buttons. Collapsed by default. |
| **+ LFO / + ENV** | `AddModulatorButtons` | Creates a modulator pre-targeted to the first available parameter. |

### Main Area

Scrollable center column showing **Parameters** and **Shader Parameters** together. Both sections use the same slider row layout:

- Label (right-aligned, monospace)
- Range slider with green accent (parameters) or cyan accent (shaders)
- Numeric value display
- Purple `~` icon and live indicator when modulated

**Inline modulator cards** appear directly below each modulated parameter. Cards start **collapsed** (one-liner showing type, shape, rate) and expand on click to show full controls (shape, Hz/sync, phase, ADSR, min/max, easing curve). This eliminates the need to switch to a separate Modulators tab.

### Bottom Tray

Collapsible panel at the bottom of the main area:

- **Closed** (32px): shows tab labels with status indicators — "● PLAYING" for sequencer, channel count for scenes
- **Open** (280px): two tabs:
  - **Sequencer** — `SequencerPanel` with step grid, p-locks, morph
  - **Scenes** — `SceneSequencerPanel` with scene bank and channel grid

The tray opens by clicking a tab label or the SHOW/HIDE toggle. Transitions are < 80ms.

## Components

### New layout components

| Component | File | Purpose |
|-----------|------|---------|
| `AppHeader` | `AppHeader.svelte` | Header bar with brand, connection, context, BPM, transport |
| `Sidebar` | `Sidebar.svelte` | Left column assembling patches, shader layers, savestates, add-mod buttons |
| `ShaderLayerSelector` | `ShaderLayerSelector.svelte` | Shader ON/OFF + layer dropdowns (sidebar portion of old ShadersPanel) |
| `ShaderParamsInline` | `ShaderParamsInline.svelte` | Shader param sliders with inline mod cards (main area portion) |
| `ParameterListWithMods` | `ParameterListWithMods.svelte` | Patch param sliders with inline mod cards |
| `InlineModCard` | `InlineModCard.svelte` | Collapsible modulator card for a single target parameter |
| `AddModulatorButtons` | `AddModulatorButtons.svelte` | + LFO / + ENV buttons in sidebar |
| `BottomTray` | `BottomTray.svelte` | Collapsible tray housing Sequencer and Scene panels |

### Preserved components (unchanged)

| Component | Purpose |
|-----------|---------|
| `PatchesPanel` | Patch grid (used inside Sidebar) |
| `SavestatePanel` | Save/load snapshots (used inside Sidebar) |
| `SequencerPanel` | Step sequencer (used inside BottomTray) |
| `SceneSequencerPanel` | Scene sequencer (used inside BottomTray) |
| `SlotSelector` | Slot buttons (used in slot strip) |
| `ConnectionStatus` | Connection dot (preserved, replaced by AppHeader's built-in LED) |
| `ParameterInspector` | Original param sliders (preserved for backward compat) |
| `ShadersPanel` | Original combined shaders panel (preserved for backward compat) |
| `ModulatorPanel` | Original modulator list (preserved for backward compat) |
| `ProjectBar` | Original BPM bar (preserved for backward compat) |

### Derived store

`modulatorsByParam.js` provides a derived store that groups modulators by `"resource:param"` key. This enables efficient lookup for inline modulator cards without repeated filtering.

## Color Language

| Usage | Color | Hex |
|-------|-------|-----|
| Background | Dark base | `#1a1a1e` |
| Surfaces | Header, sidebar | `#222227` |
| Active elements | Slot highlight | `#2a2a30` |
| Patch parameters | Green | `#5a9a6a` |
| Shader parameters | Cyan | `#6a9aaa` |
| Modulation | Purple | `#a88adc` / `#8a6aaa` |
| Sequencer state | Amber | `#c9a24a` |
| Off / destructive | Red | `#c06060` |

## State Management

All UI state lives in Svelte stores (`studio/src/lib/stores.js`):

| Store | Content |
|-------|---------|
| `slots` | Array of `{index, name}` per slot |
| `selectedSlot` | Currently viewed slot (1-based) |
| `schema` | Parameters for current slot |
| `availablePatches` | Patches from config |
| `slotShaders` | Shader info for current slot |
| `modulators` | Active modulators |
| `lfoShapes` | Available LFO waveform shapes |
| `easingNames` | Available easing curves |
| `sequencer` | Step sequencer state + BPM |
| `sceneSequencer` | Scene sequencer state |
| `savestateList` | Available savestates |
| `liveValues` | Live modulated parameter values (broadcast) |
| `liveShaderValues` | Live modulated shader parameter values (broadcast) |
| `connected` | WebSocket connection status |

## Behavior on Patch Change

When a patch is loaded (manually or via scene sequencer), LOVJ Deck refreshes slot data (schema, shaders, savestates) without disrupting the layout. This ensures rapid patch switching by the sequencer doesn't interrupt parameter editing.

## Building

```bash
cd studio
npm install
npm run build
```

Output goes to `studio/dist/`, served by LOVJ's built-in HTTP server.

For development with hot-reload:
```bash
npm run dev
```

This starts Vite's dev server on port 5173.

## Related

- [WebSocket Protocol](studio-protocol.md) — message format and types
- [Command System](../controls/commands.md) — commands triggered by the GUI
- [Modulators](../state/modulators.md) — LFO/envelope binding to parameters
- [Step Sequencer](../sequencing/sequencer.md) — channels, p-locks, morph
- [Scene Sequencer](../sequencing/scene-sequencer.md) — scene caching, transitions
