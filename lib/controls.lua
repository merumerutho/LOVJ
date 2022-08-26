-- controls.lua
--
-- Handle general controls (non patch-specific)
--

controls = {}
kp = require("lib/utils/keypress")
cmd = require("lib/utils/cmdmenu")

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
		if kp.isDown("up") then p:set("_warpParameter", (p:get("_warpParameter") + 0.1)) end
		if kp.isDown("down") then p:set("_warpParameter", (p:get("_warpParameter") - 0.1)) end
	end
	-- kaleido
	if kp.isDown("k") then
		if kp.keypressOnAttack("up") then p:set("_segmentParameter", (p:get("_segmentParameter")+1)) end
		if kp.keypressOnAttack("down") then p:set("_segmentParameter", (p:get("_segmentParameter")-1)) end
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
		screen.ToggleFullscreen()
	end

	-- handle shaders
	handleShaderCommands()

	-- load patch from associated quick-slot
	for k,v in pairs(controls.slots) do
		if kp.keypressOnRelease(v) and not cmd.isOpen then
			patch = require(cfg_patches.patches[k])
			patch.init()
		end
	end

	return
end

return controls