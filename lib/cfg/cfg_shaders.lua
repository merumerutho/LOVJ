cfg_shaders = {}

cfg_shaders.enabled = true

--- @public toggleShaders enable / disable shaders
function toggleShaders()
    cfg_shaders.enabled = not cfg_shaders.enabled
end

return cfg_shaders