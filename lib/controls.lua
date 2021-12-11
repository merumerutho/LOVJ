controls = {}

function controls.updateByKeys(p)
	
	-- INCREASE
	if love.keyboard.isDown("up") then
		-- Param "a"
		if love.keyboard.isDown("a") then
			p.a = p.a + .1
		end
		-- Param "b"
		if love.keyboard.isDown("b") then
			p.b = p.b + .1
		end
		
	end
	
	-- DECREASE
	if love.keyboard.isDown("down") then
		-- Param "a"
		if love.keyboard.isDown("a") then
			p.a = p.a - .1 
		end
		-- Param "b"
		if love.keyboard.isDown("b") then
			p.b = p.b - .1
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
		p.a=0.5
		p.b=1
		timer.initial_time = love.timer.getTime()
	end
	
	return p
end

return controls