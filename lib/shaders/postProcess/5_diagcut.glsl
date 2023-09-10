vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec2 new_coords;
	new_coords = texture_coords - mod(texture_coords.y + texture_coords.x, 0.2);
	return vec4(Texel(tex, new_coords));
}