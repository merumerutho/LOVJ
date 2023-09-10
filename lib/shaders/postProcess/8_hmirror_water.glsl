//extern float _time;
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
	// left or right side of screen.
	float lr = clamp(sign(texture_coords.y - 0.5), 0., 1.);
	texture_coords.x = mod(texture_coords.x + lr * .01*texture_coords.y*sin(50*texture_coords.y), 1);
	texture_coords.y = texture_coords.y - lr * (2*(texture_coords.y - 0.5));
	return vec4(Texel(tex, texture_coords));
}