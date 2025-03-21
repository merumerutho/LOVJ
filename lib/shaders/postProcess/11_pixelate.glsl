// @param float _pixres 0.1 //
extern float _pixres;
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
	vec2 distortedUv = floor(texture_coords*_pixres) / _pixres;
	return vec4(Texel(tex, distortedUv));
}