extern float _glitchDisplace;
extern float _glitchFreq;
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
	texture_coords[0] += (0.01 + _glitchDisplace)*sin(texture_coords[0]*100*_glitchFreq);
	texture_coords[0] = mod(texture_coords[0], 1);
	return vec4(Texel(tex, texture_coords));
}