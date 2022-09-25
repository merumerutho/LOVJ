local Patch = require "lib/patch"
local palettes = require "lib/utils/palettes"
local screen = require "lib/screen"
local kp = require "lib/utils/keypress"
local cmd = require "lib/utils/cmdmenu"
local amath = require "lib/automations/automation_math"

-- import pico8 palette
PALETTE = palettes.BW

patch = Patch:new()

function patch.patchControls()
	p = resources.parameters
	if kp.isDown("lctrl") then
		-- Inverter
		patch.invert = kp.isDown("x")

		patch.freeRunning = kp.isDown("f")
  	end
	
	-- Reset
	if kp.isDown("r") then
    	patch.init()
	end
end


local function init_params()
	p = resources.parameters
end


function patch.init()
	patch.palette = PALETTE
	patch.invert = false

	patch:setCanvases()

	math.randomseed(timer.T)

	patch.bpm = 128  -- TODO: implement
	patch.n = 10
	patch.localTimer = 0

	patch.hang = true

	init_params()

	patch:assignDefaultDraw()
end


function patch.draw()
	patch:drawSetup()

	-- draw
	if timer.oneSecondTimer() then
		love.graphics.clear()
		for i= -1, patch.n-1 do
			-- type: outer or inner rectangle
			local c = math.random(2)
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
	patch:drawExec()
end


function patch.update()
	-- update parameters with patch controls
	if not cmd.isOpen then patch.patchControls() end
	--beat per step?
  	--local bps = patch.bpm/60*4
end

return patch