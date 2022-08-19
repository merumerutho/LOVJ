available_palettes = require "lib/palettes"
screen = require "lib/screen"
kp = require "lib/utils/keypress"

-- import pico8 palette
PALETTE = available_palettes.BW

patch = {}
patch.methods = {}

function patch.patchControls()
	p = resources.parameters
	if kp.isDown("lctrl") then
		if kp.isDown("a") then
		  p[1] = 0
		else
		  p[1] = 1
		end

		-- Hanger
		if kp.isDown("x") then
			patch.invert = 1
		else
			patch.invert = 0
		end
  	end
	
	-- Reset
	if kp.isDown("r") then
		timer.InitialTime = love.timer.getTime()
    	patch.init()
	end

	return p
end


function patch.init()
  
	patch.hang = false
	patch.palette = PALETTE
	patch.invert = 0
	
	math.randomseed(timer.T)

	patch.bpm = 128
	patch.n = 10

	--params[1][1] = 1

end


function patch.draw()
	--p = params[1]
	for i= -1, patch.n-1 do
		-- type: outer or inner
		local c = math.random(2)
		-- shortcut :)
		local hi = screen.InternalRes.H
		-- random offset
		local r = math.random(20) + 1
		-- x coordinate
		local x = math.random(screen.InternalRes.W / 2)
		-- y coordinates
		-- y1 = top of rectangle
		-- y2 = bottom of rectangle
		local y1 = ((hi / patch.n) * i) - r / 2 - 5  + (timer.T * 20) % (screen.InternalRes.H / patch.n)
		local y2 = y1 + (hi / patch.n)  + r / 2 + 5  + (timer.T * 20) % (screen.InternalRes.H / patch.n)

		--y1 = y1 + (screen.ExternalRes.H-screen.InternalRes.H)/2
		--y2 = y2 + (screen.ExternalRes.H-screen.InternalRes.H)/2

		-- draw
		transparency = 1
		if c == 1 then
			local color = patch.palette[2 - patch.invert]
			love.graphics.setColor(color[1], color[2], color[3], transparency)
			love.graphics.rectangle("fill", x, y1, screen.InternalRes.W - (2 * x), y2 - y1)
		else
			local color = patch.palette[2 - patch.invert]
			love.graphics.setColor(color[1], color[2], color[3], transparency)
			love.graphics.rectangle("fill", 0, y1, screen.InternalRes.W, y2 - y1)
			color = patch.palette[1 + patch.invert]
			love.graphics.setColor(color[1], color[2], color[3], 1)
			love.graphics.rectangle("fill", x, y1, screen.InternalRes.W - (2 * x), y2 - y1)
		end
	end
end


function patch.update(new_params)
  	params = new_params
	-- update parameters with patch controls
	patch.patchControls()

	--beat per step? (why times 4 though?)
  	--local bps = patch.bpm/60*4

end

return patch