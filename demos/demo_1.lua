available_palettes = require "lib/palettes"
kp = require "lib/utils/keypress"

-- import pico8 palette
PALETTE = available_palettes.PICO8

patch = {}
patch.methods = {}

-- Fill screen with background color
function patch.methods.fill_bg(x, y, r, g, b, a)
	r = PALETTE[1][1] / 255
	g = PALETTE[1][2] / 255
	b = PALETTE[1][3] / 255
	a = 1
	return r,g,b,a
end


-- Check if pixel in screen boundary
function patch.methods.inScreen(x, y)
	return (x > 0 and x < screen.InternalRes.W and y > 0 and y < screen.InternalRes.H)
end


function patch.patchControls()
	-- p = params[1]
	p = resources.parameters
	
	-- INCREASE
	if kp.isDown("up") then
		-- Param "a"
		if kp.isDown("a") then
			p[1].value = p[1].value + .1
		end
		-- Param "b"
		if kp.isDown("b") then
			p[2].value = p[2].value + .1
		end
	end
	
	-- DECREASE
	if kp.isDown("down") then
		-- Param "a"
		if kp.isDown("a") then
			p[1].value = p[1].value - .1
		end
		-- Param "b"
		if kp.isDown("b") then
			p[2].value = p[2].value - .1
		end
	end
	
	-- Hanger
	if kp.isDown("x") then
		hang = true
	else
		hang = false
	end
	
	-- Reset
	if kp.isDown("r") then
		p[1].value = 0.5
		p[2].value = 1
		timer.InitialTime = love.timer.getTime()
	end
	
	return p
end


function patch.init()
	patch.hang = false
	patch.palette = PALETTE

	patch.img = false
	patch.img_data = love.image.newImageData(screen.InternalRes.W, screen.InternalRes.H)
	
end


function patch.draw()
	-- clear picture
	if not hang then
		patch.img_data:mapPixel(patch.methods.fill_bg)
	end
	
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
			local px = w / 2 + (r - p[2].value) * x1
			local py = h / 2 + (r - p[1].value) * y1
			px = px + 8 * math.cos(r)
			-- calculate color position in lookup table
			local col = -r * 2 + math.atan(x1, y1)
			col = patch.palette[(math.floor(col) % 16) + 1]
			-- draw pixels on picture
			if patch.methods.inScreen(px, py) then
				patch.img_data:setPixel(px, py, col[1] / 255, col[2] / 255, col[3] / 255, 1)
			end
		end
	end
	
	-- render picture
	local img = love.graphics.newImage(patch.img_data)
	love.graphics.draw(img, 0, 0)
end


function patch.update()
	-- update parameters with patch controls
	patch.patchControls()
	return
end

return patch