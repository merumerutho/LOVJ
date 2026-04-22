# Screen & Resolution

[Back to index](index.md)

The screen module (`lib/screen.lua`) manages LOVJ's rendering resolution, window configuration, and upscaling modes.

## Resolution Model

LOVJ uses a two-tier resolution system:

| Resolution | Purpose | Default |
|------------|---------|---------|
| **Internal** | Render target for patches | 640 x 320 |
| **External** | Window / output size | 1280 x 640 |

Patches render at internal resolution. The output is upscaled to the window size.

## Upscaling Modes

Configured in `cfg/cfg_screen.lua`:

| Mode | Constant | Behavior |
|------|----------|----------|
| Low-res | `cfg_screen.LOW_RES` | Patches render at internal resolution, nearest-neighbor upscale |
| High-res | `cfg_screen.HIGH_RES` | Patches render at external resolution directly |

Toggle at runtime:
```lua
screen.changeUpscaling()         -- cycle modes
screen.isUpscalingHiRes()        -- check current mode
```

## Properties

```lua
screen.InternalRes.W, screen.InternalRes.H  -- internal render size
screen.ExternalRes.W, screen.ExternalRes.H  -- window/output size
screen.Scaling.X, screen.Scaling.Y          -- scale factors
screen.isFullscreen                          -- current fullscreen state
```

## API

```lua
screen.init()              -- initialize (called once at startup)
screen.toggleFullscreen()  -- toggle fullscreen mode
screen.changeUpscaling()   -- cycle upscaling mode
screen.isUpscalingHiRes()  -- returns true if in HIGH_RES mode
```

## Usage in Patches

```lua
-- Resolution-independent positioning
local cx = screen.InternalRes.W / 2
local cy = screen.InternalRes.H / 2

-- Canvas creation matching current mode
if screen.isUpscalingHiRes() then
    canvas = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
else
    canvas = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
end

-- Scaling when compositing in hi-res mode
if screen.isUpscalingHiRes() then
    love.graphics.draw(canvas, 0, 0, 0, screen.Scaling.X, screen.Scaling.Y)
end
```

## Related

- [Creating Patches](creating-patches.md) — canvas setup in patches
- [Configuration](configuration.md) — screen config options
