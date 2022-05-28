available_palettes = require "lib/palettes"
screen = require "lib/screen"
-- import pico8 palette
PALETTE = available_palettes.PICO8

patch = {}
patch.methods = {}


function patch.patchControls()
	local p = params[1]
	if love.keyboard.isDown("lctrl") then
    if love.keyboard.isDown("a") then
      p[1] = 0
    else
      p[1] = 1
    end
    
    -- Hanger
    if love.keyboard.isDown("x") then
      hang = true
    else
      hang = false
    end
  end
	
	-- Reset
	if love.keyboard.isDown("r") then
		timer.initial_time = love.timer.getTime()
    	patch.init()
	end
	
	return p
end


function patch.init()
  
	patch.hang = false
	patch.palette = PALETTE
	
	math.randomseed(timer.t)

	patch.bpm = 128
	patch.n = 10

	params[1][1] = 1

end


function patch.draw()
	p = params[1]
	for i=-1,patch.n-1 do
		-- type: outer or inner
		local c = math.random(2)
		-- shortcut :)
		local hi = screen.inner.h
		-- random offset
		local r = math.random(20)+1
		-- x coordinate
		local x = math.random(screen.inner.w/2)
		-- y coordinates
		local y1 = ((hi/patch.n)*i) - r/2 - 5 + (timer.t*20)%(screen.inner.h/patch.n)
		local y2 = y1 + (hi/patch.n)  + r/2 + 5 + (timer.t*20)%(screen.inner.h/patch.n)
		-- draw
		if c == 1 then
			love.graphics.setColor(1, 1, 1, p[1])
			love.graphics.rectangle("fill", x, y1, screen.inner.w-(2*x), y2-y1)
		else
			love.graphics.setColor(1, 1, 1, p[1])
			love.graphics.rectangle("fill", 0, y1, screen.inner.w, y2-y1)
			love.graphics.setColor(0, 0, 0, 1)
			love.graphics.rectangle("fill", x,y1, screen.inner.w-(2*x), y2-y1)
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