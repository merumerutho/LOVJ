-- controls.lua
--
-- Handle general controls (non patch-specific)
--

controls = {}
kp = require("lib/utils/keypress")
cmd = require("lib/utils/cmdmenu")

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

	return
end

return controls