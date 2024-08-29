local Patch = lovjRequire("lib/patch")
local palettes = lovjRequire("lib/utils/palettes")
local kp = lovjRequire("lib/utils/keypress")
local Timer = lovjRequire("lib/timer")
local cfg_timers = lovjRequire("cfg/cfg_timers")
local cfg_screen = lovjRequire("cfg/cfg_screen")
local Lfo = lovjRequire("lib/signals/lfo")

local ansi_table = {
	"▀","▄","█","▌","▐","░","▒","▓"
}

local PALETTE

local textSlideShow = {"LOVJ"}

local patch = Patch:new()

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
	-- Hanger
	if kp.isDown("x") then patch.hang = true else patch.hang = false end
end

function patch:setCanvases()
	Patch.setCanvases(patch)  -- call parent function
	-- patch-specific execution (window canvas)
	if cfg_screen.UPSCALE_MODE == cfg_screen.LOW_RES then
		patch.canvases.balls = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
		patch.canvases.bg = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
	else
		patch.canvases.balls = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
		patch.canvases.bg = love.graphics.newCanvas(screen.ExternalRes.W, screen.ExternalRes.H)
	end
end


--- @public init init routine
function patch.init(slot)
	Patch.init(patch, slot)
	PALETTE = palettes.PICO8
	patch:setCanvases()

	init_params()

	patch.push = Lfo:new(0.1, 0)

	patch.fontSize = 8
	patch.ANSI_font = love.graphics.newFont("data/fonts/arial.ttf", patch.fontSize)
	patch.TXT_font = love.graphics.newFont("data/fonts/c64mono.ttf", patch.fontSize*2)
end


local function draw_spheres(t,cx,cy)
	local nSpheresX = 0
	local nSpheresY = 0
	local offsetX = 1
	local offsetY = 1

	for i=-nSpheresX/2,nSpheresX/2,offsetX do
		for j=-nSpheresY/2,nSpheresY/2,offsetY do
			local x = cx + cx/2*i
			local y = cy + cy/2*j + 6 * math.sin(t)

			love.graphics.setColor(1,1,1,1)
			love.graphics.circle("line", x, y, (t % 1) * (screen.InternalRes.W + cx) * math.sqrt(2) / 2, 8)
			for i = 0,16 do
				local c = 1- i/16
				love.graphics.setColor(i/16,i/16,i/16,i/16)
				love.graphics.circle("line", x, y, i, 8)
			end
			love.graphics.setColor(0,0,0,.5)
			love.graphics.ellipse("fill", x, y + 30 - 6 * math.sin(t), 16, 4)
			love.graphics.setColor(0,0,0,1)
			love.graphics.circle("line", x, y, 16)

		end
	end
end


local function draw_text(t,cx,cy)
	local txtString = textSlideShow[math.floor(t*1.1)%#textSlideShow+1]
	love.graphics.setFont(patch.TXT_font)
	for i = 1, #txtString do
		local c = txtString:sub(i,i)
		local x = cx + 16*(i-1) - 8*#txtString
		local y = cy + 4*math.sin((2*math.pi)*(t+(i-1)/#txtString))
		love.graphics.setColor(1,1,1,0.3)
		love.graphics.print(c, x - 4, y - 4)
		love.graphics.print(c, x + 4, y - 4)
		love.graphics.setColor(1,1,1,1)
		love.graphics.print(c, x, y - 8)
	end
end

--- @private draw_bg draw background graphics
local function draw_scene()
	local t = cfg_timers.globalTimer.T

	local g = patch.resources.graphics
	local p = patch.resources.parameters

	local cx = screen.InternalRes.W/2
	local cy = screen.InternalRes.H/2

	love.graphics.setFont(patch.ANSI_font)

	for j = -patch.fontSize, screen.InternalRes.W, patch.fontSize do
		for k = -patch.fontSize, screen.InternalRes.H, patch.fontSize do
			local x = j
			local y = k + 10*math.sin((2*math.pi)*(t + j/ 20))
			local alpha = math.abs( 1 - (t + k / 100 + j/100)%1)
			local c = (math.floor(8*t+j/10 + math.sin(t/3)*j*j/1000 +  math.sin(t/5)*k*k/1000) % #ansi_table) + 1
			love.graphics.setColor((j/100+t + j*k/1000)%1, (math.abs(math.sin(2*math.pi*t + k/200))) % 1, (c/20), alpha)
			love.graphics.print(ansi_table[c], x, y)

		end
	end

	--draw_spheres(t,cx,cy)



	--draw_text(t,cx,cy)


end

--- @public patch.draw draw routine
function patch.draw()
	patch:drawSetup(patch.hang)

	-- clear main canvas
	patch.canvases.main:renderTo(function()
									love.graphics.clear(0,0,0,1)
								end )

	-- draw picture
	draw_scene()

	return patch:drawExec()
end


function patch.update()
	local t = cfg_timers.globalTimer.T

	patch.push:UpdateTrigger(true)

	patch:mainUpdate()
end


function patch.commands(s)



end

return patch