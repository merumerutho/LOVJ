-- cfg_spout.lua
--
-- Configure spout sender and receivers
--

local cfg_spout = {}
cfg_screen = require("cfg/cfg_screen")

cfg_spout.enable = true

cfg_spout.senders = 
{
    ["main"] = { ["name"] = "LOVJ_SPOUT_SENDER", ["width"] = cfg_screen.INTERNAL_RES_WIDTH, ["height"] = cfg_screen.INTERNAL_RES_HEIGHT }
}

cfg_spout.receivers = 
{
    "Avenue - Avenue2LOVJ"
}

return cfg_spout