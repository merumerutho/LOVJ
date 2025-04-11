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

local shader_code = [[
	#pragma language glsl3

	extern float _time;

	float spikyExplosion(vec3 pos) {
		float radius = length(pos);
		vec3 dir = normalize(pos);

		float t = _time;
		float angularNoise =
			sin(dot(mod(dir.xy + _time * 0.1, 0.25), vec2(3.0, 1.3)) * 2.0 + t * 0.5) +
			sin(dot(dir.yz, vec2(1.5, 2.8)) * 2.5 + t * 0.35) +
			sin(dot(dir.zx, vec2(2.1, 3.3)) * 1.5 + t * 0.25);

		float radialDistortion = sin(radius * 4.0 + angularNoise * 1.5);
		return radius - (0.1 + 2. * radialDistortion* (1.+.2*sin(length(t*.1+pos.xz*.15))*3.5));
	}

	float map(vec3 pos) {
		pos += 0.05 * sin(pos.z*4. + _time * 2.5);
		return spikyExplosion(pos);
	}

	vec3 getNormal(vec3 pos, float t) {
		float e = max(0.05, 0.01 * t);
		return normalize(vec3(
			map(pos + vec3(e, 0, 0)) - map(pos - vec3(e, 0, 0)),
			map(pos + vec3(0, e, 0)) - map(pos - vec3(0, e, 0)),
			map(pos + vec3(0, 0, e)) - map(pos - vec3(0, 0, e))
		));
	}

	mat3 rotateY(float a) {
		float c = cos(a), s = sin(a);
		return mat3(c, 0.0, -s, 0.0, 1.0, 0.0, s, 0.0, c);
	}

	mat3 rotateX(float a) {
		float c = cos(a), s = sin(a);
		return mat3(1.0, 0.0, 0.0, 0.0, c, -s, 0.0, s, c);
	}

	vec3 lighting(vec3 p, vec3 n, vec3 rd) {
		vec3 lightDir = normalize(vec3(1.2, 1.0, 2.5));
		vec3 h = normalize(lightDir - rd);
		float diff = max(dot(n, lightDir), 0.0);
		float spec = pow(max(dot(n, h), 0.0), 18.0);
		float fresnel = pow(1.0 - max(dot(n, -rd), 0.0), 2.0);

		float tWave = 0.5 + 0.5 * sin(_time * 0.6);
		vec3 dynamicBlue = mix(vec3(0.1, 0.35, 0.8), vec3(0.2, 0.6, 1.0), tWave);
		vec3 base = mix(dynamicBlue, vec3(1.0), diff);
		vec3 highlight = mix(vec3(0.7, 0.85, 1.0), vec3(1.0), spec) * (spec + fresnel);

		return base + highlight;
	}

	vec3 render(vec2 uv) {
		vec3 ro = vec3(0.0, 0.0, -3.5 + sin(_time));
		vec3 rd = normalize(vec3(uv, 1.0));
		mat3 camRot = rotateY(_time * 0.4) * rotateX(_time * 0.2);
		ro = camRot * ro;
		rd = camRot * rd;

		float t = 0.0;
		bool hit = false;
		vec3 p;
		float d;

		for (int i = 0; i < 400; i++) {
			p = ro + rd * t;
			d = map(p);
			if (d < 0.001) {
				hit = true;
				break;
			}
			t += min(d * 0.5, 0.01);
			if (t > 20.0) break;
		}

		vec3 col = vec3(0.0);
		if (hit) {
			vec3 n = getNormal(p, t);
			col = lighting(p, n, rd);
		}

		float glow = pow(1.0 - length(uv), 5.0);
		col += glow * vec3(0.2, 0.3, 0.9);
		return clamp(col, 0.0, 1.0);
	}

	vec4 effect(vec4 color, Image tex, vec2 texCoord, vec2 screenCoord) {
		vec2 uv = texCoord - .5;
    uv = uv * (1.+0.25*mod(sin(_time+(uv.x+uv.y*uv.y)), 0.12));
		uv.x *= love_ScreenSize.x / love_ScreenSize.y;
		vec3 colorOut = render(uv);
		return vec4(colorOut, 1.0);
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

	patch.lfo = Lfo:new(1.,0)
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
	local t = cfg_timers.globalTimer.T

	patch:mainUpdate()
	patch.lfo:UpdateTrigger(t)
end


function patch.commands(s)

end

return patch