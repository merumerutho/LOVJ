local Connections = {}
local cfg_connections = require("cfg/cfg_connections")
local dispatcher = require("lib/dispatcher")

function Connections.init()
    Connections.OscThreads = {}
    Connections.OscChannels = {}

    for k, v in pairs(cfg_connections.listOfThreads) do
        local channelName = "oscChannel_" .. k
        
        -- Create and start OSC thread
        local oscThread = love.thread.newThread("lib/OSCThread.lua")
        oscThread:start(k, v)
        
        -- Store reference to the OSC thread and its channel
        Connections.OscThreads[k] = oscThread
        Connections.OscChannels[k] = channelName
        
    end
end

-- Function to stop an OSC thread and remove its channel
function Connections.stopOSCThread(id)
    if Connections.OscThreads[id] then
        Connections.OscThreads[id]:release()
        Connections.OscThreads[id] = nil
        
		-- Remove OSC Channel
        local channelName = Connections.OscChannels[id]
        if channelName then
            Connections.OscChannels[id] = nil
        end
    end
end

return Connections
