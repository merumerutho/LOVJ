logging = {}

logging.LOG_ERROR = bit.lshift(1, 1)
logging.LOG_INFO = 	bit.lshift(1, 2)

logging.logLevel = 0

--- @public setLoglevel apply specified level of logging
function logging.setLogLevel(levels)
	logging.logLevel = 0
	for k, l in pairs(levels) do
		logging.logLevel = logging.logLevel + l
	end
end

--- @public logInfo provide log info printing also the component name
function logInfo(msg)
	if bit.band(logging.logLevel, logging.LOG_INFO) then
		filename = debug.getinfo(2)["short_src"]:match("[^/]*.lua")
		print("INFO ["..filename.."] "..msg)
	end
end

--- @public logError provide log error printing also the component name
function logError(msg)
	if bit.band(logging.logLevel, logging.LOG_ERROR) then
		filename = debug.getinfo(3)["short_src"]:match("[^/]*.lua")
		print("ERROR ["..filename.."] "..msg)
	end
end

