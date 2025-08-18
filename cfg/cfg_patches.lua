-- cfg_patches.lua
--
-- Configure and handle patches configuration
--

local cfg_patches = {}

-- Current state
cfg_patches.selectedPatch = 1

--- @public DEFAULT_PATCH default patch loaded at startup
cfg_patches.defaultPatch = {"demos/demo24/source/demo_24"}

--- @public patches list of patches
cfg_patches.patches = {"demos/demo20/source/demo_20",
                       "demos/demo3/source/demo_3",
                       "demos/demo4/source/demo_4",
                       "demos/demo5/source/demo_5",
                       "demos/demo6/source/demo_6",
                       "demos/demo16/source/demo_16",
                       "demos/demo8/source/demo_8",
                       "demos/demo13/source/demo_13",
                       "demos/demo18/source/demo_18",
                       "demos/demo11/source/demo_11",
                       "demos/demo12/source/demo_12",
                       "demos/demo14/source/demo_14"
}


return cfg_patches