-- controls.lua
--
-- Handle general controls (non patch-specific)
--

controls = {}
kp = require("lib/utils/keypress")
cmd = require("lib/utils/cmdmenu")

controls.slots = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0"}

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

	if kp.keypressOnRelease("2") then
		patch = require(cfg_patches.patches[2])
		patch.init()
	end

	return
end

return controls