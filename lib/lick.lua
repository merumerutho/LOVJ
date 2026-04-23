-- lick.lua
--
-- Hot-reload / live-coding system for LOVJ.
--
-- Three reload strategies:
--   HARD    — full application restart (re-run main.lua + love.load).
--             Used for main.lua and cfg files whose side effects are baked
--             into love.load (e.g. window/spout init).
--   MODULE  — drop the module from package.loaded; next `require` pulls
--             fresh. Used for utility libs with no live instances.
--   REBUILD — for each instance bound to the file: snapshot the current
--             instance reference, re-require the module, build a new
--             instance via an optional hook, then commit + teardown old.
--             On any failure, the previous instance stays live (no
--             half-swapped state).
--
-- Principles:
--   * Syntax errors never touch live state. mtime is not advanced until
--     the file parses, so we keep retrying on every save.
--   * Runtime errors in love.update / love.draw / patch hooks don't swap
--     anything out — the last-good instance keeps running. User sees a
--     banner and can fix + save.
--   * Banners are persistent until the file reloads successfully or the
--     user dismisses them (Ctrl+Esc).
--
-- Credits: original `lick` library by usysrc; this is a rewrite around
-- the same love.run-override idea.
--

require("lib/utils/logging")

local lick = {}

-- Reload strategies
lick.HARD    = "HARD"
lick.MODULE  = "MODULE"
lick.REBUILD = "REBUILD"

-- Back-compat aliases for existing lovjRequire(..., lick.PATCH_RESET) calls.
lick.HARD_RESET  = lick.HARD
lick.SOFT_RESET  = lick.MODULE
lick.PATCH_RESET = lick.REBUILD

-- Registered files.
-- path -> { mtime = number, strategy = string }
lick.files = {}

-- Per-file instance bindings (REBUILD only).
-- path -> array of bindings.
-- Each binding: { get = fn()->instance,
--                 set = fn(newInstance),
--                 build = fn?(newModule)->newInstance,   -- default: returns newModule
--                 teardown = fn?(oldInstance) }
lick.instances = {}

-- Persistent errors: key -> { message, timestamp }
-- key is the file path for reload errors, or "runtime:update" / "runtime:draw"
-- for per-frame errors in the main loop.
lick.errors = {}

-- Set by the user via Ctrl+Esc to hide banners until a new error appears.
lick.dismissed = false

lick.MAIN_FILE = "main"


--- @public register a file for hot-reload watching.
function lick.register(path, strategy)
    if lick.files[path] then return end
    local info = love.filesystem.getInfo(path .. ".lua")
    lick.files[path] = {
        mtime = info and info.modtime or 0,
        strategy = strategy or lick.HARD,
    }
end


--- @public remove a file from the watch list.
function lick.unregister(path)
    lick.files[path] = nil
    lick.instances[path] = nil
end


--- @public bind an instance to a REBUILD file. Returns the binding handle
--- so callers can unbind later when the instance is retired.
function lick.bindInstance(path, binding)
    lick.instances[path] = lick.instances[path] or {}
    table.insert(lick.instances[path], binding)
    return binding
end


--- @public remove a specific binding from a file.
function lick.unbindInstance(path, binding)
    local list = lick.instances[path]
    if not list then return end
    for i = #list, 1, -1 do
        if list[i] == binding then table.remove(list, i) end
    end
end


--- @private record an error under a key.
local function recordError(key, msg)
    lick.errors[key] = {
        message = tostring(msg),
        timestamp = love.timer.getTime(),
    }
    lick.dismissed = false
    logError("[" .. key .. "] " .. tostring(msg))
end


--- @public clear an error for a key.
function lick.clearError(key)
    lick.errors[key] = nil
end


--- @public hide all current banners (user pressed Ctrl+Esc).
function lick.dismissBanners()
    lick.dismissed = true
end


--- @private syntax-check a file without executing it.
local function checkSyntax(path)
    local ok, chunkOrErr = pcall(love.filesystem.load, path .. ".lua")
    if not ok then return false, chunkOrErr end
    return true
end


--- @private detect all changed files since the last check.
local function detectChanges()
    local changed = {}
    for path, info in pairs(lick.files) do
        local stat = love.filesystem.getInfo(path .. ".lua")
        if stat and stat.modtime ~= info.mtime then
            table.insert(changed, path)
        end
    end
    return changed
end


--- @private REBUILD path: full destroy + reload + re-init with revert on failure.
local function doRebuild(path)
    local bindings = lick.instances[path] or {}

    -- Snapshot live instances before anything changes.
    local oldInstances = {}
    for i, b in ipairs(bindings) do
        oldInstances[i] = b.get()
    end

    -- Save old module so we can roll back if require fails.
    local oldModule = package.loaded[path]
    package.loaded[path] = nil

    local okReq, newModule = pcall(require, path)
    if not okReq then
        package.loaded[path] = oldModule
        recordError(path, "require failed: " .. tostring(newModule))
        return false
    end

    -- Build new instances. Old ones are still live in bindings — if any
    -- build fails, we revert and the user never sees the swap.
    local newInstances = {}
    for i, b in ipairs(bindings) do
        local builder = b.build or function(m) return m end
        local okBuild, built = pcall(builder, newModule)
        if not okBuild then
            package.loaded[path] = oldModule
            recordError(path, "build failed: " .. tostring(built))
            return false
        end
        newInstances[i] = built
    end

    -- Teardown old instances. Errors here are logged but don't block the
    -- swap — the new instances are already built and ready.
    for i, b in ipairs(bindings) do
        if b.teardown then
            local okTd, tdErr = pcall(b.teardown, oldInstances[i])
            if not okTd then
                logError("[" .. path .. "] teardown error (non-fatal): " .. tostring(tdErr))
            end
        end
    end

    -- Commit.
    for i, b in ipairs(bindings) do
        b.set(newInstances[i])
    end

    lick.clearError(path)
    logInfo("[" .. path .. "] rebuilt (" .. #bindings .. " instance(s))")
    return true
end


--- @private MODULE path: clear package cache so next require reloads.
local function doModuleReload(path)
    package.loaded[path] = nil
    lick.clearError(path)
    logInfo("[" .. path .. "] module cache cleared")
    return true
end


--- @private HARD path: full app re-init — reload main.lua, re-run love.load.
local function doHardReload(path)
    logInfo("[" .. path .. "] hard reset")

    -- Stop any background threads that would leak across the reload.
    if dispatcher and dispatcher.stopAllOSCThreads then
        pcall(dispatcher.stopAllOSCThreads)
    end
    if dispatcher and dispatcher.stopAllMIDIThreads then
        pcall(dispatcher.stopAllMIDIThreads)
    end

    -- Drop cached modules so main.lua's top-level requires re-execute.
    -- We can't blanket-clear package.loaded (would unload LÖVE itself);
    -- instead we clear only what lick has registered.
    for p, _ in pairs(lick.files) do
        if p ~= lick.MAIN_FILE then
            package.loaded[p] = nil
        end
    end
    package.loaded[lick.MAIN_FILE] = nil

    -- Drop all instance bindings — they capture references to the
    -- about-to-be-replaced patchSlots table and would rebuild stale
    -- instances. love.load will re-bind fresh ones.
    lick.instances = {}

    local okLoad, chunkOrErr = pcall(love.filesystem.load, lick.MAIN_FILE .. ".lua")
    if not okLoad then
        recordError(path, "main load failed: " .. tostring(chunkOrErr))
        return false
    end

    local okExec, execErr = xpcall(chunkOrErr, debug.traceback)
    if not okExec then
        recordError(path, "main exec failed: " .. tostring(execErr))
        return false
    end

    if love.load then
        local okLod, lodErr = xpcall(love.load, debug.traceback)
        if not okLod then
            recordError(path, "love.load failed: " .. tostring(lodErr))
            return false
        end
    end

    lick.clearError(path)
    return true
end


--- @private process all pending file changes for this tick.
local function processChanges()
    for _, path in ipairs(detectChanges()) do
        local info = lick.files[path]

        -- Syntax-check first. If the file doesn't parse, we do NOT advance
        -- mtime — so next save (even if it's the fix) is detected again.
        local syntaxOk, syntaxErr = checkSyntax(path)
        if not syntaxOk then
            recordError(path, "syntax error: " .. tostring(syntaxErr))
        else
            -- Advance mtime past this save. If the reload below fails at
            -- runtime (not syntax), the user needs to save again anyway.
            local stat = love.filesystem.getInfo(path .. ".lua")
            info.mtime = stat.modtime

            if info.strategy == lick.HARD then
                doHardReload(path)
                return  -- love.load was re-run; stop processing this tick.
            elseif info.strategy == lick.MODULE then
                doModuleReload(path)
            elseif info.strategy == lick.REBUILD then
                doRebuild(path)
            else
                logError("[" .. path .. "] unknown strategy: " .. tostring(info.strategy))
            end
        end
    end
end


--- @public draw persistent error banners.
function lick.drawBanners()
    local keys = {}
    for k in pairs(lick.errors) do table.insert(keys, k) end
    if #keys == 0 then return end
    table.sort(keys)

    love.graphics.push("all")
    love.graphics.origin()

    local now = love.timer.getTime()
    local lineHeight = 16
    local detailHeight = 13
    local padding = 6
    local maxDetailLines = 3

    -- measure height: each error gets 1 summary line + up to maxDetailLines of stack
    local totalLines = 0
    local entries = {}
    for _, k in ipairs(keys) do
        local err = lick.errors[k]
        local lines = {}
        for line in err.message:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end
        local summary = lines[1] or err.message
        local detail = {}
        for i = 2, math.min(#lines, maxDetailLines + 1) do
            table.insert(detail, lines[i])
        end
        local age = now - err.timestamp
        table.insert(entries, { key = k, summary = summary, detail = detail, age = age })
        totalLines = totalLines + 1 + #detail
    end

    local height = lineHeight + (totalLines - 1) * detailHeight + padding * 2 +
                   (#entries - 1) * (lineHeight - detailHeight)

    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), height)

    local y = padding
    for _, entry in ipairs(entries) do
        local fade = math.max(0.4, 1.0 - entry.age * 0.05)
        local ageStr = entry.age < 60 and string.format("%.0fs", entry.age) or string.format("%.0fm", entry.age / 60)

        love.graphics.setColor(1, 0.4, 0.4, fade)
        love.graphics.print("[" .. entry.key .. "] " .. entry.summary .. "  (" .. ageStr .. " ago)", padding, y)
        y = y + lineHeight

        love.graphics.setColor(0.7, 0.35, 0.35, fade * 0.7)
        for _, line in ipairs(entry.detail) do
            love.graphics.print("    " .. line, padding, y)
            y = y + detailHeight
        end
    end

    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.print("Ctrl+Esc to dismiss", love.graphics.getWidth() - 160, padding)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end


--- @private per-frame update wrapper.
local function liveUpdate(dt)
    processChanges()
    local ok, err = xpcall(function() love.update(dt) end, debug.traceback)
    if not ok then
        -- Only record if this isn't already captured by a patch-level handler.
        -- Patch errors go under "patch:N:update"; this catches everything else.
        if not tostring(err):match("patch:") then
            recordError("runtime:update", err)
        end
    else
        lick.clearError("runtime:update")
    end
end


--- @private per-frame draw wrapper.
local function liveDraw()
    local ok, err = xpcall(love.draw, debug.traceback)
    if not ok then
        if not tostring(err):match("patch:") then
            recordError("runtime:draw", err)
        end
    else
        lick.clearError("runtime:draw")
    end

    if not lick.dismissed then
        lick.drawBanners()
    end
end


-- Register main.lua for HARD reload on first require of this module.
lick.register(lick.MAIN_FILE, lick.HARD)


--- @public love.run main loop override.
function love.run()
    math.randomseed(os.time())
    math.random() math.random()

    -- Call love.load once. The while-loop style of love.run is responsible
    -- for invoking love.load before the main loop starts — boot.lua does
    -- not do it for us when we override love.run.
    if love.load then
        local ok, err = xpcall(function() love.load(arg) end, debug.traceback)
        if not ok then
            recordError("runtime:load", err)
        end
    end

    if love.timer then love.timer.step() end

    local dt = 0
    while true do
        if love.event then
            love.event.pump()
            for e, a, b, c, d in love.event.poll() do
                if e == "quit" then
                    if not love.quit or not love.quit() then
                        if love.audio then love.audio.stop() end
                        if dispatcher and dispatcher.stopAllOSCThreads then
                            pcall(dispatcher.stopAllOSCThreads)
                        end
                        return
                    end
                end
                love.handlers[e](a, b, c, d)
            end
        end

        if love.timer then
            love.timer.step()
            dt = love.timer.getDelta()
        end

        liveUpdate(dt)

        if love.graphics and love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(love.graphics.getBackgroundColor())
            liveDraw()
            love.graphics.present()
        end
    end
end


return lick
