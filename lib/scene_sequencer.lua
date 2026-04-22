-- scene_sequencer.lua
--
-- Meta-sequencer that triggers scene loads on beat-quantized step
-- boundaries. Each channel targets a patch slot and steps through
-- named scenes. Two scene types are supported:
--
--   "patch"     — loads the patch fresh (default init)
--   "savestate" — loads the patch (if needed) then applies saved
--                 parameters, shaderext, and modulators.  LFO/envelope
--                 phases continue uninterrupted.
--
-- Usage:
--   local ss = SceneSequencer:new()
--   ss:cachePatchScene("blank", "demos/demo20/source/demo_20")
--   ss:cacheSavestateScene("intro", "demo_20", 1)
--   ss:captureScene("live", 1)
--   ss:channel("vis", { slot = 1, steps = 8, divider = 1 })
--   ss:setScene(1, "vis", "intro")
--   ss:setScene(5, "vis", "blank")
--   ss:play()
--   -- in update(): ss:tick()
--

local clock  = lovjRequire("lib/clock")
local saveMgr = lovjRequire("lib/savemgr")

local SceneSequencer = {}
SceneSequencer.__index = SceneSequencer


function SceneSequencer:new()
    local self = setmetatable({}, SceneSequencer)
    self.scenes       = {}
    self.channels     = {}
    self.channelOrder = {}
    self.playing      = false
    self.startBeat    = 0
    return self
end


--- Cache a patch-only scene (loads the patch fresh, no savestate).
function SceneSequencer:cachePatchScene(label, patchPath)
    self.scenes[label] = {
        _type      = "patch",
        _patchPath = patchPath,
    }
    logInfo("SceneSeq: cached patch scene '" .. label .. "' -> " .. patchPath)
    return self
end


--- Cache a savestate scene from a file on disk.
--- filename: savestate base name (e.g. "demo_20")
--- idx:      save-slot index within that file
function SceneSequencer:cacheSavestateScene(label, filename, idx)
    local data = saveMgr.loadSceneData(filename, idx)
    if data then
        data._type      = "savestate"
        data._patchPath = data.patchName
        self.scenes[label] = data
        logInfo("SceneSeq: cached savestate scene '" .. label .. "' from " .. filename .. " idx " .. idx)
    end
    return self
end


--- Cache a savestate scene from the live state of a slot.
function SceneSequencer:captureScene(label, slot)
    local data = saveMgr.captureSlot(slot)
    if data then
        data._type      = "savestate"
        data._patchPath = patchSlots[slot].name
        self.scenes[label] = data
        logInfo("SceneSeq: captured scene '" .. label .. "' from slot " .. slot)
    end
    return self
end


--- @private Apply a scene entry to a slot, swapping the patch if needed.
local function applySceneToSlot(sceneData, slot)
    local needsSwap = sceneData._patchPath
        and (not patchSlots[slot] or patchSlots[slot].name ~= sceneData._patchPath)

    if needsSwap then
        saveMgr.loadPatch(sceneData._patchPath, slot)
        if wireParamNotifications then
            wireParamNotifications(slot, patchSlots[slot].patch)
        end
    end

    if sceneData._type == "savestate" then
        saveMgr.applyScene(sceneData, slot)
    end
end


--- Add a channel. Each channel targets one patch slot and has its own
--- step count and clock divider (polyrhythmic scene changes).
function SceneSequencer:channel(name, config)
    if self.channels[name] then self:removeChannel(name) end

    local ch = {
        name        = name,
        slot        = config.slot or 1,
        numSteps    = config.steps or 8,
        divider     = config.divider or 1,
        steps       = {},
        currentStep = 0,
        lastScene   = nil,
    }
    for i = 1, ch.numSteps do ch.steps[i] = {} end

    self.channels[name] = ch
    table.insert(self.channelOrder, name)
    return self
end


function SceneSequencer:removeChannel(name)
    self.channels[name] = nil
    for i = #self.channelOrder, 1, -1 do
        if self.channelOrder[i] == name then
            table.remove(self.channelOrder, i)
        end
    end
    return self
end


--- Assign a cached scene to a step on a channel.
function SceneSequencer:setScene(step, channelName, sceneLabel)
    local ch = self.channels[channelName]
    if ch and step >= 1 and step <= ch.numSteps then
        ch.steps[step].scene = sceneLabel
    end
    return self
end


function SceneSequencer:clearScene(step, channelName)
    local ch = self.channels[channelName]
    if ch and step >= 1 and step <= ch.numSteps then
        ch.steps[step].scene = nil
    end
    return self
end


--- Resize a channel.
function SceneSequencer:setChannelSteps(channelName, n)
    local ch = self.channels[channelName]
    if not ch then return self end
    ch.numSteps = n
    while #ch.steps < n do table.insert(ch.steps, {}) end
    while #ch.steps > n do table.remove(ch.steps) end
    return self
end


function SceneSequencer:setChannelDivider(channelName, div)
    local ch = self.channels[channelName]
    if ch then ch.divider = div end
    return self
end


function SceneSequencer:play()
    self.playing   = true
    self.startBeat = clock.beat
    for _, ch in pairs(self.channels) do
        ch.currentStep = 0
        ch.lastScene   = nil
    end
    return self
end


function SceneSequencer:stop()
    self.playing = false
    return self
end


function SceneSequencer:toggle()
    if self.playing then self:stop() else self:play() end
    return self
end


function SceneSequencer:realign()
    self.startBeat = clock.beat
    for _, ch in pairs(self.channels) do
        ch.currentStep = 0
        ch.lastScene   = nil
    end
    return self
end


--- Advance all channels. Apply scenes on step transitions.
function SceneSequencer:tick()
    if not self.playing then return end

    local beatsSinceStart = clock.beat - self.startBeat

    for _, chName in ipairs(self.channelOrder) do
        local ch = self.channels[chName]
        local stepFloat = beatsSinceStart * ch.divider
        local newStep   = math.floor(stepFloat) % ch.numSteps + 1

        if newStep ~= ch.currentStep then
            ch.currentStep = newStep
            local sceneLabel = ch.steps[newStep].scene

            if sceneLabel and sceneLabel ~= ch.lastScene then
                local sceneData = self.scenes[sceneLabel]
                if sceneData then
                    applySceneToSlot(sceneData, ch.slot)
                    ch.lastScene = sceneLabel
                end
            end
        end
    end
end


--- Serialisable snapshot for the GUI.
function SceneSequencer:getState()
    local channels = {}
    for _, name in ipairs(self.channelOrder) do
        local ch = self.channels[name]
        local steps = {}
        for i = 1, ch.numSteps do
            steps[i] = ch.steps[i].scene or false
        end
        table.insert(channels, {
            name        = name,
            slot        = ch.slot,
            numSteps    = ch.numSteps,
            divider     = ch.divider,
            currentStep = ch.currentStep,
            steps       = steps,
        })
    end
    return {
        playing  = self.playing,
        scenes   = self:getSceneList(),
        channels = channels,
    }
end


function SceneSequencer:getSceneList()
    local list = {}
    for name, data in pairs(self.scenes) do
        table.insert(list, {
            label     = name,
            sceneType = data._type or "savestate",
            patchPath = data._patchPath or "",
        })
    end
    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end


return SceneSequencer
