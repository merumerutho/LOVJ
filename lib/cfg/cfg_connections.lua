local cfg_connections = {}

cfg_connections.TIMEOUT_TIME = 1000  -- [ms]

-- List of request channels to open
cfg_connections.listOfThreads = {
                        {   -- UDP connection 1
                            ["address"] = "127.0.0.1",
                            ["port"] = 55555
                        }
}

-- string sent as a request notifier, in request channels
cfg_connections.reqMsg = "RQST"

-- string sent as an acknowledgement, in response channels
cfg_connections.ackMsg = "ACK"

-- string sent as a closure notifier, in request channels
cfg_connections.quitMsg = "QUIT"

-- string sent as a acknowledge to closer notifier, in response channels
cfg_connections.ackQuit = "CLEAR"

return cfg_connections