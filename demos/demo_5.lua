available_palettes = require "lib/palettes"
shaders = require "lib/shaders"
controls = require "lib/controls"

-- import palette
PALETTE = available_palettes.TIC80

patch = {}
patch.methods = {}

patch.shaders = { shaders.default, shaders.h_mirror, shaders.w_mirror, shaders.wh_mirror }

--- @private inScreen Check if pixel in screen boundary
function patch.methods.inScreen(x, y)
	return (x>0 and x< screen.inner.w and y > 0 and y < screen.inner.h)
end

--- @private patchCheckControls Checks the input controls locally
function patch.patchCheckControls()
	p = params.elements[1]
	
	-- Reset
	if love.keyboard.isDown("r") then
		patch.reset()
	end
	
	return params
end

--- @protected keypressed Key press callback function
function love.keypressed(key, scancode, isrepeat)
	p = params.elements[1]
	-- parameter 'c'
	if key == 'c' then
		p[3] = (p[3] + 1) % 4
	end
	-- hang command
	if key == 'x' then
		hang = not hang
	end

	-- fallback to general controls callback
	controls.HandleGeneralControls()
end


--- @private generatePoint Generate a random point in space
function patch.generatePoint(i)
	local po = {}
	po.x = screen.inner.w/2 + math.random(screen.inner.w/2) - math.random(screen.inner.w/2)
	po.y = screen.inner.h/2 + math.random(screen.inner.h/2) - math.random(screen.inner.h/2)
	po.dx = tonumber(po.x > screen.inner.w/2) or -1
	po.dy = tonumber(po.y > screen.inner.h/2) or -1
	po.i = i
	return po
end


--- @private updatePoints Updates points positions
function patch.updatePoints(l)
	p = params.elements[1]
	for k,v in pairs(l) do
		v.x = v.x + math.random()*math.sin(2*math.pi*(timer.t / (p[1]*3) + v.i/#l)) + v.dx*(math.sin(math.pi* timer.t*2))^3
		v.y = v.y + math.random()*math.cos(2*math.pi*(timer.t / (p[2]*3) + v.i/#l)) + v.dy*(math.cos(math.pi* timer.t*2))^3
	end
end


--- @public init Initializes the patch
function patch.init()
	p=params.elements[1]
	patch.hang = false
	patch.palette = PALETTE
	patch.nPoints = 3+math.random(32)
	patch.points = {}
	for i=1, patch.nPoints do
		table.insert(patch.points, patch.generatePoint(i))
	end
	-- canvases
	patch.canvases = {}
	patch.canvases.main = love.graphics.newCanvas(screen.outer.w, screen.outer.h)
	patch.canvases.trail = love.graphics.newCanvas(screen.outer.w, screen.outer.h)
	-- move this somewhere else?
	patch.shader_trail = nil
end

function patch.reset()
	-- regenerate points
	patch.nPoints = 3+math.random(32)
	patch.points = {}
	for i=1, patch.nPoints do
		table.insert(patch.points, patch.generatePoint(i))
	end
end

--- @public draw Draws the content of the patch
function patch.draw()
	p = params.elements[1]
	-- clean trail buffer
	patch.canvases.trail:renderTo(love.graphics.clear)

	-- if hanging, copy content of main buffer onto trail buffer applying trail shader
	if hang then
		patch.shader_trail = love.graphics.newShader(shaders.trail) -- set/update trail shader
		patch.shader_trail:send("trailColor", { p[4], p[5], p[6], 0.99804684})
		patch.canvases.trail:renderTo(function()
			love.graphics.setColor(1,1,1,1)
			love.graphics.setShader(patch.shader_trail) -- apply shader
			love.graphics.draw(patch.canvases.main, -- draw content of main buffer onto trail buffer
								0, 0, 0, 1/ screen.scale.x, 1/ screen.scale.y)
			love.graphics.setShader() -- remove shader
		end)
	end

	-- copy back from trail buffer onto main
	patch.canvases.main:renderTo(love.graphics.clear)
	patch.canvases.main:renderTo(function()
			love.graphics.setColor(1,1,1,1)
			love.graphics.draw(patch.canvases.trail,  -- draw content of main buffer onto trail buffer
								0, 0, 0, 1/ screen.scale.x, 1/ screen.scale.y)
		end)

	-- update points positions
	patch.updatePoints(patch.points)

	-- select shader
	local shader = love.graphics.newShader(patch.shaders[1+p[3]])

	-- set canvas
	love.graphics.setCanvas(patch.canvases.main)

	-- if inside screen, draw points
	for k,pix in pairs(patch.points) do
		if patch.methods.inScreen(pix.x,pix.y) then
			love.graphics.setColor({1,1,1,1})
			love.graphics.points(pix.x, pix.y)
		end
	end

	-- draw line
	for k, pix in pairs(patch.points) do
		local po = patch.points
		if k==#(patch.points) then
			love.graphics.line(po[k].x, po[k].y, po[1].x, po[1].y)
		else
			love.graphics.line(po[k].x, po[k].y, po[k+1].x, po[k+1].y)
		end
	end

	-- remove canvas
	love.graphics.setCanvas()

	-- apply shader
	love.graphics.setShader(shader)
	-- render graphics
	love.graphics.draw(patch.canvases.main, 0, 0, 0, 1/ screen.scale.x, 1/ screen.scale.y)
	-- remove shader
	love.graphics.setShader()
end

--- @public update Updates the patch
function patch.update()
	-- update parameters with local patch controls
	params = patch.patchCheckControls()
end


return patch