-- savemgr.lua
--
-- Handle real-time management of patches
-- i.e. loading patches, loading / saving parameter status
--

local json = lovjRequire("lib/json/json")

local saveMgr = {}

-- TODO: move this to cfg_saveMgr
saveMgr.savestatePath = "savestates/"

--- @public controls.loadPatch remove previous patch, load and init a new patch based on its relative path
function saveMgr.loadPatch(patchName, slot)
	-- Search if patch already loaded somewhere else
	local unrequire = true
	for i = 1, #patchSlots do
		if (i ~= slot) and (patchName == patchSlots[i].name) then
			unrequire = false
		end
	end
	-- If that is the case, don't unrequire the patch
	if (unrequire) then
		lovjUnrequire(patchSlots[slot].name)
	end
	patchSlots[slot].name = patchName
	patchSlots[slot].patch = lovjRequire(patchName, lick.PATCH_RESET)
	patchSlots[slot].patch.init(slot, globalSettings, patchSlots[slot].shaderext)
	-- for debugging
	--print("global settings: " .. tostring(globalSettings))
	--print("shaderext: " .. tostring(patchSlots[slot].shaderext))
	--print("parameters: " .. tostring(patchSlots[slot].patch.resources.parameters))
end


--- @public saveMgr.saveResources save current resources status as a JSON savestate
function saveMgr.saveResources(filename, idx, slot)
	local data = {}
	data.patchName = patchSlots[slot].name
	data.parameters = patchSlots[slot].patch.resources.parameters
	data.globals = patchSlots[slot].patch.resources.globals
	data.graphics = patchSlots[slot].patch.resources.graphics
	data.shaderext = patchSlots[slot].patch.resources.shaderext
	local jsonEncoded = json.encode(data)

	-- Assemble filepath
	local filepath = (saveMgr.savestatePath .. (filename .. "_slot" .. tostring(idx) ..".json"):gsub(".*/", ""))
	logInfo("Saving " .. filepath)
	local f = assert(io.open(filepath, "w"))
	f:write(jsonEncoded)
	f:close()
end


--- @public saveMgr.loadResources load JSON savestate onto resources
function saveMgr.loadResources(filename, idx, slot)
	local filepath = (saveMgr.savestatePath .. (filename .. "_slot" .. tostring(idx) ..".json"):gsub(".*/", ""))
	local f = io.open(filepath, "r")
	if (f == nil) then logError("Couldn't open " .. filepath) return end
	local jsonEncoded = f:read("a")
	f:close()

	local data = json.decode(jsonEncoded)
	-- If the name of the patch is correct, load data
	if patchSlots[slot].name == data.patchName then
		-- Load parameters resources
		for k,t in pairs(data.parameters) do
			patchSlots[slot].patch.resources.parameters:setName(k, t.name)
			patchSlots[slot].patch.resources.parameters:setByIdx(k, t.value)
		end
		-- Load globals resources
		for k,t in pairs(data.globals) do
			patchSlots[slot].patch.resources.globals:setName(k, t.name)
			patchSlots[slot].patch.resources.globals:setByIdx(k, t.value)
		end
		-- Load graphics resources
		for k,t in pairs(data.graphics) do
			patchSlots[slot].patch.resources.graphics:setName(k, t.name)
			patchSlots[slot].patch.resources.graphics:setByIdx(k, t.value)
		end
		-- Load shader resources
		for k,t in pairs(data.shaderext) do
			patchSlots[slot].patch.resources.shaderext:setName(k, t.name)
			patchSlots[slot].patch.resources.shaderext:setByIdx(k, t.value)
		end
		logInfo("Loaded " .. filepath .. " savestate.")
	else
		logError("Cannot load " .. filepath .. " savestate to patch " .. patchSlots[slot])
	end
end

return saveMgr