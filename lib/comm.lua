-- comm.lua
--
-- Several communications can be managed (lists specified in the configuration).
-- A dedicated process (UDP_thread) is used to manage the communication.

Comm = {}
local cfg = require "lib/cfg/connection_cfg"

function Comm.Init()
  -- initialize list of udp threads and channels (request, response)
  Comm.UdpThreads = {}
  Comm.ReqChannels = {}
  Comm.RspChannels = {}

  -- initialize threads
  for k,v in pairs(cfg.listOfThreads) do
    table.insert(Comm.UdpThreads, love.thread.newThread("lib/UDPThread.lua"))
    Comm.UdpThreads[k]:start(k, v)  -- k used as ID, v contains ip and port
    -- Get request and response channels
    table.insert(Comm.ReqChannels, love.thread.getChannel("reqChannel_" + k))
    table.insert(Comm.RspChannels, love.thread.getChannel("rspChannel_" + k))
  end
end


function Comm.SendRequests()
  local responses = {}

  for k,reqCh in pairs(Comm.ReqChannels) do
    love.thread.getChannel(reqCh):push(cfg.reqMsg)  -- send request to all channels
  end

  for k,rspCh in pairs(Comm.RspChannels) do
    table.insert(responses, rspCh:demand(cfg.TIMEOUT_TIME))  -- expect response from all channels
    love.thread.getChannel(Comm.ReqChannels[i]):push(cfg.ackMsg)  -- send ACK
  end

  return responses

end


return Comm