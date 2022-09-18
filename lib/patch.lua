Patch = {}

Patch.__index = Patch

-- Constructor
function Patch:new(p)
    p = p or {}
    setmetatable(p, self)

    -- assign defaultDraw
    p.defaultDraw = p.draw

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
end


return Patch