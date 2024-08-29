local Patch = lovjRequire("lib/patch")
local palettes = lovjRequire("lib/utils/palettes")
local kp = lovjRequire("lib/utils/keypress")
local Timer = lovjRequire("lib/timer")
local cfg_timers = lovjRequire("cfg/cfg_timers")
local Envelope = lovjRequire("lib/signals/envelope")

-- import pico8 palette
local PALETTE = palettes.PICO8

local patch = Patch:new()

--- @private inScreen Check if pixel in screen boundary
local function inScreen(x, y)
	return (x > 0 and x < screen.InternalRes.W and y > 0 and y < screen.InternalRes.H)
end


--- @private init_params initialize parameters for this patch
local function init_params()
	local p = patch.resources.parameters

	p:setName(1, "a")			p:set("a", 0.5)
	p:setName(2, "b")			p:set("b", 1)

	return p
end

--- @private patchControls handle controls for current patch
function patch.patchControls()
	local p = patch.resources.parameters
	local gr = patch.resources.graphics
	local gl = patch.resources.globals
	
	-- INCREASE
	if kp.isDown("up") then
		-- Param "a"
		if kp.isDown("a") then p:set("a", p:get("a") + .1) end
		-- Param "b"
		if kp.isDown("b") then p:set("b", p:get("b") + .1) end
	end
	
	-- DECREASE
	if kp.isDown("down") then
		-- Param "a"
		if kp.isDown("a") then p:set("a", p:get("a") - .1) end
		-- Param "b"
		if kp.isDown("b") then p:set("b", p:get("b") - .1) end
	end
	
	-- Hanger
	if kp.isDown("x") then patch.hang = true else patch.hang = false end

	return p, gr, gl
end

--- @public init init routine
function patch.init(slot)
	Patch.init(patch, slot)

	patch.resources.parameters = init_params()

	patch:setCanvases()

	patch.bpm = 170

	patch.timers = {}
	patch.timers.bpm = Timer:new(60 / patch.bpm )  -- 60 are seconds in 1 minute, 4 are sub-beats

	patch.env = Envelope:new(0.005, 0, 1, 0.5)
end

--- @public patch.draw draw routine
function patch.draw()
	patch:drawSetup()

	local p = patch.resources.parameters
	local t = cfg_timers.globalTimer.T

	local points_list = {}
	-- draw picture
	for x = -20, 20, .25 do
		for y = -20, 20, .25 do
			-- calculate oscillating radius
			local r = ((x * x) + (y * y)) + 10 * math.sin(t / 2.5)
			-- apply time-dependent rotation
			local x1 = x * math.cos(t) - y * math.sin(t)
			local y1 = x * math.sin(t) + y * math.cos(t)
			-- calculate pixel position to draw
			local w, h = screen.InternalRes.W, screen.InternalRes.H
			local px = w / 2 + (r - p:get("b")) * x1
			local py = h / 2 + (r - p:get("a")) * y1
			px = px + 8 * math.cos(r)
			-- calculate color position in lookup table
			local col = -r * 2 + math.atan(x1, y1)
			col = palettes.getColor(PALETTE, (math.floor(col) % 16) + 1)
			-- add to list of points to draw
			if inScreen(px, py) then
				--table.insert(points_list, {px, py, col[1], col[2], col[3], patch.env:Calculate(t)})
				love.graphics.setColor(col[1], col[2], col[3], patch.env:Calculate(t))
				love.graphics.rectangle("fill", px, py, 3,3)
			end
		end
	end


	return patch:drawExec()
end


function patch.update()
	patch:mainUpdate()
	patch.timers.bpm:update()

	patch.env:UpdateTrigger(patch.timers.bpm:Activated())
end


function patch.commands(s)

end


return patch