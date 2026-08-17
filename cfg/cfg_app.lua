-- cfg_app.lua
--
-- Configure application-level settings
--

local machine = require("lib/machine")

local cfg_app = {}

cfg_app.title = "LOVJ"
cfg_app.icon = "data/app/lovj.png"

-- Livecoding support (lick): when false, the per-frame file watching / hot-reload
-- machinery is disabled entirely. Turn off on sealed performance boxes — error
-- banners still render, only the reload-on-save behavior goes away.
cfg_app.liveCoding = true

-- Watch sweep budget for lick: how many registered files get an mtime stat per
-- frame (round-robin over the whole watch list). Higher catches saves sooner at
-- the cost of more per-frame filesystem stats. Only meaningful with liveCoding on.
cfg_app.lickFilesPerTick = 8

-- Periodic FPS log line: 0 disables, > 0 logs at the console timer rate (~1 Hz).
cfg_app.fpsLogHz = 1

-- Frame-stall diagnostics (lib/utils/frame_profiler): logs a per-section
-- breakdown of any frame slower than the stall threshold plus a periodic
-- heap/FPS heartbeat. Cheap enough to leave on while hunting hitches.
cfg_app.frameDiagnostics = true

return machine.apply("cfg_app", cfg_app)
