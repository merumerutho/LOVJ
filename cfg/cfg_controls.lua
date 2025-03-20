-- cfg_controls.lua
--
-- Handle general input controls (non patch-specific)
--

local controls = lovjRequire("lib/controls")
local rtmgr = lovjRequire("lib/realtimemgr")
local patch = lovjRequire("lib/patch")

local cfgShaders = lovjRequire("cfg/cfg_shaders")
local cfgPatches = lovjRequire("cfg/cfg_patches")

--- 

local cfg_controls = {}

cfg_controls.selectors = { "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12"}

cfg_controls.selectedPatch = 1

local MODKEY_PRIMARY = "lctrl"
local MODKEY_SECONDARY = "lshift"

-- Swap shader with the next one (currently valid only for slot1
local function increaseShader()
	local s = patchSlots[cfg_controls.selectedPatch].shaderext
  
	s:set("shaderSlot1", 1 + (s:get("shaderSlot1")) % (#cfgShaders.PostProcessShaders))
	print(cfgShaders.PostProcessShaders[s:get("shaderSlot1")]["name"])
end

--- @private handleShaderCommands
--- Handle shader-related keyboard commands
local function handleShaderCommands(slot)
	local s = patchSlots[slot].shaderext

	-- toggle shaders on / off
	if kp.isDown(MODKEY_PRIMARY) and kp.keypressOnAttack("s") then
		cfgShaders.toggleShaders()
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
function cfg_controls.handleKeyBoard()
	-- handle debug
	if kp.keypressOnRelease("d") then
        if kp.isDown("lctrl") then
            if kp.isDown("lalt") then
                debug.debug()  -- 'cont' to exit debug
            end
        end
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
  patchSlots[cfg_controls.selectedPatch].patch.resources.shaderext = handleShaderCommands(cfg_controls.selectedPatch) 
	

	-- switch selected patch
	for i=1, #patchSlots do
		if kp.keypressOnRelease(tostring(i)) then
			cfg_controls.selectedPatch = i
		end
	end

	-- load patch from associated selector
	for k,v in pairs(cfg_controls.selectors) do
		if kp.keypressOnRelease(v) then
			-- Load / Save states
			if kp.isDown(MODKEY_PRIMARY) then
				if kp.isDown(MODKEY_SECONDARY) then
					-- SAVE with index F1...F12
					rtmgr.saveResources(patchSlots[cfg_controls.selectedPatch].name, k, cfg_controls.selectedPatch)
				else
					-- LOAD from index F1...F12
					rtmgr.loadResources(patchSlots[cfg_controls.selectedPatch].name, k, cfg_controls.selectedPatch)
				end
			else
				-- Otherwise, load patch
				local patchName = cfgPatches.patches[k]
				rtmgr.loadPatch(patchName, cfg_controls.selectedPatch)
			end
		end
	end
end


function cfg_controls.init()
  --controls.bindRegular(patch.reset , controls.onPress, {"r"})						          -- R 				= RESET  (TODO)
  controls.bind(increaseShader , controls.onPress, {"s"})					                  -- S 				= CHANGE SHADER
  
  controls.bind(cfgShaders.toggleShaders, controls.onPress, {"lctrl", "s"})			    -- CTRL + S 		= toggle shaders
  controls.bind(screen.toggleFullscreen, controls.onPress, {"lctrl", "return"})		  -- CTRL + ENTER 	= toggle fullscreen
  controls.bind(screen.changeUpscaling, controls.onPress, {"lctrl", "u"})			      -- CTRL + U 		= toggle upscaling mode
end

return cfg_controls