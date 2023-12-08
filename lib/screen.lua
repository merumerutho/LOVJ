-- screen.lua
--
-- Handle screen graphical settings

local cfgScreen = require("lib/cfg/cfg_screen")

local screen = {}

---@private SetInternalRes
--- assign internal resolution to be (w by h), where h is calculated as w/r
local function SetInternalRes(w, r)
	screen.InternalRes = {}
	screen.InternalRes.W = w
	screen.InternalRes.R = 1/r
	screen.InternalRes.H = math.floor(w/r)
end

--- @private SetExternalRes
--- assign external resolution to be (w by h), where h is calculated as w/r
local function SetExternalRes(w, r)
	screen.ExternalRes = {}
	screen.ExternalRes.W = w
	screen.ExternalRes.R = 1/r
	screen.ExternalRes.H = math.floor(w/r)
end

--- @public updateScreenOptions Update screen options to defaults
function screen.updateScreenOptions()
	love.window.setMode(screen.ExternalRes.W, screen.ExternalRes.H)
	love.graphics.setDefaultFilter("linear", "nearest")
	love.window.setVSync(true)
	love.window.setFullscreen(screen.isFullscreen)
end

--- @private calculateScaling calculate scaling proportions based on internal and external resolution
local function calculateScaling()
	screen.Scaling = {}
	screen.Scaling.RatioX = screen.ExternalRes.W / screen.InternalRes.W
	screen.Scaling.RatioY = screen.ExternalRes.H / screen.InternalRes.H

	-- set upscaling mode
	screen.Scaling.Upscale = cfgScreen.UPSCALE_MODE

	-- depending on upscaling mode, set x and y for scaling to "r" or "1/r" => (^1 or ^-1)
	screen.Scaling.X = screen.Scaling.RatioX ^ (1-2*screen.Scaling.Upscale)
	screen.Scaling.Y = screen.Scaling.RatioY ^ (1-2*screen.Scaling.Upscale)

end

--- @public toggleFullscreen toggle fullscreen option on/off
function screen.toggleFullscreen()
	screen.isFullscreen = (not screen.isFullscreen)
	if screen.isFullscreen then
		screen.ExternalRes.W, screen.ExternalRes.H = love.window.getDesktopDimensions()
	else
		SetExternalRes(cfgScreen.OUTER_RES_WIDTH, cfgScreen.OUTER_RES_RATIO)
	end
	calculateScaling()
	screen.updateScreenOptions()
	for i=1,#patchSlots do
		patchSlots[i].patch:setCanvases()
	end
		
end

--- @public changeUpscaling changes upscaling mode (lowres = 0, highres = 1)
function screen.changeUpscaling()
	cfgScreen.UPSCALE_MODE = math.abs(cfgScreen.UPSCALE_MODE - 1)  -- boolean inversion
	-- calculate new scaling
	calculateScaling()
	-- reset canvases
	for i=1,#patchSlots do
		patchSlots[i].patch:setCanvases()
	end
end

--- @public init Initialize screen, setting resolutions, calculating scaling and updating options
function screen.init()
	-- Set internal resolution and screen scaling settings
	SetInternalRes(cfgScreen.INTERNAL_RES_WIDTH, cfgScreen.INTERNAL_RES_RATIO)
	SetExternalRes(cfgScreen.OUTER_RES_WIDTH, cfgScreen.OUTER_RES_RATIO)
	screen.isFullscreen = false
	calculateScaling()
	screen.updateScreenOptions()
	return screen
end

--- @public isUpscalingHiRes return whether the upscaling mode is hi-res or lo-res
function screen.isUpscalingHiRes()
	return (screen.Scaling.Upscale == cfgScreen.HIGH_RES)
end

return screen