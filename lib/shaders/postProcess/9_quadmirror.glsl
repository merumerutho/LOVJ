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