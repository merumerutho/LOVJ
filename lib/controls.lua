-- controls.lua
--
-- Handle general controls (non patch-specific)
--

controls = {}
kp = require("lib/utils/keypress")
cmd = require("lib/utils/cmdmenu")

controls.slots = {"f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12"}

function controls.handleGeneralControls(key, scancode, isrepeat)
	if kp.keypressOnRelease("escape") then
		cmd.handleCmdMenu()
		-- debug.debug()
	end

	if kp.isDown("lalt") and kp.keypressOnAttack("return") then
		screen.ToggleFullscreen()
	end

	-- toggle shaders
	if kp.isDown("lctrl") and kp.keypressOnAttack("s") then
		toggleShaders()
	end

	-- load patch from associated quick-slot
	for k,v in pairs(controls.slots) do
		if kp.keypressOnRelease(v) then
			patch = require(cfg_patches.patches[k])
			patch.init()
		end
	end

	return
end

return controls