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
    extern vec4 trailColor;
    vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
	{
        vec4 texcolor = Texel(tex, texture_coords);
        texcolor *= trailColor;
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

return shaders