-- controls.lua
--
-- Handle general controls (non patch-specific)
--
local kp = lovjRequire("lib/utils/keypress")
local cmd = lovjRequire("lib/cmdmenu")
local rtmgr = lovjRequire("lib/realtimemgr")

local controls = {}

controls.slots = {"f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12"}

local function handleShaderCommands()
	-- toggle shaders on / off
	if kp.isDown("lctrl") and kp.keypressOnAttack("s") then
		toggleShaders()
	end
	-- select main shader
	if kp.keypressOnAttack("s") then
		g:set("selected_shader", (g:get("selected_shader") + 1) % #cfg_shaders.shaders)
	end
	-- warp
	if kp.isDown("w") then
		if kp.isDown("up") then g:set("_warpParameter", (g:get("_warpParameter") + 0.1)) end
		if kp.isDown("down") then g:set("_warpParameter", (g:get("_warpParameter") - 0.1)) end
	end
	-- kaleido
	if kp.isDown("k") then
		if kp.keypressOnAttack("up") then g:set("_segmentParameter", (g:get("_segmentParameter")+1)) end
		if kp.keypressOnAttack("down") then g:set("_segmentParameter", (g:get("_segmentParameter")-1)) end
	end
end


function controls.handleGeneralControls()
	g = resources.globals

	-- handle command menu
	if kp.keypressOnRelease("escape") then
		cmd.handleCmdMenu()
	end

	-- toggle fullscreen
	if kp.isDown("lalt") and kp.keypressOnAttack("return") then
		screen.toggleFullscreen()
	end

	-- handle low-res/hi-res upscaling
	if kp.isDown("lalt") and kp.keypressOnAttack("u") then
		screen.changeUpscaling()
	end

	-- handle shaders
	if not cmd.isOpen then handleShaderCommands() end

	-- load patch from associated quick-slot
	for k,v in pairs(controls.slots) do
		if kp.keypressOnRelease(v) and not cmd.isOpen then
			local patchName = cfg_patches.patches[k]
			rtmgr.loadPatch(patchName)
		end
	end
end

return controls