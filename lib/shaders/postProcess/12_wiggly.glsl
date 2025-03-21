// @param float _time 0 //
extern float _time;
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
	// left or right side of screen.
	float lr = clamp(sign(texture_coords.y - 0.5), 0., 1.);
	// water displacement on the y axis
	texture_coords.x = mod(texture_coords.x + .1*sin(10*texture_coords.y*5 + _time), 1);
	// reflection on the x axis
	texture_coords.y = mod(texture_coords.y + .01*sin(10*texture_coords.y + _time), 1);
	return vec4(Texel(tex, texture_coords));
}