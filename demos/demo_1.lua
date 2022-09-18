local Patch = require "lib/patch"
local palettes = require "lib/utils/palettes"
local kp = require "lib/utils/keypress"

-- import pico8 palette
local PALETTE = palettes.PICO8

patch = Patch:new()

--- @private inScreen Check if pixel in screen boundary
local function inScreen(x, y)
	return (x > 0 and x < screen.InternalRes.W and y > 0 and y < screen.InternalRes.H)
end


--- @private init_params initialize parameters for this patch
local function init_params()
	p = resources.parameters
	p:setName(1, "a")			p:set("a", 0.5)
	p:setName(2, "b")			p:set("b", 1)
end

--- @private patchControls handle controls for current patch
function patch.patchControls()
	p = resources.parameters
	
	-- INCREASE
	if kp.isDown("up") then
		-- Param "a"
		if kp.isDown("a") then p:set("a", p:get("a") + .1) end
		-- Param "b"
		if kp.isDown("b") then p:set("b", p:get("b") + .1) end
	end
	
	-- DECREASE
	if kp.isDown("down") then
		-- Param "a"
		if kp.isDown("a") then p:set("a", p:get("a") - .1) end
		-- Param "b"
		if kp.isDown("b") then p:set("b", p:get("b") - .1) end
	end
	
	-- Hanger
	if kp.isDown("x") then hang = true else hang = false end
end

--- @public init init routine
function patch.init()
	patch.hang = false
	patch:setCanvases()
	init_params()
end

--- @public patch.draw draw routine
function patch.draw()

	love.graphics.setColor(1,1,1,1)
	-- clear background picture
	if not hang then
		patch.canvases.main:renderTo(love.graphics.clear)
	end

	local shader
	if cfg_shaders.enabled then shader = cfg_shaders.selectShader() end

	-- set canvas
	love.graphics.setCanvas(patch.canvases.main)

	local points_list = {}
	-- draw picture
    for x = -20, 20, .25 do
		for y = -20, 20, .25 do
			-- calculate oscillating radius
			local r = ((x * x) + (y * y)) + 10 * math.sin(timer.T / 2.5)
			-- apply time-dependent rotation
			local x1 = x * math.cos(timer.T) - y * math.sin(timer.T)
			local y1 = x * math.sin(timer.T) + y * math.cos(timer.T)
			-- calculate pixel position to draw
			local w, h = screen.InternalRes.W, screen.InternalRes.H
			local px = w / 2 + (r - p:get("b")) * x1
			local py = h / 2 + (r - p:get("a")) * y1
			px = px + 8 * math.cos(r)
			-- calculate color position in lookup table
			local col = -r * 2 + math.atan(x1, y1)
			col = palettes.getColor(PALETTE, (math.floor(col) % 16) + 1)
			-- add to list of points to draw
			if inScreen(px, py) then
				table.insert(points_list, {px, py, col[1], col[2], col[3], 1})
			end
		end
	end
	-- draw pixels
	love.graphics.points(points_list)

	-- reset Canvas
	love.graphics.setCanvas()
	-- apply shader
	if cfg_shaders.enabled then cfg_shaders.applyShader(shader) end
	-- render picture
	love.graphics.draw(patch.canvases.main, 0, 0, 0, screen.Scaling.X, screen.Scaling.Y)
	-- remove shader
	if cfg_shaders.enabled then cfg_shaders.applyShader() end
end


function patch.update()
	-- apply keyboard patch controls
	if not cmd.isOpen then patch.patchControls() end
	return
end



return patch