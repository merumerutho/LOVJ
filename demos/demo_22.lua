local Patch = lovjRequire("lib/patch")
local palettes = lovjRequire("lib/utils/palettes")
local kp = lovjRequire("lib/utils/keypress")
local Timer = lovjRequire("lib/timer")
local cfg_timers = lovjRequire("cfg/cfg_timers")
local cfg_screen = lovjRequire("cfg/cfg_screen")
local Lfo = lovjRequire("lib/signals/lfo")

local ansi_table = {
	"w","i","r","e","d","s","o","u","l"
}

local PALETTE

local textSlideShow = {"wired sound, wired soul, "}

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
	local offsetX = .1
	local offsetY = 1
    local n = 64
    i = 0
    j = 0
	--for i=-nSpheresX/2,nSpheresX/2,offsetX do
		--for j=-nSpheresY/2,nSpheresY/2,offsetY do
			local x = cx + cx/2*i
			local y = cy + cy/2*j + 20 * math.sin(t)

			love.graphics.setColor(1,1,1,1)
			--love.graphics.circle("line", cx, cy, (t % 1) * (screen.InternalRes.W + cx) * math.sqrt(2) / 2 , 8 )
			for i = 0, n do
				local c = 1- i/n
				love.graphics.setColor(i/n,i/n,i/n,i/n)
				love.graphics.circle("line", x, y, math.exp(i/10), 8)
			end
			--love.graphics.setColor(0,0,0,.5)
			--love.graphics.ellipse("fill", x, y + 30 - 6 * math.sin(t), 16, 4)
			--love.graphics.setColor(0,0,0,1)
			--love.graphics.circle("line", x, y, 16)

		--end
	--end
end


local function draw_text(t,cx,cy, alpha)
	local txtString = textSlideShow[math.floor(t*1.1)%#textSlideShow+1]
	love.graphics.setFont(patch.TXT_font)
	for i = 1, #txtString do
        local idx = math.floor(t*20 + i + cy/2) % #txtString + 1
		local c = txtString:sub(idx, idx)
		local x = cx + 16*(i-1) - 8*#txtString
		local y = cy + 4*math.sin((2*math.pi)*(t+(i-1)/#txtString))
		love.graphics.setColor(1,1,1,alpha*0.3)
		love.graphics.print(c, x - 4, y - 4)
		love.graphics.print(c, x + 4, y - 4)
		love.graphics.setColor(1,1,1,alpha)
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

    --draw_spheres(t,cx,cy)
    
    for j = -8, 8 do
    --    draw_text(t, cx, cy + j*16, .3)
    end
    
	for j = -25, 25, 1 do
		for k = -20, 20, .5 do
			local x = cx + j * (4 + 8*math.sin(k/10+t)) 
			local y = cy + k * 8 + (j*k/20)+(k*j)*math.sin(t)
			local alpha = math.abs( 1 - (t + .5*math.sin(t + k/10 + j/10)) % 1)
            local size = 2*(j+k) + math.sin(t+j-k) * 40
            love.graphics.setColor((math.abs(alpha+j-k+math.sin(t*2)))*.05, alpha+.4 - math.sin(t+j/10)%3, .3 + .2*math.abs(math.sin(k+t)), alpha)
            love.graphics.arc("fill", 20*math.sin(k)+x, y, size, 0.5*math.sin(t+k), .1*math.sin(j*k*10), 1)
		end
	end
    
    love.graphics.setColor(0,0,0,1)
    
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