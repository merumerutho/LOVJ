-- cfg_spout.lua
--
-- Configure spout sender and receivers
--

local cfg_spout = {}
cfg_screen = lovjRequire("cfg/cfg_screen")

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
		for k,v in pairs(cfg_spout.senders) do
			if cfg_spout.senderHandles[i].name == v.name then
				cfg_spout.senderHandles[i].canvas = love.graphics.newCanvas(v.width, v.height)
			end
		end
	end
end

return cfg_spout