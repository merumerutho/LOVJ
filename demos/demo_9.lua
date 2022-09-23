local Patch = require "lib/patch"
local palettes = require "lib/utils/palettes"
local kp = require "lib/utils/keypress"
local cmd = require "lib/utils/cmdmenu"
local Envelope = require "lib/automations/envelope"

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
		timer.init()
	end

    -- insert here your patch controls
end


--- @public init init routine
function patch.init()
	PALETTE = palettes.PICO8

	patch:setCanvases()

	init_params()

	patch.env = Envelope:new(2, 1, 0.5, 1)

	patch:assignDefaultDraw()
end

--- @private draw_bg draw background graphics
local function draw_stuff()
	g = resources.graphics
	p = resources.parameters

	local t = timer.T
    -- insert here your draw routine
	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.line(t * 30, screen.InternalRes.H,
						t * 30, screen.InternalRes.H - 100*patch.env:Calculate(t))

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

	-- update trigger, activated for 5 seconds
	patch.env:UpdateTrigger(timer.T<5)

	return
end

return patch