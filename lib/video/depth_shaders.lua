local DepthFX = {}

-- Pass 1: Estimate depth from multiple visual cues
DepthFX.estimate = love.graphics.newShader([[
	extern float _darkChannelWeight;
	extern float _saturationWeight;
	extern float _blueShiftWeight;
	extern float _sharpnessWeight;
	extern float _verticalWeight;
	extern vec2 _texelSize;

	float luminance(vec3 c) {
		return dot(c, vec3(0.299, 0.587, 0.114));
	}

	vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
		vec4 pixel = Texel(tex, tc);
		vec3 rgb = pixel.rgb;
		float depth = 0.0;
		float totalWeight = 0.001;

		// Dark channel prior: min(R,G,B) over a local patch
		// Low values = hazy/distant
		if (_darkChannelWeight > 0.0) {
			float darkMin = 1.0;
			for (int dx = -1; dx <= 1; dx++) {
				for (int dy = -1; dy <= 1; dy++) {
					vec3 s = Texel(tex, tc + vec2(float(dx), float(dy)) * _texelSize * 3.0).rgb;
					darkMin = min(darkMin, min(s.r, min(s.g, s.b)));
				}
			}
			// High dark channel = close, low = far
			depth += (1.0 - darkMin) * _darkChannelWeight;
			totalWeight += _darkChannelWeight;
		}

		// Saturation: low saturation = distant (atmospheric desaturation)
		if (_saturationWeight > 0.0) {
			float maxC = max(rgb.r, max(rgb.g, rgb.b));
			float minC = min(rgb.r, min(rgb.g, rgb.b));
			float sat = (maxC > 0.001) ? (maxC - minC) / maxC : 0.0;
			// High saturation = close
			depth += sat * _saturationWeight;
			totalWeight += _saturationWeight;
		}

		// Blue shift: distant objects are more blue
		if (_blueShiftWeight > 0.0) {
			float blueExcess = rgb.b - (rgb.r + rgb.g) * 0.5;
			float blueDepth = 1.0 - clamp(blueExcess * 2.0 + 0.5, 0.0, 1.0);
			depth += blueDepth * _blueShiftWeight;
			totalWeight += _blueShiftWeight;
		}

		// Local sharpness via Laplacian: sharp = close
		if (_sharpnessWeight > 0.0) {
			float center = luminance(rgb) * 4.0;
			float neighbors = luminance(Texel(tex, tc + vec2(_texelSize.x, 0.0)).rgb)
			               + luminance(Texel(tex, tc - vec2(_texelSize.x, 0.0)).rgb)
			               + luminance(Texel(tex, tc + vec2(0.0, _texelSize.y)).rgb)
			               + luminance(Texel(tex, tc - vec2(0.0, _texelSize.y)).rgb);
			float laplacian = abs(center - neighbors);
			depth += clamp(laplacian * 5.0, 0.0, 1.0) * _sharpnessWeight;
			totalWeight += _sharpnessWeight;
		}

		// Vertical position: higher in frame = further
		if (_verticalWeight > 0.0) {
			depth += (1.0 - tc.y) * _verticalWeight;
			totalWeight += _verticalWeight;
		}

		depth /= totalWeight;
		return vec4(depth, depth, depth, 1.0);
	}
]])

-- Pass 2: Two-pass separable Gaussian blur for smooth depth map
DepthFX.blurH = love.graphics.newShader([[
	extern vec2 _texelSize;
	extern float _sigma;

	vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
		vec4 sum = vec4(0.0);
		float total = 0.0;
		int r = int(_sigma * 3.0);
		float s2 = _sigma * _sigma * 2.0;
		for (int i = -r; i <= r; i++) {
			float w = exp(-float(i*i) / s2);
			sum += Texel(tex, tc + vec2(float(i) * _texelSize.x, 0.0)) * w;
			total += w;
		}
		return sum / total;
	}
]])

DepthFX.blurV = love.graphics.newShader([[
	extern vec2 _texelSize;
	extern float _sigma;

	vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
		vec4 sum = vec4(0.0);
		float total = 0.0;
		int r = int(_sigma * 3.0);
		float s2 = _sigma * _sigma * 2.0;
		for (int i = -r; i <= r; i++) {
			float w = exp(-float(i*i) / s2);
			sum += Texel(tex, tc + vec2(0.0, float(i) * _texelSize.y)) * w;
			total += w;
		}
		return sum / total;
	}
]])

-- Pass 3: Parallax displacement using depth map
DepthFX.displace = love.graphics.newShader([[
	extern Image _depthMap;
	extern vec2 _cameraOffset;
	extern float _displaceStrength;
	extern float _dofAmount;
	extern vec2 _texelSize;

	vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
		float depth = Texel(_depthMap, tc).r;

		// Parallax: displace based on depth and camera offset
		// Close objects (depth~1) move more, far objects (depth~0) move less
		vec2 offset = _cameraOffset * depth * _displaceStrength;
		vec2 displaced_tc = clamp(tc + offset, vec2(0.0), vec2(1.0));
		vec4 pixel = Texel(tex, displaced_tc);

		// Depth-of-field: blur distant objects
		if (_dofAmount > 0.0) {
			float blur = (1.0 - depth) * _dofAmount;
			int r = int(blur * 4.0);
			if (r > 0) {
				vec4 sum = pixel;
				float total = 1.0;
				for (int dx = -r; dx <= r; dx++) {
					for (int dy = -r; dy <= r; dy++) {
						if (dx == 0 && dy == 0) continue;
						float w = 1.0 / (1.0 + float(dx*dx + dy*dy));
						sum += Texel(tex, displaced_tc + vec2(float(dx), float(dy)) * _texelSize * blur) * w;
						total += w;
					}
				}
				pixel = sum / total;
			}
		}

		return pixel;
	}
]])

return DepthFX
