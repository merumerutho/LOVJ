extern float _windowSize;
extern float _scx;
extern float _scy;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	float dist = length(texture_coords - vec2(_scx, _scy));
	color = vec4(Texel(tex, texture_coords).xyz, 0.25 + 0.75 * step(_windowSize, 1.-dist));
	return color;
}