vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
	vec2 distortedUv = texture_coords;
	distortedUv.y = ((distortedUv.y-.5) * (distortedUv.y - .5));
	return vec4(Texel(tex, distortedUv));
}