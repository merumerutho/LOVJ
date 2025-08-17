# LOVJ OSC Reference

This document describes the OSC (Open Sound Control) infrastructure for LOVJ, including the address hierarchy, message format, and usage examples.

## Overview

LOVJ implements a hierarchical OSC control system that maps to its internal architecture:
- **Global controls**: System-wide settings
- **Patch controls**: Per-patch parameters and operations  
- **Shader controls**: Shader selection and parameters
- **System controls**: Application-level operations

## OSC Address Hierarchy

### Global Controls
- `/lovj/global/selectedPatch <int>` - Change currently selected patch (1-N)
- `/lovj/global/bpm <float>` - Set global BPM (60-200)

### System Controls
- `/lovj/system/fullscreen <bool>` - Toggle fullscreen mode
- `/lovj/system/shaders/enabled <bool>` - Enable/disable all shaders
- `/lovj/system/upscaling <int>` - Change upscaling mode (0-3)
- `/lovj/system/reset <trigger>` - Reset system

### Patch Controls (per slot 1-N)
- `/lovj/patch/<slot>/load <string>` - Load specific patch by name
- `/lovj/patch/<slot>/reset <trigger>` - Reset patch
- `/lovj/patch/<slot>/param/<param_id> <float>` - Set patch parameter by ID
- `/lovj/patch/<slot>/savestate/<savestate_id>/load <trigger>` - Load savestate (1-12)
- `/lovj/patch/<slot>/savestate/<savestate_id>/save <trigger>` - Save savestate (1-12)
- `/lovj/patch/<slot>/graphics/<resource_name> <variant>` - Set graphics resource
- `/lovj/patch/<slot>/global/<global_name> <variant>` - Set global resource

### Shader Controls (per patch slot)
- `/lovj/shader/<slot>/<layer>/select <int>` - Select shader for layer
- `/lovj/shader/<slot>/<layer>/param/<param_name> <float>` - Set shader parameter

## Message Format

LOVJ accepts OSC messages in two formats:

### 1. Standard OSC Binary Format
Standard OSC packets with proper type tags (,f ,i ,s)

### 2. Simple String Format  
For testing and simple applications: `"<address> <value>"`

Examples:
```
"/lovj/global/selectedPatch 2"
"/lovj/patch/1/param/1 1.5"
"/lovj/system/fullscreen 1"
```

## Configuration

### Connection Settings
Edit `cfg/cfg_osc_mapping.lua` to configure OSC connections:

```lua
cfg_osc_mapping.connections = {
    {
        id = "touchosc",
        address = "127.0.0.1", 
        port = 8000,
        enabled = true
    }
}
```

### Adding Custom Mappings
Add new OSC addresses to the mappings:

```lua
cfg_osc_mapping.directMappings["/lovj/custom/mycontrol"] = {
    command = "myCustomCommand",
    args = {"$1"}
}
```

Or use pattern mappings for dynamic addresses:

```lua
table.insert(cfg_osc_mapping.patternMappings, {
    pattern = "^/lovj/custom/(%d+)/(.+)$",
    command = "myCustomCommand",
    args = {"$1", "$2", "$3"}
})
```

## Usage Examples

### TouchOSC / OSCPilot
```
# Select patch 3
/lovj/global/selectedPatch 3

# Set BPM to 128
/lovj/global/bpm 128

# Toggle fullscreen
/lovj/system/fullscreen 1

# Set patch 1 parameter ID 1 to 1.5
/lovj/patch/1/param/1 1.5

# Load demo_3 into patch slot 2
/lovj/patch/2/load demo_3

# Select shader 5 for layer 1 of patch 1
/lovj/shader/1/1/select 5
```

### Pure Data / Max/MSP
```
# Send to udpsend object at 127.0.0.1:8000
/lovj/global/selectedPatch 2
/lovj/patch/1/param/1 0.8
```

### Python (python-osc)
```python
from pythonosc import udp_client

client = udp_client.SimpleUDPClient("127.0.0.1", 8000)
client.send_message("/lovj/global/selectedPatch", 3)
client.send_message("/lovj/patch/1/param/1", 1.5)
```

## Testing

Send manual messages using netcat:
```bash
echo "/lovj/global/selectedPatch 2" | nc -u 127.0.0.1 8000
```

## Data Types

- **int**: Integer values (automatically clamped to valid ranges)
- **float**: Floating point values (automatically clamped to valid ranges)  
- **bool**: Boolean values (>0 = true, <=0 = false)
- **string**: String values
- **trigger**: Trigger actions (>0 triggers the action)
- **variant**: Mixed type (string or number)

## Error Handling

- Invalid addresses are logged to console
- Out-of-range values are automatically clamped
- Malformed messages are logged and ignored
- Connection errors are reported in the log

## Architecture Notes

- **Thread-safe**: OSC processing runs in separate OSCThread instances
- **Asynchronous**: OSC messages are queued and processed in main thread
- **Feedback**: Current values can be sent back to OSC clients
- **Hot-reload**: Configuration changes require restart
- **Multiple connections**: Support for multiple simultaneous OSC connections
- **Standard compliant**: Supports standard OSC binary format and simple text fallback

## Extending the System

1. Add new mappings to `cfg_osc_mapping.lua`
2. Implement corresponding commands in `cfg_commands.lua` 
3. Register commands in the command system
4. Test with OSC clients or test scripts

For advanced OSC parsing or bundle support, extend `OSCThread.lua` with a full OSC library like `losc`.