-- patch.lua
--
-- Patch class including common elements shared among all patches
--

local cfgScreen = lovjRequire("cfg/cfg_screen")
local cfgShaders = lovjRequire("cfg/cfg_shaders")

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
	local default = table.getValueByName("default", cfgShaders.PostProcessShaders)
	self.CurrentShaders = { {name = default, object = nil},
							{name = default, object = nil},
							{name = default, object = nil} }
end


--- @public setCanvases (re)set canvases for patch
function Patch:setCanvases()
	self.canvases = {}
	self.canvases.ShaderCanvases = {}

	local resW, resH
	-- Calculate appropriate size
	resW, resH = screen.InternalRes.W, screen.InternalRes.H
    
	-- Generate canvases with calculated size
	self.canvases.main = love.graphics.newCanvas(resW, resH)
	for i = 1, #self.CurrentShaders do
		table.insert(self.canvases.ShaderCanvases, love.graphics.newCanvas(resW, resH))
	end
end


function Patch:init(slot, globals, shaderext)
	self.slot = slot
	self.resources = ResourceList:new(globals, shaderext)
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
	love.graphics.setColor(1, 1, 1, 1)

	cfgShaders.updateTime(self.slot)

	-- select shaders
	if cfgShaders.enabled then
		for i = 1, #self.CurrentShaders do
			self.CurrentShaders[i] = cfgShaders.selectPPShader(self.slot, i, self.CurrentShaders[i])
		end
	end

	love.graphics.setCanvas(self.canvases.ShaderCanvases[#self.CurrentShaders])
	-- set canvas
	love.graphics.setCanvas(self.canvases.main)
end


--- @public drawExec Draw procedure shared across all patches
function Patch:drawExec(hang)
	hang = false or hang
	love.graphics.setColor(1, 1, 1, 1)  -- Reset color

	-- Cycle over post process shaders applying them on respective canvases
	if cfgShaders.enabled then
		for i = 1, #self.CurrentShaders do
			local srcCanvas, dstCanvas
			if i == 1 then
				srcCanvas, dstCanvas = self.canvases.main, self.canvases.ShaderCanvases[1]
			else
				srcCanvas, dstCanvas = self.canvases.ShaderCanvases[i-1], self.canvases.ShaderCanvases[i]      
			end
			-- Set canvas, apply shader, draw and then remove shader
			love.graphics.setCanvas(dstCanvas)
			love.graphics.setShader(self.CurrentShaders[i].object)
			love.graphics.draw(srcCanvas)
			love.graphics.setShader()
			love.graphics.setCanvas(srcCanvas)
            -- clear if not hanging
			if not hang then
				love.graphics.clear(0, 0, 0, 0)
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
		-- only handle controls if patch is selected
		if cfgControls.selectedPatch == self.slot then
			self.resources.parameters,
			self.resources.graphics,
			self.resources.globals = self.patchControls()
		end
end

return Patch