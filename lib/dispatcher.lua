-- dispatcher.lua
--
-- dispatch the content of a received msg to the relative section
--

local resources = require("lib/resources")
local oscConfig = require("cfg/cfg_osc_handlers")

local dispatcher = {}

-- Table to store dynamically registered channels
local activeChannels = {}

-- Table to store the latest values for feedback
local currentValues = {}

-- Function to register a new channel
function dispatcher.registerChannel(channelName)
    if not activeChannels[channelName] then
        activeChannels[channelName] = love.thread.getChannel(channelName)
    end
end

-- Function to unregister a channel (e.g., when a UDP thread disconnects)
function dispatcher.unregisterChannel(channelName)
    activeChannels[channelName] = nil
end

-- Generate the dynamic handler table
local oscHandlers = {}
for address, functionName in pairs(oscConfig) do
    if resources[functionName] then
        oscHandlers[address] = function(args)
            resources[functionName](args[1])
            currentValues[address] = args[1] -- Store the value for feedback
        end
    else
        print("Warning: Function", functionName, "not found in resources")
    end
end

-- Function to process received OSC messages from dynamically tracked channels
function dispatcher.update()
    for channelName, oscChannel in pairs(activeChannels) do
        while true do
            local rawMsg = oscChannel:pop()
            if not rawMsg then break end
            
            local address, value = rawMsg:match("([^ ]+) (.+)")
            if address and value then
                local handler = oscHandlers[address]
                if handler then
                    handler({tonumber(value)})
                else
                    print("No handler for OSC address:", address)
                end
            end
        end
    end
    
    -- Push the latest values to a feedback channel for UDPThread to process
    local feedbackChannel = love.thread.getChannel("oscFeedback")
    feedbackChannel:push(currentValues)
end

return dispatcher