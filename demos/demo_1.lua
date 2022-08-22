available_palettes = require "lib/palettes"
kp = require "lib/utils/keypress"
shaders = require "lib/shaders"

-- import pico8 palette
PALETTE = available_palettes.PICO8

patch = {}
patch.methods = {}

patch.shaders = {shaders.default, shaders.h_mirror, shaders.w_mirror, shaders.wh_mirror, shaders.warp, shaders.kaleido}

-- Fill screen with background color
local function fill_bg(x, y, r, g, b, a)
	r = PALETTE[1][1] / 255
	g = PALETTE[1][2] / 255
	b = PALETTE[1][3] / 255
	a = 1
	return r,g,b,a
end

--- @private patch.methods.in Check if pixel in screen boundary
local function inScreen(x, y)
	return (x > 0 and x < screen.InternalRes.W and y > 0 and y < screen.InternalRes.H)
end


function patch.patchControls()
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

	-- selected shader
	if kp.keypressOnAttack("s") then
		rSetByName(p, "selected_shader", (rGetByName(p, "selected_shader") + 1) % #patch.shaders)
	end

end


function patch.init()
	p = resources.parameters

	patch.hang = false
	patch.palette = PALETTE

	patch.img = false
	patch.img_data = love.image.newImageData(screen.InternalRes.W, screen.InternalRes.H)

	rSet(p, 10, 0)			rSetName(p, 10, "selected_shader")
	rSet(p, 11, 2)			rSetName(p, 11, "_warpParameter")
	rSet(p, 12, 3)			rSetName(p, 12, "_segmentParameter")
end


function patch.draw()
	-- clear picture
	if not hang then
		patch.img_data:mapPixel(fill_bg)
	end

	local shader = nil
	-- select shader
	if cfg_shaders.enabled then
		shader = love.graphics.newShader(patch.shaders[1 + rGetByName(p, "selected_shader")])
		if rGetByName(p, "selected_shader") == 4 then
			shader:send("_warpParameter", rGetByName(p, "_warpParameter"))
		end
		if rGetByName(p, "selected_shader") == 5 then
			shader:send("_segmentParameter", rGetByName(p, "_segmentParameter"))
		end
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
			if inScreen(px, py) then
				patch.img_data:setPixel(px, py, col[1] / 255, col[2] / 255, col[3] / 255, 1)
			end
		end
	end

	-- apply shader
	if cfg_shaders.enabled then
		love.graphics.setShader(shader)
	end
	-- render picture
	local img = love.graphics.newImage(patch.img_data)
	love.graphics.draw(img, 0, 0)

	-- remove shader
	if cfg_shaders.enabled then
		love.graphics.setShader()
	end
end


function patch.update()
	-- update parameters with patch controls
	patch.patchControls()
	return
end

return patch