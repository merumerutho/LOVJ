cfg = {}

cfg.TIMEOUT_TIME = 1000  -- [ms]

-- List of request channels to open
cfg.listOfThreads = {
                        {   -- UDP connection 1
                            ["address"] = "127.0.0.1",
                            ["port"] = 69420
                        }
}

-- string sent as a request notifier, in request channels
cfg.reqMsg = "RQST"

-- string sent as an acknowledgement, in request channels
cfg.ackMsg = "ACK"

-- string sent as a closure notifier, in request channels
cfg.quitMsg = "QUIT"

return cfg