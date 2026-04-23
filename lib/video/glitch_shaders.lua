local GlitchFX = {}

GlitchFX.blockDisplace = love.graphics.newShader([[
	extern float _intensity;
	extern float _time;
	extern float _blockSize;

	float hash(vec2 p) {
		return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
	}

	vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
		vec2 block = floor(tc * _blockSize) / _blockSize;
		float h = hash(block + floor(_time * 2.0));
		float trigger = step(1.0 - _intensity * 0.3, h);
		float dx = (hash(block + vec2(0.5, 0.0)) - 0.5) * _intensity * 0.15 * trigger;
		float dy = (hash(block + vec2(0.0, 0.5)) - 0.5) * _intensity * 0.15 * trigger;
		return Texel(tex, clamp(tc + vec2(dx, dy), vec2(0.0), vec2(1.0)));
	}
]])

GlitchFX.channelShift = love.graphics.newShader([[
	extern float _intensity;
	extern float _time;

	vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
		float shift = _intensity * 0.02;
		float t = sin(_time * 3.0) * shift;
		float r = Texel(tex, tc + vec2(t, 0.0)).r;
		float g = Texel(tex, tc).g;
		float b = Texel(tex, tc - vec2(t, 0.0)).b;
		float a = Texel(tex, tc).a;
		return vec4(r, g, b, a);
	}
]])


GlitchFX.quantize = love.graphics.newShader([[
	extern float _intensity;
	extern float _time;

	vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
		vec4 pixel = Texel(tex, tc);
		float levels = max(2.0, 256.0 - _intensity * 500.0);
		pixel.rgb = floor(pixel.rgb * levels + 0.5) / levels;
		return pixel;
	}
]])

GlitchFX.hSmear = love.graphics.newShader([[
	extern float _intensity;
	extern float _time;
	extern float _threshold;

	vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
		vec4 pixel = Texel(tex, tc);
		float luma = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));

		if (luma > _threshold) {
			float sortOffset = _intensity * 0.25 * (luma - _threshold);
			vec2 sorted_tc = vec2(tc.x + sortOffset, tc.y);
			pixel = Texel(tex, clamp(sorted_tc, vec2(0.0), vec2(1.0)));
		}
		return pixel;
	}
]])

GlitchFX.frameEcho = love.graphics.newShader([[
	extern float _intensity;
	extern float _time;
	extern Image _prevFrame;
	extern float _hasPrev;

	vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
		vec4 current = Texel(tex, tc);
		if (_hasPrev < 0.5) return current;

		float displaceAmt = _intensity * 0.03;
		vec2 offset = vec2(
			sin(_time * 1.7 + tc.y * 5.0) * displaceAmt,
			cos(_time * 2.3 + tc.x * 5.0) * displaceAmt
		);
		vec4 prev = Texel(_prevFrame, tc + offset);
		float blend = _intensity * 0.5;
		return mix(current, prev, blend);
	}
]])

return GlitchFX
