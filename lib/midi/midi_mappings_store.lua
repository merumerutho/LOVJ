local json = lovjRequire("lib/json/json")
local staticConfig = lovjRequire("cfg/cfg_midi_mapping")

local MappingStore = {}

local SAVE_PATH = "savestates/midi_mappings.json"

local mappings = {}
local nextUserId = 1

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = deepCopy(v)
    end
    return copy
end

local function makeCCId(key)
    return "cc_" .. tostring(key)
end

local function makeNoteId(key)
    return "note_" .. tostring(key)
end

local function makeProgId(key)
    return "prog_" .. tostring(key)
end

local function importStatic()
    for key, mapping in pairs(staticConfig.ccMappings) do
        local id = makeCCId(key)
        mappings[id] = deepCopy(mapping)
        mappings[id].id = id
        mappings[id].midiType = "cc"
        mappings[id].midiKey = key
        mappings[id].source = "static"
    end
    for key, mapping in pairs(staticConfig.noteMappings) do
        local id = makeNoteId(key)
        mappings[id] = deepCopy(mapping)
        mappings[id].id = id
        mappings[id].midiType = "note"
        mappings[id].midiKey = key
        mappings[id].source = "static"
    end
    for key, mapping in pairs(staticConfig.programMappings) do
        local id = makeProgId(key)
        mappings[id] = deepCopy(mapping)
        mappings[id].id = id
        mappings[id].midiType = "program"
        mappings[id].midiKey = key
        mappings[id].source = "static"
    end
end

function MappingStore.init()
    mappings = {}
    nextUserId = 1
    importStatic()
    MappingStore.load()
    logInfo("MappingStore: Initialized with " .. table.count(mappings) .. " mappings")
end

function MappingStore.getAll()
    local list = {}
    for _, m in pairs(mappings) do
        table.insert(list, m)
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

function MappingStore.get(id)
    return mappings[id]
end

function MappingStore.lookupCC(key)
    return mappings[makeCCId(key)]
end

function MappingStore.lookupNote(key)
    return mappings[makeNoteId(key)]
end

function MappingStore.lookupProgram(key)
    return mappings[makeProgId(key)]
end

function MappingStore.add(mapping)
    local id = "user_" .. nextUserId
    nextUserId = nextUserId + 1

    local entry = deepCopy(mapping)
    entry.id = id
    entry.source = "learned"

    local midiType = entry.midiType
    local midiKey = entry.midiKey

    if midiType == "cc" then
        local staticId = makeCCId(midiKey)
        if mappings[staticId] then
            mappings[staticId] = nil
        end
    elseif midiType == "note" then
        local staticId = makeNoteId(midiKey)
        if mappings[staticId] then
            mappings[staticId] = nil
        end
    elseif midiType == "program" then
        local staticId = makeProgId(midiKey)
        if mappings[staticId] then
            mappings[staticId] = nil
        end
    end

    mappings[id] = entry
    return id
end

function MappingStore.remove(id)
    if mappings[id] then
        mappings[id] = nil
        return true
    end
    return false
end

function MappingStore.update(id, changes)
    local m = mappings[id]
    if not m then return false end
    for k, v in pairs(changes) do
        m[k] = v
    end
    return true
end

function MappingStore.save()
    local learned = {}
    for _, m in pairs(mappings) do
        if m.source == "learned" then
            local entry = deepCopy(m)
            entry.transform = nil
            if m.transform then
                entry.transformNames = m.transform
            end
            table.insert(learned, entry)
        end
    end
    local encoded = json.encode(learned)
    local f = io.open(SAVE_PATH, "w")
    if f then
        f:write(encoded)
        f:close()
        logInfo("MappingStore: Saved " .. #learned .. " learned mappings")
    end
end

function MappingStore.load()
    local f = io.open(SAVE_PATH, "r")
    if not f then return end
    local content = f:read("*a")
    f:close()
    local ok, data = pcall(json.decode, content)
    if not ok or type(data) ~= "table" then return end

    for _, entry in ipairs(data) do
        if entry.transformNames then
            entry.transform = entry.transformNames
            entry.transformNames = nil
        end
        entry.source = "learned"
        local id = entry.id or ("user_" .. nextUserId)
        entry.id = id
        mappings[id] = entry

        local num = tonumber(id:match("^user_(%d+)$"))
        if num and num >= nextUserId then
            nextUserId = num + 1
        end
    end
end

function MappingStore.getTransformations()
    return staticConfig.transformations
end

function MappingStore.getConnections()
    return staticConfig.connections
end

return MappingStore
