-- connections.lua
--
-- Handler of exchange of UDP / OSC packets from/to different peers
-- Several connections can be managed specifying the list through cfg_connections.lua
-- A dedicated process (UDP_thread) is used to manage the communication for each entry.
--

local Connections = {}
local cfgConnections = require("lib/cfg/cfg_connections")


--- @public init Initialize connections (open UDP threads and req / rsp channels for communicating)
function Connections.init()
  -- initialize list of udp threads and channels (request, response)
  Connections.UdpThreads = {}
  Connections.ReqChannels = {}
  Connections.RspChannels = {}

  -- initialize threads
  for k,v in pairs(cfgConnections.listOfThreads) do
    table.insert(Connections.UdpThreads, love.thread.newThread("lib/UDPThread.lua"))
    Connections.UdpThreads[k]:start(k, v)  -- k used as ID, v contains ip and port
    -- Get request and response channels
    table.insert(Connections.ReqChannels, love.thread.getChannel("reqChannel_" .. k))
    table.insert(Connections.RspChannels, love.thread.getChannel("rspChannel_" .. k))
  end
end


--- @public sendRequests return responses after sending requests to all req channels.
function Connections.sendRequests()
  local responses = {}

  for k,reqCh in pairs(Connections.ReqChannels) do
    reqCh:push(cfgConnections.reqMsg)  -- send request to all channels
  end

  for k,rspCh in pairs(Connections.RspChannels) do
    table.insert(responses, rspCh:demand(cfgConnections.TIMEOUT_TIME))  -- expect response from all channels
    Connections.ReqChannels[k]:push(cfgConnections.ackMsg)  -- send ACK
  end
  return responses
end


return Connections