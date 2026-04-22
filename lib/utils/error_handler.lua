-- error_handler.lua
--
-- Thin helpers around pcall for patch operations.
-- Banner display and error persistence live in lib/lick.lua now — this
-- module only provides:
--   * safePatchCall: pcall + log + record into lick.errors keyed by slot
--   * createFallbackPatch: red "PATCH X ERROR" patch used when a patch
--     fails on initial app load (before a last-good version exists)
--
-- Runtime errors no longer auto-swap to the fallback. The running patch
-- keeps its place; the user sees a persistent banner via lick and fixes
-- the source file.
--

local ErrorHandler = {}

-- Safe patch operation wrapper.
-- Records failures into lick.errors so they show up in the persistent banner.
function ErrorHandler.safePatchCall(patchSlot, operation, func, ...)
    if not func then
        logError("ErrorHandler: nil function passed for " .. operation)
        return false
    end

    local args = {...}
    local ok, result = xpcall(function() return func(unpack(args)) end, debug.traceback)

    local key = "patch:" .. tostring(patchSlot) .. ":" .. operation
    if ok then
        if lick and lick.clearError then lick.clearError(key) end
        return true, result
    else
        local name = (patchSlots and patchSlots[patchSlot] and patchSlots[patchSlot].name) or "unknown"
        local msg = name .. " " .. operation .. ": " .. tostring(result)
        if lick and lick.errors then
            lick.errors[key] = { message = msg, timestamp = love.timer.getTime() }
            lick.dismissed = false
        end
        logError("[" .. key .. "] " .. msg)
        return false, result
    end
end


-- Create a red-background fallback patch for first-load failures.
function ErrorHandler.createFallbackPatch(patchSlot)
    local fallbackPatch = {}

    function fallbackPatch.init(slot, globals, shaderext)
        -- minimal safe initialization
    end

    function fallbackPatch.draw()
        local canvas = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
        love.graphics.setCanvas(canvas)

        love.graphics.setColor(0.2, 0, 0, 1)
        love.graphics.rectangle("fill", 0, 0, screen.InternalRes.W, screen.InternalRes.H)

        love.graphics.setColor(1, 0.5, 0.5, 1)
        love.graphics.printf(
            "PATCH " .. patchSlot .. " LOAD FAILED\nCheck banner / console",
            0, screen.InternalRes.H / 2 - 20, screen.InternalRes.W, "center")

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setCanvas()
        return canvas
    end

    function fallbackPatch.update() end

    return fallbackPatch
end


return ErrorHandler
