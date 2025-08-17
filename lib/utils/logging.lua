-- logging.lua
--
-- Handler for log messages
--

logging = {}

logging.LOG_ERROR = bit.lshift(1, 1)
logging.LOG_INFO = 	bit.lshift(1, 2)
logging.LOG_DEBUG = bit.lshift(1, 3)

logging.logLevel = 0

--- @public setLoglevel apply specified level of logging
function logging.setLogLevel(levels)
	logging.logLevel = 0
	for k, l in pairs(levels) do
		logging.logLevel = logging.logLevel + l
	end
end

--- @public logInfo provide log info, printing also the component name
function logInfo(msg)
	if bit.band(logging.logLevel, logging.LOG_INFO) then
		local filename = debug.getinfo(2)["short_src"]:match("[^/]*.lua")
		-- filename = "" or filename
		print("INFO ["..filename.."] "..tostring(msg))
	end
end

--- @public logError provide log error, printing also the component name
function logError(msg)
	if bit.band(logging.logLevel, logging.LOG_ERROR) then
		local filename = debug.getinfo(3)["short_src"]:match("[^/]*.lua")
		-- filename = "" or filename
		print("ERROR ["..filename.."] "..msg)
	end
end

--- @public logDebug provide log debug, printing also the component name
function logDebug(msg)
	if bit.band(logging.logLevel, logging.LOG_DEBUG) then
		local filename = debug.getinfo(3)["short_src"]:match("[^/]*.lua")
		-- filename = "" or filename
		print("DEBUG ["..filename.."] "..msg)
	end
end