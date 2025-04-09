local Patch = lovjRequire("lib/patch")
local palettes = lovjRequire("lib/utils/palettes")
local controls = lovjRequire("lib/controls")
local cfg_timers = lovjRequire("cfg/cfg_timers")
local cfg_shaders = lovjRequire("cfg/cfg_shaders")


-- import palette
local PALETTE = palettes.TIC80

local ALPHA_MAGIC_NUM = 0.995

local patch = Patch:new()

--- @public setCanvases (re)set canvases for this patch
function patch:setCanvases()
	Patch.setCanvases(patch)  -- call parent function
	-- patch-specific execution (trail canvas)
	patch.canvases.trail = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
end


--- @private inScreen Check if pixel in screen boundary
local function inScreen(x, y)
	return (x > 0 and x < screen.InternalRes.W and y > 0 and y < screen.InternalRes.H)
end

--- @private patchControls Checks the input controls locally
function patch.patchControls()
	-- reset
	--if kp.keypressOnAttack("r") then patch.init(self.slot) end
	--if kp.isDown("lshift") and kp.isDown("r") then
	--	patch.reset()
	--end
	-- hang
	--if kp.keypressOnAttack("x") then
	--	patch.hang = not patch.hang
	--end
	-- fallback to general controls callback
	controls.handleKeyBoard()
end


--- @private generatePoint Generate a random point in space
function patch.generatePoint(i)
	local point = {}
	point.x = screen.InternalRes.W / 2 + math.random(screen.InternalRes.W / 2) - math.random(screen.InternalRes.W / 2)
	point.y = screen.InternalRes.H / 2 + math.random(screen.InternalRes.H / 2) - math.random(screen.InternalRes.H / 2)
	point.dx = tonumber(point.x > screen.InternalRes.W / 2) or -1
	point.dy = tonumber(point.y > screen.InternalRes.H / 2) or -1
	point.i = i
	return point
end


--- @private updatePoints Updates points positions
function patch.updatePoints(l)
	local p = patch.resources.parameters

	local t = cfg_timers.globalTimer.T
	local dt = cfg_timers.globalTimer:dt()

	local r = math.random
	local cos = math.cos
	local sin = math.sin
	local pi = math.pi

	for k, v in pairs(l) do
		v.y = v.y + (r() * cos(2 * pi * (t / (p:getByIdx(2) * 3) + v.i / #l)) + v.dy * (cos(pi * t * 2)) ^ 3) * dt * 50
		v.x = v.x + (r() * sin(2 * pi * (t / (p:getByIdx(1) * 3) + v.i / #l)) + v.dx * (sin(pi * t * 2)) ^ 3) * dt * 50
	end
end

--- @private init_params Initialize parameters for this patch
local function init_params()
	local p = patch.resources.parameters

	-- Initialize parameters
	p:setName(1, "speed_x") 			p:set("speed_x", 20)
	p:setName(2, "speed_y") 			p:set("speed_y", 30)
	p:setName(3, "selected_shader") 	p:set("selected_shader", 0)

	-- trail color
	p:setName(4, "trail_color_red")		p:set("trail_color_red", 1)
	p:setName(5, "trail_color_green")	p:set("trail_color_green", 0.75)
	p:setName(6, "trail_color_blue")	p:set("trail_color_blue", 0.85)

	-- shader parameters
	p:setName(7, "_warpParameter")		p:set("_warpParameter", 2.)
	p:setName(8, "_segmentParameter")	p:set("_segmentParameter", 4.)

	return p
end

--- @public init Initializes the patch
function patch.init(slot)
	Patch.init(patch, slot)
	patch.palette = PALETTE
	patch.nPoints = 3 + math.random(32)
	patch.points = {}
	for i = 1, patch.nPoints do
		table.insert(patch.points, patch.generatePoint(i))
	end

	-- canvases
	patch:setCanvases()
	-- move this somewhere else?
	patch.shader_trail = nil

	patch.resources.parameters = init_params()
end

function patch.reset()
	-- regenerate points
	patch.nPoints = 3 + math.random(32)
	patch.points = {}
	for i = 1, patch.nPoints do
		table.insert(patch.points, patch.generatePoint(i))
	end
end

--- @public draw Draws the content of the patch
function patch.draw()
	local p = patch.resources.parameters

	-- clean trail buffer
	patch.canvases.trail:renderTo(love.graphics.clear)

	-- if hanging, copy content of main buffer onto trail buffer applying trail shader
	if patch.hang and cfg_shaders.enabled then
		patch.shader_trail = love.graphics.newShader(table.getValueByName("trail", cfg_shaders.OtherShaders)) -- set/update trail shader
		patch.shader_trail:send("_trailColor", {
												p:get("trail_color_red"),
												p:get("trail_color_green"),
												p:get("trail_color_blue"),
												ALPHA_MAGIC_NUM
												})
		patch.canvases.trail:renderTo(
			function()
				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.setShader(patch.shader_trail) -- apply shader
				-- draw content of main buffer onto trail buffer
					love.graphics.draw(patch.canvases.main,
							0, 0, 0, 1, 1)
				love.graphics.setShader() -- remove shader
			end)
	end
	-- copy back from trail buffer onto main
	patch.canvases.main:renderTo(love.graphics.clear)
	patch.canvases.main:renderTo(function()
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(patch.canvases.trail,  -- draw content of main buffer onto trail buffer
							0, 0, 0, screen.Scaling.X, screen.Scaling.Y)
		end)

	patch:drawSetup()

	-- if inside screen, draw points
	for k, pix in pairs(patch.points) do
		if inScreen(pix.x, pix.y) then
			love.graphics.setColor({1, 1, 1, 1})
			love.graphics.points(pix.x, pix.y)
		end
	end

	-- draw line
	for k, pix in pairs(patch.points) do
		local po = patch.points
		if k==#(patch.points) then
			love.graphics.line(po[k].x, po[k].y, po[1].x, po[1].y)
		else
			love.graphics.line(po[k].x, po[k].y, po[k + 1].x, po[k + 1].y)
		end
	end

	return patch:drawExec()
end

--- @public update Updates the patch
function patch.update()
	patch:mainUpdate()

	-- update points positions
	if cfg_timers.fpsTimer:Activated() then
		patch.updatePoints(patch.points)
	end
end


function patch.commands(s)

end

return patch