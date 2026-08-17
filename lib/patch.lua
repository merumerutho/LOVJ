-- patch.lua
--
-- Patch class including common elements shared among all patches
--

local cfgScreen = lovjRequire("cfg/cfg_screen")
local cfgShaders = lovjRequire("cfg/cfg_shaders")
local cfg_patches = lovjRequire("cfg/cfg_patches")

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
	local first = cfgShaders.PostProcessShaders[1]
	local defaultName = first and first.name or "00_default"
	self.CurrentShaders = {}
	for i = 1, 10 do
		self.CurrentShaders[i] = {name = defaultName, object = nil}
	end
end


--- @public releaseCanvases explicitly free this patch's GPU canvases (base, patch-specific
--- and the lazy shader chain) instead of waiting for an incidental GC cycle. Called on
--- every setCanvases reallocation and on patch switch; canvases must not be referenced
--- after this (the next setCanvases rebuilds them).
local function releaseCanvasTree(v)
	if type(v) == "userdata" and v.typeOf and v:typeOf("Canvas") then
		v:release()
	elseif type(v) == "table" then
		for _, c in pairs(v) do
			releaseCanvasTree(c)
		end
	end
end

function Patch:releaseCanvases()
	if not self.canvases then return end
	for _, v in pairs(self.canvases) do
		releaseCanvasTree(v)
	end
	self.canvases = nil
end


--- @public setCanvases (re)set canvases for patch
function Patch:setCanvases()
	self:releaseCanvases()
	self.canvases = {}
	self.canvases.ShaderCanvases = {}
	self.canvases.FeedbackCanvases = {}  -- ping-pong pairs for stateful PP layers
	self.canvases.main = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
end


function Patch:init(slot, globals, shaderext)
	self.slot = slot
	-- Preserve existing globals/shaderext if caller didn't pass them
	-- (e.g. internal reset calls like patch.init(patch.slot))
	globals = globals or (self.resources and self.resources.globals)
	shaderext = shaderext or (self.resources and self.resources.shaderext)
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

	love.graphics.setCanvas(self.canvases.main)
end


--- @public drawExec Draw procedure shared across all patches
function Patch:drawExec(hang)
	hang = false or hang
	love.graphics.setColor(1, 1, 1, 1)

	if cfgShaders.enabled then
		local lastCanvas = self.canvases.main
		local sc = self.canvases.ShaderCanvases
		local fbl = self.canvases.FeedbackCanvases
		for i = 1, #self.CurrentShaders do
			local cur = self.CurrentShaders[i]
			if cur.name ~= "00_default" and cur.object then
				local dstCanvas
				if cur.object:hasUniform("_prev") then
					-- Stateful pass: a shader declaring `extern Image _prev` gets its
					-- own previous OUTPUT as a texture (trails, freeze, persistence).
					-- Ping-pong pair: read the front canvas, write the back, flip.
					-- History resets when the layer's shader selection changes.
					local fb = fbl[i]
					if not fb or fb.name ~= cur.name then
						if fb then releaseCanvasTree(fb) end
						fb = { love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H),
						       love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H),
						       front = 1, name = cur.name }
						for k = 1, 2 do  -- first frame must read silence, not garbage
							love.graphics.setCanvas(fb[k])
							love.graphics.clear(0, 0, 0, 1)
						end
						fbl[i] = fb
					end
					cur.object:send("_prev", fb[fb.front])
					dstCanvas = fb[3 - fb.front]
					fb.front = 3 - fb.front
				else
					if not sc[i] then
						sc[i] = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
					end
					dstCanvas = sc[i]
				end
				love.graphics.setCanvas(dstCanvas)
				love.graphics.setShader(cur.object)
				love.graphics.draw(lastCanvas)
				love.graphics.setShader()
				if not hang then
					love.graphics.setCanvas(lastCanvas)
					love.graphics.clear(0, 0, 0, 0)
				end
				lastCanvas = dstCanvas
			end
		end
		return lastCanvas
	else
		return self.canvases.main
	end
end

--- @public mainUpdate Update procedures shared across all patches.
--- patchControls() is expected to mutate self.resources in place (via
--- p:set / g:set etc.) — any return value is ignored. The previous
--- design reassigned self.resources from the return, which silently
--- nil'd the resources for any demo that forgot to return them.
function Patch:mainUpdate()
	if cfg_patches.selectedPatch == self.slot then
		self:patchControls()
	end
end

return Patch