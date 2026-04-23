-- Regular requirements
require("lib/utils/table_extensions")
lick = require("lib/lick")
require("lib/utils/require")  -- registers lovjRequire/lovjUnrequire/lovjTest globals
version = require("cfg/cfg_version")

-- From here on, use lovjRequire and load modules as globals
local log = lovjRequire("lib/utils/logging")
logging.setLogLevel({ logging.LOG_ERROR, logging.LOG_INFO })

-- Load and create global references to core modules.
-- These modules are intentionally exposed as globals because patches
-- (and other modules) reference them directly without re-requiring.
screen = lovjRequire("lib/screen")
timer = lovjRequire("lib/timer")
ResourceList = lovjRequire("lib/resources")
controls = lovjRequire("lib/controls")
dispatcher = lovjRequire("lib/dispatcher")
errorHandler = lovjRequire("lib/utils/error_handler")
clock = lovjRequire("lib/clock")
studioBridge = lovjRequire("lib/studio/bridge")
studioProtocol = lovjRequire("lib/studio/protocol")
saveMgr = lovjRequire("lib/savemgr")
modulator = lovjRequire("lib/modulator")
Sequencer = lovjRequire("lib/sequencer")
SceneSequencer = lovjRequire("lib/scene_sequencer")
globalSequencer = nil
globalSceneSequencer = nil

-- Load configuration modules as globals
cfgKbMapping = lovjRequire("cfg/cfg_kb_mapping")
cfgPatches = lovjRequire("cfg/cfg_patches")
cfgShaders = lovjRequire("cfg/cfg_shaders")
cfgTimers = lovjRequire("cfg/cfg_timers")
cfgSpout = lovjRequire("cfg/cfg_spout")
cfgApp = lovjRequire("cfg/cfg_app")
cfgScreen = lovjRequire("cfg/cfg_screen")
cfgGlobals = lovjRequire("cfg/cfg_globals")
cfgCommands = lovjRequire("cfg/cfg_commands")

-- Initialize Spout support
if (cfgSpout.enable and
	love.system.getOS() == "Windows" and
	love.filesystem.getInfo("dynlib/SpoutLibrary.dll")) then
	spout = lovjRequire("lib/spout")
else
	spout = lovjRequire("lib/stubs/spout-stub")
end

drawingUtils = lovjRequire("lib/utils/drawing")

-- Set title with LOVJ version
love.window.setTitle(cfgApp.title .. " v" ..  version)
love.window.setIcon(love.image.newImageData(cfgApp.icon))

-- Add sender "MAIN"
local main_sender_cfg = cfgSpout.senders["main"]
table.insert(cfgSpout.senderHandles, spout.SpoutSender:new(nil, main_sender_cfg["name"], main_sender_cfg["width"], main_sender_cfg["height"]))

local receivers_cfg = cfgSpout.receivers
receivers_obj = {}
for i = 1, #receivers_cfg do
	table.insert(receivers_obj, spout.SpoutReceiver:new(nil, receivers_cfg[i]))
end

--- @private wireParamNotifications
--- Set a change hook on the patch's parameters Resource so any value
--- mutation (keyboard, command, direct code) broadcasts to the studio GUI.
function wireParamNotifications(slotIdx, patchObj)
	if patchObj and patchObj.resources and patchObj.resources.parameters then
		patchObj.resources.parameters._onChange = function(name, value)
			if studioProtocol and studioProtocol.notifyParamChanged then
				studioProtocol.notifyParamChanged(slotIdx, name, value)
			end
		end
	end
end

function wireShaderNotifications(slotIdx)
	local s = patchSlots[slotIdx]
	if s and s.shaderext then
		s.shaderext._onChange = function(name, value)
			if studioProtocol and studioProtocol.notifyShaderParamChanged then
				studioProtocol.notifyShaderParamChanged(slotIdx, name, value)
			end
		end
	end
end


--- @public bindPatchSlot
--- Register slot[i]'s source file with lick's REBUILD strategy so that
--- on-disk edits fully re-evaluate the patch. If the slot already had a
--- binding (e.g. loadPatch is swapping in a different file) the old
--- binding is removed first. Call this again whenever a slot's .name
--- changes.
function bindPatchSlot(slot_idx)
	local slot = patchSlots[slot_idx]
	if not slot then return end

	if slot.lickBinding and slot.lickBindingPath then
		lick.unbindInstance(slot.lickBindingPath, slot.lickBinding)
		slot.lickBinding = nil
		slot.lickBindingPath = nil
	end

	local path = slot.name
	slot.lickBindingPath = path
	slot.lickBinding = lick.bindInstance(path, {
		get = function() return slot.patch end,
		set = function(p) slot.patch = p end,
		build = function(newModule)
			newModule:init(slot_idx, globalSettings, slot.shaderext)
			wireParamNotifications(slot_idx, newModule)
			return newModule
		end,
	})
end


-- Mouse: left button feeds the BPM tap-tempo.
function love.mousepressed(x, y, button)
	if button == 1 then
		clock.tap()
	end
end


-- Ctrl+Esc dismisses persistent lick error banners until the next error.
function love.keypressed(key)
	if key == "escape" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
		lick.dismissBanners()
	end
end


--- @public love.load
function love.load()
	if arg[#arg] == "-debug" then require("mobdebug").start() end
	screen.init()
	cfgTimers.init()
	cfgShaders.init()
	clock.init()

	-- Set running patches
	patchSlots = {}
	for i=1,#cfgPatches.defaultPatch do
		table.insert(patchSlots, {name = cfgPatches.defaultPatch[i]})
	end
	for i=1, #patchSlots do
		patchSlots[i].patch = lovjRequire(patchSlots[i].name, lick.REBUILD)
	end

	-- Global setting resources
	globalSettings = ResourceList:newResource()
	for i, setting in ipairs(cfgGlobals.settings) do
		globalSettings:setByIdx(i, setting.value)
		globalSettings:setName(i, setting.name)
		logInfo("Global setting " .. i .. ": " .. setting.name .. " = " .. tostring(setting.value))
	end

	-- Initialize patches. Only fall back to the red error patch on first-load
	-- failure — there's no previous-good instance to keep running yet.
	for i, slot in ipairs(patchSlots) do
		slot.shaderext = ResourceList:newResource()
		cfgShaders.initShaderExt(i)
		wireShaderNotifications(i)

		local success = xpcall(function() slot.patch:init(i, globalSettings, slot.shaderext) end, debug.traceback)
		if not success then
			slot.patch = errorHandler.createFallbackPatch(i)
		end
		wireParamNotifications(i, slot.patch)

		-- Register this slot with lick so edits to the source file rebuild
		-- the patch in place. This happens after init so the first live
		-- reload starts from a known-good state.
		bindPatchSlot(i)
	end

	cfgCommands.init()
	cfgKbMapping.init()
	dispatcher.init()
	studioBridge.init()
	studioProtocol.init()

	globalSequencer = Sequencer:new()
	globalSceneSequencer = SceneSequencer:new()

	downMixCanvas = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
	dummyCanvas = love.graphics.newCanvas(1,1)

	local main_spout_sender = cfgSpout.senderHandles[1]
	main_spout_sender:init()

	for i = 1, #receivers_obj do
		receivers_obj[i]:init()
	end
end


--- @public love.draw
function love.draw()
	love.graphics.setCanvas(dummyCanvas)
	drawingUtils.clearCanvas(downMixCanvas)
	drawingUtils.clearCanvas(nil)

	for i=1, #patchSlots do
		local success, canvas = errorHandler.safePatchCall(i, "draw")
		if success and canvas then
			drawingUtils.drawCanvasToCanvas(canvas, downMixCanvas)
			canvas = drawingUtils.clearCanvas(canvas)
		end
	end

	-- Draw downmix to the main screen.
	drawingUtils.drawCanvasToCanvas(downMixCanvas, nil, 0, 0, 0, screen.Scaling.WindowRatioX, screen.Scaling.WindowRatioY)

	-- Spout output.
	local main_spout_sender = cfgSpout.senderHandles[1]
	main_spout_sender:SendCanvas(downMixCanvas, screen.Scaling.SpoutRatioX, screen.Scaling.SpoutRatioY)

	love.graphics.setCanvas()
end


--- @public love.update
function love.update()
	cfgTimers.update()
	clock.update()

	local fps = love.timer.getFPS()
	if cfgTimers.consoleTimer:activated() then
		logInfo("FPS: " .. fps)
		for i=1, #receivers_obj do
			receivers_obj[i]:update()
		end
	end

	controls.update()
	dispatcher.update()
	studioBridge.update()
	saveMgr.tick()
	if globalSequencer then globalSequencer:tick() end
	if globalSceneSequencer then globalSceneSequencer:tick() end
	-- Copy baseValue → value for all params before modulators apply on top
	for i = 1, #patchSlots do
		if patchSlots[i].patch and patchSlots[i].patch.resources and patchSlots[i].patch.resources.parameters then
			patchSlots[i].patch.resources.parameters:resetModulation()
		end
		if patchSlots[i].shaderext then
			patchSlots[i].shaderext:resetModulation()
		end
	end
	modulator.tick()
	studioProtocol.flush()

	-- Update all patches. Failures surface in the banner; instance stays live.
	for i=1, #patchSlots do
		errorHandler.safePatchCall(i, "update")
	end
end
