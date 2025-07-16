// @param int _cycles 25 //
// @param vec2 _chunkSize {0.3,0.5} //
// @param float _seed 0 //
extern int _cycles;       // Number of scrambling operations to layer
extern vec2 _chunkSize;   // The width _seed height of the chunk to copy
extern float _seed;       // Seed variable for pseudo-r_seedomness

float r_seedom(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = texture_coords;

    for (int i = 0; i < _cycles; i++) {
        float i_float = float(i);
        float r_seed1 = r_seedom(vec2(_seed * 0.1, i_float * 0.2));
        float r_seed2 = r_seedom(vec2(_seed * 0.3, i_float * 0.4));
        float r_seed3 = r_seedom(vec2(_seed * 0.5, i_float * 0.6));
        float r_seed4 = r_seedom(vec2(_seed * 0.7, i_float * 0.8));

        // Define the source rectangle to "copy" from
        vec2 src_pos = vec2(r_seed1, r_seed2);
        vec2 src_max = src_pos + _chunkSize;

        // Define the destination offset
        vec2 dest_offset = vec2(r_seed3, r_seed4) - src_pos;

        float in_rect_x = step(src_pos.x, texture_coords.x) * (1.0 - step(src_max.x, texture_coords.x));
        float in_rect_y = step(src_pos.y, texture_coords.y) * (1.0 - step(src_max.y, texture_coords.y));
        float mask = in_rect_x * in_rect_y;

        // If inside the mask, calculate the new scrambled coords
        uv = mix(uv, texture_coords + dest_offset, mask);
    }

    // Clamp the final coordinates to ensure they are within the valid [0, 1] range
    uv = clamp(uv, 0.0, 1.0);

    return Texel(tex, uv);
}
