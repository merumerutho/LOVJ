// @param float _time 0 //
extern float _time;
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
    vec2 uv = texture_coords;

    float reflection_mask = step(0.5, uv.y);

    // Flip bottom half
    float flipped_y = 1.0 - uv.y;
    uv.y = mix(uv.y, flipped_y, reflection_mask);

    // Wave distortion
    float wave_amplitude = 0.01;
    float wave_frequency = 10.0;
    float wave_speed = 2.0;
    float wave_distortion = sin(uv.y * wave_frequency + _time * wave_speed) * wave_amplitude;
    uv.x += wave_distortion * reflection_mask;

    return Texel(tex, uv);
}
