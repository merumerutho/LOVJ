-- screen.lua
--
-- Graphical settings
local screen_settings = require "lib/cfg/cfg_screen"

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


function screen.updateScreenOptions()
	love.window.setMode(screen.ExternalRes.W, screen.ExternalRes.H)
	love.graphics.setDefaultFilter("linear", "nearest")
	love.window.setVSync(false)
	love.window.setFullscreen(screen.isFullscreen)
end


local function calculateScaling()
	screen.Scaling = {}
	screen.Scaling.RatioX = screen.ExternalRes.W / screen.InternalRes.W
	screen.Scaling.RatioY = screen.ExternalRes.H / screen.InternalRes.H

	-- set upscaling mode
	screen.Scaling.Upscale = screen_settings.UPSCALE_MODE

	-- depending on upscaling mode, set x and y for scaling to "r" or "1/r" => (^1 or ^-1)
	screen.Scaling.X = screen.Scaling.RatioX ^ (1-2*screen.Scaling.Upscale)
	screen.Scaling.Y = screen.Scaling.RatioY ^ (1-2*screen.Scaling.Upscale)

end

-- Toggle fullscreen on / off
function screen.toggleFullscreen()
	screen.isFullscreen = (not screen.isFullscreen)
	if screen.isFullscreen then
		screen.ExternalRes.W, screen.ExternalRes.H = love.window.getDesktopDimensions()
	else
		local ss = screen_settings
		SetExternalRes(ss.OUTER_RES_WIDTH, ss.OUTER_RES_RATIO)
	end
	calculateScaling()
	screen.updateScreenOptions()
	patch.init()
end

--- @function changeUpscaling changes upscaling mode (lowres = 0, highres = 1)
function screen.changeUpscaling()
	screen_settings.UPSCALE_MODE = math.abs(screen_settings.UPSCALE_MODE - 1)  -- boolean inversion
	-- calculate new scaling
	calculateScaling()
	-- reset canvases
	patch:setCanvases()
end


function screen.init()
	-- Set internal resolution and screen scaling settings
	local ss = screen_settings
	SetInternalRes(ss.INTERNAL_RES_WIDTH, ss.INTERNAL_RES_RATIO)
	SetExternalRes(ss.OUTER_RES_WIDTH, ss.OUTER_RES_RATIO)
	screen.isFullscreen = false
	calculateScaling()
	screen.updateScreenOptions()
	return screen
end


function screen.isUpscalingHiRes()
	return (screen.Scaling.Upscale == screen_settings.HIGH_RES)
end

return screen