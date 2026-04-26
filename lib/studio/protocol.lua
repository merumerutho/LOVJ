-- protocol.lua
--
-- JSON message protocol between the studio web app and LOVJ.
--
-- Message shape: every message is a JSON object with a `type` field and an
-- optional `id` for request/response correlation. M1 handles:
--
--   Client -> LOVJ:
--     {type:"hello",     id}
--     {type:"listSlots", id}
--     {type:"getSchema", id, slot}
--     {type:"setParam",  id?, slot, name, value}
--
--   LOVJ -> client:
--     {type:"welcome",      id, version, slots, selectedSlot}
--     {type:"slots",        id, slots:[{index,name}], selected}
--     {type:"schema",       id, slot, patchName, params:[{name,type,value,paramId}]}
--     {type:"paramChanged", slot, name, value}    (broadcast)
--     {type:"error",        id?, message}
--
-- A `paramChanged` broadcast is emitted whenever a parameter changes
-- through the command system (GUI, MIDI, OSC). Direct `p:set(...)` calls
-- inside patch code bypass this for M1 — the GUI can re-request the
-- schema to pick those up.
--

local json = lovjRequire("lib/json/json")
local studioBridge = lovjRequire("lib/studio/bridge")
local CommandSystem = lovjRequire("lib/command_system")
local cfg_patches = lovjRequire("cfg/cfg_patches")
local cfgShaders = lovjRequire("cfg/cfg_shaders")
local saveMgr = lovjRequire("lib/savemgr")
local MappingStore = lovjRequire("lib/midi/midi_mappings_store")
local MidiLearn = lovjRequire("lib/midi/midi_learn")
local MIDIDispatcher = lovjRequire("lib/midi/midi_dispatcher")

local protocol = {}


local function send(t)
    studioBridge.broadcast(json.encode(t))
end


-- `Resource:new()` fills each slot with a default name "resourceN". Treat
-- those as unused.
local function isRealName(name)
    return name and not name:match("^resource%d+$")
end


-- Enumerate named parameters for a given patch slot.
local function buildSchema(slot)
    local s = patchSlots and patchSlots[slot]
    if not s or not s.patch or not s.patch.resources then return nil end

    -- Lazy-require to avoid circular init issues.
    local Modulator = require("lib/modulator")
    local modSet = Modulator.getModulatedSet()

    local params = {}
    local p = s.patch.resources.parameters
    for idx = 1, #p do
        local name = p:getName(idx)
        if isRealName(name) then
            local value = p:getBaseByIdx(idx) or p:getByIdx(idx)
            local meta = p:getMeta(idx)
            local paramType = (type(value) == "number") and "float" or type(value)
            local entry = {
                name      = name,
                type      = meta and meta.type or paramType,
                value     = value,
                paramId   = idx,
                modulated = modSet["parameters:" .. slot .. ":" .. name] or false,
            }
            if meta then
                if meta.min then entry.min = meta.min end
                if meta.max then entry.max = meta.max end
                if meta.step then entry.step = meta.step end
            end
            table.insert(params, entry)
        end
    end

    return {
        slot      = slot,
        patchName = s.name,
        params    = params,
    }
end


local function handleHello(msg)
    local cfg_bpm = require("cfg/cfg_bpm")
    send({
        type         = "welcome",
        id           = msg.id,
        version      = version or "unknown",
        slots        = patchSlots and #patchSlots or 0,
        selectedSlot = cfg_patches.selectedPatch,
        defaultBpm   = cfg_bpm.default_bpm,
        bpm          = clock and clock.bpm or cfg_bpm.default_bpm,
    })
end


local function handleListSlots(msg)
    local slots = {}
    if patchSlots then
        for i, s in ipairs(patchSlots) do
            table.insert(slots, { index = i, name = s.name })
        end
    end
    send({
        type     = "slots",
        id       = msg.id,
        slots    = slots,
        selected = cfg_patches.selectedPatch,
    })
end


local function handleGetSchema(msg)
    local slot = tonumber(msg.slot)
    if not slot then
        send({ type = "error", id = msg.id, message = "getSchema requires 'slot' (int)" })
        return
    end
    local schema = buildSchema(slot)
    if not schema then
        send({ type = "error", id = msg.id, message = "no patch in slot " .. slot })
        return
    end
    schema.type = "schema"
    schema.id   = msg.id
    send(schema)
end


local function handleSetParam(msg)
    local slot  = tonumber(msg.slot)
    local name  = msg.name
    local value = msg.value
    if not (slot and name and value ~= nil) then
        send({ type = "error", id = msg.id, message = "setParam requires slot, name, value" })
        return
    end
    -- Queue via the existing command pipeline. The command's execute body
    -- will emit notifyParamChanged on success so the GUI (and any other
    -- connected clients) see the echo.
    local ok = CommandSystem.queueCommand("setPatchParameterByName", { slot, name, value })
    if not ok then
        send({ type = "error", id = msg.id, message = "setParam queueing failed" })
    end
end


-- ---- Modulator messages ----

local Modulator = lovjRequire("lib/modulator")
local Easing = lovjRequire("lib/signals/easing")


local function broadcastModulatorList()
    send({
        type              = "modulatorList",
        modulators        = Modulator.getAll(),
        shapes            = Modulator.LFO_SHAPES,
        easingNames       = Easing.names,
        typeDefaults      = Modulator.typeDefaults,
        typeConstraints   = Modulator.typeConstraints,
    })
end


local function handleListModulators(msg)
    send({
        type              = "modulatorList",
        id                = msg.id,
        modulators        = Modulator.getAll(),
        shapes            = Modulator.LFO_SHAPES,
        easingNames       = Easing.names,
        typeDefaults      = Modulator.typeDefaults,
        typeConstraints   = Modulator.typeConstraints,
    })
end


local function handleCreateModulator(msg)
    local id, err = Modulator.create(msg.config)
    if not id then
        send({ type = "error", id = msg.id, message = "createModulator: " .. tostring(err) })
        return
    end
    send({ type = "modulatorCreated", id = msg.id, modulatorId = id })
    broadcastModulatorList()
end


local function handleUpdateModulator(msg)
    local mid = tonumber(msg.modulatorId)
    if not mid then
        send({ type = "error", id = msg.id, message = "updateModulator requires modulatorId" })
        return
    end
    local ok, err = Modulator.update(mid, msg.changes or {})
    if not ok then
        send({ type = "error", id = msg.id, message = "updateModulator: " .. tostring(err) })
        return
    end
    broadcastModulatorList()
end


local function handleDeleteModulator(msg)
    local mid = tonumber(msg.modulatorId)
    if not mid then
        send({ type = "error", id = msg.id, message = "deleteModulator requires modulatorId" })
        return
    end
    Modulator.delete(mid)
    broadcastModulatorList()
end


-- ---- Sequencer messages ----

local TempoDivisions = require("lib/tempo_divisions")

local function seqSnapshot()
    if not globalSequencer then return {} end
    local state = globalSequencer:getState()
    state.bpm = clock and clock.bpm or 128
    state.tempoDivisions = TempoDivisions.list
    return state
end

local function broadcastSequencer()
    local snap = seqSnapshot()
    snap.type = "sequencerState"
    send(snap)
end

local function handleGetSequencer(msg)
    local snap = seqSnapshot()
    snap.type = "sequencerState"
    snap.id = msg.id
    send(snap)
end

local function handleSequencerPlay(msg)
    if globalSequencer then globalSequencer:play() end
    broadcastSequencer()
end

local function handleSequencerStop(msg)
    if globalSequencer then globalSequencer:stop() end
    broadcastSequencer()
end

local function handleSequencerResetPhase(msg)
    if clock then clock.resetPhase() end
    if globalSequencer then globalSequencer:realign() end
    broadcastSequencer()
end

local function handleSequencerAddChannel(msg)
    if not globalSequencer or not msg.name or not msg.target then
        send({ type = "error", id = msg.id, message = "addChannel needs name + target" })
        return
    end
    -- target can include steps and divider for this channel
    msg.target.steps = tonumber(msg.target.steps) or 16
    msg.target.divider = tonumber(msg.target.divider) or 4
    globalSequencer:channel(msg.name, msg.target)
    broadcastSequencer()
end

local function handleSequencerRemoveChannel(msg)
    if globalSequencer and msg.name then
        globalSequencer:removeChannel(msg.name)
    end
    broadcastSequencer()
end

local function handleSequencerUpdateChannel(msg)
    if not globalSequencer or not msg.name then
        send({ type = "error", id = msg.id, message = "updateChannel needs name" })
        return
    end
    if msg.steps then
        globalSequencer:setChannelSteps(msg.name, math.floor(tonumber(msg.steps)))
    end
    if msg.divider then
        globalSequencer:setChannelDivider(msg.name, tonumber(msg.divider))
    end
    if msg.phase then
        globalSequencer:setChannelPhase(msg.name, tonumber(msg.phase))
    end
    broadcastSequencer()
end

local function handleSequencerPlock(msg)
    local step = tonumber(msg.step)
    local ch   = msg.channel
    local val  = msg.value
    if not step or not ch or not globalSequencer then
        send({ type = "error", id = msg.id, message = "plock needs step + channel" })
        return
    end
    if val ~= nil then
        local opts = nil
        if msg.morphDuration then
            opts = {
                morphDuration = tonumber(msg.morphDuration),
                morphMode     = msg.morphMode or "beats",
                morphEasing   = msg.morphEasing or "smoothstep",
            }
        end
        globalSequencer:plock(step, ch, tonumber(val), opts)
    else
        globalSequencer:clearPlock(step, ch)
    end
    broadcastSequencer()
end

local function handleSetBPM(msg)
    local bpm = tonumber(msg.bpm)
    if bpm and bpm > 0 and clock then
        clock.setBPM(bpm)
    end
    send({ type = "bpmChanged", bpm = clock.bpm })
end

local function handleTap(msg)
    if clock then
        clock.tap()
        send({ type = "bpmChanged", bpm = clock.bpm })
    end
end

local function handleResetPhase(msg)
    if clock then clock.resetPhase() end
    if globalSequencer then globalSequencer:realign() end
    if globalSceneSequencer then globalSceneSequencer:realign() end
end

-- ---- Scene sequencer messages ----

local function sceneSeqSnapshot()
    if not globalSceneSequencer then return {} end
    return globalSceneSequencer:getState()
end

local function broadcastSceneSequencer()
    local snap = sceneSeqSnapshot()
    snap.type = "sceneSequencerState"
    send(snap)
end

local function handleGetSceneSequencer(msg)
    local snap = sceneSeqSnapshot()
    snap.type = "sceneSequencerState"
    snap.id = msg.id
    send(snap)
end

local function handleResyncPhases(msg)
    if globalSequencer then globalSequencer:resync() end
    if globalSceneSequencer then globalSceneSequencer:resync() end
    broadcastSequencer()
    broadcastSceneSequencer()
end

local function handleSceneSeqPlay(msg)
    if globalSceneSequencer then globalSceneSequencer:play() end
    broadcastSceneSequencer()
end

local function handleSceneSeqStop(msg)
    if globalSceneSequencer then globalSceneSequencer:stop() end
    broadcastSceneSequencer()
end

local function handleSceneSeqCacheScene(msg)
    if not globalSceneSequencer then return end
    local label = msg.label
    if not label then
        send({ type = "error", id = msg.id, message = "cacheScene needs label" })
        return
    end
    if msg.sceneType == "patch" and msg.patchPath then
        globalSceneSequencer:cachePatchScene(label, msg.patchPath)
    elseif msg.filename and msg.saveIdx then
        globalSceneSequencer:cacheSavestateScene(label, msg.filename, tonumber(msg.saveIdx))
    elseif msg.captureSlot then
        globalSceneSequencer:captureScene(label, tonumber(msg.captureSlot))
    else
        send({ type = "error", id = msg.id, message = "cacheScene needs patchPath, filename+saveIdx, or captureSlot" })
        return
    end
    broadcastSceneSequencer()
end

local function handleSceneSeqAddChannel(msg)
    if not globalSceneSequencer or not msg.name then
        send({ type = "error", id = msg.id, message = "sceneSeqAddChannel needs name" })
        return
    end
    globalSceneSequencer:channel(msg.name, {
        slot    = tonumber(msg.slot) or 1,
        steps   = tonumber(msg.steps) or 8,
        divider = tonumber(msg.divider) or 1,
    })
    broadcastSceneSequencer()
end

local function handleSceneSeqRemoveChannel(msg)
    if globalSceneSequencer and msg.name then
        globalSceneSequencer:removeChannel(msg.name)
    end
    broadcastSceneSequencer()
end

local function handleSceneSeqUpdateChannel(msg)
    if not globalSceneSequencer or not msg.name then
        send({ type = "error", id = msg.id, message = "sceneSeqUpdateChannel needs name" })
        return
    end
    if msg.steps then
        globalSceneSequencer:setChannelSteps(msg.name, math.floor(tonumber(msg.steps)))
    end
    if msg.divider then
        globalSceneSequencer:setChannelDivider(msg.name, tonumber(msg.divider))
    end
    if msg.phase then
        globalSceneSequencer:setChannelPhase(msg.name, tonumber(msg.phase))
    end
    broadcastSceneSequencer()
end

local function handleSceneSeqSetScene(msg)
    local step = tonumber(msg.step)
    local ch = msg.channel
    local label = msg.scene
    if not step or not ch or not globalSceneSequencer then
        send({ type = "error", id = msg.id, message = "sceneSeqSetScene needs step + channel" })
        return
    end
    if label then
        globalSceneSequencer:setScene(step, ch, label)
    else
        globalSceneSequencer:clearScene(step, ch)
    end
    broadcastSceneSequencer()
end


-- ---- Patch management ----

local function handleListAvailablePatches(msg)
    local seen = {}
    local patches = {}

    -- Include all configured patches first (preserves user ordering)
    for _, name in ipairs(cfg_patches.patches) do
        if not seen[name] then
            seen[name] = true
            local short = name:match("([^/]+)$") or name
            table.insert(patches, { index = #patches + 1, path = name, short = short })
        end
    end

    -- Scan demos/ folder for any patches not already in the config list
    local items = love.filesystem.getDirectoryItems("demos")
    local discovered = {}
    for _, item in ipairs(items) do
        local num = item:match("^demo(%d+)$")
        if num then
            local srcDir = "demos/" .. item .. "/source"
            local info = love.filesystem.getInfo(srcDir, "directory")
            if info then
                local files = love.filesystem.getDirectoryItems(srcDir)
                for _, f in ipairs(files) do
                    local base = f:match("^(.+)%.lua$")
                    if base then
                        local path = srcDir .. "/" .. base
                        if not seen[path] then
                            table.insert(discovered, { num = tonumber(num), path = path, base = base })
                            seen[path] = true
                        end
                    end
                end
            end
        end
    end
    table.sort(discovered, function(a, b) return a.num < b.num end)
    for _, d in ipairs(discovered) do
        table.insert(patches, { index = #patches + 1, path = d.path, short = d.base })
    end

    send({ type = "availablePatches", id = msg.id, patches = patches })
end

local function handleLoadPatch(msg)
    local slot = tonumber(msg.slot)
    local patchName = msg.patchName
    if not slot or not patchName then
        send({ type = "error", id = msg.id, message = "loadPatch needs slot + patchName" })
        return
    end
    local ok, err = pcall(saveMgr.loadPatch, patchName, slot)
    if ok then
        wireParamNotifications(slot, patchSlots[slot].patch)
        send({ type = "patchLoaded", id = msg.id, slot = slot, patchName = patchName })
    else
        send({ type = "error", id = msg.id, message = "loadPatch failed: " .. tostring(err) })
    end
end


-- ---- Shader control ----

local function handleGetSlotShaders(msg)
    local slot = tonumber(msg.slot)
    if not slot then
        send({ type = "error", id = msg.id, message = "getSlotShaders needs slot" })
        return
    end
    local s = patchSlots and patchSlots[slot]
    if not s or not s.patch then
        send({ type = "error", id = msg.id, message = "no patch in slot " .. slot })
        return
    end

    -- Available shader names
    local available = {}
    for i, sh in ipairs(cfgShaders.PostProcessShaders) do
        table.insert(available, { index = i, name = sh.name })
    end

    -- Current shader selections (from shaderext resources)
    local layers = {}
    local shaderext = s.shaderext
    if shaderext then
        for layer = 1, 10 do
            local idx = shaderext:get("shaderSlot" .. layer) or 1
            local name = (cfgShaders.PostProcessShaders[idx] or {}).name or "default"
            table.insert(layers, { layer = layer, shaderIndex = idx, shaderName = name })
        end
    end

    -- Shader ext params (non-slot, non-time)
    local modSet = Modulator.getModulatedSet()
    local shaderParams = {}
    if shaderext then
        for idx = 1, #shaderext do
            local name = shaderext:getName(idx)
            if isRealName(name) and not name:match("^shaderSlot") and not name:match("_time$") then
                local value = shaderext:getBaseByIdx(idx) or shaderext:getByIdx(idx)
                local meta = shaderext:getMeta(idx)
                local entry = {
                    name = name,
                    value = value,
                    type = (type(value) == "number") and "float" or type(value),
                    modulated = modSet["shaderext:" .. slot .. ":" .. name] or false,
                }
                if meta then
                    if meta.min then entry.min = meta.min end
                    if meta.max then entry.max = meta.max end
                end
                table.insert(shaderParams, entry)
            end
        end
    end

    send({
        type = "slotShaders",
        id = msg.id,
        slot = slot,
        available = available,
        layers = layers,
        shaderParams = shaderParams,
        enabled = cfgShaders.enabled,
    })
end

local function handleSetSlotShader(msg)
    local slot = tonumber(msg.slot)
    local layer = tonumber(msg.layer)
    local shaderIdx = tonumber(msg.shaderIndex)
    if not (slot and layer and shaderIdx) then
        send({ type = "error", id = msg.id, message = "setSlotShader needs slot, layer, shaderIndex" })
        return
    end
    CommandSystem.queueCommand("selectShader", { slot, layer, shaderIdx })
end

local function handleSetShaderParam(msg)
    local slot = tonumber(msg.slot)
    local name = msg.name
    local value = msg.value
    if not (slot and name and value ~= nil) then
        send({ type = "error", id = msg.id, message = "setShaderParam needs slot, name, value" })
        return
    end
    local s = patchSlots and patchSlots[slot]
    if s and s.shaderext then
        s.shaderext:set(name, tonumber(value))
    end
end

local function handleToggleShaders(msg)
    local enable = msg.enable
    if enable ~= nil then
        cfgShaders.enabled = enable and true or false
    else
        cfgShaders.enabled = not cfgShaders.enabled
    end
    send({ type = "shadersToggled", enabled = cfgShaders.enabled })
end


-- ---- Savestates ----

local function handleListSavestates(msg)
    local slot = tonumber(msg.slot)
    if not slot then
        send({ type = "error", id = msg.id, message = "listSavestates needs slot" })
        return
    end
    local s = patchSlots and patchSlots[slot]
    if not s then
        send({ type = "error", id = msg.id, message = "no patch in slot " .. slot })
        return
    end

    local baseName = s.name:gsub(".*/", "")
    local currentPatch = {}
    local otherMap = {}

    local files = love.filesystem.getDirectoryItems("savestates")
    for _, fname in ipairs(files) do
        local patchBase, slotNum = fname:match("^(.+)_slot(%d+)%.json$")
        if patchBase and slotNum then
            local id = tonumber(slotNum)
            if patchBase == baseName then
                table.insert(currentPatch, id)
            else
                if not otherMap[patchBase] then
                    otherMap[patchBase] = { ids = {}, fullPath = nil }
                end
                table.insert(otherMap[patchBase].ids, id)
                if not otherMap[patchBase].fullPath then
                    local data = saveMgr.loadSceneData(patchBase, id)
                    if data and data.patchName then
                        otherMap[patchBase].fullPath = data.patchName
                    end
                end
            end
        end
    end

    table.sort(currentPatch)

    local otherPatches = {}
    for name, info in pairs(otherMap) do
        table.sort(info.ids)
        table.insert(otherPatches, {
            patchName = name,
            fullPath  = info.fullPath,
            savestates = info.ids,
        })
    end
    table.sort(otherPatches, function(a, b) return a.patchName < b.patchName end)

    send({
        type = "savestateList",
        id = msg.id,
        slot = slot,
        patchName = s.name,
        currentPatch = currentPatch,
        otherPatches = otherPatches,
    })
end

local function handleSaveSavestate(msg)
    local slot = tonumber(msg.slot)
    local savestateId = tonumber(msg.savestateId)
    if not (slot and savestateId) then
        send({ type = "error", id = msg.id, message = "saveSavestate needs slot + savestateId" })
        return
    end
    local ok, err = pcall(function()
        saveMgr.saveResources(patchSlots[slot].name, savestateId, slot)
    end)
    if ok then
        send({ type = "savestateSaved", id = msg.id, slot = slot, savestateId = savestateId })
    else
        send({ type = "error", id = msg.id, message = "save failed: " .. tostring(err) })
    end
end

local function handleLoadSavestate(msg)
    local slot = tonumber(msg.slot)
    local savestateId = tonumber(msg.savestateId)
    if not (slot and savestateId) then
        send({ type = "error", id = msg.id, message = "loadSavestate needs slot + savestateId" })
        return
    end
    local opts = {
        morphTime = tonumber(msg.morphTime) or saveMgr.defaultMorphTime,
        morphEasing = msg.morphEasing or saveMgr.defaultMorphEasing,
    }
    local ok, err = pcall(function()
        saveMgr.loadResources(patchSlots[slot].name, savestateId, slot, opts)
    end)
    if ok then
        send({ type = "savestateLoaded", id = msg.id, slot = slot, savestateId = savestateId })
    else
        send({ type = "error", id = msg.id, message = "load failed: " .. tostring(err) })
    end
end


local function handleGetMorphSettings(msg)
    send({
        type = "morphSettings",
        id = msg.id,
        enabled = saveMgr.morphEnabled,
        time = saveMgr.defaultMorphTime,
        easing = saveMgr.defaultMorphEasing,
    })
end

local function handleSetMorphSettings(msg)
    if msg.enabled ~= nil then saveMgr.morphEnabled = msg.enabled end
    if msg.time then saveMgr.defaultMorphTime = tonumber(msg.time) or saveMgr.defaultMorphTime end
    if msg.easing then saveMgr.defaultMorphEasing = msg.easing end
    send({
        type = "morphSettings",
        enabled = saveMgr.morphEnabled,
        time = saveMgr.defaultMorphTime,
        easing = saveMgr.defaultMorphEasing,
    })
end

-- ---- MIDI messages ----

local function handleGetMidiDevices(msg)
    local status = MIDIDispatcher.getStatus()
    local connections = MappingStore.getConnections()
    local devices = {}
    for _, conn in ipairs(connections) do
        table.insert(devices, {
            id = conn.id,
            name = conn.device,
            enabled = conn.enabled,
        })
    end
    send({
        type = "midiDevices",
        id = msg.id,
        devices = devices,
        activeChannels = status.activeChannels,
        activeThreads = status.activeThreads,
    })
end

local function serializeMapping(m)
    return {
        id = m.id,
        midiType = m.midiType,
        midiKey = m.midiKey,
        command = m.command,
        args = m.args,
        transform = m.transform,
        source = m.source,
        label = m.label,
        type = m.type,
        targetType = m.targetType,
        modulatorId = m.modulatorId,
        modulatorField = m.modulatorField,
    }
end

local function broadcastMidiMappings()
    local all = MappingStore.getAll()
    local list = {}
    for _, m in ipairs(all) do
        table.insert(list, serializeMapping(m))
    end
    send({ type = "midiMappings", mappings = list })
end

local function handleGetMidiMappings(msg)
    local all = MappingStore.getAll()
    local list = {}
    for _, m in ipairs(all) do
        table.insert(list, serializeMapping(m))
    end
    send({ type = "midiMappings", id = msg.id, mappings = list })
end

local function handleStartMidiLearn(msg)
    local slot = tonumber(msg.slot)
    local paramName = msg.paramName
    if not (slot and paramName) then
        send({ type = "error", id = msg.id, message = "startMidiLearn needs slot + paramName" })
        return
    end
    MidiLearn.startLearn({
        slot = slot,
        paramName = paramName,
    }, function(mapping)
        send({ type = "midiLearnCaptured", mapping = serializeMapping(mapping) })
        broadcastMidiMappings()
    end)
    send({ type = "midiLearnStarted", id = msg.id })
end

local function handleStartMidiLearnModulator(msg)
    local modulatorId = tonumber(msg.modulatorId)
    local field = msg.field
    if not (modulatorId and field) then
        send({ type = "error", id = msg.id, message = "startMidiLearnModulator needs modulatorId + field" })
        return
    end
    MidiLearn.startLearn({
        targetType = "modulator",
        modulatorId = modulatorId,
        modulatorField = field,
    }, function(mapping)
        send({ type = "midiLearnCaptured", mapping = serializeMapping(mapping) })
        broadcastMidiMappings()
    end)
    send({ type = "midiLearnStarted", id = msg.id })
end

local function handleCancelMidiLearn(msg)
    MidiLearn.cancelLearn()
    send({ type = "midiLearnCancelled", id = msg.id })
end

local function handleDeleteMidiMapping(msg)
    local mappingId = msg.mappingId
    if not mappingId then
        send({ type = "error", id = msg.id, message = "deleteMidiMapping needs mappingId" })
        return
    end
    MappingStore.remove(mappingId)
    broadcastMidiMappings()
end

local function handleSaveMidiMappings(msg)
    MappingStore.save()
    send({ type = "midiMappingsSaved", id = msg.id })
end

local function handleGetMidiLearnState(msg)
    send({ type = "midiLearnState", id = msg.id, learn = MidiLearn.getState() })
end


local handlers = {
    hello            = handleHello,
    listSlots        = handleListSlots,
    getSchema        = handleGetSchema,
    setParam         = handleSetParam,
    listModulators   = handleListModulators,
    createModulator  = handleCreateModulator,
    updateModulator  = handleUpdateModulator,
    deleteModulator  = handleDeleteModulator,
    getSequencer           = handleGetSequencer,
    sequencerPlay          = handleSequencerPlay,
    sequencerStop          = handleSequencerStop,
    sequencerResetPhase    = handleSequencerResetPhase,
    sequencerAddChannel    = handleSequencerAddChannel,
    sequencerRemoveChannel = handleSequencerRemoveChannel,
    sequencerUpdateChannel = handleSequencerUpdateChannel,
    sequencerPlock         = handleSequencerPlock,
    setBPM                 = handleSetBPM,
    tap                    = handleTap,
    resetPhase             = handleResetPhase,
    resyncPhases           = handleResyncPhases,
    getSceneSequencer        = handleGetSceneSequencer,
    sceneSeqPlay             = handleSceneSeqPlay,
    sceneSeqStop             = handleSceneSeqStop,
    sceneSeqCacheScene       = handleSceneSeqCacheScene,
    sceneSeqAddChannel       = handleSceneSeqAddChannel,
    sceneSeqRemoveChannel    = handleSceneSeqRemoveChannel,
    sceneSeqUpdateChannel    = handleSceneSeqUpdateChannel,
    sceneSeqSetScene         = handleSceneSeqSetScene,
    listAvailablePatches   = handleListAvailablePatches,
    loadPatch              = handleLoadPatch,
    getSlotShaders         = handleGetSlotShaders,
    setSlotShader          = handleSetSlotShader,
    setShaderParam         = handleSetShaderParam,
    toggleShaders          = handleToggleShaders,
    listSavestates         = handleListSavestates,
    saveSavestate          = handleSaveSavestate,
    loadSavestate          = handleLoadSavestate,
    getMorphSettings       = handleGetMorphSettings,
    setMorphSettings       = handleSetMorphSettings,
    getMidiDevices         = handleGetMidiDevices,
    getMidiMappings        = handleGetMidiMappings,
    startMidiLearn         = handleStartMidiLearn,
    startMidiLearnModulator = handleStartMidiLearnModulator,
    cancelMidiLearn        = handleCancelMidiLearn,
    deleteMidiMapping      = handleDeleteMidiMapping,
    saveMidiMappings       = handleSaveMidiMappings,
    getMidiLearnState      = handleGetMidiLearnState,
}


function protocol.handle(raw)
    local ok, msg = pcall(json.decode, raw)
    if not ok or type(msg) ~= "table" then
        send({ type = "error", message = "invalid JSON: " .. tostring(msg) })
        return
    end
    local h = handlers[msg.type]
    if not h then
        send({ type = "error", id = msg.id, message = "unknown type: " .. tostring(msg.type) })
        return
    end
    h(msg)
end


-- Dirty-param buffer: flushed at a fixed rate instead of per-change,
-- so modulators and held keys don't flood the WebSocket.
local dirtyParams = {}
local lastFlush = 0
local FLUSH_INTERVAL = 1 / 30  -- 30 Hz — smooth enough for sliders


--- Mark a parameter as changed. The latest value wins; the actual
--- send happens in protocol.flush().
function protocol.notifyParamChanged(slot, name, value)
    dirtyParams[slot .. ":" .. name] = { slot = slot, name = name, value = value, source = "param" }
end


--- Mark a shader parameter as changed.
function protocol.notifyShaderParamChanged(slot, name, value)
    dirtyParams["shader:" .. slot .. ":" .. name] = { slot = slot, name = name, value = value, source = "shader" }
end


--- Send all accumulated param changes to connected clients.
--- Call once per frame from the main update loop.
function protocol.flush()
    local now = love.timer.getTime()
    if (now - lastFlush) < FLUSH_INTERVAL then return end
    lastFlush = now

    for _, p in pairs(dirtyParams) do
        send({ type = "paramChanged", slot = p.slot, name = p.name, value = p.value, source = p.source or "param" })
    end
    dirtyParams = {}

    if clock then
        local tickMsg = { type = "clockTick", beatPhase = clock.beatPhase, bpm = clock.bpm }
        if globalSequencer and globalSequencer.playing then
            local steps = {}
            for _, name in ipairs(globalSequencer.channelOrder) do
                local ch = globalSequencer.channels[name]
                steps[name] = ch.currentStep
            end
            tickMsg.seqSteps = steps
        end
        send(tickMsg)
    end
end


local lastMidiActivity = 0
local MIDI_ACTIVITY_INTERVAL = 1 / 15

function protocol.init()
    studioBridge.setMessageHandler(protocol.handle)

    MIDIDispatcher.setActivityCallback(function(deviceId, msgType, channel, data1, data2)
        local now = love.timer.getTime()
        if (now - lastMidiActivity) < MIDI_ACTIVITY_INTERVAL then return end
        lastMidiActivity = now
        send({
            type = "midiActivity",
            deviceId = deviceId,
            msgType = msgType,
            channel = channel,
            data1 = data1,
            data2 = data2,
        })
    end)

    logInfo("studio.protocol registered")
end


return protocol
