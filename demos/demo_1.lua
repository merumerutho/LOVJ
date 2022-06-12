available_palettes = require "lib/palettes"
-- import pico8 palette
PALETTE = available_palettes.PICO8

patch = {}
patch.methods = {}

-- Fill screen with background color
function patch.methods.fill_bg(x, y, r, g, b, a)
	r = PALETTE[1][1]/255
	g = PALETTE[1][2]/255
	b = PALETTE[1][3]/255
	a=1
	return r,g,b,a
end


-- Check if pixel in screen boundary
function patch.methods.inScreen(x, y)
	return (x>0 and x< screen.inner.w and y > 0 and y < screen.inner.h)
end


function patch.patchControls()
	p = params[1]
	
	-- INCREASE
	if love.keyboard.isDown("up") then
		-- Param "a"
		if love.keyboard.isDown("a") then
			p[1] = p[1] + .1
		end
		-- Param "b"
		if love.keyboard.isDown("b") then
			p[2] = p[2] + .1
		end
	end
	
	-- DECREASE
	if love.keyboard.isDown("down") then
		-- Param "a"
		if love.keyboard.isDown("a") then
			p[1] = p[1] - .1 
		end
		-- Param "b"
		if love.keyboard.isDown("b") then
			p[2] = p[2] - .1
		end
	end
	
	-- Hanger
	if love.keyboard.isDown("x") then
		hang = true
	else
		hang = false
	end
	
	-- Reset
	if love.keyboard.isDown("r") then
		p[1]=0.5
		p[2]=1
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
	p = params[1]

	-- clear picture
	if not hang then
		patch.img_data:mapPixel(patch.methods.fill_bg)
	end
	
	-- draw picture
    for x = -20,20,.25 do
		for y=-20,20,.25 do
			-- calculate oscillating radius
			local r = (x*x+y*y) + 10*math.sin(timer.t/2.5)
			-- apply time-dependent rotation
			local x1 = x*math.cos(timer.t) - y*math.sin(timer.t)
			local y1 = x*math.sin(timer.t) + y*math.cos(timer.t)
			-- calculate pixel position to draw
			local w, h = screen.inner.w, screen.inner.h
			local px = w/2 + (r-p[2])*x1
			local py = h/2 + (r-p[1])*y1
			px = px + 8*math.cos(r)
			-- calculate color position in lookup table
			local col = -r*2 + math.atan(x1,y1)
			col = patch.palette[(math.floor(col) % 16) +1]
			-- draw pixels on picture
			if patch.methods.inScreen(px,py) then
				patch.img_data:setPixel(px, py, col[1]/255, col[2]/255, col[3]/255, 1)
			end
		end
	end
	
	-- render picture
	local img = love.graphics.newImage(patch.img_data)
	love.graphics.draw(img,0,20)
end


function patch.update()
	-- update parameters with patch controls
	patch.patchControls()
	return
end

return patch