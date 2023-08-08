local Patch = lovjRequire("lib/patch")
local palettes = lovjRequire("lib/utils/palettes")
local kp = lovjRequire("lib/utils/keypress")
local Timer = lovjRequire("lib/timer")
local cfg_timers = lovjRequire("lib/cfg/cfg_timers")
local cfg_screen = lovjRequire("lib/cfg/cfg_screen")
local shaders = lovjRequire("lib/shaders")
local Envelope = lovjRequire("lib/automations/envelope")
local Lfo = lovjRequire("lib/automations/lfo")

local BG_SPRITE_SIZE = 8

patch = Patch:new()

--- @private init_params initialize patch parameters
local function init_params()
	local g = resources.graphics
	local p = resources.parameters
	g:setName(1, "bg")				g:set("bg", "data/demo_6/bg.png")
	p:setName(1, "bgSpeed")			p:set("bgSpeed", 10)
end

--- @public patchControls evaluate user keyboard controls
function patch.patchControls()
	local p = resources.parameters
	-- Hanger
	if kp.isDown("x") then patch.hang = true else patch.hang = false end
end


--- @public setCanvases (re)set canvases for this patch
function patch:setCanvases()
	Patch.setCanvases(patch)  -- call parent function
	-- patch-specific execution (window canvas)
	if cfg_screen.UPSCALE_MODE == cfg_screen.LOW_RES then
		patch.canvases.toShade = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
	else
		patch.canvases.toShade = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
	end
end


--- @public init init routine
function patch.init()
	PALETTE = palettes.PICO8

	patch:setCanvases()

	init_params()

	patch:assignDefaultDraw()

	patch.bpm = 120
	patch.timers = {}
	patch.timers.bpm = Timer:new(60 / patch.bpm )  -- 60 are seconds in 1 minute, 4 are sub-beats

end


--- @public patch.draw draw routine
function patch.draw()
	local t = cfg_timers.globalTimer.T

	patch:drawSetup(hang)

	-- clear main canvas
	patch.canvases.main:renderTo(function()
									love.graphics.clear(1,1,1,1)
								end )

	love.graphics.setCanvas(patch.canvases.main)
	love.graphics.setColor(1,1,1,1)

	for x = 0, screen.InternalRes.W, 3 do
		for y = 0, screen.InternalRes.H, 3 do
			local c = {1,
					   math.abs(math.sin((2*math.pi)*(x+y+t*100)/ (screen.InternalRes.W + screen.InternalRes.H))),
					   1,
					   1}
			love.graphics.setColor(c)
			love.graphics.rectangle("fill",x,y,3,3)
		end
	end

	love.graphics.draw(patch.canvases.toShade)

	patch:drawExec()
end


function patch.update()
	patch:mainUpdate()
	patch.timers.bpm:update()

	--patch.env:UpdateTrigger(patch.timers.bpm:Activated())
	--patch.lfo:UpdateTrigger(true)

end


function patch.commands(s)

end

return patch