-- savemgr.lua
--
-- Handle real-time management of patches
-- i.e. loading patches, loading / saving parameter status
--

local json = lovjRequire("lib/json/json")
local Modulator = lovjRequire("lib/modulator")
local Easing = lovjRequire("lib/signals/easing")

local saveMgr = {}

saveMgr.savestatePath = "savestates/"
saveMgr.morphs = {}
saveMgr.morphEnabled = true
saveMgr.defaultMorphTime = 500
saveMgr.defaultMorphEasing = "sineInOut"

local function serializeResource(res)
    local out = {}
    for idx = 1, #res do
        local entry = res[idx]
        out[idx] = { name = entry.name, value = entry.baseValue ~= nil and entry.baseValue or entry.value }
    end
    return out
end

local function loadResourceByName(res, data)
    for _, t in pairs(data) do
        if type(t) == "table" and t.name and t.value ~= nil then
            local idx = res:getIdxByName(t.name)
            if idx > 0 then
                res:setByIdx(idx, t.value)
            end
        end
    end
end

local function morphResourceByName(res, data, duration, easingFn)
    local now = love.timer.getTime()
    for _, t in pairs(data) do
        if type(t) == "table" and t.name and t.value ~= nil and type(t.value) == "number" then
            local idx = res:getIdxByName(t.name)
            if idx > 0 then
                local fromVal = res:getByIdx(idx)
                local isDiscrete = t.name:match("^shaderSlot")
                if not isDiscrete and type(fromVal) == "number" and fromVal ~= t.value then
                    table.insert(saveMgr.morphs, {
                        res       = res,
                        idx       = idx,
                        fromVal   = fromVal,
                        toVal     = t.value,
                        startTime = now,
                        duration  = duration,
                        easingFn  = easingFn,
                    })
                else
                    res:setByIdx(idx, t.value)
                end
            end
        end
    end
end

function saveMgr.tick()
    if #saveMgr.morphs == 0 then return end
    local now = love.timer.getTime()
    local alive = {}
    for _, m in ipairs(saveMgr.morphs) do
        local elapsed = now - m.startTime
        local t = elapsed / m.duration
        if t >= 1 then
            m.res:setBaseByIdx(m.idx, m.toVal)
        else
            local shaped = m.easingFn(t)
            m.res:setBaseByIdx(m.idx, m.fromVal + (m.toVal - m.fromVal) * shaped)
            table.insert(alive, m)
        end
    end
    saveMgr.morphs = alive
end

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
	patchSlots[slot].patch = lovjRequire(patchName, lick.REBUILD)
	patchSlots[slot].patch.init(slot, globalSettings, patchSlots[slot].shaderext)
	-- Re-bind this slot to lick so subsequent edits to the new patch file
	-- trigger a rebuild targeting this slot.
	if bindPatchSlot then bindPatchSlot(slot) end
	-- for debugging
	--print("global settings: " .. tostring(globalSettings))
	--print("shaderext: " .. tostring(patchSlots[slot].shaderext))
	--print("parameters: " .. tostring(patchSlots[slot].patch.resources.parameters))
end


--- @public saveMgr.saveResources save current resources status as a JSON savestate
function saveMgr.saveResources(filename, idx, slot)
	local data = {}
	data.globals = serializeResource(globalSettings)
	data.patchName = patchSlots[slot].name
	data.parameters = serializeResource(patchSlots[slot].patch.resources.parameters)
	data.graphics = serializeResource(patchSlots[slot].patch.resources.graphics)
	data.shaderext = serializeResource(patchSlots[slot].shaderext)
	data.modulators = Modulator.getAll()
	local jsonEncoded = json.encode(data)

	-- Assemble filepath
	local filepath = (saveMgr.savestatePath .. (filename .. "_slot" .. tostring(idx) ..".json"):gsub(".*/", ""))
	logInfo("Saving " .. filepath)
	local f = assert(io.open(filepath, "w"))
	f:write(jsonEncoded)
	f:close()
end


--- @public saveMgr.loadResources load JSON savestate onto resources.
--- opts: { morphTime = ms, morphEasing = "name" } for smooth transitions.
function saveMgr.loadResources(filename, idx, slot, opts)
	local filepath = (saveMgr.savestatePath .. (filename .. "_slot" .. tostring(idx) ..".json"):gsub(".*/", ""))
	local f = io.open(filepath, "r")
	if (f == nil) then logError("Couldn't open " .. filepath) return end
	local jsonEncoded = f:read("a")
	f:close()

	local data = json.decode(jsonEncoded)

	opts = opts or {}
	local enabled = saveMgr.morphEnabled and (opts.morphTime == nil or opts.morphTime > 0)
	local morphTime = enabled and (opts.morphTime or saveMgr.defaultMorphTime) / 1000 or 0
	local easingFn = Easing.byName(opts.morphEasing or saveMgr.defaultMorphEasing)
	local samePatch = patchSlots[slot].name == data.patchName
	local doMorph = morphTime > 0

	if not samePatch then
		logError("Cannot load " .. filepath .. " savestate to patch " .. tostring(patchSlots[slot].name))
		-- Still morph shader params even if patch doesn't match
		if data.shaderext and doMorph then
			morphResourceByName(patchSlots[slot].shaderext, data.shaderext, morphTime, easingFn)
		elseif data.shaderext then
			loadResourceByName(patchSlots[slot].shaderext, data.shaderext)
		end
		if data.modulators then
			Modulator.restoreAll(data.modulators)
		end
		return
	end

	-- Same patch: morph both patch params and shader params
	if data.parameters then
		if doMorph then
			morphResourceByName(patchSlots[slot].patch.resources.parameters, data.parameters, morphTime, easingFn)
		else
			loadResourceByName(patchSlots[slot].patch.resources.parameters, data.parameters)
		end
	end
	if data.globals then
		loadResourceByName(globalSettings, data.globals)
	end
	if data.graphics then
		loadResourceByName(patchSlots[slot].patch.resources.graphics, data.graphics)
	end
	if data.shaderext then
		if doMorph then
			morphResourceByName(patchSlots[slot].shaderext, data.shaderext, morphTime, easingFn)
		else
			loadResourceByName(patchSlots[slot].shaderext, data.shaderext)
		end
	end
	if data.modulators then
		Modulator.restoreAll(data.modulators)
	end
	logInfo("Loaded " .. filepath .. " savestate (morph " .. (morphTime * 1000) .. "ms)")
end

--- Load a savestate file into a raw data table (no side effects).
function saveMgr.loadSceneData(filename, idx)
	local filepath = saveMgr.savestatePath .. (filename .. "_slot" .. tostring(idx) .. ".json"):gsub(".*/", "")
	local f = io.open(filepath, "r")
	if not f then logError("Scene file not found: " .. filepath); return nil end
	local raw = f:read("a")
	f:close()
	local ok, data = pcall(json.decode, raw)
	if not ok then logError("Scene JSON error: " .. filepath); return nil end
	return data
end


--- Snapshot the live state of a slot into a data table.
function saveMgr.captureSlot(slot)
	if not patchSlots or not patchSlots[slot] then return nil end
	local patch = patchSlots[slot].patch
	if not patch then return nil end

	local data = {}
	data.patchName  = patchSlots[slot].name
	data.parameters = serializeResource(patch.resources.parameters)
	data.shaderext  = serializeResource(patchSlots[slot].shaderext)
	data.modulators = Modulator.getAll()
	return data
end


--- Apply a cached scene data table to a slot (parameters + shaderext +
--- modulators).  No disk I/O — this is the fast path for the scene
--- sequencer.
function saveMgr.applyScene(data, slot)
	if not data or not patchSlots or not patchSlots[slot] then return end
	local patch = patchSlots[slot].patch
	if not patch then return end

	if data.patchName and patchSlots[slot].name ~= data.patchName then
		logError("Scene patch mismatch: expected " .. patchSlots[slot].name .. ", got " .. data.patchName)
		return
	end

	if data.parameters then
		loadResourceByName(patch.resources.parameters, data.parameters)
	end

	if data.shaderext then
		loadResourceByName(patchSlots[slot].shaderext, data.shaderext)
	end

	if data.modulators then
		Modulator.restoreAll(data.modulators)
	end
end


return saveMgr