-- cfg_screen.lua
--
-- Configure and handle screen settings
--

local cfg_screen = {}

cfg_screen.INTERNAL_RES_WIDTH = 608  -- 608  -- 640
cfg_screen.INTERNAL_RES_HEIGHT = 1080  -- 1080  -- 360
cfg_screen.INTERNAL_RES_RATIO = cfg_screen.INTERNAL_RES_WIDTH / cfg_screen.INTERNAL_RES_HEIGHT

cfg_screen.WINDOW_WIDTH = 608
cfg_screen.WINDOW_HEIGHT = 1080

cfg_screen.WINDOW_WIDTH = math.max(cfg_screen.WINDOW_WIDTH, cfg_screen.INTERNAL_RES_WIDTH)
cfg_screen.WINDOW_HEIGHT = math.max(cfg_screen.WINDOW_HEIGHT, cfg_screen.INTERNAL_RES_HEIGHT)

cfg_screen.WINDOW_RATIO = cfg_screen.WINDOW_WIDTH / cfg_screen.WINDOW_HEIGHT

-- define LOW_RES and HIGH_RES
cfg_screen.LOW_RES = 0
cfg_screen.HIGH_RES = 1

cfg_screen.UPSCALE_MODE = cfg_screen.LOW_RES

return cfg_screen