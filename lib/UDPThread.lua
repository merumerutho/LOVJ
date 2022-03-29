-- UDPThread.lua
--
-- Implementation of thread handling UDP sockets

local socket = require "socket"
local cfg = require "lib/cfg/sock_cfg"

-- Parse from argument passed by initializer
local udp_cfg = ... 

-- Function to receive incoming packets
function receivePacket()
	-- Receive packets
	local packet
	local msg_or_ip
	local port
	packet, msg_or_ip, port = udp:receivefrom()
	return packet
end

-- Function to parse packets and extract their contents
function parsePacket()
	if packet then
    -- TODO extract content of packets
		packetCount = packetCount+1
	end
end

-- Function to send back info obtained from extracted packets
function parseRequest()
  -- Get request
	req = reqChannel:pop()
  -- If reqMsg
	if req == cfg.reqMsg then		-- 
		infoChannel:push(packetCount)
	elseif req == cfg.quitMsg then	-- Close UDP socket upon request
		udp:close()
		infoChannel:push("clear")
		listen = false
	end
	req = false
end


-- Create channel "info" 
reqChannel = love.thread.getChannel("UDP_REQUEST")
infoChannel = love.thread.getChannel("UDP_SYSTEM_INFO")

-- Setup UDP listener
udp = socket.udp()
udp:settimeout(0.0001)
assert(udp:setsockname(udp_cfg.address, udp_cfg.port))

-- Set listen flag
listen = true
-- Initialize packet count
packetCount=0

-- Listen to UDP
while listen do
  packet = receivePacket()
  -- Parse UDP packets
  parsePacket(packet)
  -- Parse main thread requests
  parseRequest()
end