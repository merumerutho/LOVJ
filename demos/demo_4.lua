local Patch = lovjRequire("lib/patch")
local palettes = lovjRequire("lib/utils/palettes")
local screen = lovjRequire("lib/screen")
local kp = lovjRequire("lib/utils/keypress")
local Timer = lovjRequire("lib/timer")
local cfg_timers = lovjRequire("lib/cfg/cfg_timers")
local Envelope = lovjRequire("lib/automations/envelope")

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


--- @private recalculateRects empty drawList and populate with new list of random rectangles
local function recalculateRects()
	local t = cfg_timers.globalTimer.T

	-- erase content of list (garbage collector takes care of this... right?)
	patch.drawList = {}

	-- add new rectangles
	for i = -1, patch.n-1 do
		local iw = screen.InternalRes.W
		local ih = screen.InternalRes.H
		local c = math.random(2)					 -- random inner or outer rectangle
		local x = math.random(iw / 2)                -- random x coordinate
		local r = math.random(20) + 1                -- random height offset
		local y1 = ((ih / patch.n) * i) - r / 2 - 5  -- top of rectangle
		local y2 = y1 + (ih / patch.n)  + r / 2 + 5  -- bottom of rectangle

		table.insert(patch.drawList, {x = x, y1 = y1, y2 = y2, c = c})
	end
end


--- @private updateRects move rectangles according to some defined behaviour
local function updateRects()
	local t = cfg_timers.globalTimer.T
	local dt = cfg_timers.globalTimer:dt()  -- use this to make the code fps-independent!

	for k,v in pairs(patch.drawList) do
		v.y1 = v.y1 + (math.sin(t + v.y1 / screen.InternalRes.H)) * 20 * dt
		v.y2 = v.y2 + (math.sin(t*1.5) + math.atan(v.x/v.y2))     * 50 * dt
		v.x  = v.x  + (math.cos(t*3 - v.y1/screen.InternalRes.H)) * 30 * dt
	end

end


--- @public patch.draw draw the patch
function patch.draw()
	patch:drawSetup()  -- call parent setup function

	local t = cfg_timers.globalTimer.T

	local transparency = patch.env:Calculate(t)     -- transparency set according to patch.env Envelope

	if patch.freeRunning then transparency = 1 end  -- in free running, transparency disabled
	local inversion = patch.invert and 1 or 0       -- convert "inversion" bool to int

	-- draw all rectangles
	for k,v in pairs(patch.drawList) do
		local color = palettes.getColor(patch.palette, 2-inversion)
		if v.c == 1 then
			love.graphics.setColor(color[1], color[2], color[3], transparency)
			love.graphics.rectangle("fill", v.x, v.y1, screen.InternalRes.W - (2 * v.x), v.y2 - v.y1)
		else
			love.graphics.setColor(color[1], color[2], color[3], transparency)
			love.graphics.rectangle("fill", 0, v.y1, screen.InternalRes.W, v.y2 - v.y1)
			color = palettes.getColor(patch.palette, 1 + inversion)		-- swap color
			love.graphics.setColor(color[1], color[2], color[3], transparency)
			love.graphics.rectangle("fill", v.x, v.y1, screen.InternalRes.W - (2 * v.x), v.y2 - v.y1)
		end
	end

	patch:drawExec()  -- call parent rendering function
end


function patch.update()
	patch:mainUpdate()

	-- Update bpm timer
	patch.timers.bpm:update()

	-- Upon bpm timer trigger, update envelope trigger
	patch.env:UpdateTrigger(patch.timers.bpm:Activated())

	-- Upon bpm timer trigger, also update rectangles
	if patch.timers.bpm:Activated() then
		recalculateRects()
	else
		updateRects()
	end
end

return patch