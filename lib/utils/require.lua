requirements = {}

requirements.globalReset = {}
requirements.patchReset = {}

requirements.HARD_RESET = "Hard reset"

requirements.PATCH_RESET = "Patch reset"

-- TODO:refactor move this function to somewhere else!
function table.contains(list, element)
    for k,v in pairs(list) do
        if v == element then return true end
    end
    return false
end

---
--- The require function in lua is pretty much equivalent, in its purpose, to the include statement in languages like
--- C and C++, or the import statement in python. However, require is a function.
---
--- This allows the creation of a wrapper function which "overloads" the require() performing some additional tasks.
--- Wrapping the require enables the possibility to keep track of the files "required" by simply adding them to a list,
--- which in turn can be checked by the lick library that allows the livecoding feature.
---
--- In principle, the lick library performs continuous checks on the date of modification of a list of files, and if
--- the date has changed, it triggers some procedures. Typically, the most "radical" procedure that can be triggered
--- is to entirely reload the LOVJ program, but for some files it could be possible to perform only a partial reload
--- (e.g. patches may only need to be require()-d again, and then have a re-call of the patch.init() function). This
--- can be achieved by using different lists associated with different degrees of "reload".
---
--- This way one can keep allow hotswapping and livecoding functionalities on various degrees, as well as on-the.fly
--- debugging (hopefully). Moreover, if a patch is reloaded by simply performing require() and patch.init() without
--- entirely reloading the LOVJ program, it will keep in memory the parameters state and the timer will not reset,
--- thus keeping intact the livecode experience without frequent hard resets.

--- @public lickrequire wrapper function for require, allows for livecoding features
function lovjRequire(component, resetType)
    resetType = resetType or requirements.HARD_RESET  -- default value

    local ret = require(component)  -- require the component

    -- Add to specified requirements lists
    if resetType == requirements.HARD_RESET then
        if table.contains(requirements.globalReset, component) then return ret end
        table.insert(requirements.globalReset, component)
    elseif resetType == requirements.PATCH_RESET then
        if table.contains(requirements.patchReset, component) then return ret end
        table.insert(requirements.patchReset, component)
    end

    logInfo("Added " .. component .. " to " .. resetType .." list.")

    return ret
end


return requirements