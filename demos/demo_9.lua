local Patch = require "lib/patch"
local palettes = require "lib/utils/palettes"
local kp = require "lib/utils/keypress"
local cmd = require "lib/utils/cmdmenu"
local Envelope = require "lib/automations/envelope"
local Lfo = require "lib/automations/lfo"

-- import pico8 palette
local PALETTE = palettes.PICO8

patch = Patch:new()

--- @private init_params initialize patch parameters
local function init_params()
	g = resources.graphics
	p = resources.parameters

    -- insert here your patch parameters
end

--- @public patchControls evaluate user keyboard controls
function patch.patchControls()
	p = resources.parameters

	if kp.isDown("r") then
		patch.init()
	end

    -- insert here your patch controls
end


--- @public init init routine
function patch.init()
	PALETTE = palettes.PICO8

	patch:setCanvases()

	init_params()

	timer.init() -- special case, just for the sake of this demo!

	patch.lfo = Lfo:new(1, 0)
	patch.env = Envelope:new(0.5, 0.5, 0.5, 1)

	patch:assignDefaultDraw()
end

--- @private draw_bg draw background graphics
local function draw_stuff()
	g = resources.graphics
	p = resources.parameters

	local t = timer.T
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

	patch:drawExec()
end


function patch.update()
	-- apply keyboard patch controls
	if not cmd.isOpen then patch.patchControls() end
	patch.hang = not kp.isDown("r")

	-- update triggers
	patch.env:UpdateTrigger(timer.T>6 and timer.T < 8)
	patch.lfo:UpdateTrigger(timer.T<5)

	return
end

return patch