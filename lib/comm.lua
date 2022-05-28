-- comm.lua
--
-- Several communications can be managed (lists specified in the configuration).
-- A dedicated process (UDP_thread) is used to manage the communication.

comm = {}
cfg = require "lib/cfg/connection_cfg"

function comm.init()
  -- initialize list of udp threads and channels (request, response)
  comm.UDP_threads = {}
  comm.reqChannels = {}
  comm.rspChannels = {}

  -- initialize threads
  for k,v in pairs(cfg.listOfThreads) do
    table.insert(comm.UDP_threads, love.thread.newThread("lib/UDPThread.lua"))
    comm.UDP_threads[k]:start(k, v)  -- k used as ID, v contains ip and port
    -- Get request and response channels
    table.insert(comm.reqChannels, love.thread.getChannel("reqChannel_" + k))
    table.insert(comm.rspChannels, love.thread.getChannel("rspChannel_" + k))
  end
end


function comm.request()
  local responses = {}

  for k,reqCh in pairs(comm.reqChannels) do
    love.thread.getChannel(reqCh):push(cfg.reqMsg)  -- send request to all channels
  end

  for k,rspCh in pairs(comm.rspChannels) do
    table.insert(responses, rspCh:demand(cfg.TIMEOUT_TIME))  -- expect response from all channels
    love.thread.getChannel(comm.reqChannels[i]):push(cfg.ackMsg)  -- send ACK
  end

  return responses
end


return comm