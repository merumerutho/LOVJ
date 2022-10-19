-- realtimemgr.lua
--
-- Handle real-time management of patches
-- i.e. loading patches, loading / saving parameter status
--

json = require("lib/json")
resources = lovjRequire("lib/resources")

local rtMgr = {}

rtMgr.savestatePath = "savestates/"

--- @public controls.loadPatch remove previous patch, load and init a new patch based on its relative path
function rtMgr.loadPatch(patchName)
	lovjUnrequire(currentPatchName)
	currentPatchName = patchName
	patch = lovjRequire(currentPatchName, lick.PATCH_RESET)
	patch.init()
end


--- @public rtMgr.saveResources save current resources status as a JSON savestate
function rtMgr.saveResources(filename, idx)
	local data = {}
	data.patchName = currentPatchName
	data.parameters = resources.parameters
	data.globals = resources.globals
	data.graphics = resources.graphics
	local jsonEncoded = json.encode(data)

	-- Assemble filepath
	local filepath = (rtMgr.savestatePath .. (filename .. "_slot" .. tostring(idx) ..".json"):gsub(".*/", ""))
	logInfo("Saving " .. filepath)
	local f = assert(io.open(filepath, "w"))
	f:write(jsonEncoded)
	f:close()
end


--- @public rtMgr.loadResources load JSON savestate onto resources
function rtMgr.loadResources(filename, idx)
	local filepath = (rtMgr.savestatePath .. (filename .. "_slot" .. tostring(idx) ..".json"):gsub(".*/", ""))
	local f = io.open(filepath, "r")
	if f == nil then logError("Couldn't open " .. filepath) return end
	local jsonEncoded = f:read("a")
	f:close()

	local data = json.decode(jsonEncoded)
	-- If the name of the patch is correct, load data
	if currentPatchName == data.patchName then
		-- Load parameters resources
		for k,t in pairs(data.parameters) do
			resources.parameters:setName(k, t.name)
			resources.parameters:setByIdx(k, t.value)
		end
		-- Load globals resources
		for k,t in pairs(data.globals) do
			resources.globals:setName(k, t.name)
			resources.globals:setByIdx(k, t.value)
		end
		-- Load graphics resources
		for k,t in pairs(data.graphics) do
			resources.graphics:setName(k, t.name)
			resources.graphics:setByIdx(k, t.value)
		end
		logInfo("Loaded " .. filepath .. " savestate.")
	else
		logError("Cannot load " .. filepath .. " savestate to patch " .. currentPatchName)
	end
end

return rtMgr