-- connections.lua
--
-- Several communications can be managed (lists specified in the configuration).
-- A dedicated process (UDP_thread) is used to manage the communication.

local Connections = {}
local cfg = lovjRequire("lib/cfg/cfg_connections")

function Connections.init()
  -- initialize list of udp threads and channels (request, response)
  Connections.UdpThreads = {}
  Connections.ReqChannels = {}
  Connections.RspChannels = {}

  -- initialize threads
  for k,v in pairs(cfg.listOfThreads) do
    table.insert(Connections.UdpThreads, love.thread.newThread("lib/UDPThread.lua"))
    Connections.UdpThreads[k]:start(k, v)  -- k used as ID, v contains ip and port
    -- Get request and response channels
    table.insert(Connections.ReqChannels, love.thread.getChannel("reqChannel_" .. k))
    table.insert(Connections.RspChannels, love.thread.getChannel("rspChannel_" .. k))
  end
end


function Connections.sendRequests()
  local responses = {}

  for k,reqCh in pairs(Connections.ReqChannels) do
    reqCh:push(cfg.reqMsg)  -- send request to all channels
  end

  for k,rspCh in pairs(Connections.RspChannels) do
    table.insert(responses, rspCh:demand(cfg.TIMEOUT_TIME))  -- expect response from all channels
    rspCh:push(cfg.ackMsg)  -- send ACK
  end

  return responses

end


return Connections