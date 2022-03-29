-- socket.lua
--
-- Communication is handled through UDP sockets.
-- Several sockets can be managed (lists specified in the configuration).
-- A dedicated process (UDP_thread) is used to manage the communication.

socket = {}
cfg = require "lib/cfg/sock_cfg"

function socket.init()
  -- UDP thread set-up
	socket.UDP_thread = love.thread.newThread("lib/UDPThread.lua")
  
  local test = {}
  test.address= "127.0.0.1"
  test.port = 55555
  
	socket.UDP_thread:start(test)
  	
  -- Get list of request channels
  socket.reqChannels = {}
  for i=1,#(cfg.reqChannels) do
    table.insert(socket.reqChannels, love.thread.getChannel(cfg.reqChannels[i]))
  end
  -- Get list of response channels
  socket.rspChannels = {}
  for i=1,#(cfg.rspChannels) do
    table.insert(socket.rspChannels, love.thread.getChannel(cfg.rspChannels[i]))
  end
end 


function socket.update()
  responses = {}
  -- Send request to all request channels
  for i=1,#(cfg.reqChannels) do
    love.thread.getChannel(cfg.reqChannels[i]):push(cfg.reqMsg)
  end
  -- Expect answer from all response channels
  for i=1,#(cfg.rspChannels) do
    table.insert(responses, love.thread.getChannel(cfg.rspChannels[i]):demand())
  end
	return responses
end

return socket