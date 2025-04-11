-- cfg_patches.lua
--
-- Configure and handle patches configuration
--

local cfg_patches = {}

--- @public DEFAULT_PATCH default patch loaded at startup
cfg_patches.defaultPatch = {"demos/demo_23"}

--- @public patches list of patches
cfg_patches.patches = {"demos/demo_20",
                       "demos/demo_3",
                       "demos/demo_4",
                       "demos/demo_5",
                       "demos/demo_6",
                       "demos/demo_16",
                       "demos/demo_8",
                       "demos/demo_13",
                       "demos/demo_18",
                       "demos/demo_11",
                       "demos/demo_12",
                       "demos/demo_14"
}


return cfg_patches