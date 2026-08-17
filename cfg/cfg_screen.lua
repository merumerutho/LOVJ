-- cfg_screen.lua
--
-- Configure and handle screen settings
--

local machine = require("lib/machine")

local cfg_screen = {}

cfg_screen.INTERNAL_RES_WIDTH = 640  -- 608  -- 640
cfg_screen.INTERNAL_RES_HEIGHT = 360  -- 1080  -- 360

cfg_screen.WINDOW_WIDTH = 640
cfg_screen.WINDOW_HEIGHT = 360

-- define LOW_RES and HIGH_RES
cfg_screen.LOW_RES = 0
cfg_screen.HIGH_RES = 1

cfg_screen.UPSCALE_MODE = cfg_screen.LOW_RES

-- When true, changeUpscaling is refused (HIGH_RES redefines InternalRes to the window
-- size and multiplies every canvas — lock it out on memory-constrained machines).
cfg_screen.UPSCALE_LOCKED = false

-- Power-of-2 divisor applied to the internal resolution (Hypno-style render scaling):
-- 1 = full, 2 = quarter pixels, ... Trades resolution for shader headroom.
cfg_screen.RENDER_SCALE = 1

cfg_screen.VSYNC = true
cfg_screen.FULLSCREEN_AT_BOOT = false

-- Per-machine overrides come in BEFORE the derived values below, so a profile that
-- changes e.g. WINDOW_WIDTH gets consistent ratios.
machine.apply("cfg_screen", cfg_screen)

cfg_screen.INTERNAL_RES_RATIO = cfg_screen.INTERNAL_RES_WIDTH / cfg_screen.INTERNAL_RES_HEIGHT

cfg_screen.WINDOW_WIDTH = math.max(cfg_screen.WINDOW_WIDTH, cfg_screen.INTERNAL_RES_WIDTH)
cfg_screen.WINDOW_HEIGHT = math.max(cfg_screen.WINDOW_HEIGHT, cfg_screen.INTERNAL_RES_HEIGHT)

cfg_screen.WINDOW_RATIO = cfg_screen.WINDOW_WIDTH / cfg_screen.WINDOW_HEIGHT

return cfg_screen
