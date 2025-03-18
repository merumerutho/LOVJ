-- cfg_connections.lua
--
-- Configure and handle list of connections to open and maintain
--

local cfg_connections = {}

cfg_connections.TIMEOUT_TIME = 1000  -- [ms]

-- List of request channels to open
cfg_connections.listOfThreads = {
                        {   -- UDP connection 1
                            ["address"] = "127.0.0.1",
                            ["port"] = 55555
                        }
}

return cfg_connections