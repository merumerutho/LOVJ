local Patch = lovjRequire("lib/patch")
local palettes = lovjRequire("lib/utils/palettes")
local kp = lovjRequire("lib/utils/keypress")
local Envelope = lovjRequire("lib/automations/envelope")
local Lfo = lovjRequire("lib/automations/lfo")
local Timer = lovjRequire("lib/timer")
local cfg_timers = lovjRequire("lib/cfg/cfg_timers")


-- import pico8 palette
local PALETTE = palettes.PICO8

local patch = Patch:new()

--- @private init_params initialize patch parameters
local function init_params()
	local g = patch.resources.graphics
	local p = patch.resources.parameters
end

--- @public patchControls evaluate user keyboard controls
function patch.patchControls()
	local p = patch.resources.parameters

	if kp.isDown("r") then
		patch.init(patch.resources)
		cfg_timers.reset()
	end

end


--- @public init init routine
function patch.init(resources)
	patch:assignResources(resources)
	PALETTE = palettes.PICO8

	patch:setCanvases()

	init_params()

	patch.lfo = Lfo:new(1, 0)
	patch.env = Envelope:new(0.5, 0.5, 0.5, 1)

	patch:assignDefaultDraw()
end

--- @private draw_bg draw background graphics
local function draw_stuff()
	local g = patch.resources.graphics
	local p = patch.resources.parameters

	local t = cfg_timers.globalTimer.T
	love.graphics.setColor(1, 1, 1, 1)

	-- LFO
	love.graphics.line(t * 20, screen.InternalRes.H - 10,
						t * 20, screen.InternalRes.H - 10 - 10*patch.lfo:Square(t))

	love.graphics.line(t * 20, screen.InternalRes.H - 40,
						t * 20, screen.InternalRes.H - 40 - 10*patch.lfo:Sine(t))

	love.graphics.line(t * 20, screen.InternalRes.H - 70,
						t * 20, screen.InternalRes.H - 70 - 10*patch.lfo:RampUp(t))

	love.graphics.line(t * 20, screen.InternalRes.H - 100,
						t * 20, screen.InternalRes.H - 100 - 10*patch.lfo:RampDown(t))

	love.graphics.line(t * 20, screen.InternalRes.H - 130,
						t * 20, screen.InternalRes.H - 130 - 10*patch.lfo:SampleHold(t))

	-- ENVELOPE
	love.graphics.line(t * 20, screen.InternalRes.H - 10,
						t * 20, screen.InternalRes.H  - 10 - 100 * patch.env:Calculate(t))

end

--- @public patch.draw draw routine
function patch.draw()
	patch:drawSetup()

	-- draw picture
	draw_stuff()

	return patch:drawExec()
end


function patch.update()

	patch:mainUpdate()

	local t = cfg_timers.globalTimer.T

	patch.hang = not kp.isDown("r")

	-- update triggers
	patch.lfo:UpdateTrigger(t<5)
	patch.env:UpdateTrigger(t>6 and t<8)

	return
end

function patch.commands(s)

end


return patch