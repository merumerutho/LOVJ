-- cfg_spout.lua
--
-- Configure spout sender and receivers
--

local cfg_spout = {}
local cfg_screen = lovjRequire("cfg/cfg_screen")

cfg_spout.enable = true

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

function cfg_spout.updateCanvases()
	for i=1,#cfg_spout.senderHandles do
		local s = cfg_spout.senderHandles[i]
		if s.reinit then
			s:reinit()
		else
			s.canvas = love.graphics.newCanvas(s.width, s.height)
		end
	end
end

return cfg_spout