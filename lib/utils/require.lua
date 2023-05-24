-- require.lua
--
-- Functions for loading, unloading and reloading libraries
--

lick = require("lib/lick")

requirements = {}

---
--- Wrapper function for "require", integrated with the "lick" library for livecoding purposes.
---
--- Wrapping the require enables the possibility to keep track of the files "required" by simply adding them to a list,
--- which in turn can be checked by the lick library that allows the livecoding feature.
---
--- In principle, the lick library performs checks on the date of modification of a list of files, and if
--- the date has changed, it triggers reset procedures. For files which require hard-resets, the whole program is
--- reloaded, but for some files it is necessary to perform only a patch reload.
--- @param component string
--- @param resetType string
--- @return table
function lovjRequire(component, resetType)
    resetType = resetType or lick.HARD_RESET  -- default value
    local ret = require(component)  -- safe if protected by lovjTest

    if lick.resetList[component] ~= nil then return ret end  -- if already present, skip
    -- Otherwise add to lick reset list
    lick.resetList[component] = {time = love.filesystem.getInfo(component .. ".lua").modtime ,
                                 resetType = resetType }
    logInfo("Added " .. component .. " to " .. resetType .." list.")
    return ret
end

--- @public lovjUnrequire removes component from the list of loaded packages and the resetlist
function lovjUnrequire(component)
    logInfo("Unrequiring " .. component)
    package.loaded[component] = nil
    _G[component] = nil
    lick.resetList[component] = nil
end

--- @public lovjTest test if a component can be loaded without issues
function lovjTest(component)
    if not component then return false end
    local status, ret = pcall(love.filesystem.load, component..".lua")
    -- if error found:
    if not status then
        logError(component.." - Check failed.")
        logError(ret) -- print error
        return false
    end
    logInfo(component.." - Check passed.")
    return true
end

return requirements