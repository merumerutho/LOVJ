palettes = require "lib/utils/palettes"
controls = require "lib/controls"
kp = require "lib/utils/keypress"

-- import palette
local PALETTE = palettes.TIC80

local ALPHA_MAGIC_NUM = 0.959--804--684

patch = {}

--- @private inScreen Check if pixel in screen boundary
local function inScreen(x, y)
	return (x > 0 and x < screen.InternalRes.W and y > 0 and y < screen.InternalRes.H)
end

--- @private patchCheckControls Checks the input controls locally
function patch.patchCheckControls()
	local p = resources.parameters
	-- reset
	if kp.isDown("r") then
		patch.reset()
	end
	-- warp
	if kp.isDown("w") then
		if kp.isDown("up") then p:set("_warpParameter", (p:get("_warpParameter") + 0.1)) end
		if kp.isDown("down") then p:set("_warpParameter", (p:get("_warpParameter") - 0.1)) end
	end
	if kp.isDown("k") then
		if kp.keypressOnAttack("up") then p:set("_segmentParameter", (p:get("_segmentParameter")+1)) end
		if kp.keypressOnAttack("down") then p:set("_segmentParameter", (p:get("_segmentParameter")-1)) end
	end
	-- hang
	if kp.keypressOnAttack("x") then
		patch.hang = not patch.hang
	end
	-- fallback to general controls callback
	controls.handleGeneralControls()
end


--- @private generatePoint Generate a random point in space
function patch.generatePoint(i)
	local point = {}
	point.x = screen.InternalRes.W / 2 + math.random(screen.InternalRes.W / 2) - math.random(screen.InternalRes.W / 2)
	point.y = screen.InternalRes.H / 2 + math.random(screen.InternalRes.H / 2) - math.random(screen.InternalRes.H / 2)
	point.dx = tonumber(point.x > screen.InternalRes.W / 2) or -1
	point.dy = tonumber(point.y > screen.InternalRes.H / 2) or -1
	point.i = i
	return point
end


--- @private updatePoints Updates points positions
function patch.updatePoints(l)
	local p = resources.parameters
	for k, v in pairs(l) do
		v.y = v.y + math.random() * math.cos(2 * math.pi * (timer.T / (p:getByIdx(2) * 3) + v.i / #l)) + v.dy * (math.cos(math.pi * timer.T * 2)) ^ 3
		v.x = v.x + math.random() * math.sin(2 * math.pi * (timer.T / (p:getByIdx(1) * 3) + v.i / #l)) + v.dx * (math.sin(math.pi * timer.T * 2)) ^ 3
	end
end

--- @private init_params Initialize parameters for this patch
local function init_params()
	p = resources.parameters

	-- Initialize parameters
	p:setName(1, "speed_x") 			p:set("speed_x", 20)
	p:setName(2, "speed_y") 			p:set("speed_y", 30)
	p:setName(3, "selected_shader") 	p:set("selected_shader", 0)

	-- trail color
	p:setName(4, "trail_color_red")		p:set("trail_color_red", 1)
	p:setName(5, "trail_color_green")	p:set("trail_color_green", 0.75)
	p:setName(6, "trail_color_blue")	p:set("trail_color_blue", 0.85)

	-- shader parameters
	p:setName(7, "_warpParameter")		p:set("_warpParameter", 2.)
	p:setName(8, "_segmentParameter")	p:set("_segmentParameter", 4.)
end

--- @public init Initializes the patch
function patch.init()
	patch.hang = false
	patch.palette = PALETTE
	patch.nPoints = 3 + math.random(32)
	patch.points = {}
	for i = 1, patch.nPoints do
		table.insert(patch.points, patch.generatePoint(i))
	end
	-- canvases
	patch.canvases = {}
	patch.canvases.main = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
	patch.canvases.trail = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
	-- move this somewhere else?
	patch.shader_trail = nil

	init_params()
end

function patch.reset()
	-- regenerate points
	patch.nPoints = 3 + math.random(32)
	patch.points = {}
	for i = 1, patch.nPoints do
		table.insert(patch.points, patch.generatePoint(i))
	end
end

--- @public draw Draws the content of the patch
function patch.draw()
	local p = resources.parameters

	-- clean trail buffer
	patch.canvases.trail:renderTo(love.graphics.clear)

	-- if hanging, copy content of main buffer onto trail buffer applying trail shader
	if patch.hang and cfg_shaders.enabled then
		patch.shader_trail = love.graphics.newShader(shaders.trail) -- set/update trail shader
		patch.shader_trail:send("_trailColor", {
												p:get("trail_color_red"),
												p:get("trail_color_green"),
												p:get("trail_color_blue"),
												ALPHA_MAGIC_NUM
												})
		patch.canvases.trail:renderTo(
			function()
				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.setShader(patch.shader_trail) -- apply shader
				love.graphics.draw(patch.canvases.main, -- draw content of main buffer onto trail buffer
									0, 0, 0, (1 / screen.Scaling.X), (1 / screen.Scaling.Y))
				love.graphics.setShader() -- remove shader
			end)
	end
	-- copy back from trail buffer onto main
	patch.canvases.main:renderTo(love.graphics.clear)
	patch.canvases.main:renderTo(function()
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(patch.canvases.trail,  -- draw content of main buffer onto trail buffer
							0, 0, 0, (1 / screen.Scaling.X), (1 / screen.Scaling.Y))
		end)

	-- update points positions
	patch.updatePoints(patch.points)

	-- select shader
	local shader
	if cfg_shaders.enabled then shader = cfg_shaders.selectShader() end

	-- set canvas
	love.graphics.setCanvas(patch.canvases.main)

	-- if inside screen, draw points
	for k, pix in pairs(patch.points) do
		if inScreen(pix.x, pix.y) then
			love.graphics.setColor({1, 1, 1, 1})
			love.graphics.points(pix.x, pix.y)
		end
	end

	-- draw line
	for k, pix in pairs(patch.points) do
		local po = patch.points
		if k==#(patch.points) then
			love.graphics.line(po[k].x, po[k].y, po[1].x, po[1].y)
		else
			love.graphics.line(po[k].x, po[k].y, po[k + 1].x, po[k + 1].y)
		end
	end

	-- remove canvas
	love.graphics.setCanvas()
	-- apply shader
	if cfg_shaders.enabled then cfg_shaders.applyShader(shader) end
	-- render graphics
	love.graphics.draw(patch.canvases.main, 0, 0, 0, (1 / screen.Scaling.X), (1 / screen.Scaling.Y))
	-- remove shader
	if cfg_shaders.enabled then cfg_shaders.applyShader() end

end

--- @public update Updates the patch
function patch.update()
	-- update parameters with local patch controls
	params = patch.patchCheckControls()
end

--- @public defaultDraw assigned to draw method by default
patch.defaultDraw = patch.draw

return patch