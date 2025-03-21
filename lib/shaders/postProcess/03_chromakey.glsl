// @param vec4 _chromaColor {0.0, 1.0, 0.0, 1.0} //
// @param vec2 _chromaTolerance {-0.1, 0.1} //

extern vec4 _chromaColor;
extern vec2 _chromaTolerance;
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
	vec4 texColor = Texel(tex, texture_coords);
	// calculate norm of difference wrt chromaColor (discard alpha)
	float diff = length(texColor.xyz - _chromaColor.xyz);
	// low difference => low alpha
	float alpha = smoothstep(_chromaTolerance.x, _chromaTolerance.y, diff);
	// return color with alpha applied
	texColor.w = alpha;
	return texColor;
}