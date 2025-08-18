-- cfg_kb_mapping.lua
--
-- Keyboard-specific mapping configuration
-- Maps keyboard combinations to generic commands
--

local cfg_kb_mapping = {}
local cfg_patches = lovjRequire("cfg/cfg_patches")

-- Direct key combination to command mappings
cfg_kb_mapping.directMappings = {
	-- Single key mappings
	["r"] = {
		command = "resetPatch",
		args = {"$selectedPatch"},
		trigger = "onPress"
	},
	["s"] = {
		command = "cycleShader",
		args = {"$selectedPatch", "1"},
		trigger = "onPress"
	},
	
	-- Modifier combinations
	["lctrl+s"] = {
		command = "toggleShaders",
		args = {"$toggleShadersState"},
		trigger = "onPress"
	},
	["lctrl+return"] = {
		command = "toggleFullscreen",
		args = {},
		trigger = "onPress"
	},
	["lctrl+u"] = {
		command = "changeUpscaling",
		args = {},
		trigger = "onPress"
	}
}

-- Value resolvers for dynamic arguments
cfg_kb_mapping.argumentResolvers = {
	["$selectedPatch"] = function()
		return cfg_patches.selectedPatch
	end,
	
	["$toggleShadersState"] = function()
		return not cfgShaders.enabled
	end
}

-- Initialize keyboard mappings (called from main.lua)
function cfg_kb_mapping.init()
	-- Load required dependencies
	local controls = lovjRequire("lib/controls")
	local CommandSystem = lovjRequire("lib/command_system")
	local cfgPatches = lovjRequire("cfg/cfg_patches")
	
	-- Generate dynamic mappings
	cfg_kb_mapping.generateMappings()
	
	-- Set up all keyboard bindings
	for keyCombo, mapping in pairs(cfg_kb_mapping.directMappings) do
		local keys = cfg_kb_mapping.parseKeyCombo(keyCombo)
		local triggerFunc = controls[mapping.trigger]
		
		if triggerFunc then
			controls.bind(
				function()
					-- Resolve dynamic arguments
					local resolvedArgs = cfg_kb_mapping.resolveArguments(mapping.args)
					
					-- Queue command through command system
					CommandSystem.queueCommand(mapping.command, resolvedArgs)
				end,
				{},
				triggerFunc,
				keys
			)
		else
			logError("KB Mapping: Unknown trigger function: " .. mapping.trigger)
		end
	end
	
	-- Sort controls to ensure high keycount combinations are evaluated first
	controls.sort()
	
	logInfo("KB Mapping: Initialized " .. table.getn(cfg_kb_mapping.directMappings) .. " keyboard bindings")
end

-- Auto-generate repetitive mappings
function cfg_kb_mapping.generateMappings()
	local cfgPatches = lovjRequire("cfg/cfg_patches")
	
	-- Generate F1-F12 mappings
	for i = 1, 12 do
		local fkey = "f" .. tostring(i)
		local ctrlFkey = "lctrl+f" .. tostring(i)
		local ctrlShiftFkey = "lctrl+lshift+f" .. tostring(i)
		
		-- F# = Load patch (only if patch exists)
		if cfgPatches.patches[i] then
			cfg_kb_mapping.directMappings[fkey] = {
				command = "loadPatch",
				args = {"$selectedPatch", cfgPatches.patches[i]},
				trigger = "onPress"
			}
		end
		
		-- Ctrl+F# = Load savestate
		cfg_kb_mapping.directMappings[ctrlFkey] = {
			command = "loadSavestate",
			args = {"$selectedPatch", tostring(i)},
			trigger = "onPress"
		}
		
		-- Ctrl+Shift+F# = Save savestate
		cfg_kb_mapping.directMappings[ctrlShiftFkey] = {
			command = "saveSavestate",
			args = {"$selectedPatch", tostring(i)},
			trigger = "onPress"
		}
	end
	
	-- Generate number key mappings (1-9 for patch slots)
	for i = 1, 9 do
		cfg_kb_mapping.directMappings[tostring(i)] = {
			command = "setSelectedPatch",
			args = {tostring(i)},
			trigger = "onPress"
		}
	end
end

-- Parse key combination string into array
function cfg_kb_mapping.parseKeyCombo(keyCombo)
	local keys = {}
	for key in keyCombo:gmatch("[^+]+") do
		table.insert(keys, key)
	end
	return keys
end

-- Resolve dynamic argument values
function cfg_kb_mapping.resolveArguments(args)
	local resolvedArgs = {}
	for _, arg in ipairs(args) do
		if type(arg) == "string" and arg:match("^%$") then
			local resolver = cfg_kb_mapping.argumentResolvers[arg]
			if resolver then
				table.insert(resolvedArgs, resolver())
			else
				logError("KB Mapping: Unknown argument resolver: " .. arg)
				table.insert(resolvedArgs, nil)
			end
		else
			table.insert(resolvedArgs, arg)
		end
	end
	return resolvedArgs
end

return cfg_kb_mapping