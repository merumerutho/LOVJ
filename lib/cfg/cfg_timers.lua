-- cfg_screen.lua
--
-- Configure and handle global timers
--

local Timer = lovjRequire("lib/timer")
local cfg_timers = {}

cfg_timers.timers_list = {}

function cfg_timers.insertTimer(t)
    table.insert(cfg_timers.timers_list, t)
end


function cfg_timers.update()
    for i,t in pairs(cfg_timers.timers_list) do
        t:update()
    end
end


function cfg_timers.reset()
    for i, t in pairs(cfg_timers.timers_list) do
        t:reset()
    end
end


function cfg_timers.init()
    -- global
    cfg_timers.globalTimer = Timer:new()
    cfg_timers.insertTimer(cfg_timers.globalTimer)
    -- console
    cfg_timers.consoleTimer = Timer:new(1)
    cfg_timers.insertTimer(cfg_timers.consoleTimer)
    -- fps
    cfg_timers.fpsTimer = Timer:new(1/60)
    cfg_timers.insertTimer(cfg_timers.fpsTimer)
    -- one second
    cfg_timers.oneSecTimer = Timer:new(1)
    cfg_timers.insertTimer(cfg_timers.oneSecTimer)

end

return cfg_timers