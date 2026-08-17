-- frame_profiler.lua
--
-- Lightweight frame-stall diagnostics. main.lua marks named sections through
-- update/draw; when a frame's measured work (or the raw dt) exceeds the stall
-- threshold, a per-section breakdown is logged together with the Lua heap
-- size. A periodic heartbeat line logs heap + FPS so slow leaks show up as a
-- trend (a steadily growing heap means steadily growing GC pauses).
--
-- Enabled via cfg_app.frameDiagnostics; every call is a no-op when disabled.
--

local profiler = {}

profiler.enabled = false
profiler.threshold = 0.030        -- seconds of frame work that counts as a stall
profiler.heartbeatPeriod = 10     -- seconds between heap/FPS trend lines

local names, times = {}, {}
local count = 0
local injected = 0
local frameStart, lastMark = 0, 0
local lastHeartbeat = 0

function profiler.frameBegin()
    if not profiler.enabled then return end
    count = 0
    injected = 0
    frameStart = love.timer.getTime()
    lastMark = frameStart
end

--- Record the time elapsed since the previous mark under `name`.
function profiler.mark(name)
    if not profiler.enabled then return end
    local now = love.timer.getTime()
    count = count + 1
    names[count] = name
    times[count] = now - lastMark
    lastMark = now
end

--- Record an externally measured duration (work that ran outside the
--- frameBegin..frameEnd window, e.g. lick's file watching in love.run).
function profiler.add(name, duration)
    if not profiler.enabled or not duration then return end
    count = count + 1
    names[count] = name
    times[count] = duration
    injected = injected + duration
end

function profiler.frameEnd(dt)
    if not profiler.enabled then return end
    local now = love.timer.getTime()
    local total = (now - frameStart) + injected

    if total > profiler.threshold or (dt or 0) > profiler.threshold * 2 then
        local parts = {}
        for i = 1, count do
            if times[i] >= 0.001 then
                table.insert(parts, string.format("%s %.1fms", names[i], times[i] * 1000))
            end
        end
        logInfo(string.format("STALL work %.1fms dt %.1fms heap %.1fMB | %s",
            total * 1000, (dt or 0) * 1000, collectgarbage("count") / 1024,
            table.concat(parts, ", ")))
    end

    if now - lastHeartbeat > profiler.heartbeatPeriod then
        lastHeartbeat = now
        logInfo(string.format("HEAP %.1fMB FPS %d", collectgarbage("count") / 1024, love.timer.getFPS()))
    end
end

return profiler
