local Patch = lovjRequire("lib/patch")
local palettes = lovjRequire("lib/utils/palettes")
local kp = lovjRequire("lib/utils/keypress")
local Envelope = lovjRequire("lib/signals/envelope")
local Lfo = lovjRequire("lib/signals/lfo")
local Timer = lovjRequire("lib/timer")
local cfg_timers = lovjRequire("cfg/cfg_timers")
local cfg_shaders  = lovjRequire("cfg/cfg_shaders")

-- declare palette
local PALETTE

local patch = Patch:new()

local sea_reflection = love.graphics.newShader("lib/shaders/postProcess/19_sea_reflection.glsl")

local t

--- @private init_params initialize patch parameters
local function init_params()
	local g = patch.resources.graphics
	local p = patch.resources.parameters

	p:setName(1, "moonSize") p:set("moonSize", 1.)

	patch.resources.parameters = p
end

--- @public patchControls evaluate user keyboard controls
function patch.patchControls()
	local p = patch.resources.parameters

	if kp.isDown("left") then p:set("moonSize", p:get("moonSize")-.01) end
	if kp.isDown("right") then p:set("moonSize", p:get("moonSize")+.01) end
	-- clamp colorInversion between 0 and 1
	p:set("moonSize", math.min(math.max(p:get("moonSize"), 0), 2.) )
end


--- @public init init routine
function patch.init(slot)
	Patch.init(patch, slot)
	PALETTE = palettes.PICO8
	patch:setCanvases()

	init_params()
	
	t = 0

	patch.lfo = Lfo:new(1.,0)
end

--- @private draw_bg draw background graphics
local function draw_stuff()
	local sw, sh = screen.InternalRes.W, screen.InternalRes.H
	
	local g = patch.resources.graphics
	local p = patch.resources.parameters

	local c = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
	
	love.graphics.setCanvas(c)
	---  DRAW HERE
	love.graphics.setColor(1,1,1)  -- white 
	love.graphics.circle("fill", sw/2, sh/4, math.sqrt(sw^2 + sh^2)/10 * p:get("moonSize"))

	if cfg_shaders.enabled then
		love.graphics.setShader(sea_reflection)
	end
  ---  STOP DRAWING HERE
  
  love.graphics.setCanvas(patch.canvases.main)
  
	love.graphics.draw(c)

end

--- @public patch.draw draw routine
function patch.draw()
	patch:drawSetup()

	-- draw picture
	draw_stuff()

	return patch:drawExec()
end


function patch.update()
  -- reflection time
  if cfg_shaders.enabled then
    sea_reflection:send("_time", cfg_timers.globalTimer.T) 
  end

	patch:mainUpdate()
	patch.lfo:UpdateTrigger(t)
end


function patch.commands(s)

end

return patch