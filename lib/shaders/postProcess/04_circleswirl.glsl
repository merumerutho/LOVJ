// @param float _time 0 //
// @param float _swirlmodx 0.1 //
// @param float _swirlmody 0.1 //

extern float _time, _swirlmodx, _swirlmody;
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
	vec2 uv = texture_coords;

	vec2 center = vec2(0.5, 0.5);

	vec2 delta = uv - center;
	float distance = length(delta);
	float angle = atan(delta.y, delta.x);

	float swirlAmount = 0.5*(sin(_time) + 1);
	float swirlRadius = 0.5;
	float swirlAngle = swirlAmount * distance / swirlRadius;

	vec2 distortedUV = center + 0.707*vec2(cos(angle + swirlAngle+uv.x*_swirlmodx),
										   sin(angle + swirlAngle+uv.y*_swirlmody)) * mod(sin(_time+uv.x*uv.y), distance*2);

	distortedUV = distortedUV + 0.707 * vec2(cos(angle + swirlAngle + _time*.8), sin(angle + swirlAngle)) * distance;

	distortedUV.y = ((distortedUV.x-.1) * (distortedUV.y + .1)) + ((distortedUV.y-.1) * (distortedUV.x + .1));

	distortedUV.x += sin(distortedUV.x);
	distortedUV.x = mod(distortedUV.x, 1);

	color = vec4(Texel(tex, distortedUV));
	return color;
}