-- shaders.lua
--
-- List of shaders
--

local shaders = {}

-- default shader (does nothing)
shaders.default = [[
    vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
	{
        return vec4(Texel(tex, texture_coords));
	}
]]

-- 'trail' shader
shaders.trail = [[
    extern vec4 _trailColor;
    vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
	{
        vec4 texcolor = Texel(tex, texture_coords);
        texcolor *= _trailColor;
        return vec4(texcolor);
	}
]]

-- horizontal mirror shader
shaders.h_mirror = [[
	vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
	{
        // left or right side of screen.
        float lr = clamp(sign(texture_coords[0] - 0.5), 0., 1.);
        // flip on the x axis
        texture_coords[0] = texture_coords[0] - lr * (2*(texture_coords[0] - 0.5));
        return vec4(Texel(tex, texture_coords));
	}
]]

-- horizontal water mirror shader
shaders.w_mirror_water = [[
    //extern float _time;
	vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
	{
        // left or right side of screen.
        float lr = clamp(sign(texture_coords[1] - 0.5), 0., 1.);
        // water displacement on the y axis
        texture_coords[0] = mod(texture_coords[0] + lr * .01*texture_coords[1]*sin(50*texture_coords[1]), 1);
        // reflection on the x axis
        texture_coords[1] = texture_coords[1] - lr * (2*(texture_coords[1] - 0.5));
        return vec4(Texel(tex, texture_coords));
	}
]]

-- underwater shader
shaders.underwater = [[
    extern float _time;
	vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
	{
        // left or right side of screen.
        float lr = clamp(sign(texture_coords[1] - 0.5), 0., 1.);
        // water displacement on the y axis
        texture_coords[0] = mod(texture_coords[0] + .02*sin(10*texture_coords[1] + _time), 1);
        // reflection on the x axis
        texture_coords[1] = mod(texture_coords[1] + .01*sin(10*texture_coords[1] + _time), 1);
        return vec4(Texel(tex, texture_coords));
	}
]]

-- underwater shader
shaders.glitch = [[
    extern float _glitchDisplace;
    extern float _glitchFreq;
	vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
	{
        texture_coords[0] += (0.01 + _glitchDisplace)*sin(texture_coords[0]*100*_glitchFreq);
        texture_coords[0] = mod(texture_coords[0], 1);
        return vec4(Texel(tex, texture_coords));
	}
]]

shaders.w_mirror = [[
	vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
	{
        // up or down side of screen.
        float ud = clamp(sign(texture_coords[1] - 0.5), 0., 1.);
        // flip on the y axis
        texture_coords[1] = texture_coords[1] - ud * (2*(texture_coords[1] - 0.5));
        return vec4(Texel(tex, texture_coords));
	}
]]

shaders.wh_mirror = [[
	vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
	{
        // left or right side of screen.
        float lr = clamp(sign(texture_coords[0] - 0.5), 0., 1.);
        float ud = clamp(sign(texture_coords[1] - 0.5), 0., 1.);
        // flip on the x axis and y axis
        texture_coords[0] = texture_coords[0] - lr * (2*(texture_coords[0] - 0.5));
        texture_coords[1] = texture_coords[1] - ud * (2*(texture_coords[1] - 0.5));
        return vec4(Texel(tex, texture_coords));
	}
]]

shaders.warp = [[
    extern float _warpParameter;
    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
    {
        #define M_PI 3.1415926535897932384626433832795
        vec2 shiftUV = texture_coords - 0.5;

        float radius = sqrt(dot(shiftUV, shiftUV));
        float angle = atan(shiftUV.y, shiftUV.x); // here angle is [-pi; pi]
        angle = (angle*_warpParameter);

        //angle = min(angle, segmentAngle - angle);

        texture_coords = (vec2(cos(angle), sin(angle)) * radius) + 0.5;

        //texture_coords = max(min(texture_coords, 2.0 - texture_coords), -texture_coords);
        //return vec4(angle, 0.0, 0.0, 1.0);
        return vec4(Texel(tex, texture_coords));

    }
]]

shaders.kaleido = [[
    extern float _segmentParameter;
    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
    {
        #define M_PI 3.1415926535897932384626433832795
        vec2 shiftUV = texture_coords - 0.5;

        float radius = sqrt(dot(shiftUV, shiftUV));
        float angle = atan(shiftUV.y, shiftUV.x); // here angle is [-pi; pi]

        float segmentAngle = 2*M_PI / _segmentParameter;
        angle -= segmentAngle*floor(angle / segmentAngle);

        angle = min(angle, segmentAngle - angle);

        texture_coords = (vec2(cos(angle), sin(angle)) * radius) + 0.5;

        texture_coords = max(min(texture_coords, 2.0 - texture_coords), -texture_coords);
        //return vec4(angle, 0.0, 0.0, 1.0);
        return vec4(Texel(tex, texture_coords));

    }
]]

shaders.chromakey = [[
    extern vec4 _chromaColor;
    extern vec2 _chromaTolerance;
    vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
	{
        vec4 texColor = Texel(tex, texture_coords);
        // calculate norm of difference wrt chromaColor (discard alpha)
        float diff = length(texColor.xyz - _chromaColor.xyz);
        // low difference => low alpha
        float alpha = smoothstep(_chromaTolerance.x, _chromaTolerance.y, diff);
        // return color with alpha applied
        texColor.w = alpha;
        return texColor;
	}
]]


shaders.diag_cut = [[
    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
    {
        vec2 new_coords;
        new_coords = texture_coords - mod(texture_coords.y + texture_coords.x, 0.2);
        return vec4(Texel(tex, new_coords));
    }
]]

shaders.blur = [[
    extern float _blurOffset;
    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
    {
        color = vec4(Texel(tex, texture_coords));
        vec4 color2 = vec4(Texel(tex, texture_coords - _blurOffset));
        vec4 color3 = vec4(Texel(tex, texture_coords + _blurOffset));
        return (color+color2+color3)/3;
    }
]]

shaders.circleWindow = [[
    #pragma language glsl3

    extern float _windowSize;
    extern float _scx;
    extern float _scy;

    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
    {
        float dist = length(texture_coords - vec2(_scx, _scy));
        color = vec4(Texel(tex, texture_coords).xyz, 0.25 + 0.75 * step(_windowSize, 1.-dist));
        return color;
    }
]]

return shaders