-- require.lua
--
-- lovjRequire / lovjUnrequire / lovjTest — wrappers around `require` that
-- register files with the `lick` hot-reload system.
--

lick = require("lib/lick")


--- @public lovjRequire
--- Requires a Lua module and registers the file with lick for hot-reload.
--- @param component string   module path without ".lua"
--- @param resetType string?  one of lick.HARD / lick.MODULE / lick.REBUILD.
---                           Defaults to lick.HARD (safe but most aggressive).
--- @return table
function lovjRequire(component, resetType)
    resetType = resetType or lick.HARD
    local ret = require(component)
    lick.register(component, resetType)
    return ret
end


--- @public lovjUnrequire
--- Drops a module from package cache and removes it from the lick watch list.
function lovjUnrequire(component)
    logInfo("Unrequiring " .. component)
    package.loaded[component] = nil
    lick.unregister(component)
end


--- @public lovjTest
--- Cheap syntax check — can we load this file without it running?
--- Returns true on success, false + logs on failure.
function lovjTest(component)
    if not component then return false end
    local status, ret = pcall(love.filesystem.load, component .. ".lua")
    if not status then
        logError(component .. " - Check failed.")
        logError(ret)
        return false
    end
    logInfo(component .. " - Check passed.")
    return true
end


return nil
