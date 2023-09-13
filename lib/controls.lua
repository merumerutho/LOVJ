-- controls.lua
--
-- Handle general keyboard controls (non patch-specific)
--

local kp = lovjRequire("lib/utils/keypress")
local cmd = lovjRequire("lib/cmdmenu")
local rtmgr = lovjRequire("lib/realtimemgr")
local cfg_shaders = lovjRequire("lib/cfg/cfg_shaders")

local controls = {}

-- TODO: Move these to cfg_controls
controls.slots = {"f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12"}

local MODKEY_PRIMARY = "lctrl"
local MODKEY_SECONDARY = "lshift"

-- TODO: move this function somewhere in the cfg_shaders, maybe?
--- @private handleShaderCommands Handle shader-related keyboard commands
local function handleShaderCommands()
	local s = resources.shaderext
	-- toggle shaders on / off
	if kp.isDown(MODKEY_PRIMARY) and kp.keypressOnAttack("s") then
		cfg_shaders.toggleShaders()
	end
	-- select main shader
	if kp.keypressOnAttack("s") then
		s:set("shaderSlot1", (s:get("shaderSlot1") + 1) % #cfg_shaders.PostProcessShaders)
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
end

--- @public handleGeneralControls Main function to handle general keyboard controls (patch-independent)
function controls.handleGeneralControls()
	-- handle command menu
	if kp.keypressOnRelease("escape") then
		cmd.handleCmdMenu()
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
	if not cmd.isOpen then handleShaderCommands() end

	-- load patch from associated quick-slot
	for k,v in pairs(controls.slots) do
		if kp.keypressOnRelease(v) and not cmd.isOpen then
			-- Load / Save states
			if kp.isDown(MODKEY_PRIMARY) then
				if kp.isDown(MODKEY_SECONDARY) then
					-- SAVE with index F1...F12
					rtmgr.saveResources(currentPatchName, k)
				else
					-- LOAD from index F1...F12
					rtmgr.loadResources(currentPatchName, k)
				end
			else
				-- Otherwise, load patch
				local patchName = cfg_patches.patches[k]
				rtmgr.loadPatch(patchName, 2) -- TODO: change this (forcefully load on slot 2)
			end
		end
	end
end

return controls