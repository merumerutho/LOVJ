-- NETWORK SETTINGS
local socket = require "socket"
local address, port = "127.0.0.1", 55555

function receivePacket()
	-- Receive packets
	local packet
	local msg_or_ip
	local port
	packet, msg_or_ip, port = udp:receivefrom()
	return packet
end

-- Parse Packet and get content
function parsePacket()
	if packet then
		i = i+1
	end
end

-- Get requests and satisfy them
function parseRequest()
	req = reqChannel:pop()	
	if req == "go" then		-- 
		infoChannel:push(i)
	elseif req == "quit" then	-- Close UDP socket upon request
		udp:close()
		infoChannel:push("clear")
		listen = false
	end
	req = false
end

-- Create channel "info" 
infoChannel = love.thread.getChannel("UDP_SYSTEM_INFO")
reqChannel = love.thread.getChannel("UDP_REQUEST")

-- Setup UDP listener
udp = socket.udp()
udp:settimeout(0.0001)
assert(udp:setsockname(address, port))

listen = true
i=0

-- Listen to UDP
while listen do
	packet = receivePacket()
	-- Parse UDP packets
	parsePacket(packet)
	-- Parse main thread requests
	parseRequest()
end

