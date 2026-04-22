# Patch Rendering Pipeline

[Back to index](index.md)

Each frame, LOVJ renders visible patch slots through a multi-stage canvas pipeline with post-process shader support.

## Pipeline Overview

```
patch.draw()
  ├── drawSetup()          Clear main canvas
  ├── [patch-specific drawing onto canvases]
  └── drawExec()           Return main canvas
        │
        ▼
main.lua draw loop
  ├── Apply post-process shader layer 1
  ├── Apply post-process shader layer 2
  ├── Apply post-process shader layer 3
  ├── Composite to screen
  └── Send to Spout (if enabled)
```

## Patch Canvases

Every patch has `patch.canvases.main` created by `Patch:setCanvases()`. Patches can add custom canvases for multi-pass rendering:

```lua
function patch:setCanvases()
    Patch.setCanvases(patch)  -- creates main canvas
    patch.canvases.layer1 = love.graphics.newCanvas(w, h)
    patch.canvases.layer2 = love.graphics.newCanvas(w, h)
end
```

## Drawing Flow

### `drawSetup()`

Prepares the patch for drawing:
- Sets the main canvas as render target
- Clears it

### Custom Drawing

Between `drawSetup()` and `drawExec()`, the patch draws onto `patch.canvases.main` (or intermediate canvases that eventually composite onto main):

```lua
function patch.draw()
    patch:drawSetup()

    -- Draw onto an intermediate canvas
    love.graphics.setCanvas(patch.canvases.layer1)
    love.graphics.clear(0, 0, 0, 0)
    -- ...draw stuff...

    -- Composite onto main
    love.graphics.setCanvas(patch.canvases.main)
    love.graphics.draw(patch.canvases.layer1)

    return patch:drawExec()
end
```

### `drawExec()`

Finalizes and returns the rendered canvas for the main loop to apply shaders and display.

## Post-Process Shaders

Each slot has 3 shader layers, selected via `shaderext` resources (`shaderSlot1`, `shaderSlot2`, `shaderSlot3`). The main loop applies them sequentially using `cfgShaders.selectPPShader()`.

Shaders are GLSL fragment programs with the signature:

```glsl
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
```

See [Writing Shaders](shaders.md) for details.

## Feedback Integration

[Feedback buffers](feedback.md) fit between `drawSetup()` and `drawExec()`:

```lua
-- Draw fresh content → contentCanvas
-- Process feedback with content
patch.fbk:process(contentCanvas, {...})
-- Draw feedback output → main canvas
love.graphics.setCanvas(patch.canvases.main)
love.graphics.draw(patch.fbk:getOutput(), ...)
```

## Resolution Awareness

Patches should use `screen.InternalRes` for coordinates and check `screen.isUpscalingHiRes()` when creating canvases or scaling draws. See [Screen & Resolution](screen.md).

## Related

- [Creating Patches](creating-patches.md) — full patch anatomy
- [Writing Shaders](shaders.md) — post-process shader pipeline
- [Feedback Buffers](feedback.md) — echo/trail effects
- [Screen & Resolution](screen.md) — resolution modes
