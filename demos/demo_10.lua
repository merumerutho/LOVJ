local Patch = lovjRequire("lib/patch")
local palettes = lovjRequire("lib/utils/palettes")
local kp = lovjRequire("lib/utils/keypress")
local Envelope = lovjRequire("lib/automations/envelope")
local Lfo = lovjRequire("lib/automations/lfo")
local Timer = lovjRequire("lib/timer")
local cfg_timers = lovjRequire("lib/cfg/cfg_timers")

-- declare palette
local PALETTE

local shader_code = [[
	#pragma language glsl3
	uniform float _time;

	// Constants
	#define PI 3.1415925359
	#define TWO_PI 6.2831852
	#define MAX_STEPS 100
	#define MAX_DIST 100.
	#define SURFACE_DIST .01

	vec3 pMod2(inout vec3 p, float size){
		float halfsize = size*0.5;
		vec3 c = floor((p+halfsize)/size);
		p = mod(p+halfsize,size)-halfsize;
		return c;
	}

	float GetDist(vec3 p)
	{
		vec3 coords = vec3(1. , 1.+.3*sin(_time), 2.);
		vec4 s = vec4(coords, .5+.3*sin(_time*3+p.z+p.x/10+p.y)); //Sphere. xyz is position w is radius
		float sphereDist = length(mod(p-_time, 2.5)-s.xyz) - s.w;
		//float planeDist = p.y;
		//float d = min(sphereDist,planeDist);
		float d = sphereDist;
		return d;
	}

	float RayMarch(vec3 ro, vec3 rd)
	{
		float dO = 0.; //Distane Origin
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

        vec3 ro = vec3(0,1,0); // Camera position
        vec3 rd = normalize(vec3(uv.x, uv.y, 1));
        float d = RayMarch(ro,rd);
        d /= 50.;
        vec3 output_color = vec3(d);

        return vec4(output_color, 1.);
	}
]]

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

    -- insert here your patch controls
end


--- @public init init routine
function patch.init()
	PALETTE = palettes.PICO8

	patch:setCanvases()

	init_params()

	patch:assignDefaultDraw()
end

--- @private draw_bg draw background graphics
local function draw_stuff()
	g = resources.graphics
	p = resources.parameters

	local t = cfg_timers.globalTimer.T

	local c = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
	love.graphics.setCanvas(c)

	local shader
	if cfg_shaders.enabled then
		shader = love.graphics.newShader(shader_code)
		love.graphics.setShader(shader)
		shader:send("_time", t)
	end

	love.graphics.setCanvas(patch.canvases.main)
	love.graphics.draw(c)




end

--- @public patch.draw draw routine
function patch.draw()
	patch:drawSetup()

	-- draw picture
	draw_stuff()

	patch:drawExec()
end


function patch.update()
	patch:mainUpdate()
end

return patch