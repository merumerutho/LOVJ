palettes = require "lib/utils/palettes"
screen = require "lib/screen"
kp = require "lib/utils/keypress"

-- import pico8 palette
PALETTE = palettes.BW

patch = {}

function patch.patchControls()
	p = resources.parameters
	if kp.isDown("lctrl") then
		-- Inverter
		patch.invert = kp.isDown("x")
  	end
	
	-- Reset
	if kp.isDown("r") then
		timer.InitialTime = love.timer.getTime()
    	patch.init()
	end
end


local function init_params()
	p = resources.parameters
end


function patch.init()
	patch.palette = PALETTE
	patch.invert = false
	
	math.randomseed(timer.T)

	patch.bpm = 128  -- TODO: implement
	patch.n = 10

	init_params()
end


function patch.draw()
	for i= -1, patch.n-1 do
		-- type: outer or inner rectangle
		local c = math.random(2)
		-- shortcuts :)
		local iw = screen.InternalRes.W
		local ih = screen.InternalRes.H
		-- x coordinate
		local x = math.random(iw / 2)
		-- random height offset
		local r = math.random(20) + 1
		-- y1 = top of rectangle
		-- y2 = bottom of rectangle
		local y1 = ((ih / patch.n) * i) - r / 2 - 5  + (timer.T * 20) % (ih / patch.n)
		local y2 = y1 + (ih / patch.n)  + r / 2 + 5  + (timer.T * 20) % (ih / patch.n)

		-- draw
		local transparency = 1

		local inversion = patch.invert and 1 or 0  -- convert bool to int

		if c == 1 then
			local color = patch.palette[2 - inversion]
			love.graphics.setColor(color[1], color[2], color[3], transparency)
			love.graphics.rectangle("fill", x, y1, screen.InternalRes.W - (2 * x), y2 - y1)
		else
			local color = patch.palette[2 - inversion]
			love.graphics.setColor(color[1], color[2], color[3], transparency)
			love.graphics.rectangle("fill", 0, y1, screen.InternalRes.W, y2 - y1)
			color = patch.palette[1 + inversion]
			love.graphics.setColor(color[1], color[2], color[3], 1)
			love.graphics.rectangle("fill", x, y1, screen.InternalRes.W - (2 * x), y2 - y1)
		end
	end
end


function patch.update()
	-- update parameters with patch controls
	patch.patchControls()

	--beat per step? (why times 4 though?)
  	--local bps = patch.bpm/60*4

end

--- @public defaultDraw assigned to draw method by default
patch.defaultDraw = patch.draw

return patch