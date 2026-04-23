-- cfg_patches.lua
--
-- Configure and handle patches configuration
--

local cfg_patches = {}

-- Current state
cfg_patches.selectedPatch = 1

--- @public DEFAULT_PATCH default patch loaded at startup
cfg_patches.defaultPatch = {"demos/demo23/source/demo_23"}

--- @public patches list of patches
cfg_patches.patches = {
    "demos/demo1/source/demo_1",
    "demos/demo2/source/demo_2",
    "demos/demo3/source/demo_3",
    "demos/demo4/source/demo_4",
    "demos/demo5/source/demo_5",
    "demos/demo6/source/demo_6",
    "demos/demo7/source/demo_7",
    "demos/demo8/source/demo_8",
    "demos/demo9/source/demo_9",
    "demos/demo10/source/demo_10",
    "demos/demo11/source/demo_11",
    "demos/demo12/source/demo_12",
    "demos/demo13/source/demo_13",
    "demos/demo14/source/demo_14",
    "demos/demo15/source/demo_15",
    "demos/demo16/source/demo_16",
    "demos/demo17/source/demo_17",
    "demos/demo18/source/demo_18",
    "demos/demo19/source/demo_19",
    "demos/demo20/source/demo_20",
    "demos/demo21/source/demo_21",
    "demos/demo22/source/demo_22",
    "demos/demo23/source/demo_23",
    "demos/demo24/source/demo_24",
    "demos/demo25/source/demo_25",
    "demos/demo26/source/demo_26",
    "demos/demo27/source/demo_27",
    "demos/demo28/source/demo_28",
}


return cfg_patches