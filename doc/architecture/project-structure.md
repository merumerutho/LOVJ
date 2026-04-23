# Project Structure

[Back to index](../index.md)

```
LOVJ/
  main.lua                  Entry point (LOVE2D load/draw/update)
  conf.lua                  LOVE2D configuration (console, identity)

  cfg/                      Configuration modules
    cfg_app.lua               App title, icon
    cfg_bpm.lua               Default BPM
    cfg_commands.lua          Command registration
    cfg_globals.lua           Global settings structure
    cfg_kb_mapping.lua        Keyboard → command bindings
    cfg_midi_mapping.lua      MIDI → command bindings
    cfg_osc_mapping.lua       OSC → command bindings
    cfg_patches.lua           Patch list, default patch
    cfg_screen.lua            Resolution, upscaling mode
    cfg_shaders.lua           Shader loading, @param parsing
    cfg_spout.lua             Spout senders/receivers
    cfg_studio.lua            Studio GUI server config
    cfg_timers.lua            Timer setup
    cfg_version.lua           Version string

  lib/                      Core libraries
    patch.lua                 Patch base class
    resources.lua             Resource/ResourceList classes
    screen.lua                Screen management
    clock.lua                 Global transport clock
    timer.lua                 Timer utility
    controls.lua              Input handling
    feedback.lua              Feedback buffer class
    modulator.lua             Modulator registry
    sequencer.lua             Step sequencer
    scene_sequencer.lua       Scene sequencer
    savemgr.lua               Save/load manager
    command_system.lua        Command registration & queue
    dispatcher.lua            Protocol coordinator
    lick.lua                  Live-coding hot-reload

    signals/                Signal processing
      signals.lua             Base class (trigger state)
      lfo.lua                 LFO (oscillators)
      envelope.lua            ADSR envelope
      signal_math.lua         Math utilities
      easing.lua              Easing/shaping curves
      interpolator.lua        Value transitions

    shaders/                GLSL shaders
      source/postProcess/     Post-process effect shaders
      source/other/           Utility shaders

    osc/                    OSC networking
      osc_dispatcher.lua      OSC message routing
      osc_feedback.lua        Parameter discovery
      parameter_discovery.lua Discovery protocol

    midi/                   MIDI I/O
      midi_dispatcher.lua     MIDI message routing

    studio/                 Web GUI backend
      bridge.lua              Main-thread channel pump
      bridge_thread.lua       Worker thread (HTTP + WS)
      protocol.lua            JSON message handlers
      websocket.lua           RFC 6455 codec
      http.lua                Static file server

    utils/                  Utilities
      error_handler.lua       Safe patch calls, fallback patch
      logging.lua             Log levels, output
      require.lua             lovjRequire (hot-reload aware)
      table_extensions.lua    Table utilities
      palettes.lua            Color palettes
      drawing.lua             Drawing helpers
      video.lua               Video loop handler
      keypress.lua            Key state wrapper

    json/                   JSON library
      json.lua                Encoding/decoding

  studio/                   Web GUI (Svelte)
    src/
      App.svelte              Root component, tab routing
      main.js                 Mount point
      lib/
        stores.js             Svelte reactive stores
        transport.js          WebSocket client
      components/
        ConnectionStatus.svelte
        ProjectBar.svelte
        SlotSelector.svelte
        PatchesPanel.svelte
        ParameterInspector.svelte
        ShadersPanel.svelte
        ModulatorPanel.svelte
        SequencerPanel.svelte
        SceneSequencerPanel.svelte
        SavestatePanel.svelte
    dist/                   Built output (served by LOVJ)

  demos/                    Example patches (demo1–demo24)
    demoN/
      source/demo_N.lua       Patch source
      assets/                 Images, audio, fonts

  savestates/               Persisted parameter snapshots
  data/app/                 App icons, branding
```

## Module Loading

LOVJ uses `lovjRequire()` instead of Lua's standard `require()`. This wrapper:

- Tracks file modification timestamps for live-reload
- Returns cached modules on subsequent calls
- Integrates with the `lick` hot-reload system

```lua
local Patch = lovjRequire("lib/patch")
```

Paths are relative to the project root, without `.lua` extension.

## Global vs Local

Core modules loaded in `main.lua` are exposed as globals (`screen`, `clock`, `cfgShaders`, `patchSlots`, etc.) so patches can reference them without re-requiring. Library code that needs isolation uses local requires.

See [Runtime & Main Loop](runtime.md) for the full initialization sequence.
