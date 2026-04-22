# OSC

[Back to index](index.md)

LOVJ receives OSC messages via background threads and routes them to [commands](commands.md) through `lib/osc/osc_dispatcher.lua`.

## Overview

OSC connections are configured in `cfg/cfg_connections.lua`. Each enabled connection spawns a thread listening on a UDP port. Incoming messages are parsed and matched against address patterns or direct mappings.

## Message Format

Internal message format (from OSC thread to dispatcher):

```
senderIP:senderPort|/address value1 value2 ...
```

## Address Routing

OSC addresses are mapped to commands in `cfg/cfg_osc_mapping.lua`:

```lua
cfg_osc_mapping.directMappings = {
    ["/bpm"] = { command = "setBPM" },
    ["/patch/1/speed"] = { command = "setPatchParameterByName", args = {1, "speed"} },
}
```

Pattern-based routing is also supported for dynamic address matching.

## Parameter Discovery

LOVJ supports an OSC parameter discovery protocol (`lib/osc/osc_feedback.lua`) that allows external controllers to query available parameters:

1. Controller sends a discovery request
2. LOVJ responds with parameter names, types, and current values
3. Controller can then build a dynamic UI

The `requestAllParameters` command triggers a full parameter dump to the requesting client.

## Feedback

When parameters change (from any source), LOVJ can send OSC feedback messages to registered clients, keeping external controllers in sync.

## Related

- [Command System](commands.md) — available commands
- [MIDI](midi.md) — alternative control protocol
- [Studio Overview](studio.md) — web-based alternative to OSC control
