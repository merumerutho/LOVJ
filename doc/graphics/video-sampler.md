# Video Sampler

The video sampler (`lib/video/video_sampler.lua`) provides FFmpeg-based video playback with threaded decoding, supporting any codec FFmpeg can handle (H.264, ProRes, Theora, MJPEG, HAP, etc.).

## Dependencies

Run `python installFFmpeg.py` to download the required FFmpeg shared libraries into `dynlib/`.

## Usage

```lua
local VideoSampler = lovjRequire("lib/video/video_sampler")

function patch:init(slot, globals, shaderext)
    Patch.init(self, slot, globals, shaderext)
    self.sampler = VideoSampler:new()
    self.sampler:open("path/to/video.mp4")
    self.sampler:setLoopPoints(0, 10)  -- loop first 10 seconds
    self.sampler:play()
end

function patch:draw()
    self:drawSetup()
    local img = self.sampler:getImage()
    if img then
        love.graphics.draw(img, 0, 0)
    end
    return self:drawExec()
end

function patch:update()
    self:mainUpdate()
    self.sampler:update(love.timer.getDelta())
end
```

## API

| Method | Description |
|--------|-------------|
| `VideoSampler:new()` | Create a new sampler instance |
| `sampler:open(path)` | Open a video file (any FFmpeg-supported format) |
| `sampler:play()` | Start playback |
| `sampler:pause()` | Pause playback |
| `sampler:stop()` | Stop and seek to beginning |
| `sampler:seek(seconds)` | Seek to position in seconds |
| `sampler:setSpeed(speed)` | Set playback speed (negative for reverse) |
| `sampler:setLoopPoints(start, end)` | Set loop region in seconds |
| `sampler:setBendMode(mode)` | Set databending mode (see [Databending](databending.md)) |
| `sampler:setBendIntensity(value)` | Set databending intensity |
| `sampler:update(dt)` | Advance playhead (call each frame) |
| `sampler:getImage()` | Get current frame as LÖVE Image |
| `sampler:close()` | Release all resources |

## Properties

| Property | Description |
|----------|-------------|
| `sampler.width` | Video width in pixels |
| `sampler.height` | Video height in pixels |
| `sampler.duration` | Video duration in seconds |
| `sampler.position` | Current playhead position in seconds |

## Architecture

The sampler uses a threaded decode pipeline:

```
Main thread                    Decode thread
    │                              │
    ├─ cmdChannel ────────────────→│  (open/seek/play/pause/bend)
    │                              │
    │←──── frameChannel ──────────┤  ("frame", pts, ByteData)
    │                              │
    ├─ recycleChannel ────────────→│  (return used ByteData to pool)
```

A ring buffer of 8 pre-allocated `ByteData` frames circulates between threads. The decode thread fills them with RGBA pixels via `sws_scale`, the main thread uploads to a LÖVE Image via `replacePixels`.
