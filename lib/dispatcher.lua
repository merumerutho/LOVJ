-- dispatcher.lua
--
-- Main Protocol Dispatcher for LOVJ
-- Coordinates all external protocol handlers and the generic command system
-- Routes messages from OSC, MIDI, and other protocols to unified commands
--

local dispatcher = {}

-- Protocol handlers
local OSCDispatcher = lovjRequire("lib/osc/osc_dispatcher")
local MIDIDispatcher = lovjRequire("lib/midi/midi_dispatcher")
local CommandSystem = lovjRequire("lib/command_system")

-- Initialize all protocol dispatchers and command system
function dispatcher.init()
    logInfo("Main Dispatcher: Initializing command system and protocol handlers")
    
    -- Initialize command system with all LOVJ commands
    local cfgCommands = require("cfg/cfg_commands")
    cfgCommands.init()
    
    -- Initialize OSC dispatcher
    OSCDispatcher.init()
    
    -- Initialize MIDI dispatcher
    MIDIDispatcher.init()
    
    logInfo("Main Dispatcher: Initialization complete")
end

-- Main update function - processes all protocol messages and executes commands
function dispatcher.update()
    -- Update all protocol dispatchers (they queue commands)
    OSCDispatcher.update()
    MIDIDispatcher.update()
    
    -- Execute all queued commands in main thread
    CommandSystem.processCommands()
end

-- Register OSC channel (delegated to OSC dispatcher)
function dispatcher.registerOSCChannel(channelName)
    OSCDispatcher.registerOSCChannel(channelName)
end

-- Unregister OSC channel (delegated to OSC dispatcher)  
function dispatcher.unregisterOSCChannel(channelName)
    OSCDispatcher.unregisterOSCChannel(channelName)
end

-- Register MIDI channel (delegated to MIDI dispatcher)
function dispatcher.registerMIDIChannel(channelName)
    MIDIDispatcher.registerMIDIChannel(channelName)
end

-- Unregister MIDI channel (delegated to MIDI dispatcher)
function dispatcher.unregisterMIDIChannel(channelName)
    MIDIDispatcher.unregisterMIDIChannel(channelName)
end

-- Get status of all dispatchers
function dispatcher.getStatus()
    return {
        osc = OSCDispatcher.getStatus(),
        midi = MIDIDispatcher.getStatus(),
        commands = {
            queueLength = #CommandSystem.commandQueue,
            availableCommands = table.getn(CommandSystem.getCommands())
        }
    }
end

-- Stop all OSC threads (for cleanup during resets)
function dispatcher.stopAllOSCThreads()
    OSCDispatcher.stopAllOSCThreads()
end

-- Stop all MIDI threads (for cleanup during resets)
function dispatcher.stopAllMIDIThreads()
    MIDIDispatcher.stopAllMIDIThreads()
end

-- Emergency reset all dispatchers
function dispatcher.reset()
    CommandSystem.clearQueue()
    OSCDispatcher.stopAllOSCThreads()
    MIDIDispatcher.stopAllMIDIThreads()
    logInfo("Main Dispatcher: Reset complete")
end

return dispatcher