local Patch = lovjRequire("lib/patch")
local palettes = lovjRequire("lib/utils/palettes")
local kp = lovjRequire("lib/utils/keypress")
local Envelope = lovjRequire("lib/signals/envelope")
local Lfo = lovjRequire("lib/signals/lfo")
local Timer = lovjRequire("lib/timer")
local cfg_timers = lovjRequire("cfg/cfg_timers")
local cfg_shaders = lovjRequire("cfg/cfg_shaders")

-- declare palette
local PALETTE

local shader_code = [[
	#pragma language glsl3
	uniform float _time;
	uniform float _ballSize;
	extern float _colorInversion;
	extern vec3 _cameraMovement;

	// Constants
	#define PI 3.1415925359
	#define TWO_PI 6.2831852
	#define MAX_STEPS 100
	#define MAX_DIST 50.
	#define SURFACE_DIST .1

	vec3 pMod2(inout vec3 p, float size){
		float halfsize = size*0.5;
		vec3 c = floor((p+halfsize)/size);
		p = mod(p+halfsize,size)-halfsize;
		return c;
	}

	float GetDist(vec3 p)
	{
		vec3 coords = vec3(1. , 1. , 2.);
		vec4 s = vec4(coords, _ballSize+.3*sin(_time*3.+p.z+p.x/10+p.y)); //Sphere. xyz is position w is radius
		float sphereDist = length(mod(p, 2.5)-s.xyz) - s.w;
		//float planeDist = p.y;
		//float d = min(sphereDist,planeDist);
		float d = sphereDist;
		return d;
	}

	float RayMarch(vec3 ro, vec3 rd)
	{
		float dO = 0.; // Distance Origin
		for(int i=0;i<MAX_STEPS;i++)
		{
			vec3 p = ro + rd * dO;
			float ds = GetDist(p); // ds is Distance Scene
			dO += ds;
			if(dO > MAX_DIST || ds < SURFACE_DIST) break;
		}
		return dO;
	}

	vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
	{
        vec2 uv = (texture_coords - .5);

		vec3 ro = vec3(-.2, 1., 0.);
		ro += _cameraMovement;
        ro += vec3(0.,_time*5, _time*20); // Camera position

        vec3 rd = normalize(vec3(uv.x, uv.y, 1));
        float d = RayMarch(ro,rd);
        d /= 50.;
        vec3 output_color = vec3(d + (1. - 2*d)*_colorInversion);

        return vec4(output_color, 1.);
	}
]]

local patch = Patch:new()

--- @private init_params initialize patch parameters
local function init_params()
	local g = patch.resources.graphics
	local p = patch.resources.parameters

	p:setName(1, "colorInversion") p:set("colorInversion", 0)
	p:setName(2, "ballSize") p:set("ballSize", .1)

	patch.resources.parameters = p
end

--- @public patchControls evaluate user keyboard controls
function patch.patchControls()
	local p = patch.resources.parameters
	-- update the colorInversion parameter
	if kp.isDown("up") then p:set("colorInversion", p:get("colorInversion")+.1) end
	if kp.isDown("down") then p:set("colorInversion", p:get("colorInversion")-.1) end
	-- clamp colorInversion between 0 and 1
	p:set("colorInversion", math.min(math.max(p:get("colorInversion"), 0), 1) )

	if kp.isDown("left") then p:set("ballSize", p:get("ballSize")-.01) end
	if kp.isDown("right") then p:set("ballSize", p:get("ballSize")+.01) end
	-- clamp colorInversion between 0 and 1
	p:set("ballSize", math.min(math.max(p:get("ballSize"), 0), .7) )


end


--- @public init init routine
function patch.init(slot)
	Patch.init(patch, slot)
	PALETTE = palettes.PICO8
	patch:setCanvases()
	init_params()
end

--- @private draw_bg draw background graphics
local function draw_stuff()
	local g = patch.resources.graphics
	local p = patch.resources.parameters

	local t = cfg_timers.globalTimer.T

	local c = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
	love.graphics.setCanvas(c)

	local shader
	if cfg_shaders.enabled then
		shader = love.graphics.newShader(shader_code)
		love.graphics.setShader(shader)
		shader:send("_time", t)
		shader:send("_colorInversion", p:get("colorInversion"))
		shader:send("_ballSize", p:get("ballSize"))
		shader:send("_cameraMovement", {t,0,0})
	end

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

	patch:mainUpdate()
end


function patch.commands(s)

end

return patch