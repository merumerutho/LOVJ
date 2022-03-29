cfg = {}

-- List of request channels to open
cfg.reqChannels = { "UDP_REQUEST" }

-- list of response channels to open
cfg.rspChannels = { "UDP_SYSTEM_INFO" }

-- string sent as a request notifier, in request channels
cfg.reqMsg = "go"

-- string sent as a closure notifier, in request channels
cfg.quitMsg = "quit"

return cfg