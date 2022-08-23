-- resources.lua
--
-- Generate and handle patch resources
--

resources = {}
-- subdivided in three sections:
resources.global = {}  -- shared globally: general option values, post-processing shaders, etc.
resources.graphics = {} -- filepaths or data bound to graphics resources / sprites etc.

local DEFAULT_SIZE = 128

Resource = {}

-- functions
--- @public set setter for resource value by idx
function Resource:setByIdx(idx, v)
    self[idx].value = v
end

--- @public get setter for resource value by idx
function Resource:getByIdx(idx)
    return self[idx].value
end

--- @public setName setter for resource name by idx
function Resource:setName(idx, n)
    self[idx].name = n
end

--- @public getName setter for resource name by idx
function Resource:getName(idx)
    return self[idx].name
end

--- @public getIdxByName Obtain idx of resource based on its name
function Resource:getIdxByName(name)
    for idx=1,#self do
        if self[idx].name == name then return idx end
    end
    return -1
end

--- @public setByName setter for resource value by name
function Resource:set(name, n)
    return self:setByIdx(self:getIdxByName(name), n)
end

--- @public getByName getter for resource value by name
function Resource:get(name)
    return self:getByIdx(self:getIdxByName(name))
end

--- @public New Initializer for a resource object
function Resource:new(o, n)
    o = {} or o
    setmetatable(o, self)
    self.__index = self
    for i=1,n do
        local r = {}
        r.name = "resource" .. i
        r.value = 0
        table.insert(o, r)
    end
    return o
end

--- @public init Initializer for overall resources
function resources.Init()
    -- used as parameters bound to elements in patches
    resources.parameters = Resource:new(nil, DEFAULT_SIZE)
end

--- @public Update Updater for overall resources
function resources.Update(update_msg)
    for k, msg in pairs(update_msg) do
        local destination = msg[1] -- destination (osc)
        local content = msg[2] -- content of packet (osc)
        if true then end -- pass
    end
    return resources
end

return resources