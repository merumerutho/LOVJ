shaders = require "lib/shaders"

cfg_shaders = {}

cfg_shaders.enabled = true
--- @public shaders list of shaders
cfg_shaders.shaders = {shaders.default,
                       shaders.h_mirror,
                       shaders.w_mirror,
                       shaders.wh_mirror,
                       shaders.warp,
                       shaders.kaleido}

--- @public toggleShaders enable / disable shaders
function toggleShaders()
    cfg_shaders.enabled = not cfg_shaders.enabled
end

return cfg_shaders