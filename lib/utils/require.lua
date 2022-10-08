lick = require("lib/lick")

requirements = {}

-- TODO:[refactor] move this function to somewhere else!
function table.contains(list, element)
    for k,v in pairs(list) do
        if v.name == element then return true end
    end
    return false
end

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

    local ret = require(component)  -- require the component
    if table.contains(lick.resetList, component) then return ret end  -- if already present, skip
    -- Add to lick reset list
    table.insert(lick.resetList, { name = component,
                                   time = love.filesystem.getInfo(component .. ".lua").modtime,
                                   resetType = resetType })

    logInfo("Added " .. component .. " to " .. resetType .." list.")
    return ret
end

return requirements