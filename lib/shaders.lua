shaders = {}

-- default shader (does nothing)
shaders.default = [[
    vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
	{
        vec4 texcolor = Texel(tex, texture_coords);
        return texcolor*color;
	}
]]

-- 'trail' shader
shaders.trail = [[
    extern vec4 _trailColor;
    vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
	{
        vec4 texcolor = Texel(tex, texture_coords);
        texcolor *= _trailColor;
        return texcolor*color;
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
        // return color
        vec4 texcolor = Texel(tex, texture_coords);
        return texcolor*color;
	}
]]

shaders.w_mirror = [[
	vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
	{
        // up or down side of screen.
        float ud = clamp(sign(texture_coords[1] - 0.5), 0., 1.);
        // flip on the y axis
        texture_coords[1] = texture_coords[1] - ud * (2*(texture_coords[1] - 0.5));
        // return color
        vec4 texcolor = Texel(tex, texture_coords);
        return texcolor*color;
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
        // return color
        vec4 texcolor = Texel(tex, texture_coords);
        return texcolor*color;
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

return shaders