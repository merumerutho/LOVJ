socket = {}


function socket.init()
	-- EXTERNAL THREAD SETUP --
	socket.UDP_thread = love.thread.newThread("lib/receive.lua")
	socket.UDP_thread:start()
	-- Create channels
	socket.reqChannel = love.thread.getChannel("UDP_REQUEST")
	socket.infoChannel = love.thread.getChannel("UDP_SYSTEM_INFO")
end 


function socket.update()
	-- REQUEST / RESPONSE --
	love.thread.getChannel("UDP_REQUEST"):push("go")
	-- Wait for answer
	info = love.thread.getChannel("UDP_SYSTEM_INFO"):demand()
	return info
end


return socket