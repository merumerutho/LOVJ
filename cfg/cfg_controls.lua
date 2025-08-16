-- cfg_controls.lua
--
-- Handle general input controls (non patch-specific)
--

local controls = lovjRequire("lib/controls")
local saveMgr = lovjRequire("lib/savemgr")
local patch = lovjRequire("lib/patch")

local cfgShaders = lovjRequire("cfg/cfg_shaders")
local cfgPatches = lovjRequire("cfg/cfg_patches")

--- 

local cfg_controls = {}

cfg_controls.selectedPatch = 1

local MODKEY_PRIMARY = "lctrl"
local MODKEY_SECONDARY = "lshift"

---

-- To bind a key combination to a function:
-- controls.bind( FUNCTION, {ARGUMENTS}, CHECK_FUNCTION, {KEYS} )
-- e.g. controls.bind(print , {"tizio"}, controls.onPress, {"lctrl", "p"}) 
-- will bind press of CTRL+P to function print("tizio")

function cfg_controls.init()
	-- R = RESET
	controls.bind(patchSlots[cfg_controls.selectedPatch].patch.init, {cfg_controls.selectedPatch},  controls.onPress, {"r"})						                      

	-- S = CHANGE SHADER
	controls.bind(function () local s = patchSlots[cfg_controls.selectedPatch].shaderext
						s:set("shaderSlot1", 1 + (s:get("shaderSlot1")) % (#cfgShaders.PostProcessShaders)) end,
					{}, 
					controls.onPress, 
					{"s"})					                          

	-- CTRL + S = toggle shaders
	controls.bind(cfgShaders.toggleShaders, {}, controls.onPress, {MODKEY_PRIMARY, "s"})

	-- CTRL + ENTER = toggle fullscreen
	controls.bind(screen.toggleFullscreen, {}, controls.onPress, {MODKEY_PRIMARY, "return"})

	-- CTRL + U = toggle upscaling mode
	controls.bind(screen.changeUpscaling, {}, controls.onPress, {MODKEY_PRIMARY, "u"})

	-- Controls to load patches / load savestate / save savestate
	-- F1 ... F12 / CTRL + F1 ... F12 / CTRL + SHIFT + F1 ... F12
	for i=1, 12 do
		controls.bind(saveMgr.loadPatch,      
					  {cfgPatches.patches[i], cfg_controls.selectedPatch}, 
					  controls.onPress, 
					  {"f"..tostring(i)})
		controls.bind(saveMgr.loadResources,
					  {patchSlots[cfg_controls.selectedPatch].name, i, cfg_controls.selectedPatch},
					  controls.onPress,
					  {MODKEY_PRIMARY, "f"..tostring(i)})
		controls.bind(saveMgr.saveResources,
					  {patchSlots[cfg_controls.selectedPatch].name, i, cfg_controls.selectedPatch},
					  controls.onPress,
					  {MODKEY_PRIMARY, MODKEY_SECONDARY, "f"..tostring(i)})
	end

	-- 1, 2, 3... = Change currently selected patch slot
	for i=1, #patchSlots do
		controls.bind(function() cfg_controls.selectedPatch = i end, {}, controls.onPress, {tostring(i)})
	end
	
	-- sort controls at the end to guarantee high keycount controls evaluated first
	controls.sort()
end

return cfg_controls