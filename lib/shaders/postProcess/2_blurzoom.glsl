vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
	vec2 new_texture_coords = (texture_coords / 2) + 0.25;
	color = vec4(Texel(tex, texture_coords));
	vec4 zoomed_color = vec4(Texel(tex, new_texture_coords));

	vec4 total_color = mix(color, zoomed_color, 0.35);

	return total_color;
}