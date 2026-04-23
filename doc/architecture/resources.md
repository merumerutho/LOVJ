# Resource System

[Back to index](../index.md)

Resources are LOVJ's storage layer for named, indexed values. Every patch has a `ResourceList` containing multiple `Resource` objects.

## ResourceList

Created during patch initialization:

```lua
ResourceList:new(global, shader)
```

| Field | Type | Description |
|-------|------|-------------|
| `parameters` | Resource | Patch-specific numeric parameters |
| `graphics` | Resource | Asset paths, graphics data |
| `globals` | Resource | Shared global settings (passed in) |
| `shaderext` | Resource | Shader parameters (passed in) |

Access via `patch.resources.parameters`, `patch.resources.graphics`, etc.

## Resource

A Resource is an indexed array of `{name, value}` entries, pre-allocated to `SETTINGS_MAX_COUNT` (128) slots.

### API

| Method | Description |
|--------|-------------|
| `setName(idx, name)` | Set the name of entry at index |
| `getName(idx)` | Get the name of entry at index |
| `set(name, value)` | Set value by name (looks up index) |
| `get(name)` | Get value by name |
| `setByIdx(idx, value)` | Set value by index (triggers `_onChange`) |
| `getByIdx(idx)` | Get value by index |
| `getIdxByName(name)` | Find index of a named entry (-1 if not found) |
| `define(idx, name, value, meta)` | Set name, value, and metadata in one call |
| `setMeta(idx, meta)` | Attach metadata table to an entry |
| `getMeta(idx)` | Get metadata table for an entry |
| `#resource` | Length operator returns entry count |

### Parameter Metadata

Parameters can carry metadata that the Studio GUI uses for proper slider ranges:

```lua
p:define(1, "speed", 0.5, { min = 0, max = 2, type = "float" })
p:define(2, "count", 10,  { min = 1, max = 100, step = 1, type = "int" })
```

| Meta Field | Default | Description |
|------------|---------|-------------|
| `min` | 0 | Minimum value |
| `max` | 1 | Maximum value |
| `step` | auto | Slider step size (auto-computed from range if omitted) |
| `type` | `"float"` | `"float"`, `"int"`, or `"bool"` |

Parameters without metadata default to float 0-1 range in the GUI. Existing patches using `setName`/`set` continue to work unchanged.

### Change Notifications

Assigning `resource._onChange = function(name, value) ... end` installs a callback that fires on every `setByIdx` call where the value actually changes. This powers the Studio GUI's real-time parameter display.

```lua
patch.resources.parameters._onChange = function(name, value)
    studioProtocol.notifyParamChanged(slot, name, value)
end
```

### Naming Convention

Unused entries have default names like `"resource1"`, `"resource2"`. The protocol layer filters these out when building schemas for the Studio GUI.

## Usage Patterns

### Parameters

```lua
local p = patch.resources.parameters
p:setName(1, "speed")       p:set("speed", 0.5)
p:setName(2, "intensity")   p:set("intensity", 0.8)

-- In draw/update:
local speed = p:get("speed")
```

### Graphics Resources

```lua
local g = patch.resources.graphics
g:setName(1, "background")  g:set("background", "path/to/image.png")

-- Later:
local img = love.graphics.newImage(g:get("background"))
```

### Shader Extensions

The `shaderext` Resource stores per-slot shader selections and shader parameter values. It is initialized by `cfgShaders.initShaderExt(slot)`:

- `shaderSlot1`, `shaderSlot2`, `shaderSlot3` — post-process shader indices
- `shaderName_paramName` — individual shader parameter values (parsed from `@param` annotations)

See [Writing Shaders](../getting-started/shaders.md) for how shader parameters are defined and managed.
