local Envelope = require "lib/automations/envelope"
local Lfo = require "lib/automations/lfo"

cfg_automations = {}

cfg_automations.env_list = {}
cfg_automations.lfo_list = {}

table.insert(cfg_automations.env_list, Envelope:new())
table.insert(cfg_automations.lfo_list, Lfo:new())