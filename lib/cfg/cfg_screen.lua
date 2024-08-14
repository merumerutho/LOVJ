-- cfg_screen.lua
--
-- Configure and handle configurable screen settings
--

local cfg_screen = {}

cfg_screen.INTERNAL_RES_WIDTH = 800
cfg_screen.INTERNAL_RES_HEIGHT = 480
cfg_screen.INTERNAL_RES_RATIO = cfg_screen.INTERNAL_RES_WIDTH / cfg_screen.INTERNAL_RES_HEIGHT

cfg_screen.WINDOW_WIDTH = 800
cfg_screen.WINDOW_HEIGHT = 480
cfg_screen.WINDOW_RATIO = cfg_screen.WINDOW_WIDTH / cfg_screen.WINDOW_HEIGHT

cfg_screen.LOW_RES = false
cfg_screen.HIGH_RES = true

cfg_screen.UPSCALE_MODE = cfg_screen.LOW_RES

return cfg_screen