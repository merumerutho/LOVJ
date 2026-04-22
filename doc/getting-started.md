# Installation & Running

[Back to index](index.md)

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

This launches LOVJ with the default patch configured in [`cfg/cfg_patches.lua`](configuration.md).

The LOVE2D console window opens alongside the graphics window, showing log output.

## Spout Setup (Windows)

To enable video output streaming via Spout:

```bash
installSpout.bat
```

This copies `SpoutLibrary.dll` and `SpoutWrapper.dll` into the project root. Spout senders/receivers are configured in [`cfg/cfg_spout.lua`](configuration.md).

## Studio Web GUI

If `cfg_studio.enabled = true` (the default), LOVJ serves a web interface at `http://localhost:8080`. To rebuild the frontend after changes:

```bash
cd studio
npm install
npm run build
```

The built output goes to `studio/dist/` and is served by LOVJ's built-in HTTP server.

## Project Layout

See [Project Structure](project-structure.md) for the full file tree.

## Next Steps

- [Creating a Patch](creating-patches.md) — write your first visual patch
- [Configuration](configuration.md) — customize resolution, controls, network
