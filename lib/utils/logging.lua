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

local function callerFile(depth)
	local info = debug.getinfo(depth + 1, "S")
	if info and info.short_src then
		return info.short_src:match("[^/\\]*.lua$") or info.short_src
	end
	return "?"
end

--- @public logInfo provide log info, printing also the component name
function logInfo(msg)
	if bit.band(logging.logLevel, logging.LOG_INFO) ~= 0 then
		print("INFO [" .. callerFile(2) .. "] " .. tostring(msg))
	end
end

--- @public logError provide log error, printing also the component name
function logError(msg)
	if bit.band(logging.logLevel, logging.LOG_ERROR) ~= 0 then
		print("ERROR [" .. callerFile(2) .. "] " .. tostring(msg))
	end
end

--- @public logDebug provide log debug, printing also the component name
function logDebug(msg)
	if bit.band(logging.logLevel, logging.LOG_DEBUG) ~= 0 then
		print("DEBUG [" .. callerFile(2) .. "] " .. tostring(msg))
	end
end