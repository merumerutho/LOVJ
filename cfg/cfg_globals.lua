-- cfg_globals.lua
--
-- Global settings configuration for LOVJ
-- Defines global settings with their names and default values
--

local cfg_globals = {}

cfg_globals.SETTINGS_MAX_COUNT = 128

-- Dependencies
local cfg_bpm = require("cfg/cfg_bpm")

-- Global settings list
-- Each entry contains: name, value, description (optional)
cfg_globals.settings = {
    -- Setting 1: BPM
    {
        name = "bpm",
        value = cfg_bpm.default_bpm,
        description = "Global beats per minute"
    }
    
    -- Additional global settings can be added here
    -- Example entries:
    -- {
    --     name = "volume",
    --     value = 1.0,
    --     description = "Master volume level"
    -- },
    -- {
    --     name = "selectedPatch",
    --     value = 1,
    --     description = "Currently selected patch slot"
    -- }
}

-- Validate settings count 
if #cfg_globals.settings > cfg_globals.SETTINGS_MAX_COUNT then
    error("cfg_globals: Too many global settings defined (max 128, found " .. #cfg_globals.settings .. ")")
end

return cfg_globals