-- cfg_bpm.lua
--
-- Configure BPM-related parameters
--

local machine = require("lib/machine")

local cfg_bpm = {}

cfg_bpm.default_bpm = 128

return machine.apply("cfg_bpm", cfg_bpm)