palettes = require "lib/utils/palettes"
kp = require "lib/utils/keypress"

-- import pico8 palette
local PALETTE = palettes.PICO8

patch = {}
patch.methods = {}

-- Fill screen with background color
local function fill_bg(x, y, r, g, b, a)
	local color = palettes.getColor(PALETTE, 1)
	r, g, b = color[1], color[2], color[3]
	a = 1
	return r,g,b,a
end

--- @private patch.methods.in Check if pixel in screen boundary
local function inScreen(x, y)
	return (x > 0 and x < screen.InternalRes.W and y > 0 and y < screen.InternalRes.H)
end


local function init_params()
	p = resources.parameters
	p:setName(1, "a")			p:set("a", 0.5)
	p:setName(2, "b")			p:set("b", 1)
end


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
	
	-- Reset
	if kp.isDown("r") then
		init_params()
		timer.InitialTime = love.timer.getTime()
	end
end

--- @public init init routine
function patch.init()
	patch.hang = false

	patch.img = false
	patch.img_data = love.image.newImageData(screen.InternalRes.W, screen.InternalRes.H)

	init_params()
end

--- @public patch.draw draw routine
function patch.draw()

	love.graphics.setColor(1,1,1,1)
	-- clear background picture
	if not hang then
		patch.img_data:mapPixel(fill_bg)
	end

	local shader
	if cfg_shaders.enabled then shader = cfg_shaders.selectShader() end

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
			-- draw pixels on picture
			if inScreen(px, py) then
				patch.img_data:setPixel(px, py, col[1], col[2], col[3], 1)
			end
		end
	end

	-- apply shader
	if cfg_shaders.enabled then cfg_shaders.applyShader(shader) end
	-- render picture
	local img = love.graphics.newImage(patch.img_data)
	love.graphics.draw(img, 0, 0)

	-- remove shader
	if cfg_shaders.enabled then cfg_shaders.applyShader() end
end


function patch.update()
	-- apply keyboard patch controls
	if not cmd.isOpen then patch.patchControls() end
	return
end

--- @public defaultDraw assigned to draw method by default
patch.defaultDraw = patch.draw

return patch