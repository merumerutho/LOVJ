-- patch.lua
--
-- Patch class including common elements shared among all patches
--

local screen_settings = lovjRequire("lib/cfg/cfg_screen")
local cfg_patches = lovjRequire("lib/cfg/cfg_patches")
local cfg_shaders = lovjRequire("lib/cfg/cfg_shaders")
local cmd = lovjRequire("lib/cmdmenu")

local Patch = {}

Patch.__index = Patch

-- Constructor
function Patch:new(p)
    local p = p or {}
    setmetatable(p, self)
    return p
end


--- @public setCanvases (re)set canvases for patch
function Patch:setCanvases()
	self.canvases = {}
	self.canvases.ShaderCanvases = {}

	local sizeX, sizeY
	-- Calculate appropriate size
	if screen_settings.UPSCALE_MODE == screen_settings.LOW_RES then
		sizeX, sizeY = screen.InternalRes.W, screen.InternalRes.H
	else
		sizeX, sizeY = screen.ExternalRes.W, screen.ExternalRes.H
	end
    
	-- Generate canvases with calculated size
	self.canvases.main = love.graphics.newCanvas(sizeX, sizeY)
	self.canvases.cmd = love.graphics.newCanvas(sizeX, sizeY)
	for i = 1, #cfg_shaders.CurrentShaders do
		table.insert(self.canvases.ShaderCanvases, love.graphics.newCanvas(sizeX, sizeY))
	end

end


--- @public assignDefaultDraw assign patch.draw method to defaultDraw
function Patch:assignDefaultDraw()
    self.defaultDraw = self.draw
end


--- @public drawSetup Draw setup shared across all patches
function Patch:drawSetup()
	-- reset color
	love.graphics.setColor(1,1,1,1)

	-- select shaders
	if cfg_shaders.enabled then
		for i = 1, #cfg_shaders.CurrentShaders do
			cfg_shaders.CurrentShaders[i] = cfg_shaders.selectPPShader(i)
		end
	end

	-- set canvas
	love.graphics.setCanvas(self.canvases.main)
end


--- @public drawExec Draw procedure shared across all patches
function Patch:drawExec(hang)
	hang = false or hang
	-- Reset color
	love.graphics.setColor(1,1,1,1)
	-- Calculate scaling for post process shaders
	local scalingX, scalingY
	if screen_settings.UPSCALE_MODE == screen_settings.LOW_RES then
		scalingX, scalingY = 1,1
	else
		scalingX, scalingY = screen.Scaling.X, screen.Scaling.Y
	end

	-- Cycle amd apply post process shaders over relative canvases
	if cfg_shaders.enabled then
		for i = 1, #cfg_shaders.CurrentShaders do
			local srcCanvas, dstCanvas
			if i == 1 then srcCanvas, dstCanvas = self.canvases.main, self.canvases.ShaderCanvases[1]
			else srcCanvas, dstCanvas = self.canvases.ShaderCanvases[i-1], self.canvases.ShaderCanvases[i] end
			-- Set canvas, apply shader, draw and then remove shader
			love.graphics.setCanvas(dstCanvas)
			cfg_shaders.applyShader(cfg_shaders.CurrentShaders[i])
			love.graphics.draw(srcCanvas, 0, 0, 0, scalingX, scalingY)
			love.graphics.setCanvas(srcCanvas)
            -- clear if not hanging
			if not hang then
				love.graphics.clear(0,0,0,1)
			end
		end
		-- Draw final layer on default canvas
		love.graphics.setCanvas()
		cfg_shaders.applyShader()

		love.graphics.draw(self.canvases.ShaderCanvases[#cfg_shaders.CurrentShaders], 0, 0, 0, screen.Scaling.X, screen.Scaling.Y)
	else
		-- If shaders disabled, draw normally on default canvas
		love.graphics.setCanvas()
		love.graphics.draw(self.canvases.main, 0, 0, 0, screen.Scaling.X, screen.Scaling.Y)
	end
	-- draw cmd menu canvas on top
	love.graphics.draw(self.canvases.cmd, 0, 0, 0, screen.Scaling.X, screen.Scaling.Y)
end

--- @public mainUpdate Update procedures shared across all patches
function Patch:mainUpdate()
	-- apply keyboard patch controls
	if not cmd.isOpen then self.patchControls() end
end

return Patch