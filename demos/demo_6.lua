local Patch = lovjRequire("lib/patch")
local palettes = lovjRequire("lib/utils/palettes")
local kp = lovjRequire("lib/utils/keypress")
local Timer = lovjRequire("lib/timer")
local cfg_timers = lovjRequire("cfg/cfg_timers")
local cfg_screen = lovjRequire("cfg/cfg_screen")
local Envelope = lovjRequire("lib/signals/envelope")
local Lfo = lovjRequire("lib/signals/lfo")

local BG_SPRITE_SIZE = 8

local PALETTE = palettes.PICO8

local patch = Patch:new()

local resW, resH

--- @private get_bg get background graphics based on resources
local function get_bg()
	local g = patch.resources.graphics
	patch.graphics = {}
	patch.graphics.bg = {}
	patch.graphics.bg.image = love.graphics.newImage(g:get("bg"))
	patch.graphics.bg.size = {x = BG_SPRITE_SIZE, y = BG_SPRITE_SIZE}
	patch.graphics.bg.frames = {}
	for i=0,patch.graphics.bg.image:getWidth() / BG_SPRITE_SIZE do
		table.insert(patch.graphics.bg.frames, love.graphics.newQuad(	i*BG_SPRITE_SIZE,			-- x
																		0,							-- y
																		BG_SPRITE_SIZE,				-- width
																		BG_SPRITE_SIZE,				-- height
																		patch.graphics.bg.image))	-- img
	end
end

--- @private init_params initialize patch parameters
local function init_params()
	local g = patch.resources.graphics
	local p = patch.resources.parameters
	g:setName(1, "bg")				g:set("bg", "data/demo_6/bg.png")
	get_bg()
	p:setName(1, "bgSpeed")			p:set("bgSpeed", 10)

	return p, g
end

--- @public patchControls evaluate user keyboard controls
function patch.patchControls()
	local p = patch.resources.parameters
	-- Hanger
	if kp.isDown("x") then patch.hang = true else patch.hang = false end
end


--- @public setCanvases (re)set canvases for this patch
function patch:setCanvases()
	Patch.setCanvases(patch)  -- call parent function
	-- patch-specific execution (window canvas)
	if not screen.isUpscalingHiRes() then
		resW, resH = screen.InternalRes.W, screen.InternalRes.H
	else
		resW, resH = screen.ExternalRes.W, screen.ExternalRes.H
	end
	patch.canvases.toShade = love.graphics.newCanvas(resW, resH)
end


--- @public init init routine
function patch.init(slot)
	Patch.init(patch, slot)

	patch:setCanvases()

	patch.resources.parameters,
	patch.resources.graphics = init_params()

	patch.bpm = 120
	patch.timers = {}
	patch.timers.bpm = Timer:new(60 / patch.bpm )  -- 60 are seconds in 1 minute, 4 are sub-beats

	patch.env = Envelope:new(0.005, 0, 1, 0.5)
	patch.lfo = Lfo:new(patch.bpm/60, 0)

	patch.sym_shader = love.graphics.newShader(table.getValueByName("quadmirror", cfgShaders.PostProcessShaders))
end

--- @private draw_bg draw background graphics
local function draw_bg()
	local t = cfg_timers.globalTimer.T

	local g = patch.resources.graphics
	local p = patch.resources.parameters

	love.graphics.setCanvas(patch.canvases.toShade)

	love.graphics.setColor(0,0,0,1)
	love.graphics.rectangle("fill",0,0, screen.InternalRes.W, resH)
	love.graphics.setColor(1,1,1,math.abs(math.sin(t*10))*0.2)
	local idx = (math.floor(t * p:get("bgSpeed") ) % (patch.graphics.bg.image:getWidth() / BG_SPRITE_SIZE) ) + 1
	-- Generate background pic
	for x = -patch.graphics.bg.size.x, screen.InternalRes.W, patch.graphics.bg.size.x do
		for y = -patch.graphics.bg.size.y, screen.InternalRes.H, patch.graphics.bg.size.y do
			local lx = x + (t*20)% BG_SPRITE_SIZE
			local ly = y + (t*10)% BG_SPRITE_SIZE
			local rx = (lx - screen.InternalRes.W / 2)
			local ry = (ly - screen.InternalRes.H / 2)
			local rIdx = math.floor((idx + math.sqrt((rx*rx) + (ry*ry)) / 10)
									% (patch.graphics.bg.image:getWidth() / BG_SPRITE_SIZE )) + 1
			love.graphics.draw(patch.graphics.bg.image, patch.graphics.bg.frames[rIdx], lx, ly)
		end
	end
	-- Generate balls :)
	local offY = 50*math.sin(t*1.2)
	local offX = 50*math.cos(t*1.9)

	local amp = patch.env:Calculate(t) * 50

	for x = -200, 120, 10 do
		local size = 5 + 2 * math.sin(t*10 + x/50)
		love.graphics.setColor(0.4,0.4,0.4,.7)
		love.graphics.circle("fill", amp + screen.InternalRes.W/2+x,
								offY + screen.InternalRes.H/2 + 30*math.sin((t/2+x/200)*2*math.pi), size)
		love.graphics.setColor(1,1,1,.7)
		love.graphics.circle("fill", amp + screen.InternalRes.W/2+x,
								offY + screen.InternalRes.H/2 + 30*math.sin((t/2+x/200+0.05)*2*math.pi), size)
		love.graphics.setColor(0.4,0.4,0.4,.7)
		love.graphics.circle("line", amp + screen.InternalRes.W/2+x,
								offY + screen.InternalRes.H/2 + 30*math.sin((t/2+x/200+0.05)*2*math.pi), size)
	end

	for x = -200, 120, 10 do
		local size = 5 + 2 * math.cos(t*10 + x/50)
		love.graphics.setColor(0.4,0.4,0.4,.7)
		love.graphics.circle("fill",
								offX + screen.InternalRes.W/2 + 30*math.sin((t/2+x/200)*2*math.pi),
							 	amp + screen.InternalRes.W/2+x, size)
		love.graphics.setColor(1,1,1,.7)
		love.graphics.circle("fill", offX + screen.InternalRes.H/2 + 30*math.sin((t/2+x/200+0.05)*2*math.pi),
								 amp + screen.InternalRes.W/2+x, size)
		love.graphics.setColor(0.4,0.4,0.4,.7)
		love.graphics.circle("line", offX + screen.InternalRes.H/2 + 30*math.sin((t/2+x/200+0.05)*2*math.pi),
								amp + screen.InternalRes.W/2+x, size)
	end

	local rsize = patch.lfo:Sine(t) * 20

	love.graphics.setColor(1,1,1,0.2*((t*10)%1))
	love.graphics.rectangle("fill", screen.InternalRes.W/2 - 100 - rsize, screen.InternalRes.H/2 - 50 - rsize,
	200 + rsize, 100 + rsize)
	love.graphics.setColor(0,0,0,0.2*(((t+.25)*7)%1))
	love.graphics.rectangle("fill", screen.InternalRes.W/2 - 50 - .5*rsize, screen.InternalRes.H/2 - 30- .5*rsize, 100+ .5*rsize, 60 +.5*rsize)

	if cfgShaders.enabled then
		love.graphics.setShader(patch.sym_shader)
	end

end

--- @public patch.draw draw routine
function patch.draw()
	patch:drawSetup(hang)

	-- clear main canvas
	patch.canvases.main:renderTo(function()
									love.graphics.clear(1,1,1,1)
								end )
	local scaleX, scaleY = 1, 1
	if screen.isUpscalingHiRes() then
		scaleX, scaleY = screen.Scaling.X, screen.Scaling.Y
	end

	-- draw picture
	draw_bg()
	love.graphics.setCanvas(patch.canvases.main)
	love.graphics.setColor(1,1,1,1)
	love.graphics.draw(patch.canvases.toShade, 0, 0, 0, scaleX, scaleY)

	return patch:drawExec()

end


function patch.update()
	patch:mainUpdate()
	patch.timers.bpm:update()

	patch.env:UpdateTrigger(patch.timers.bpm:Activated())
	patch.lfo:UpdateTrigger(true)

end


function patch.commands(s)

end

return patch