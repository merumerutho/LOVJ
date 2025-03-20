local Connections = {}
local cfg_connections = require("cfg/cfg_connections")
local dispatcher = require("lib/dispatcher")

function Connections.init()
    Connections.UdpThreads = {}
    Connections.OscChannels = {}

    for k, v in pairs(cfg_connections.listOfThreads) do
        local channelName = "oscChannel_" .. k
        
        -- Create and start UDP thread
        local thread = love.thread.newThread("lib/UDPThread.lua")
        thread:start(k, v)
        
        -- Store reference to the thread and its OSC channel
        Connections.UdpThreads[k] = thread
        Connections.OscChannels[k] = channelName
        
    end
end

-- Function to stop a UDP thread and remove its channel
function Connections.stopThread(id)
    if Connections.UdpThreads[id] then
        Connections.UdpThreads[id]:release()
        Connections.UdpThreads[id] = nil
        
		-- Remove OscChannel
        local channelName = Connections.OscChannels[id]
        if channelName then
            Connections.OscChannels[id] = nil
        end
    end
end

return Connections
