local Envelope = require "lib/automations/envelope"
local Lfo = require "lib/automations/lfo"

cfg_automations = {}

cfg_automations.env_list = {}
cfg_automations.lfo_list = {}

table.insert(cfg_automations.env_list, Envelope:new(2,1,0.5))
table.insert(cfg_automations.lfo_list, Lfo:new())

return cfg_automations