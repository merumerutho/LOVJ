-- cfg_commands.lua
--
-- Configuration of all public commands available in LOVJ
-- These commands are protocol-agnostic and can be triggered by OSC, MIDI, etc.
--

local cfg_commands = {}

-- Initialize command system with all LOVJ commands
function cfg_commands.init()
    local CommandSystem = require("lib/command_system")
    
    -- Global commands
    CommandSystem.registerCommand("setSelectedPatch", {
        description = "Set the currently selected patch slot",
        category = "global",
        parameters = {
            {name = "slot", type = "int", min = 1, max = 12, required = true}
        },
        execute = function(slot)
            cfgControls.selectedPatch = slot
            logInfo("Selected patch slot: " .. slot)
        end
    })
    
    CommandSystem.registerCommand("setBPM", {
        description = "Set the global BPM",
        category = "global", 
        parameters = {
            {name = "bpm", type = "float", min = 0, max = 250, required = true}
        },
        execute = function(bpm)
            if bpm_est then
                bpm_est:setBPM(bpm)
                logInfo("Set BPM to: " .. bpm)
            end
        end
    })
    
    -- System commands
    CommandSystem.registerCommand("toggleFullscreen", {
        description = "Toggle fullscreen mode",
        category = "system",
        parameters = {
            {name = "enable", type = "bool", required = false}
        },
        execute = function(enable)
            if enable == nil or enable then
                screen.toggleFullscreen()
                logInfo("Toggled fullscreen")
            end
        end
    })
    
    CommandSystem.registerCommand("toggleShaders", {
        description = "Enable or disable shader processing",
        category = "system",
        parameters = {
            {name = "enable", type = "bool", required = true}
        },
        execute = function(enable)
            cfgShaders.enabled = enable and true or false
            logInfo("Shaders " .. (cfgShaders.enabled and "enabled" or "disabled"))
        end
    })
    
    CommandSystem.registerCommand("changeUpscaling", {
        description = "Change upscaling mode",
        category = "system",
        parameters = {},
        execute = function()
            screen.changeUpscaling()
            logInfo("Changed upscaling mode")
        end
    })
    
    CommandSystem.registerCommand("systemReset", {
        description = "Restart the application",
        category = "system",
        parameters = {
            {name = "confirm", type = "bool", required = true}
        },
        execute = function(confirm)
            if confirm then
                love.event.quit("restart")
                logInfo("System restart initiated")
            end
        end
    })
    
    -- Patch commands
    CommandSystem.registerCommand("loadPatch", {
        description = "Load a patch into a specific slot",
        category = "patch",
        parameters = {
            {name = "slot", type = "int", min = 1, max = 12, required = true},
            {name = "patchName", type = "string", required = true}
        },
        execute = function(slot, patchName)
            if saveMgr then
                saveMgr.loadPatch(patchName, slot)
                logInfo("Loaded patch '" .. patchName .. "' in slot " .. slot)
            end
        end
    })
    
    CommandSystem.registerCommand("resetPatch", {
        description = "Reset a patch to its initial state",
        category = "patch",
        parameters = {
            {name = "slot", type = "int", min = 1, max = 12, required = true}
        },
        execute = function(slot)
            if patchSlots and patchSlots[slot] and patchSlots[slot].patch then
                local success, err = pcall(patchSlots[slot].patch.init, slot, globalSettings, patchSlots[slot].shaderext)
                if success then
                    logInfo("Reset patch in slot " .. slot)
                else
                    logError("Failed to reset patch " .. slot .. ": " .. tostring(err))
                end
            end
        end
    })
    
    CommandSystem.registerCommand("setPatchParameter", {
        description = "Set a parameter value for a patch",
        category = "patch",
        parameters = {
            {name = "slot", type = "int", min = 1, max = 12, required = true},
            {name = "paramName", type = "string", required = true},
            {name = "value", type = "float", required = true}
        },
        execute = function(slot, paramName, value)
            if patchSlots and patchSlots[slot] and patchSlots[slot].patch then
                local patch = patchSlots[slot].patch
                if patch.resources and patch.resources.parameters then
                    patch.resources.parameters:set(paramName, value)
                    logInfo("Set " .. paramName .. " = " .. value .. " in patch " .. slot)
                end
            end
        end
    })
    
    CommandSystem.registerCommand("loadSavestate", {
        description = "Load a savestate for a patch",
        category = "patch",
        parameters = {
            {name = "slot", type = "int", min = 1, max = 12, required = true},
            {name = "savestateId", type = "int", min = 1, max = 12, required = true}
        },
        execute = function(slot, savestateId)
            if saveMgr and patchSlots and patchSlots[slot] then
                saveMgr.loadResources(patchSlots[slot].name, savestateId, slot)
                logInfo("Loaded savestate " .. savestateId .. " for patch " .. slot)
            end
        end
    })
    
    CommandSystem.registerCommand("saveSavestate", {
        description = "Save current state as a savestate",
        category = "patch",
        parameters = {
            {name = "slot", type = "int", min = 1, max = 12, required = true},
            {name = "savestateId", type = "int", min = 1, max = 12, required = true}
        },
        execute = function(slot, savestateId)
            if saveMgr and patchSlots and patchSlots[slot] then
                saveMgr.saveResources(patchSlots[slot].name, savestateId, slot)
                logInfo("Saved savestate " .. savestateId .. " for patch " .. slot)
            end
        end
    })
    
    CommandSystem.registerCommand("setPatchGraphics", {
        description = "Set a graphics parameter for a patch",
        category = "patch",
        parameters = {
            {name = "slot", type = "int", min = 1, max = 12, required = true},
            {name = "paramName", type = "string", required = true},
            {name = "value", type = "float", required = true}
        },
        execute = function(slot, paramName, value)
            if patchSlots and patchSlots[slot] and patchSlots[slot].patch then
                local patch = patchSlots[slot].patch
                if patch.resources and patch.resources.graphics then
                    patch.resources.graphics:set(paramName, value)
                    logInfo("Set graphics " .. paramName .. " = " .. value .. " in patch " .. slot)
                end
            end
        end
    })
    
    CommandSystem.registerCommand("setPatchGlobal", {
        description = "Set a global parameter for a patch",
        category = "patch",
        parameters = {
            {name = "slot", type = "int", min = 1, max = 12, required = true},
            {name = "paramName", type = "string", required = true},
            {name = "value", type = "float", required = true}
        },
        execute = function(slot, paramName, value)
            if patchSlots and patchSlots[slot] and patchSlots[slot].patch then
                local patch = patchSlots[slot].patch
                if patch.resources and patch.resources.globals then
                    patch.resources.globals:set(paramName, value)
                    logInfo("Set global " .. paramName .. " = " .. value .. " in patch " .. slot)
                end
            end
        end
    })
    
    -- Shader commands
    CommandSystem.registerCommand("selectShader", {
        description = "Select a shader for a patch layer",
        category = "shader",
        parameters = {
            {name = "slot", type = "int", min = 1, max = 12, required = true},
            {name = "layer", type = "int", min = 1, max = 3, required = true},
            {name = "shaderId", type = "int", min = 1, required = true}
        },
        execute = function(slot, layer, shaderId)
            if patchSlots and patchSlots[slot] and patchSlots[slot].patch then
                local patch = patchSlots[slot].patch
                if patch.shaderext then
                    patch.shaderext:set("shaderSlot" .. layer, shaderId)
                    logInfo("Set shader slot " .. layer .. " to " .. shaderId .. " in patch " .. slot)
                end
            end
        end
    })
    
    CommandSystem.registerCommand("setShaderParameter", {
        description = "Set a shader parameter",
        category = "shader",
        parameters = {
            {name = "slot", type = "int", min = 1, max = 12, required = true},
            {name = "layer", type = "int", min = 1, max = 3, required = true},
            {name = "paramName", type = "string", required = true},
            {name = "value", type = "float", required = true}
        },
        execute = function(slot, layer, paramName, value)
            if patchSlots and patchSlots[slot] and patchSlots[slot].patch then
                local patch = patchSlots[slot].patch
                if patch.shaderext then
                    local fullParamName = "shader" .. layer .. "_" .. paramName
                    patch.shaderext:set(fullParamName, value)
                    logInfo("Set shader param " .. fullParamName .. " = " .. value .. " in patch " .. slot)
                end
            end
        end
    })
    
    logInfo("CommandSystem: Initialized with " .. table.getn(CommandSystem.getCommands()) .. " commands")
end

return cfg_commands