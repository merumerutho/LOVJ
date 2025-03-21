// @param float _blurOffset 0.25 //

extern float _blurOffset;
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	color = vec4(Texel(tex, texture_coords));
	vec4 color2 = vec4(Texel(tex, texture_coords - _blurOffset));
	vec4 color3 = vec4(Texel(tex, texture_coords + _blurOffset));
	return (color+color2+color3)/3;
}