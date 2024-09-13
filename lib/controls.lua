-- controls.lua
--
-- Handle general keyboard controls (non patch-specific)
--

local kp = lovjRequire("lib/utils/keypress")
local rtmgr = lovjRequire("lib/realtimemgr")
local cfgShaders = lovjRequire("cfg/cfg_shaders")
local cfgPatches = lovjRequire("cfg/cfg_patches")

local controls = {}

-- TODO: Move these to cfg_controls?
controls.selectors = { "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12"}

controls.selectedPatch = 1

local MODKEY_PRIMARY = "lctrl"
local MODKEY_SECONDARY = "lshift"


-- TODO: move this function somewhere in the cfgShaders, maybe?
-- (and make it somehow structured as a table)
--- @private handleShaderCommands
--- Handle shader-related keyboard commands
local function handleShaderCommands(slot)
	local s = patchSlots[slot].shaderext

	-- toggle shaders on / off
	if kp.isDown(MODKEY_PRIMARY) and kp.keypressOnAttack("s") then
		cfgShaders.toggleShaders()
	end
	-- select main shader
	if kp.keypressOnAttack("s") then
		s:set("shaderSlot1", (s:get("shaderSlot1") + 1) % #cfgShaders.PostProcessShaders)
	end
	-- warp
	if kp.isDown("w") then
		if kp.isDown("up") then s:set("_warpParameter", (s:get("_warpParameter") + 0.1)) end
		if kp.isDown("down") then s:set("_warpParameter", (s:get("_warpParameter") - 0.1)) end
	end
	-- kaleido
	if kp.isDown("k") then
		if kp.keypressOnAttack("up") then s:set("_segmentParameter", (s:get("_segmentParameter")+1)) end
		if kp.keypressOnAttack("down") then s:set("_segmentParameter", (s:get("_segmentParameter")-1)) end
	end
	-- blur
	if kp.isDown("g") then
		if kp.isDown("up") then s:set("_blurOffset", (s:get("_blurOffset")+0.001)) end
		if kp.isDown("down") then s:set("_blurOffset", (s:get("_blurOffset")-0.001)) end
	end
	return s
end

--- @public handleGeneralControls 
--- Main function to handle general keyboard controls (patch-independent)
function controls.handleKeyBoard()
	-- handle debug
	if kp.keypressOnRelease("escape") then
		debug.debug()  -- 'cont' to exit debug
	end

	-- toggle fullscreen
	if kp.isDown(MODKEY_PRIMARY) and kp.keypressOnAttack("return") then
		screen.toggleFullscreen()
	end

	-- handle low-res/hi-res upscaling
	if kp.isDown(MODKEY_PRIMARY) and kp.keypressOnAttack("u") then
		screen.changeUpscaling()
	end

	-- handle shaders
	
    patchSlots[controls.selectedPatch].patch.resources.shaderext = handleShaderCommands(controls.selectedPatch) 
	

	-- switch selected patch
	for i=1, #patchSlots do
		if kp.keypressOnRelease(tostring(i)) then
			controls.selectedPatch = i
		end
	end

	-- load patch from associated selector
	for k,v in pairs(controls.selectors) do
		if kp.keypressOnRelease(v) then
			-- Load / Save states
			if kp.isDown(MODKEY_PRIMARY) then
				if kp.isDown(MODKEY_SECONDARY) then
					-- SAVE with index F1...F12
					rtmgr.saveResources(patchSlots[controls.selectedPatch].name, k, controls.selectedPatch)
				else
					-- LOAD from index F1...F12
					rtmgr.loadResources(patchSlots[controls.selectedPatch].name, k, controls.selectedPatch)
				end
			else
				-- Otherwise, load patch
				local patchName = cfgPatches.patches[k]
				rtmgr.loadPatch(patchName, controls.selectedPatch)
			end
		end
	end
end

return controls