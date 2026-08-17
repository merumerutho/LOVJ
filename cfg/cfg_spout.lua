-- cfg_spout.lua
--
-- Configure spout sender and receivers
--

local machine = require("lib/machine")

local cfg_spout = {}
local cfg_screen = lovjRequire("cfg/cfg_screen")

cfg_spout.enable = true
machine.apply("cfg_spout", cfg_spout)  -- before senders/receivers so a profile can redefine them

cfg_spout.senders = 
{
    ["main"] = { ["name"] = "LOVJ_SPOUT_SENDER", ["width"] = cfg_screen.WINDOW_WIDTH, ["height"] = cfg_screen.WINDOW_HEIGHT }
}

cfg_spout.receivers = 
{
    "Avenue - Avenue2LOVJ"
}

cfg_spout.senderHandles = {}
cfg_spout.receiverHandles = {}

--- @public invalidateSenders release all Spout senders ahead of a window mode
--- switch; they rebuild lazily on their next SendCanvas (real senders only —
--- the stub has no invalidate and needs none).
function cfg_spout.invalidateSenders()
	for i=1,#cfg_spout.senderHandles do
		local s = cfg_spout.senderHandles[i]
		if s.invalidate then
			s:invalidate()
		end
	end
end

return cfg_spout