local screen_settings = lovjRequire("lib/cfg/cfg_screen")
local cfg_patches = lovjRequire("lib/cfg/cfg_patches")

local Patch = {}

Patch.__index = Patch

-- Constructor
function Patch:new(p)
    p = p or {}
    setmetatable(p, self)
	p.shader = cfg_patches.defaultPatch
	p.hang = false
    return p
end


--- @public setCanvases (re)set canvases for patch
function Patch:setCanvases()
	self.canvases = {}
	if screen_settings.UPSCALE_MODE == screen_settings.LOW_RES then
		self.canvases.main = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
	else
		self.canvases.main = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
	end
	self.canvases.cmd = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
end


--- @public assignDefaultDraw assign patch.draw method to defaultDraw
function Patch:assignDefaultDraw()
    self.defaultDraw = self.draw
end


--- @public drawSetup setup the draw procedure
function Patch:drawSetup()
	-- reset color
	love.graphics.setColor(1,1,1,1)
	-- clear background picture
	if not self.hang then
		self.canvases.main:renderTo(love.graphics.clear)
	end
	-- select shader
	if cfg_shaders.enabled then self.shader = cfg_shaders.selectShader() end
	-- set canvas
	love.graphics.setCanvas(self.canvases.main)
end


--- @public drawExec execute the draw procedure
function Patch:drawExec()
	-- reset Canvas
	love.graphics.setCanvas()
	-- apply shader
	if cfg_shaders.enabled then cfg_shaders.applyShader(self.shader) end
	-- render picture
	love.graphics.draw(self.canvases.main, 0, 0, 0, screen.Scaling.X, screen.Scaling.Y)
	-- remove shader
	if cfg_shaders.enabled then cfg_shaders.applyShader() end
	-- draw cmd menu canvas on top
	love.graphics.draw(self.canvases.cmd, 0, 0, 0, screen.Scaling.X, screen.Scaling.Y)
end

return Patch