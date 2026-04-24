local DepthFX = {}

-- Pass 1: Estimate depth from multiple visual cues
DepthFX.estimate = love.graphics.newShader([[
	extern float _darkChannelWeight;
	extern float _saturationWeight;
	extern float _blueShiftWeight;
	extern float _sharpnessWeight;
	extern float _verticalWeight;
	extern float _edgeWeight;
	extern float _textureWeight;
	extern float _coherenceWeight;
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
		if (_darkChannelWeight > 0.0) {
			float darkMin = 1.0;
			for (int dx = -1; dx <= 1; dx++) {
				for (int dy = -1; dy <= 1; dy++) {
					vec3 s = Texel(tex, tc + vec2(float(dx), float(dy)) * _texelSize * 3.0).rgb;
					darkMin = min(darkMin, min(s.r, min(s.g, s.b)));
				}
			}
			depth += (1.0 - darkMin) * _darkChannelWeight;
			totalWeight += _darkChannelWeight;
		}

		// Saturation: low saturation = distant
		if (_saturationWeight > 0.0) {
			float maxC = max(rgb.r, max(rgb.g, rgb.b));
			float minC = min(rgb.r, min(rgb.g, rgb.b));
			float sat = (maxC > 0.001) ? (maxC - minC) / maxC : 0.0;
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

		// Sobel edge detection: strong edges = object boundaries = foreground
		if (_edgeWeight > 0.0) {
			float tl = luminance(Texel(tex, tc + vec2(-_texelSize.x, -_texelSize.y)).rgb);
			float tm = luminance(Texel(tex, tc + vec2(0.0, -_texelSize.y)).rgb);
			float tr = luminance(Texel(tex, tc + vec2( _texelSize.x, -_texelSize.y)).rgb);
			float ml = luminance(Texel(tex, tc + vec2(-_texelSize.x, 0.0)).rgb);
			float mr = luminance(Texel(tex, tc + vec2( _texelSize.x, 0.0)).rgb);
			float bl = luminance(Texel(tex, tc + vec2(-_texelSize.x,  _texelSize.y)).rgb);
			float bm = luminance(Texel(tex, tc + vec2(0.0,  _texelSize.y)).rgb);
			float br = luminance(Texel(tex, tc + vec2( _texelSize.x,  _texelSize.y)).rgb);
			float gx = -tl - 2.0*ml - bl + tr + 2.0*mr + br;
			float gy = -tl - 2.0*tm - tr + bl + 2.0*bm + br;
			float edge = sqrt(gx*gx + gy*gy);
			depth += clamp(edge * 3.0, 0.0, 1.0) * _edgeWeight;
			totalWeight += _edgeWeight;
		}

		// Texture variance: high local variance = detail = closer
		if (_textureWeight > 0.0) {
			float mean = 0.0;
			float meanSq = 0.0;
			for (int dx = -2; dx <= 2; dx++) {
				for (int dy = -2; dy <= 2; dy++) {
					float l = luminance(Texel(tex, tc + vec2(float(dx), float(dy)) * _texelSize * 2.0).rgb);
					mean += l;
					meanSq += l * l;
				}
			}
			mean /= 25.0;
			meanSq /= 25.0;
			float variance = meanSq - mean * mean;
			depth += clamp(sqrt(variance) * 6.0, 0.0, 1.0) * _textureWeight;
			totalWeight += _textureWeight;
		}

		// Color coherence: pixels surrounded by similar colors form solid objects = foreground
		if (_coherenceWeight > 0.0) {
			float coherence = 0.0;
			for (int dx = -1; dx <= 1; dx++) {
				for (int dy = -1; dy <= 1; dy++) {
					if (dx == 0 && dy == 0) continue;
					vec3 neighbor = Texel(tex, tc + vec2(float(dx), float(dy)) * _texelSize * 4.0).rgb;
					float diff = length(rgb - neighbor);
					coherence += 1.0 - clamp(diff * 3.0, 0.0, 1.0);
				}
			}
			coherence /= 8.0;
			depth += coherence * _coherenceWeight;
			totalWeight += _coherenceWeight;
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

-- Pass 2b: Depth contrast curve (sigmoid remapping)
DepthFX.contrast = love.graphics.newShader([[
	extern float _steepness;

	vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
		float d = Texel(tex, tc).r;
		float k = _steepness * 40.0 + 1.0;
		d = 1.0 / (1.0 + exp(-k * (d - 0.5)));
		return vec4(d, d, d, 1.0);
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

-- Pass 4: Depth-based color effects (luminance mask, hue shift, desaturation, tint)
DepthFX.colorFX = love.graphics.newShader([[
	extern Image _depthMap;
	extern float _intensity;
	extern float _mode;
	extern float _target;

	vec3 rgb2hsv(vec3 c) {
		vec4 K = vec4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
		vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
		vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
		float d = q.x - min(q.w, q.y);
		float e = 1.0e-10;
		return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
	}

	vec3 hsv2rgb(vec3 c) {
		vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
		vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
		return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
	}

	vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
		vec4 pixel = Texel(tex, tc);
		float depth = Texel(_depthMap, tc).r;

		// _target: 0 = affect foreground (depth~1), 1 = affect background (depth~0)
		float mask = (_target < 0.5) ? depth : (1.0 - depth);
		float amount = mask * _intensity;
		int mode = int(_mode + 0.5);

		vec3 result = pixel.rgb;

		if (mode == 1) {
			// Luminance mask: darken affected layer
			result *= 1.0 - amount * 0.8;
		} else if (mode == 2) {
			// Hue shift: rotate hue proportional to depth
			vec3 hsv = rgb2hsv(result);
			hsv.x = fract(hsv.x + amount * 0.5);
			result = hsv2rgb(hsv);
		} else if (mode == 3) {
			// Desaturation: pull toward grayscale
			float lum = dot(result, vec3(0.299, 0.587, 0.114));
			result = mix(result, vec3(lum), amount);
		} else if (mode == 4) {
			// Warm/cool tint: warm foreground, cool background (or inverted)
			vec3 warm = vec3(1.1, 0.95, 0.8);
			vec3 cool = vec3(0.8, 0.9, 1.2);
			vec3 tint = (_target < 0.5) ? warm : cool;
			result *= mix(vec3(1.0), tint, amount);
		}

		return vec4(result, pixel.a);
	}
]])

return DepthFX
