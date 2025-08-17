# OSC Parameter Discovery and Feedback System

## Overview

LOVJ includes an OSC parameter discovery and feedback system that allows external controllers to query LOVJ for all available parameters, their current values, and their constraints. The system works on-demand: LOVJ discovers and reports parameters only when external controllers request them, ensuring real-time accuracy.

## Features

- **On-Demand Parameter Discovery**: External controllers request parameters when needed - LOVJ responds with current state
- **Real-time Parameter Updates**: Changes made in LOVJ are sent to connected controllers in real-time
- **Categorized Parameters**: Parameters are organized by category (global, patch, shader, system)
- **Parameter Metadata**: Each parameter includes type information, constraints, descriptions, and current values
- **Client Management**: Automatic client registration and update tick monitoring
- **Fresh Data Guarantee**: Parameters are discovered fresh each time, ensuring accurate current values

## OSC Discovery Protocol

### Discovery Addresses

| Address | Purpose | Arguments |
|---------|---------|-----------|
| `/lovj/discovery/request/all` | Request all parameters | None |
| `/lovj/discovery/request/category` | Request parameters by category | `<category>` |
| `/lovj/discovery/update_tick` | Client update tick | None |
| `/lovj/discovery/welcome` | Server welcome message | (sent by server) |
| `/lovj/discovery/response/parameter` | Parameter information | (sent by server) |
| `/lovj/discovery/response/complete` | Discovery completion | (sent by server) |
| `/lovj/parameter/update` | Real-time parameter update | (sent by server) |

### Parameter Categories

- **global**: Global application parameters (BPM, selected patch, volume)
- **patch**: Patch-specific parameters and graphics resources
- **shader**: Shader parameters and selection
- **system**: System settings (fullscreen, shader enable, upscaling)

## Usage Examples

### 1. Discovering All Parameters

**Client sends:**
```
/lovj/discovery/request/all
```

**Server responds with multiple messages:**
```
/lovj/discovery/response/parameter {
    "address": "/lovj/global/bpm",
    "category": "global",
    "valueType": "float",
    "currentValue": 120.0,
    "defaultValue": 120.0,
    "minValue": 60.0,
    "maxValue": 200.0,
    "description": "Global BPM (beats per minute)",
    "readable": true,
    "writable": true
}

/lovj/discovery/response/parameter {
    "address": "/lovj/patch/1/param/1",
    "category": "patch",
    "valueType": "float",
    "currentValue": 0.8,
    "defaultValue": 0.0,
    "minValue": 0.0,
    "maxValue": 1.0,
    "paramId": 1,
    "paramName": "brightness",
    "description": "Patch 1 parameter 1: brightness",
    "readable": true,
    "writable": true
}

// ... more parameters ...

/lovj/discovery/response/complete {
    "category": "all",
    "parameterCount": 45,
    "timestamp": 1234567890.123
}
```

### 2. Category-Specific Discovery

**Client sends:**
```
/lovj/discovery/request/category global
```

**Server responds with only global parameters.**

### 3. Real-time Parameter Updates

When parameters change in LOVJ, connected clients automatically receive:

```
/lovj/parameter/update {
    "address": "/lovj/global/bpm",
    "value": 140.0,
    "timestamp": 1234567890.456
}
```

### 4. Client Update Tick

**Client sends periodically:**
```
/lovj/discovery/update_tick
```

**Server responds:**
```
/lovj/discovery/update_tick {
    "timestamp": 1234567890.789,
    "status": "ok"
}
```

## Parameter Address Structure

### Parameter ID System

**Important**: Patch parameters are now addressed by **ID** rather than name to ensure consistency across different patches. Parameter IDs are stable numeric identifiers (1, 2, 3, etc.) that remain constant regardless of parameter names.

**Benefits:**
- **Stability**: IDs don't change when parameter names change
- **Consistency**: Same ID represents the same parameter slot across all patches
- **Reliability**: No name conflicts or special character issues
- **Performance**: Direct index-based access

**Discovery Response**: Each patch parameter includes both `paramId` and `paramName` fields, allowing controllers to use stable IDs while displaying human-readable names.

### Global Parameters
- `/lovj/global/bpm` - Global BPM (60-200)
- `/lovj/global/selectedPatch` - Currently selected patch (1-12)
- `/lovj/global/volume` - Master volume (0.0-1.0)

### Patch Parameters
- `/lovj/patch/<slot>/param/<id>` - Patch-specific parameters (by ID)
- `/lovj/patch/<slot>/graphics/<name>` - Graphics resource paths
- `/lovj/patch/<slot>/name` - Patch name (read-only)
- `/lovj/patch/<slot>/enabled` - Patch enable state

### Shader Parameters
- `/lovj/shader/<slot>/<layer>/param/<name>` - Shader parameters
- `/lovj/shader/<slot>/<layer>/select` - Selected shader for layer
- `/lovj/shader/global/param/<shader>_<param>` - Global shader parameters

### System Parameters
- `/lovj/system/fullscreen` - Fullscreen mode (boolean)
- `/lovj/system/shaders` - Shader system enable (boolean)
- `/lovj/system/upscaling` - Upscaling mode ("nearest", "linear")

## Implementation Details

### Client Registration

Controllers are automatically registered when they send their first discovery request or update tick. Registration includes:

- Client IP and port
- Last update tick timestamp
- Subscribed parameter categories
- Connection capabilities

### On-Demand Discovery

Unlike traditional systems that maintain cached parameter lists, LOVJ discovers parameters fresh each time:

1. **External controller sends discovery request**
2. **LOVJ scans current application state** (patches, shaders, global settings)
3. **LOVJ builds parameter list** with current values and metadata
4. **LOVJ responds** with complete, up-to-date parameter information

This ensures controllers always receive accurate, current data without stale cached values.

### Parameter Types

- **float**: Floating-point values with min/max constraints
- **int**: Integer values with min/max constraints
- **bool**: Boolean values (true/false or 0/1)
- **string**: Text values
- **enum**: String values from a predefined list
- **stringArray**: Array of string values

### Rate Limiting

Parameter updates are rate-limited to prevent flooding:
- Default: 50ms minimum between updates
- BPM changes: 100ms minimum
- System parameters: 200ms minimum

**Note**: Discovery requests are not rate-limited as they are typically infrequent (sent when controllers connect or need to refresh their parameter list).

### Configuration Files

- `cfg/cfg_parameter_feedback.lua` - Main configuration
- `cfg/cfg_osc_mapping.lua` - OSC address mappings (includes discovery endpoints)
- `lib/osc/parameter_discovery.lua` - Core discovery logic
- `lib/osc/osc_feedback.lua` - Feedback system

## Testing

Run the test script to verify functionality:

```lua
-- In LOVJ console or main.lua
require("test_parameter_discovery")
```

## Integration Examples

### TouchOSC Setup

1. Connect to LOVJ OSC server (127.0.0.1:8000)
2. Send `/lovj/discovery/request/all` on startup
3. Parse parameter responses to create dynamic control layouts
4. Subscribe to `/lovj/parameter/update` for real-time sync

### Max/MSP Integration

```max
// Send discovery request
[udpsend 127.0.0.1 8000]
|
[/lovj/discovery/request/all(

// Receive parameter info
[udpreceive 9000]
|
[route /lovj/discovery/response/parameter]
|
[unpack]
// Parse JSON parameter data
```

### Python Controller Example

```python
import asyncio
from pythonosc import udp_client, dispatcher, server
import json

class LOVJController:
    def __init__(self):
        self.client = udp_client.SimpleUDPClient("127.0.0.1", 8000)
        self.parameters = {}
        
    async def discover_parameters(self):
        # Request all parameters
        self.client.send_message("/lovj/discovery/request/all", [])
        
    def parameter_handler(self, address, *args):
        if address == "/lovj/discovery/response/parameter":
            param_data = json.loads(args[0])
            self.parameters[param_data["address"]] = param_data
            
    def update_handler(self, address, *args):
        if address == "/lovj/parameter/update":
            update_data = json.loads(args[0])
            param_addr = update_data["address"]
            new_value = update_data["value"]
            print(f"Parameter {param_addr} changed to {new_value}")
```

## Troubleshooting

### Common Issues

1. **No parameters discovered**: Ensure OSC server is running and reachable
2. **Missing categories**: Check if patches/shaders are loaded
3. **Update delays**: Verify client update tick is being sent
4. **Connection timeouts**: Check firewall settings and network connectivity

### Debug Mode

Enable detailed logging in `cfg/cfg_parameter_feedback.lua`:

```lua
cfg_parameter_feedback.logging = {
    enabled = true,
    logDiscoveryRequests = true,
    logParameterUpdates = true,
    logClientConnections = true
}
```

## Future Enhancements

- MIDI parameter discovery (similar protocol for MIDI controllers)
- Parameter presets and snapshots via OSC
- Bidirectional parameter binding
- Custom parameter validation and transformation
- WebSocket support for web-based controllers