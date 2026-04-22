# OSC

[Back to index](../index.md)

LOVJ receives OSC messages via background threads and routes them to [commands](commands.md) through `lib/osc/osc_dispatcher.lua`.

## Connections

OSC connections are configured in `cfg/cfg_osc_mapping.lua`:

```lua
cfg_osc_mapping.connections = {
    { address = "0.0.0.0", port = 9000, enabled = true },
}
```

Each enabled connection spawns a thread listening on a UDP port. Incoming messages are parsed and matched against address patterns or direct mappings.

## Address Routing

OSC addresses are mapped to commands in `cfg/cfg_osc_mapping.lua`:

```lua
cfg_osc_mapping.directMappings = {
    ["/bpm"] = { command = "setBPM" },
    ["/patch/1/speed"] = { command = "setPatchParameterByName", args = {1, "speed"} },
}
```

### Pattern-Based Routing

Lua patterns can match dynamic addresses:

```lua
cfg_osc_mapping.patternMappings = {
    { pattern = "/lovj/patch/(%d+)/param/(.+)", command = "setPatchParameterByName" },
    { pattern = "/lovj/shader/(%d+)/(%d+)/select", command = "selectShader" },
}
```

### Standard Address Hierarchy

| Address | Description |
|---------|-------------|
| `/lovj/global/selectedPatch <slot>` | Switch to patch slot |
| `/lovj/global/bpm <value>` | Set BPM |
| `/lovj/patch/<slot>/param/<name> <value>` | Set patch parameter |
| `/lovj/shader/<slot>/<layer>/select <id>` | Set shader on layer |
| `/lovj/shader/<slot>/<layer>/param/<name> <value>` | Set shader parameter |
| `/lovj/system/fullscreen <0\|1>` | Toggle fullscreen |
| `/lovj/system/shaders <0\|1>` | Toggle shaders |

## Value Transforms

```lua
cfg_osc_mapping.transformations = {
    integerSlot = function(value) return math.floor(value) end,
    booleanValue = function(value) return value ~= 0 end,
    midiNormalize = function(value) return value / 127.0 end,
}
```

## Parameter Discovery

LOVJ includes an on-demand parameter discovery protocol (`lib/osc/parameter_discovery.lua`, `lib/osc/osc_feedback.lua`) that allows external controllers to query available parameters at runtime.

### Discovery Addresses

| Address | Direction | Purpose |
|---------|-----------|---------|
| `/lovj/discovery/request/all` | client → LOVJ | Request all parameters |
| `/lovj/discovery/request/category` | client → LOVJ | Request by category (`global`, `patch`, `shader`, `system`) |
| `/lovj/discovery/update_tick` | client → LOVJ | Client keepalive tick |
| `/lovj/discovery/welcome` | LOVJ → client | Server welcome on connect |
| `/lovj/discovery/response/parameter` | LOVJ → client | Single parameter info (JSON) |
| `/lovj/discovery/response/complete` | LOVJ → client | Discovery batch complete |
| `/lovj/parameter/update` | LOVJ → client | Real-time value change |

### Discovery Response Format

Each parameter is sent as a JSON payload:

```json
{
    "address": "/lovj/patch/1/param/1",
    "category": "patch",
    "valueType": "float",
    "currentValue": 0.8,
    "defaultValue": 0.0,
    "minValue": 0.0,
    "maxValue": 1.0,
    "paramId": 1,
    "paramName": "brightness",
    "description": "Patch 1 parameter 1: brightness"
}
```

Patch parameters include both `paramId` (stable numeric index) and `paramName` (human-readable) so controllers can use stable addressing while displaying names.

### Client Keepalive

Clients should periodically send `/lovj/discovery/update_tick` to stay registered. LOVJ tracks connected clients and sends real-time parameter updates only to active clients.

### Parameter Categories

- **global** — BPM, selected patch
- **patch** — per-slot patch parameters and graphics resources
- **shader** — shader selections and shader-specific parameters
- **system** — fullscreen, shader enable, upscaling mode

## Feedback

When parameters change (from any source), LOVJ sends OSC feedback messages to registered clients:

```
/lovj/parameter/update {"address": "/lovj/global/bpm", "value": 140.0}
```

This keeps external controllers in sync regardless of whether the change came from MIDI, keyboard, the Studio GUI, or OSC itself.

## Related

- [Command System](commands.md) — available commands
- [MIDI](midi.md) — alternative control protocol
- [Studio Overview](../studio/studio.md) — web-based alternative to OSC control
