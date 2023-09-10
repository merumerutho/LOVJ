vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
	// up or down side of screen.
	float ud = clamp(sign(texture_coords.y - 0.5), 0., 1.);
	// flip on the y axis
	texture_coords.y = texture_coords.y - ud * (2*(texture_coords.y - 0.5));
	return vec4(Texel(tex, texture_coords));
}