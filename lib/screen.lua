-- screen.lua
--
-- Graphical settings

INTERNAL_RES_WIDTH = 240
INTERNAL_RES_RATIO = 4/3

OUTER_RES_WIDTH = 800
OUTER_RES_RATIO = 4/3

screen = {}

-- set_internal_res(w,r):
-- assign internal resolution to be (w x h)
-- where h is calculated as w/r
local function SetInternalRes(w, r)
	screen.InternalRes = {}
	screen.InternalRes.W = w
	screen.InternalRes.R = 1/r
	screen.InternalRes.H = math.floor(w/r)
end


local function SetExternalRes(w, r)
	screen.ExternalRes = {}
	screen.ExternalRes.W = w
	screen.ExternalRes.R = 1/r
	screen.ExternalRes.H = math.floor(w/r)
end


local function SetScreenOptions()
	love.graphics.setDefaultFilter("linear", "nearest")
	love.window.setVSync(false)
end


local function CalculateScaling()
	screen.Scaling = {}
	screen.Scaling.X = screen.ExternalRes.W / screen.InternalRes.W
	screen.Scaling.Y = screen.ExternalRes.H / screen.InternalRes.H
end


function screen.init()
	-- Set internal resolution and screen scaling settings
	SetInternalRes(INTERNAL_RES_WIDTH, INTERNAL_RES_RATIO)
	SetExternalRes(OUTER_RES_WIDTH, OUTER_RES_RATIO)
	CalculateScaling()
	SetScreenOptions()
	return screen
end

return screen