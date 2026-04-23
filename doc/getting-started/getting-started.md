# Installation & Running

[Back to index](../index.md)

## Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| [LOVE2D](https://love2d.org/) | 11.4+ | Game engine / runtime |
| [Spout](https://spout.zeal.co/) | Optional | Windows video streaming (NDI alternative) |
| [Node.js](https://nodejs.org/) | 18+ | Building the Studio web GUI (development only) |

## Running LOVJ

From the project root:

```bash
love .
```

This launches LOVJ with the default patch configured in [`cfg/cfg_patches.lua`](../architecture/configuration.md).

The LOVE2D console window opens alongside the graphics window, showing log output.

## Spout Setup (Windows)

To enable video output streaming via Spout:

```bash
python installSpout.py
```

This downloads `SpoutLibrary.dll` into `dynlib/`. LOVJ calls SpoutLibrary directly via C++ vtable from LuaJIT FFI — no wrapper DLL needed. Senders/receivers are configured in [`cfg/cfg_spout.lua`](../architecture/configuration.md).

## FFmpeg Video Sampler

To enable the video sampler (any-codec video playback, databending):

```bash
python installFFmpeg.py
```

This downloads FFmpeg shared libraries (avformat, avcodec, avutil, swscale, swresample) into `dynlib/`. See [Video Sampler](../graphics/video-sampler.md) and [Databending](../graphics/databending.md).

## Studio Web GUI

If `cfg_studio.enabled = true` (the default), LOVJ serves a web interface at `http://localhost:8080`. To rebuild the frontend after changes:

```bash
cd studio
npm install
npm run build
```

The built output goes to `studio/dist/` and is served by LOVJ's built-in HTTP server.

## Project Layout

See [Project Structure](../architecture/project-structure.md) for the full file tree.

## Next Steps

- [Creating a Patch](creating-patches.md) — write your first visual patch
- [Configuration](../architecture/configuration.md) — customize resolution, controls, network
