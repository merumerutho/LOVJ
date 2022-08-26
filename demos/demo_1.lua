palettes = require "lib/palettes"
kp = require "lib/utils/keypress"
shaders = require "lib/shaders"
cfg_shaders = require "lib/cfg/cfg_shaders"

-- import pico8 palette
local PALETTE

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
		p:set("selected_shader", (p:get("selected_shader") + 1) % #cfg_shaders.shaders)
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

end


local function init_params()
	p = resources.parameters
	p:setName(10, "selected_shader")			p:set("selected_shader", 0)
	p:setName(11, "_warpParameter")				p:set("_warpParameter", 2)
	p:setName(12, "_segmentParameter")			p:set("_segmentParameter", 3)
end

--- @public init init routine
function patch.init()
	PALETTE = palettes.PICO8

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

	-- select shader
	local shader_script
	local shader
	if cfg_shaders.enabled then
		shader_script = cfg_shaders.shaders[1 + p:get("selected_shader")]
		shader = love.graphics.newShader(shader_script)
		if shader_script == shaders.warp then
			shader:send("_warpParameter", p:get("_warpParameter"))
		end
		if shader_script == shaders.kaleido then
			shader:send("_segmentParameter", p:get("_segmentParameter"))
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
			col = palettes.getColor(PALETTE, (math.floor(col) % 16) + 1)
			-- draw pixels on picture
			if inScreen(px, py) then
				patch.img_data:setPixel(px, py, col[1], col[2], col[3], 1)
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
	-- apply keyboard patch controls
	if not cmd.isOpen then patch.patchControls() end
	return
end

--- @public defaultDraw assigned to draw method by default
patch.defaultDraw = patch.draw

return patch