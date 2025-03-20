-- UDPThread.lua
--
-- Implementation of thread handling UDP sockets
local initParams = { ... }
local id = initParams[1]
local ip = initParams[2]["address"]
local ip_port = initParams[2]["port"]

-- include libs
local socket = require "socket"
local dispatcher = require "lib/dispatcher"

local udp = socket.udp()
udp:settimeout(0.001)
assert(udp:setsockname(ip, ip_port))

local channelName = "oscChannel_" .. id
local oscChannel = love.thread.getChannel(channelName)

dispatcher.registerChannel(channelName)  -- Register the channel in the dispatcher

while true do
    local packet, msg_or_ip, port = udp:receivefrom()
    if packet then
        oscChannel:push(packet)  -- Send received data to dispatcher
    end
end

-- Ensure cleanup if the thread is terminated
function love.thread.release(channelName)
    dispatcher.unregisterChannel(channelName)
end
