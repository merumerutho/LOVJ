extern float _time;
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
	vec2 uv = texture_coords;

	vec2 center = vec2(0.5, 0.5);

	vec2 delta = uv - center;
	float distance = length(delta);
	float angle = atan(delta.y, delta.x);

	float swirlAmount = (5*sin(_time*2) + 10);
	float swirlRadius = 0.5;
	float swirlAngle = swirlAmount * distance;

	vec2 distortedUV = center + 0.707*vec2(cos(angle + swirlAngle), sin(angle + swirlAngle)) * distance;

	color = vec4(Texel(tex, distortedUV));
	return color;
}