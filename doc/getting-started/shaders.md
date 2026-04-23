# Writing Shaders

[Back to index](../index.md)

LOVJ uses GLSL shaders for post-process effects. Shaders are auto-discovered from the filesystem and their parameters are parsed from `@param` annotations.

## Shader Locations

| Directory | Purpose |
|-----------|---------|
| `lib/shaders/source/postProcess/` | Post-process effects (applied per-slot via 3 layers) |
| `lib/shaders/source/other/` | Utility shaders (used directly in patch code) |

Files must have a `.glsl` extension. They are loaded at startup by `cfgShaders.init()`.

## Naming Convention

Post-process shaders are sorted alphabetically, so use numeric prefixes for ordering:

```
00_default.glsl
01_medianblur.glsl
02_blurzoom.glsl
03_chromakey.glsl
...
```

The name (without prefix number and extension) is used as the display name in the [Studio GUI](../studio/studio.md).

## Shader Signature

Post-process shaders must implement the LOVE2D `effect` function:

```glsl
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texColor = Texel(tex, texture_coords);
    // ... process texColor ...
    return texColor;
}
```

| Parameter | Description |
|-----------|-------------|
| `color` | Vertex color (usually white) |
| `tex` | Input texture (previous canvas) |
| `texture_coords` | UV coordinates (0-1) |
| `screen_coords` | Pixel position |

## Parameter Annotations

Shader parameters are declared in comments using `@param`:

```glsl
// @param float _zoom 0.35 //
// @param float _speed 1.0 //
// @param vec4 _color {1.0, 0.5, 0.0, 1.0} //
// @param vec2 _range {0.0, 1.0} //
```

Format: `// @param <type> <name> <default_value> //`

### Supported Types

| Type | Default Format | Example |
|------|---------------|---------|
| `float` | number | `0.35` |
| `vec2` | `{x, y}` | `{0.0, 1.0}` |
| `vec4` | `{x, y, z, w}` | `{1.0, 0.5, 0.0, 1.0}` |

Parameters must also be declared as `extern` uniforms:

```glsl
// @param float _zoom 0.35 //
extern float _zoom;
```

### Naming Convention

Parameter names should start with `_` to distinguish them from GLSL built-ins. The full parameter name in the [resource system](../architecture/resources.md) is `shaderName_paramName` (e.g., `blurzoom__zoom`).

## How Parameters Are Managed

1. `cfgShaders.init()` parses all `.glsl` files and extracts `@param` annotations
2. `cfgShaders.initShaderExt(slot)` creates `shaderext` resource entries for each parameter
3. The [Studio GUI](../studio/studio.md) Shaders tab exposes sliders for all shader parameters
4. `cfgShaders.selectPPShader()` sends current parameter values to the shader via `shader:send()`

## Example: Chromakey Shader

```glsl
// @param float _chromaHue 0.33 //
// @param float _chromaTolerance 0.1 //
// @param float _chromaSoftness 0.05 //

extern float _chromaHue;
extern float _chromaTolerance;
extern float _chromaSoftness;

vec3 rgb2hsv(vec3 c) {
    // ... RGB to HSV conversion ...
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec4 texColor = Texel(tex, texture_coords);
    vec3 hsv = rgb2hsv(texColor.rgb);

    float hueDist = abs(hsv.x - _chromaHue);
    hueDist = min(hueDist, 1.0 - hueDist);
    float dist = hueDist * hsv.y;

    float alpha = smoothstep(_chromaTolerance, _chromaTolerance + _chromaSoftness, dist);
    texColor.a = alpha;
    return texColor;
}
```

## Available Post-Process Shaders

| Shader | Description |
|--------|-------------|
| `00_default` | Pass-through (no effect) |
| `01_medianblur` | Median blur filter |
| `02_blurzoom` | Radial zoom blur |
| `03_chromakey` | HSV-based chroma keying |
| `04_circleswirl` | Circular swirl distortion |
| `05_diagcut` | Diagonal cut effect |
| `06_glitch` | Digital glitch |
| `07_hmirror` | Horizontal mirror |
| `08_hmirror_water` | Horizontal mirror with water effect |
| `09_quadmirror` | Quad mirror (kaleidoscope-like) |
| `10_vmirror` | Vertical mirror |
| `11_pixelate` | Pixelation |
| `12_wiggly` | Wave distortion |
| `13_swirl` | Swirl effect |
| `14_curvature` | CRT curvature |
| `15_warp` | Warp distortion |
| `16_kaleido` | Kaleidoscope |
| `17_multiplier` | Tile multiplier |
| `18_inverted_multiplier` | Inverted tile multiplier |
| `19_sea_reflection` | Sea/water reflection |
| `20_memory_scramble` | Memory scramble effect |
| `21_memory_scramble_layered` | Layered memory scramble |
| `22_motion_blur` | Directional + radial motion blur |
| `23_crt_scanline` | CRT scanlines, barrel distortion, chromatic aberration, vignette |

## Related

- [Studio Overview](../studio/studio.md) — Shaders tab for real-time control
- [Patch Rendering Pipeline](../graphics/rendering.md) — where shaders are applied
- [Resource System](../architecture/resources.md) — how shader parameters are stored
