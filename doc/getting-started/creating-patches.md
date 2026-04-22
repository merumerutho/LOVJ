# Creating a Patch

[Back to index](../index.md)

## Anatomy

A patch is a Lua module that inherits from the `Patch` class and implements three lifecycle methods: `init()`, `draw()`, and `update()`.

```lua
local Patch = lovjRequire("lib/patch")
local cfg_timers = lovjRequire("cfg/cfg_timers")

local patch = Patch:new()

function patch.init(slot, globals, shaderext)
    Patch.init(patch, slot, globals, shaderext)
    patch:setCanvases()
    -- set up parameters, load assets
end

function patch.draw()
    patch:drawSetup()
    -- draw your graphics onto patch.canvases.main
    return patch:drawExec()
end

function patch.update()
    patch:mainUpdate()
    -- per-frame logic
end

return patch
```

## Directory Convention

```
demos/myPatch/
  source/my_patch.lua    -- patch source
  assets/                -- images, fonts, audio, video
```

Register the patch in `cfg/cfg_patches.lua`:

```lua
cfg_patches.patches = {
    -- ...existing patches...
    "demos/myPatch/source/my_patch",
}
```

The patch will then appear in the Studio web GUI's [Patches tab](../studio/studio.md) and be discoverable via the filesystem scan.

## Lifecycle Methods

### `init(slot, globals, shaderext)`

Called once on load and on every hot-reload. Must call `Patch.init(patch, slot, globals, shaderext)` first.

| Argument | Type | Description |
|----------|------|-------------|
| `slot` | number | 1-based slot index |
| `globals` | Resource | Shared global settings |
| `shaderext` | Resource | Shader parameters for this slot |

Use this to:
- Initialize `patch.resources.parameters` (names and default values)
- Load graphics assets into `patch.resources.graphics`
- Create additional canvases (`patch.canvases.myCanvas = ...`)
- Set up signal processors (LFOs, envelopes)

### `draw()`

Called every frame. Must call `patch:drawSetup()` at the start and return `patch:drawExec()` at the end.

Between those calls, draw onto `patch.canvases.main`. The parent class handles shader post-processing and final composition.

### `update()`

Called every frame before draw. Must call `patch:mainUpdate()` which handles `patchControls()`.

### `patchControls()`

Optional. Called from `mainUpdate()` when this patch is the selected slot. Use for keyboard input handling:

```lua
local kp = lovjRequire("lib/utils/keypress")

function patch.patchControls()
    local p = patch.resources.parameters
    if kp.isDown("up") then p:set("zoom", p:get("zoom") + 0.01) end
end
```

## Parameters

Parameters are stored in `patch.resources.parameters`, a [Resource](../architecture/resources.md) object:

```lua
local function init_params()
    local p = patch.resources.parameters
    p:setName(1, "speed")       p:set("speed", 0.5)
    p:setName(2, "intensity")   p:set("intensity", 0.8)
    p:setName(3, "count")       p:set("count", 10)
end
```

Parameters are automatically exposed in the Studio GUI's Parameters tab. They can be modulated by [LFOs/envelopes](../state/modulators.md), automated by the [step sequencer](../sequencing/sequencer.md), and saved/restored via [savestates](../state/savestates.md).

## Graphics Resources

Use `patch.resources.graphics` for asset paths and non-parameter data:

```lua
local g = patch.resources.graphics
g:setName(1, "sprite")    g:set("sprite", "demos/myPatch/assets/image.png")
```

## Custom Canvases

For multi-pass rendering (e.g. [feedback effects](../graphics/feedback.md)):

```lua
function patch:setCanvases()
    Patch.setCanvases(patch)
    patch.canvases.layer = love.graphics.newCanvas(
        screen.InternalRes.W, screen.InternalRes.H)
end
```

Always call `Patch.setCanvases(patch)` first to create the base `main` canvas.

## Using Feedback

The [Feedback](../graphics/feedback.md) class simplifies echo/trail effects:

```lua
local Feedback = lovjRequire("lib/feedback")

function patch.init(slot, globals, shaderext)
    Patch.init(patch, slot, globals, shaderext)
    patch:setCanvases()
    patch.fbk = Feedback:new({ tint = {1, 0.95, 1, 0.85} })
end

function patch.draw()
    patch:drawSetup()
    -- draw fresh content onto a canvas...
    patch.fbk:process(contentCanvas, { rotation = t * 0.1, scaleX = 1.1 })
    love.graphics.draw(patch.fbk:getOutput(), 0, 0)
    return patch:drawExec()
end
```

## Tips

- Use `cfg_timers.globalTimer.T` for time-based animation (survives hot-reload)
- Use `screen.InternalRes.W/H` for resolution-independent coordinates
- The `R` key is conventionally used for patch reset in `patchControls()`
- All asset paths use forward slashes
