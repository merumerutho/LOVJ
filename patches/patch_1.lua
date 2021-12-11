PALETTE = {
	{26,28,44}, 	-- black
	{93,39,93}, 	-- purple
	{177,62,83},	-- red
	{239,125,87},	-- orange
	{255,205,117},	-- yellow
	{167,240,112},	-- light green
	{56,183,100},	-- green
	{37,113,121},	-- dark green
	{41,54,111},	-- dark blue
	{59,93,201},	-- blue
	{65,166,246},	-- light blue
	{115,239,247},	-- cyan
	{244,244,244},	-- white
	{148,176,194},	-- light grey
	{86,108,134},	-- grey
	{51,60,87}		-- dark grey
	}

patch = {}
patch.methods = {}

-- Fill screen with background color
function patch.methods.fill_bg(x,y,r,g,b,a)
	r = PALETTE[1][1]/255
	g = PALETTE[1][2]/255
	b = PALETTE[1][3]/255
	a=1
	return r,g,b,a
end


-- Check if pixel in screen boundary
function patch.methods.inScreen(x,y)
	return (x>0 and x<screen.inner.w and y > 0 and y < screen.inner.h)
end


function patch.init()
	patch.hang = false
	patch.palette = PALETTE

	patch.img = false
	patch.img_data = love.image.newImageData(screen.inner.w, screen.inner.h)
	
end


function patch.draw()
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
			local px = w/2 + (r-p.b)*x1
			local py = h/2 + (r-p.a)*y1
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

return patch