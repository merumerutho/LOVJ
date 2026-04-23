-- resources.lua
--
-- Generate and handle patch resources
--

local Resource = {}
local ResourceList = {}

local cfg_globals = lovjRequire("cfg/cfg_globals")

local DEFAULT_SIZE = cfg_globals.SETTINGS_MAX_COUNT

--- @public setByIdx setter for the base value by idx.
--- Updates both baseValue and value (they stay in sync until a modulator
--- writes a modulated value). Fires _onChange with the new value.
function Resource:setByIdx(idx, v)
    local entry = self[idx]
    if not entry then return end
    entry.baseValue = v
    if entry.value == v then return end
    entry.value = v
    if self._onChange then self._onChange(entry.name, v) end
end

--- @public setBaseByIdx setter for the base value only.
--- Used by the sequencer so modulators can modulate on top.
function Resource:setBaseByIdx(idx, v)
    local entry = self[idx]
    if not entry then return end
    entry.baseValue = v
end

--- @public setBase setter for base value by name.
function Resource:setBase(name, v)
    return self:setBaseByIdx(self:getIdxByName(name), v)
end

--- @public setModulatedByIdx write only the output value (used by modulators).
--- Does not touch baseValue. Fires _onChange so the GUI sees the live value.
function Resource:setModulatedByIdx(idx, v)
    local entry = self[idx]
    if not entry then return end
    if entry.value == v then return end
    entry.value = v
    if self._onChange then self._onChange(entry.name, v) end
end

--- @public getByIdx getter for the current (possibly modulated) value
function Resource:getByIdx(idx)
    local entry = self[idx]
    if not entry then return nil end
    return entry.value
end

--- @public getBaseByIdx getter for the base (user-set) value
function Resource:getBaseByIdx(idx)
    local entry = self[idx]
    if not entry then return nil end
    return entry.baseValue
end

--- @public resetModulation copy baseValue → value for all entries.
--- Call once per frame before modulators tick so unmodulated params
--- return to their base and modulators start from a clean slate.
function Resource:resetModulation()
    for idx = 1, #self do
        local entry = self[idx]
        if entry.baseValue ~= nil and entry.value ~= entry.baseValue then
            entry.value = entry.baseValue
        end
    end
end

--- @public setName setter for resource name by idx
function Resource:setName(idx, n)
    local entry = self[idx]
    if not entry then return end
    entry.name = n
    self._nameCache = nil
end

--- @public getName getter for resource name by idx
function Resource:getName(idx)
    local entry = self[idx]
    if not entry then return nil end
    return entry.name
end

--- @public setMeta attach metadata (min, max, step, type) to a parameter
function Resource:setMeta(idx, meta)
    local entry = self[idx]
    if not entry then return end
    entry.meta = meta
end

--- @public getMeta retrieve metadata for a parameter
function Resource:getMeta(idx)
    local entry = self[idx]
    if not entry then return nil end
    return entry.meta
end

--- @public getIdxByName Obtain idx of resource based on its name.
--- Uses a lazy cache for O(1) repeat lookups.
function Resource:getIdxByName(name)
    if not self._nameCache then self._nameCache = {} end
    local cached = self._nameCache[name]
    if cached and self[cached] and self[cached].name == name then return cached end
    for idx = 1, #self do
        if self[idx].name == name then
            self._nameCache[name] = idx
            return idx
        end
    end
    return -1
end

--- @public set setter for resource value by name
function Resource:set(name, n)
    return self:setByIdx(self:getIdxByName(name), n)
end

--- @public define declare a parameter with name, value, and optional metadata in one call.
--- meta fields: min, max, step, type ("float", "int", "bool")
function Resource:define(idx, name, value, meta)
    self:setName(idx, name)
    self:setByIdx(idx, value)
    if meta then self:setMeta(idx, meta) end
end

--- @public get getter for resource value by name
function Resource:get(name)
    return self:getByIdx(self:getIdxByName(name))
end

--- @public New Initializer for a resource object
Resource.__index = Resource

function Resource:new(o, n)
    local o = o or {}
    setmetatable(o, Resource)
    for i=1,n do
        local r = {}
        r.name = "resource" .. i
        r.value = 0
        r.baseValue = 0
        table.insert(o, r)
    end
    return o
end


ResourceList.__index = ResourceList

function ResourceList:new(global, shader)
    local res_list = {}
    setmetatable(res_list, ResourceList)

    -- used as parameters bound to elements in patches
    res_list.parameters = Resource:new(nil, DEFAULT_SIZE)
    -- filepaths or data bound to graphics resources / sprites etc.
    res_list.graphics = Resource:new(nil, DEFAULT_SIZE)

    -- these must be pre-initialized (and reside elsewhere)
    res_list.globals = global
    res_list.shaderext = shader
    return res_list
end


--- wrapper for Resource:new()
function ResourceList:newResource()
    return Resource:new(nil, DEFAULT_SIZE)
end


return ResourceList
