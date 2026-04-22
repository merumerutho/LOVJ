# Keyboard Mapping

[Back to index](index.md)

Keyboard controls are configured in `cfg/cfg_kb_mapping.lua` and bind key combinations to [commands](commands.md).

## Mapping Format

```lua
cfgKbMapping.directMappings = {
    ["f"] = { command = "toggleFullscreen" },
    ["lctrl+s"] = { command = "saveSavestate", args = {"$selectedSlot", 1} },
    ["1"] = { command = "setSelectedPatch", args = {1}, trigger = "press" },
}
```

| Field | Description |
|-------|-------------|
| `command` | Name of a registered [command](commands.md) |
| `args` | Argument array (supports `$variable` resolvers) |
| `trigger` | `"press"` (on keydown) or `"hold"` (while held). Default: `"press"` |

## Key Combo Syntax

Key combos are strings with `+` separating modifiers:

- `"r"` — single key
- `"lctrl+s"` — left ctrl + S
- `"f1"` — function key
- `"lshift+f1"` — shift + F1

## Argument Resolvers

Arguments prefixed with `$` are resolved dynamically at execution time:

| Resolver | Value |
|----------|-------|
| `$selectedSlot` | Current `cfg_patches.selectedPatch` |

```lua
cfgKbMapping.argumentResolvers = {
    ["$selectedSlot"] = function() return cfg_patches.selectedPatch end,
}
```

## Auto-Generated Mappings

`cfgKbMapping.generateMappings()` creates common bindings automatically:

- **Number keys 1-9**: `setSelectedPatch` (select slot)
- **F1-F12**: patch-specific actions
- **Ctrl+F1-F12**: system actions

## Related

- [Command System](commands.md) — available commands
- [MIDI](midi.md) — alternative control input
- [OSC](osc.md) — network-based control
