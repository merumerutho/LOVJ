-- cfg_patches.lua
--
-- Configure and handle patches configuration
--

local cfg_patches = {}

--- @public DEFAULT_PATCH default patch loaded at startup
cfg_patches.defaultPatch = {"demos/source/demo_24"}

--- @public patches list of patches
cfg_patches.patches = {"demos/source/demo_20",
                       "demos/source/demo_3",
                       "demos/source/demo_4",
                       "demos/source/demo_5",
                       "demos/source/demo_6",
                       "demos/source/demo_16",
                       "demos/source/demo_8",
                       "demos/source/demo_13",
                       "demos/source/demo_18",
                       "demos/source/demo_11",
                       "demos/source/demo_12",
                       "demos/source/demo_14"
}


return cfg_patches