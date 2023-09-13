extern vec4 _trailColor;
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
	vec4 texcolor = Texel(tex, texture_coords);
	texcolor *= _trailColor;
	return vec4(texcolor);
}