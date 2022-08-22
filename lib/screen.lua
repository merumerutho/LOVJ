-- screen.lua
--
-- Graphical settings

screen_settings = require "lib/cfg/cfg_screen"

screen = {}

-- set_internal_res(w,r):
-- assign internal resolution to be (w x h)
-- where h is calculated as w/r
function SetInternalRes(w, r)
	screen.InternalRes = {}
	screen.InternalRes.W = w
	screen.InternalRes.R = 1/r
	screen.InternalRes.H = math.floor(w/r)
end


function SetExternalRes(w, r)
	screen.ExternalRes = {}
	screen.ExternalRes.W = w
	screen.ExternalRes.R = 1/r
	screen.ExternalRes.H = math.floor(w/r)
end


function screen.UpdateScreenOptions()
	love.window.setMode(screen.ExternalRes.W, screen.ExternalRes.H)
	love.graphics.setDefaultFilter("linear", "nearest")
	love.window.setVSync(false)
	love.window.setFullscreen(screen.isFullscreen)
end


local function CalculateScaling()
	screen.Scaling = {}
	screen.Scaling.X = screen.ExternalRes.W / screen.InternalRes.W
	screen.Scaling.Y = screen.ExternalRes.H / screen.InternalRes.H
end

-- Toggle fullscreen on / off
function screen.ToggleFullscreen()
	screen.isFullscreen = (not screen.isFullscreen)
	if screen.isFullscreen then
		screen.ExternalRes.W, screen.ExternalRes.H = love.window.getDesktopDimensions()
	else
		local ss = screen_settings
		SetExternalRes(ss.OUTER_RES_WIDTH, ss.OUTER_RES_RATIO)
	end
	CalculateScaling()
	screen.UpdateScreenOptions()
end


function screen.init()
	-- Set internal resolution and screen scaling settings
	local ss = screen_settings
	SetInternalRes(ss.INTERNAL_RES_WIDTH, ss.INTERNAL_RES_RATIO)
	SetExternalRes(ss.OUTER_RES_WIDTH, ss.OUTER_RES_RATIO)
	screen.isFullscreen = false
	CalculateScaling()
	screen.UpdateScreenOptions()
	return screen
end

return screen