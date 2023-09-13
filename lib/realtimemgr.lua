-- realtimemgr.lua
--
-- Handle real-time management of patches
-- i.e. loading patches, loading / saving parameter status
--

json = require("lib/json")
resources = lovjRequire("lib/resources")

local rtMgr = {}

-- TODO: move this to cfg_rtmgr
rtMgr.savestatePath = "savestates/"

--- @public controls.loadPatch remove previous patch, load and init a new patch based on its relative path
function rtMgr.loadPatch(patchName, slot)
	lovjUnrequire(runningPatches[slot].name)
	runningPatches[slot].name = patchName
	runningPatches[slot].patch = lovjRequire(patchName, lick.PATCH_RESET)
	runningPatches[slot].patch.init(runningPatches[slot].resources)
end


--- @public rtMgr.saveResources save current resources status as a JSON savestate
function rtMgr.saveResources(filename, idx, slot)
	local data = {}
	data.patchName = runningPatches[slot].name
	data.parameters = runningPatches[slot].resources.parameters
	data.globals = runningPatches[slot].resources.globals
	data.graphics = runningPatches[slot].resources.graphics
	data.shaderext = runningPatches[slot].resources.shaderext
	local jsonEncoded = json.encode(data)

	-- Assemble filepath
	local filepath = (rtMgr.savestatePath .. (filename .. "_slot" .. tostring(idx) ..".json"):gsub(".*/", ""))
	logInfo("Saving " .. filepath)
	local f = assert(io.open(filepath, "w"))
	f:write(jsonEncoded)
	f:close()
end


--- @public rtMgr.loadResources load JSON savestate onto resources
function rtMgr.loadResources(filename, idx, slot)
	local filepath = (rtMgr.savestatePath .. (filename .. "_slot" .. tostring(idx) ..".json"):gsub(".*/", ""))
	local f = io.open(filepath, "r")
	if f == nil then logError("Couldn't open " .. filepath) return end
	local jsonEncoded = f:read("a")
	f:close()

	local data = json.decode(jsonEncoded)
	-- If the name of the patch is correct, load data
	if runningPatches[slot].name == data.patchName then
		-- Load parameters resources
		for k,t in pairs(data.parameters) do
			runningPatches[slot].resources.parameters:setName(k, t.name)
			runningPatches[slot].resources.parameters:setByIdx(k, t.value)
		end
		-- Load globals resources
		for k,t in pairs(data.globals) do
			runningPatches[slot].resources.globals:setName(k, t.name)
			runningPatches[slot].resources.globals:setByIdx(k, t.value)
		end
		-- Load graphics resources
		for k,t in pairs(data.graphics) do
			runningPatches[slot].resources.graphics:setName(k, t.name)
			runningPatches[slot].resources.graphics:setByIdx(k, t.value)
		end
		-- Load shader resources
		for k,t in pairs(data.shaderext) do
			runningPatches[slot].resources.shaderext:setName(k, t.name)
			runningPatches[slot].resources.shaderext:setByIdx(k, t.value)
		end
		logInfo("Loaded " .. filepath .. " savestate.")
	else
		logError("Cannot load " .. filepath .. " savestate to patch " .. runningPatches[slot])
	end
end

return rtMgr