// @param int _cycles 25 //
// @param vec2 _chunkSize {0.3,0.5} //
// @param float _seed 0 //
extern int _cycles;       // Number of scrambling operations to layer
extern vec2 _chunkSize;   // The width and height of the chunk to copy
extern float _seed;       // Seed variable for pseudo-randomness

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = texture_coords;

    for (int i = 0; i < _cycles; i++) {
        float i_float = float(i);
        float rand1 = random(vec2(_seed * 0.1, i_float * 0.2));
        float rand2 = random(vec2(_seed * 0.3, i_float * 0.4));
        float rand3 = random(vec2(_seed * 0.5, i_float * 0.6));
        float rand4 = random(vec2(_seed * 0.7, i_float * 0.8));

        // Define the source rectangle to copy from
        vec2 src_pos = vec2(rand1, rand2);
        vec2 src_min = src_pos;
        vec2 src_max = src_pos + _chunkSize;

        // Define the destination offset
        vec2 dest_offset = vec2(rand3, rand4) - src_pos;

        // 1.0 if inside, 0.0 if outside
        float in_rect_x = step(src_min.x, uv.x) * (1.0 - step(src_max.x, uv.x));
        float in_rect_y = step(src_min.y, uv.y) * (1.0 - step(src_max.y, uv.y));
        float mask = in_rect_x * in_rect_y;

        // Apply the offset to the coords
        uv += dest_offset * mask;
    }

    uv = clamp(uv, 0.0, 1.0);

    return Texel(tex, uv);
}
