-- machine.lua
--
-- Per-machine configuration profiles.
--
-- A profile is a plain Lua table of DELTAS over the cfg/ modules, keyed by cfg module
-- name (e.g. profile.cfg_screen.WINDOW_WIDTH). The cfg files remain the single source
-- of truth for defaults; a profile only holds what differs on a given machine
-- (resolution, bind addresses, feature gates, ...). See cfg/machines/default.lua for
-- the documented keys and cfg/machines/jetson-nano.lua for a real deployment profile.
--
-- Selection: the LOVJ_MACHINE environment variable names the profile file under
-- cfg/machines/ (without extension). Unset -> "default" (empty overrides, i.e. the
-- behavior is exactly the cfg files' defaults).
--
-- Each participating cfg module opts in with one line:
--     return machine.apply("cfg_x", cfg_x)
-- (or calls apply earlier when derived values must be computed AFTER overrides,
-- as cfg_screen does).
--
-- Loaded with plain require (NOT lovjRequire) on purpose: the profile is boot-time
-- state that must survive lick hot-reloads unchanged and must never be watched.

local machine = {}

machine.profileName = nil
machine.overrides = nil

-- Array-like override tables (e.g. cfg_osc_mapping.connections) REPLACE the target
-- wholesale; map-like tables merge recursively; scalars overwrite.
local function isArray(t)
	return rawget(t, 1) ~= nil
end

local function merge(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" and type(dst[k]) == "table" and not isArray(v) then
			merge(dst[k], v)
		else
			dst[k] = v
		end
	end
end

local function ensureLoaded()
	if machine.overrides then return end
	machine.profileName = os.getenv("LOVJ_MACHINE") or "default"
	machine.overrides = {}
	local path = "cfg/machines/" .. machine.profileName
	if love.filesystem.getInfo(path .. ".lua") then
		local ok, profile = pcall(require, path)
		if ok and type(profile) == "table" then
			machine.overrides = profile
			-- print, not logInfo: cfg modules (and therefore this) can load before logging is up
			print("MACHINE | profile: " .. machine.profileName)
		else
			print("MACHINE | failed to load profile '" .. machine.profileName .. "': " .. tostring(profile))
		end
	elseif machine.profileName ~= "default" then
		print("MACHINE | profile '" .. machine.profileName .. "' not found under cfg/machines/ — using cfg defaults")
	end
end

--- @public apply merge this machine's overrides for one cfg module (mutates in place).
function machine.apply(cfgName, cfg)
	ensureLoaded()
	local o = machine.overrides[cfgName]
	if o then merge(cfg, o) end
	return cfg
end

return machine
