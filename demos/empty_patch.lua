-- barebone empty patch

local Patch = lovjRequire("lib/patch")

local patch = Patch:new()

function patch.init(slot)
    Patch.init(patch, slot)
    patch:setCanvases()
end


function patch.draw()
    patch:drawSetup()
    return patch:drawExec()
end


function patch.update()
    patch:mainUpdate()
end

function patch.patchControls()

end

return patch