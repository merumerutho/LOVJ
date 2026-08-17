-- screen.lua
--
-- Handle screen graphical settings

local cfgScreen = lovjRequire("cfg/cfg_screen")
local cfgSpout = lovjRequire("cfg/cfg_spout")

local screen = {}

---@private SetInternalRes
--- assign internal resolution to be (w by h)
local function SetInternalRes(w, h)
	screen.InternalRes = {}
	screen.InternalRes.W = w
	screen.InternalRes.H = h
	screen.InternalRes.R = w/h
end

--- @private SetExternalRes
--- assign external resolution to be (w by h)
local function SetExternalRes(w, h)
	screen.ExternalRes = {}
	screen.ExternalRes.W = w
	screen.ExternalRes.H = h
	screen.ExternalRes.R = w/h
end

--- @public updateScreenOptions Update screen options to defaults
function screen.updateScreenOptions()
	love.window.setMode(screen.ExternalRes.W, screen.ExternalRes.H)
	love.graphics.setDefaultFilter("linear", "nearest")
	love.window.setVSync(cfgScreen.VSYNC and 1 or 0)
	love.window.setFullscreen(screen.isFullscreen, "desktop")
	cfgSpout.updateCanvases()
end

--- @private calculateScaling calculate scaling proportions based on internal and external resolution
local function calculateScaling()
	screen.Scaling = {}
  
	-- set upscaling mode
	screen.Scaling.Upscale = cfgScreen.UPSCALE_MODE
  
	-- Set Internal Resolution. RENDER_SCALE is a power-of-2 divisor (Hypno-style
	-- render scaling): trades pixels for shader headroom on constrained machines.
	local rscale = math.max(1, cfgScreen.RENDER_SCALE or 1)
	if screen.isUpscalingHiRes() then
		SetInternalRes(math.floor(cfgScreen.WINDOW_WIDTH / rscale), math.floor(cfgScreen.WINDOW_HEIGHT / rscale))
	else
		SetInternalRes(math.floor(cfgScreen.INTERNAL_RES_WIDTH / rscale), math.floor(cfgScreen.INTERNAL_RES_HEIGHT / rscale))
	end

	screen.Scaling.WindowRatioX = screen.ExternalRes.W / screen.InternalRes.W
	screen.Scaling.WindowRatioY = screen.ExternalRes.H / screen.InternalRes.H

	screen.Scaling.SpoutRatioX = cfgScreen.WINDOW_WIDTH / screen.InternalRes.W
	screen.Scaling.SpoutRatioY = cfgScreen.WINDOW_HEIGHT / screen.InternalRes.H

end

--- @public toggleFullscreen toggle fullscreen option on/off
function screen.toggleFullscreen()
	screen.isFullscreen = (not screen.isFullscreen)
	if screen.isFullscreen then
		screen.ExternalRes.W, screen.ExternalRes.H = love.window.getDesktopDimensions()
	else
		SetExternalRes(cfgScreen.WINDOW_WIDTH, cfgScreen.WINDOW_HEIGHT)
	end
  
	calculateScaling()
	screen.updateScreenOptions()
	for i=1,#patchSlots do
		patchSlots[i].patch:setCanvases()
	end
  
end

--- @public changeUpscaling changes upscaling mode (lowres = 0, highres = 1)
function screen.changeUpscaling()
	if cfgScreen.UPSCALE_LOCKED then
		logInfo("changeUpscaling refused: UPSCALE_LOCKED on this machine profile")
		return
	end
	cfgScreen.UPSCALE_MODE = (1 - cfgScreen.UPSCALE_MODE)  -- apply inversion
	calculateScaling()
	screen.updateScreenOptions()
	for i=1,#patchSlots do
		patchSlots[i].patch:setCanvases()
	end
end

--- @public init Initialize screen, setting resolutions, calculating scaling and updating options
function screen.init()
	-- Set internal resolution and screen scaling settings
	SetInternalRes(cfgScreen.INTERNAL_RES_WIDTH, cfgScreen.INTERNAL_RES_HEIGHT)
	SetExternalRes(cfgScreen.WINDOW_WIDTH, cfgScreen.WINDOW_HEIGHT)
	screen.isFullscreen = (cfgScreen.FULLSCREEN_AT_BOOT == true)
	if screen.isFullscreen then
		SetExternalRes(love.window.getDesktopDimensions())
	end
	calculateScaling()
	screen.updateScreenOptions()
	return screen
end

--- @public isUpscalingHiRes return whether the upscaling mode is hi-res or lo-res
function screen.isUpscalingHiRes()
	return (screen.Scaling.Upscale == cfgScreen.HIGH_RES)
end

return screen