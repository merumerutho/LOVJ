-- patch.lua
--
-- Patch class including common elements shared among all patches
--

local screen_settings = lovjRequire("lib/cfg/cfg_screen")
local cfg_patches = lovjRequire("lib/cfg/cfg_patches")
local cfg_shaders = lovjRequire("lib/cfg/cfg_shaders")
local resources = lovjRequire("lib/resources")
local cmd = lovjRequire("lib/cmdmenu")

local Patch = {}

Patch.__index = Patch

-- Constructor
function Patch:new(p)
    local p = p or {}
    setmetatable(p, self)
    return p
end


--- @public setShaders set-up shader list for patch with default shader
function Patch:setShaders()
	local default = table.getValueByName("default", cfg_shaders.PostProcessShaders)
	self.CurrentShaders = { {name = default, object = nil},
							{name = default, object = nil},
							{name = default, object = nil} }
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
	for i = 1, #self.CurrentShaders do
		table.insert(self.canvases.ShaderCanvases, love.graphics.newCanvas(sizeX, sizeY))
	end
end


function Patch:init(slot)
	self.slot = slot
	self.resources = ResourceList:new()
	self:setShaders()
	self:assignDefaultDraw()
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
		for i = 1, #self.CurrentShaders do
			self.CurrentShaders[i] = cfg_shaders.selectPPShader(self.slot, i, self.CurrentShaders[i])
		end
	end

	love.graphics.setCanvas(self.canvases.ShaderCanvases[#self.CurrentShaders])
	love.graphics.clear(0,0,0,0)
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
		for i = 1, #self.CurrentShaders do
			local srcCanvas, dstCanvas
			if i == 1 then srcCanvas, dstCanvas = self.canvases.main, self.canvases.ShaderCanvases[1]
			else srcCanvas, dstCanvas = self.canvases.ShaderCanvases[i-1], self.canvases.ShaderCanvases[i] end
			-- Set canvas, apply shader, draw and then remove shader
			love.graphics.setCanvas(dstCanvas)
			love.graphics.setShader(self.CurrentShaders[i].object)
			love.graphics.draw(srcCanvas, 0, 0, 0, scalingX, scalingY)
			love.graphics.setShader()
			love.graphics.setCanvas(srcCanvas)
            -- clear if not hanging
			if not hang then
				love.graphics.clear(0,0,0,0)
			end
		end
		-- return last shader canvas
		return self.canvases.ShaderCanvases[#self.CurrentShaders]
	else
		-- If shaders disabled, return main
		return self.canvases.main
	end
end

--- @public mainUpdate Update procedures shared across all patches
function Patch:mainUpdate()
	-- apply keyboard patch controls
	if not cmd.isOpen then
		-- only handle controls if patch is selected
		if controls.selectedPatch == self.slot then
			self.resources.parameters,
			self.resources.graphics,
			self.resources.globals = self.patchControls()
		end
	end
end

return Patch