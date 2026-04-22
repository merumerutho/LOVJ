# Feedback Buffers

[Back to index](index.md)

The `Feedback` class (`lib/feedback.lua`) provides a reusable ping-pong buffer for creating echo, trail, and recursive visual effects.

## How It Works

Feedback maintains two canvases (`front` and `back`) that swap roles each frame:

1. **Echo step**: Draw `back` → `front` with a transform (rotation, scale around center)
2. **Accumulate step**: Clear `back`, draw `front` onto it with a color tint (controls decay), then composite fresh content on top
3. The result accumulates over time — each frame's content persists and transforms

## Constructor

```lua
local Feedback = lovjRequire("lib/feedback")

local fbk = Feedback:new({
    width      = 640,          -- canvas width (optional, defaults to 2x screen)
    height     = 320,          -- canvas height (optional, defaults to 2x screen)
    rotation   = 0,            -- default rotation per frame (radians)
    scaleX     = 1.0,          -- default X scale per frame
    scaleY     = 1.0,          -- default Y scale per frame
    tint       = {1, 1, 1, 0.9},   -- RGBA tint for decay (alpha < 1 = fade)
    clearColor = {0, 0, 0, 0},     -- clear color for back buffer
    shader     = nil,          -- LÖVE shader applied during echo step
    processFn  = nil,          -- callback(front, back, opts) after echo step
})
```

If `width`/`height` are omitted, canvases are sized to `2x` the current screen resolution (accounting for [upscaling mode](screen.md)).

## API

### `process(contentCanvas, opts)`

Runs one feedback iteration. `contentCanvas` is the fresh content to feed in (can be `nil` for pure feedback decay).

Per-frame overrides via `opts`:

```lua
fbk:process(myCanvas, {
    rotation   = t * 0.1,        -- animate rotation
    scaleX     = 1.05,           -- slight zoom each frame
    scaleY     = 1.05,
    tint       = {1, 0.95, 1, 0.8},  -- override tint
    clearColor = {0, 0, 0, 1},       -- opaque clear
    shader     = myShader,            -- GLSL shader applied during echo step
    processFn  = myFunction,          -- custom callback after echo step
})
```

Any field not provided in `opts` falls back to the defaults set in the constructor.

#### `shader`

A compiled LÖVE shader applied during the echo step (when `back` is drawn onto `front` with the transform). The shader receives the back buffer as its texture, so standard `effect()` signatures work. It is automatically cleared after the draw.

```lua
local blur = love.graphics.newShader(blurCode)
fbk:process(content, { shader = blur })
```

You can send uniforms to the shader before calling `process()`:

```lua
blur:send("_radius", 3.0)
fbk:process(content, { shader = blur })
```

#### `processFn`

A callback `function(front, back, opts)` invoked after the echo step but before the tint/composite step. The canvas is set to `front` when the callback is entered. Use this for arbitrary drawing, multi-pass effects, or anything that doesn't fit a single shader pass.

```lua
fbk:process(content, {
    processFn = function(front, back, opts)
        love.graphics.setColor(0, 0, 0, 0.02)
        love.graphics.rectangle("fill", 0, 0, front:getWidth(), front:getHeight())
        love.graphics.setColor(1, 1, 1, 1)
    end,
})
```

Both `shader` and `processFn` can be used together — the shader runs first (during the echo draw), then `processFn` runs on the result.

### `getOutput()`

Returns the `front` canvas for compositing onto the patch's main canvas. The canvas is larger than the requested content size (sized to the diagonal) to prevent edge clipping during rotation. Use `getDrawOffset()` to position it correctly.

### `getDrawOffset()`

Returns `offsetX, offsetY` to compensate for the overscan padding. Use when drawing the output:

```lua
local offX, offY = fbk:getDrawOffset()
love.graphics.draw(fbk:getOutput(), offX, offY)
```

### `resize(w, h)`

Recreates both canvases at a new size (with overscan). Existing feedback content is lost.

## Example

```lua
local Feedback = lovjRequire("lib/feedback")

function patch.init(slot, globals, shaderext)
    Patch.init(patch, slot, globals, shaderext)
    patch:setCanvases()
    patch.canvases.content = love.graphics.newCanvas(
        2 * screen.InternalRes.W, 2 * screen.InternalRes.H)
    patch.fbk = Feedback:new({
        tint = {1, 0.95, 1, 0.85},
        clearColor = {0, 0, 0, 0},
    })
end

function patch.draw()
    patch:drawSetup()
    local t = cfg_timers.globalTimer.T
    local cx, cy = screen.InternalRes.W, screen.InternalRes.H

    -- Draw fresh content
    love.graphics.setCanvas(patch.canvases.content)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", cx + 50 * math.sin(t), cy, 10)

    -- Feed into feedback loop
    patch.fbk:process(patch.canvases.content, {
        rotation = t * 0.05,
        scaleX = 1.02,
        scaleY = 1.02,
    })

    -- Compose onto main
    local offX, offY = patch.fbk:getDrawOffset()
    love.graphics.setCanvas(patch.canvases.main)
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(patch.fbk:getOutput(), -cx / 2 + offX, -cy / 2 + offY)

    return patch:drawExec()
end
```

## Blend Modes for Composition

How you draw `getOutput()` onto your main canvas determines how the feedback trails interact with the background.

### Alpha blending (default)

```lua
love.graphics.draw(fbk:getOutput(), offX, offY)
```

Standard alpha blend: `result = src * alpha + dst * (1 - alpha)`. Trails replace the background proportionally — a white trail at 30% alpha dims the background by 30%. Good for opaque feedback scenes (e.g. feedback over a black background, or when the feedback IS the background).

### Additive blending

```lua
love.graphics.setBlendMode("add", "alphamultiply")
love.graphics.draw(fbk:getOutput(), offX, offY)
love.graphics.setBlendMode("alpha")
```

Additive blend: `result = src * alpha + dst`. Trails add light on top of the background without dimming it. White trails glow bright and fade by losing intensity, not by greying out. **Use this when the feedback is a transparent overlay on top of a colored background** — it produces bright, luminous ghost trails.

Always reset to `"alpha"` afterward so the post-process shader pipeline isn't affected.

### Choosing the right mode

| Scenario | Blend Mode | Why |
|----------|-----------|-----|
| Feedback IS the scene (full-canvas echo) | `alpha` | Background is black or irrelevant |
| Feedback over colored background | `add` | Prevents greying, trails glow |
| Selective overlay (balls only, etc.) | `add` | Bright trails that don't darken the scene |

## Creative Parameters

| Parameter | Visual Effect |
|-----------|--------------|
| `tint` alpha < 1 | Trails fade over time |
| `tint` RGB = 1,1,1 | Trails stay white/original color as they fade |
| `tint` RGB ≠ 1 | Color shift in echoes (each frame multiplies) |
| `rotation` ≠ 0 | Spiral/rotating trails |
| `scaleX/Y` > 1 | Zoom-out echo (expanding) |
| `scaleX/Y` < 1 | Zoom-in echo (converging) |
| `clearColor` alpha = 1 | Clean feedback (no transparency bleed) |
| `clearColor` alpha = 0 | Transparent feedback (composites with background) |

## Related

- [Creating Patches](creating-patches.md) — using feedback in patches
- [Patch Rendering Pipeline](rendering.md) — where feedback fits in the draw flow
