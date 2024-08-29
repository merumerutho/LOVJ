local Patch = lovjRequire("lib/patch")
local palettes = lovjRequire("lib/utils/palettes")
local kp = lovjRequire("lib/utils/keypress")
local Timer = lovjRequire("lib/timer")
local cfg_timers = lovjRequire("cfg/cfg_timers")
local cfg_screen = lovjRequire("cfg/cfg_screen")
local Envelope = lovjRequire("lib/signals/envelope")
local Lfo = lovjRequire("lib/signals/lfo")

local patch = Patch:new()

local PALETTE

--- @private init_params initialize patch parameters
local function init_params()
	local g = patch.resources.graphics
	local p = patch.resources.parameters

	patch.resources.parameters = p
	patch.resources.graphics = g
end

--- @public patchControls evaluate user keyboard controls
function patch.patchControls()
	local p = patch.resources.parameters
	if love.keyboard.isDown("r") then patch.init(patch.slot) cfg_timers.globalTimer:reset() end
end


--- @public setCanvases (re)set canvases for this patch
function patch:setCanvases()
	Patch.setCanvases(patch)  -- call parent function
    
	-- patch-specific execution (window canvas)
	if cfg_screen.UPSCALE_MODE == cfg_screen.LOW_RES then
        patch.canvases.c1 = love.graphics.newCanvas(2*screen.InternalRes.W, 2*screen.InternalRes.H)
		patch.canvases.fbk = love.graphics.newCanvas(2*screen.InternalRes.W, 2*screen.InternalRes.H)
		patch.canvases.bak = love.graphics.newCanvas(2*screen.InternalRes.W, 2*screen.InternalRes.H)
		patch.canvases.top1 = love.graphics.newCanvas(2*screen.InternalRes.W, 2*screen.InternalRes.H)
		patch.canvases.top2 = love.graphics.newCanvas(2*screen.InternalRes.W, 2*screen.InternalRes.H)
		patch.canvases.globaltop = love.graphics.newCanvas(2*screen.InternalRes.W, 2*screen.InternalRes.H)
	else
		patch.canvases.c1 = love.graphics.newCanvas(2*screen.ExternalRes.W, 2*screen.ExternalRes.H)
		patch.canvases.fbk = love.graphics.newCanvas(2*screen.ExternalRes.W, 2*screen.ExternalRes.H)
		patch.canvases.bak = love.graphics.newCanvas(2*screen.ExternalRes.W, 2*screen.ExternalRes.H)
		patch.canvases.top1 = love.graphics.newCanvas(2*screen.ExternalRes.W, 2*screen.ExternalRes.H)
		patch.canvases.top2 = love.graphics.newCanvas(2*screen.ExternalRes.W, 2*screen.ExternalRes.H)
		patch.canvases.globaltop = love.graphics.newCanvas(2*screen.ExternalRes.W, 2*screen.ExternalRes.H)
	end
end


--- @public init init routine
function patch.init(slot)
	Patch.init(patch, slot)

	PALETTE = palettes.PICO8

	patch:setCanvases()
    
	init_params()
end


--- @public patch.draw draw routine
function patch.draw()
	local t = cfg_timers.globalTimer.T

	local cx, cy = screen.InternalRes.W , screen.InternalRes.H


	patch:drawSetup()

    -- ## main graphics pipeline ##
    love.graphics.setColor(1,1,1,1)
	love.graphics.setCanvas(patch.canvases.c1)
	love.graphics.clear(0,0,0,0)  -- erase as transparent


	--for i = 30, 0, -1 do
	--	love.graphics.setColor(1,1,1-i/100,1)
	--	love.graphics.circle("fill", cx , cy, i + 50*math.abs(math.sin(2*math.pi*t)))
	--end

	-- spheres play
	for i = -10, 10, .5 do
		local c = 1--((i+20)/10)
		love.graphics.setColor(c, c, c, 1)
		love.graphics.circle("fill",
							 cx + 100 * math.sin(2*math.pi*(t/30+i/3)) + 50* math.cos(2*math.pi*(t/100 + i/40)),
							 cy + 80 * math.cos(2*math.pi*(t/10+i/20)) + 50 * math.sin(2*math.pi*(t/100 + i/40)),
							 7)
	--	local r = 300 + 50 * math.cos(2*math.pi*(t+i/100))
	--	local lx = cx
	--	love.graphics.setColor(i/50,1,1,1)
	--	love.graphics.line(lx + i, cy-r/2, lx-i, cy+r/2)
	end


	-- rectangle play
	--local w = 20*math.max(0.5, math.sin(2*math.pi*t))
	--for i = -5, 5 do
	--	for j = -5, 5 do
	--		love.graphics.rectangle("fill", cx + i * 50 * math.sin(2*math.pi*(t/10 + i/5)) - w/2, cy + j * 50 * math.cos(2*math.pi*(t/10+j/5))- w/2, w, w)
	--	end
	--end


	-- cross rectangles
	--local cw, ch = 2*cx/3 + 100 * math.cos(2*math.pi*t/15) , 250 + 50 * math.sin(2*math.pi*t/20)
	--local crx, cry = cx/4 + (cx/4-cw/2), cy/4 + (cy/4-ch/2)

	-- erase globalTop (make it black for correct alpha multiply)
	--love.graphics.setCanvas(patch.canvases.globalTop)
	--love.graphics.clear(0,0,0,1)

	-- prepare top1
	--love.graphics.clear(0,0,0,1)
	--love.graphics.setColor(1,1,1,1)
	--love.graphics.rectangle("fill", crx, cry, cw, ch, 15, 15)
	--love.graphics.setCanvas(patch.canvases.top1)


	-- copy on top2
	--love.graphics.setCanvas(patch.canvases.top2)
	--love.graphics.clear(0,0,0, t%1)
	--love.graphics.setColor(1,1,1,1)
	--love.graphics.draw(patch.canvases.top1, cx/2, cy/2, 3.1415/2, cx/2, cy/2)


	-- ## feedback pipeline ##
    love.graphics.setCanvas(patch.canvases.fbk)
	love.graphics.draw(patch.canvases.bak, cx, cy, t%1, 1 + (t%.1)*math.abs(math.sin(t)), 1.1, cx, cy)
	love.graphics.setCanvas(patch.canvases.bak)
	love.graphics.clear(0,0,0,0)
	love.graphics.setColor(1.0,0.9,1,0.7)  -- reduced opacity
	love.graphics.draw(patch.canvases.fbk)
	love.graphics.setColor(1,1,1,1)
    love.graphics.draw(patch.canvases.c1)

	-- %% cross composition pipeline %%
	--love.graphics.setCanvas(patch.canvases.globaltop)
	--love.graphics.setColor(1,1,1,1)
	--love.graphics.draw(patch.canvases.top1, cx/2, cy/2, 0, 1, 1, cx/2, cy/2)
	--love.graphics.draw(patch.canvases.top2, cx/2, cy/2, 0, 1, 1, cx/2, cy/2)

    -- ## compose output pipeline ##
    love.graphics.setCanvas(patch.canvases.main)
	love.graphics.clear(0,0,0,0)
	--love.graphics.draw(patch.canvases.globaltop)
	love.graphics.setColor(1,1,1,1)
	love.graphics.draw(patch.canvases.fbk, -cx/2, -cy/2)
	love.graphics.setColor(1,1,1,1)
    --love.graphics.draw(patch.canvases.c1, -cx/2, -cy/2)

	--for i = 0,4 do
	--	love.graphics.circle("fill", cx/2 + 100 * math.cos(2*math.pi*(t+i/4)), cy/2 + 100 * math.sin(2*math.pi*(t+i/4)), 10)
	--end

	-- %% alphamasking pipeline %%
	--love.graphics.setBlendMode("multiply", "premultiplied")
	--love.graphics.draw(patch.canvases.globaltop)
	--love.graphics.setBlendMode("alpha")

	return patch:drawExec()
end


function patch.update()
	patch:mainUpdate()
end


function patch.commands(s)

end

return patch