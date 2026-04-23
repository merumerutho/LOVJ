# Databending & Glitch Effects

LOVJ provides two layers of video glitch effects: packet-level databending (authentic codec artifacts) and shader-based glitch FX (reliable, real-time).

## Databending (lib/video/databender.lua)

Operates on compressed video packets before they reach the decoder. Produces authentic codec artifacts — the decoder itself generates the glitches. Works best with delta-encoded codecs (H.264, MPEG-4).

### Modes

| Mode | Description |
|------|-------------|
| `off` | Normal playback |
| `melt` | Skips I-frames so P-frames apply deltas to stale references. Classic datamosh pixel-bleeding effect |
| `crush` | Corrupts I-frame data so the decoder builds a garbled reference. P-frames then apply motion on top |
| `corrupt` | Copies/shifts memory blocks within P-frame packets. Produces macro-block displacement artifacts |
| `smash` | Combines I-frame skipping with P-frame repetition. The same motion vectors accumulate on a stale reference |

### Usage

```lua
sampler:setBendMode("melt")
sampler:setBendIntensity(2.0)  -- higher = more aggressive
```

Intensity controls both the number of operations per packet and the scale of corruption. Range is 0–10+.

### Notes

- Databending disables FFmpeg's error concealment (`ec=0`, `skip_loop_filter=all`) for raw artifacts
- Seeking does not flush the decoder when bending is active, preserving stale reference frames
- The decode thread throttles to the video's native frame rate to prevent speedup
- Results are inherently unpredictable — that's the point

## Glitch Shaders (lib/video/glitch_shaders.lua)

GLSL-based effects that simulate glitch aesthetics. Fully reliable, controllable, and stackable via ping-pong rendering.

| Shader | Effect |
|--------|--------|
| `blockDisplace` | Shifts rectangular blocks by pseudo-random offsets (macro-block errors) |
| `channelShift` | RGB channel separation with temporal drift |
| `quantize` | Reduces color depth with banding artifacts |
| `hSmear` | Horizontal luminance-based displacement (smear effect) |
| `frameEcho` | Blends with previous frame using displaced UVs (ghosting) |

### Usage in a patch

```lua
local GlitchFX = lovjRequire("lib/video/glitch_shaders")

-- In draw, apply as shader passes:
love.graphics.setShader(GlitchFX.blockDisplace)
GlitchFX.blockDisplace:send("_intensity", 0.5)
GlitchFX.blockDisplace:send("_time", t)
GlitchFX.blockDisplace:send("_blockSize", 20)
love.graphics.draw(sourceCanvas)
love.graphics.setShader()
```

See demo29 for a full example with chainable ping-pong rendering.

## Depth FX (lib/video/depth_shaders.lua)

Estimates scene depth from monocular video using traditional computer vision cues, then applies parallax displacement and depth-of-field.

### Depth estimation cues

| Cue | Weight | Principle |
|-----|--------|-----------|
| Dark channel prior | 0.4 | Min(R,G,B) in local patch correlates with atmospheric depth |
| Saturation | 0.25 | Distant objects lose color saturation |
| Blue shift | 0.15 | Atmospheric scattering shifts distant objects blue |
| Sharpness | 0.3 | Sharp/detailed regions are closer (Laplacian) |
| Vertical position | 0.1 | Higher in frame = further (perspective prior) |

### Pipeline

1. **Estimate** — generates grayscale depth map from combined cues
2. **Blur** — two-pass separable Gaussian (sigma=8, applied twice) for smooth gradients
3. **Displace** — parallax shift based on depth × camera offset, optional DOF blur on distant objects

### Parameters

| Parameter | Effect |
|-----------|--------|
| `cameraX`, `cameraY` | Virtual camera offset for parallax (-5 to 5) |
| `depthParallax` | Displacement strength |
| `depthDOF` | Depth-of-field blur amount |

Modulate `cameraX`/`cameraY` with an LFO for automatic 2.5D parallax movement.
