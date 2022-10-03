local Patch = require "lib/patch"
local palettes = require "lib/utils/palettes"
local screen = require "lib/screen"
local kp = require "lib/utils/keypress"
local cmd = require "lib/utils/cmdmenu"
local Timer = require "lib/timer"
local cfg_timers = require "lib/cfg/cfg_timers"
local Envelope = require "lib/automations/envelope"

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

	patch.bpm = 120
	patch.n = 10
	patch.localTimer = 0

	patch.timers = {}
	patch.timers.bpm = Timer:new(60 / patch.bpm )  -- 60 are seconds in 1 minute, 4 are sub-beats
	patch.env = Envelope:new(0.005, 0, 1, 0.5)
	patch.drawList = {}

	init_params()
	patch:assignDefaultDraw()
end


function recalculateRects()
	local t = cfg_timers.globalTimer.T

	-- empty list
	patch.drawList = {}

	-- add new elements
	for i = -1, patch.n-1 do
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
		local y1 = ((ih / patch.n) * i) - r / 2 - 5 -- + (t * 20) % (ih / patch.n)
		local y2 = y1 + (ih / patch.n)  + r / 2 + 5 -- + (t * 20) % (ih / patch.n)
		-- add to the table
		table.insert(patch.drawList, {x = x, y1 = y1, y2 = y2, c = c})
	end
end


function updateRects()
	local t = cfg_timers.globalTimer.T
	for k,v in pairs(patch.drawList) do
		v.y1 = v.y1 + math.sin(t + v.y1 / screen.InternalRes.H) * 2
		v.y2 = v.y2 + math.sin(t*1.5) + 5 * math.atan(v.x/v.y2)
		v.x = v.x + math.cos(t*3 - v.y1/screen.InternalRes.H) * 3
	end
end


function patch.draw()
	patch:drawSetup()

	local t = cfg_timers.globalTimer.T

	love.graphics.clear()

	local transparency = patch.env:Calculate(t)
	if patch.freeRunning then transparency = 1 end
	local inversion = patch.invert and 1 or 0  -- convert bool to int

	for k,v in pairs(patch.drawList) do
		if v.c == 1 then
			local color = patch.palette[2 - inversion]
			love.graphics.setColor(color[1], color[2], color[3], transparency)
			love.graphics.rectangle("fill", v.x, v.y1, screen.InternalRes.W - (2 * v.x), v.y2 - v.y1)
		else
			local color = patch.palette[2 - inversion]
			love.graphics.setColor(color[1], color[2], color[3], transparency)
			love.graphics.rectangle("fill", 0, v.y1, screen.InternalRes.W, v.y2 - v.y1)
			color = patch.palette[1 + inversion]
			love.graphics.setColor(color[1], color[2], color[3], transparency)
			love.graphics.rectangle("fill", v.x, v.y1, screen.InternalRes.W - (2 * v.x), v.y2 - v.y1)
		end
	end

	patch:drawExec()
end


function patch.update()
	-- Update bpm timer
	patch.timers.bpm:update()

	-- Upon bpm timer trigger, update envelope trigger
	patch.env:UpdateTrigger(patch.timers.bpm:Activated())

	-- Upon bpm timer trigger, recalculate rectangles
	if patch.timers.bpm:Activated() then
		recalculateRects()
	else
		updateRects()
	end

		-- update parameters with patch controls
		if not cmd.isOpen then patch.patchControls() end
	end

return patch