-- bridge.lua
--
-- Main-thread side of the studio bridge. Spawns the worker thread, pumps
-- its inbox/log channels each tick, and exposes broadcast() for later
-- milestones to push updates to connected web clients.
--
-- M1 scope: pump the inbox and log lines. Actual protocol handling (parse
-- JSON, dispatch commands, build schema) lands in step 2.
--

local cfg_studio = lovjRequire("cfg/cfg_studio")

local bridge = {}

bridge.thread = nil
bridge.inbox = nil
bridge.outbox = nil
bridge.logChan = nil
bridge.messageHandler = nil   -- set by step 2 (protocol.lua)


local function defaultHandler(msg)
    logInfo("studio.bridge recv: " .. msg:sub(1, 200))
end


--- @public bridge.init spawn the worker thread.
function bridge.init()
    if not cfg_studio.enabled then
        logInfo("studio.bridge disabled via cfg_studio.enabled = false")
        return
    end

    bridge.inbox   = love.thread.getChannel("studio:inbox")
    bridge.outbox  = love.thread.getChannel("studio:outbox")
    bridge.logChan = love.thread.getChannel("studio:log")

    -- Drain any leftover messages from a previous run.
    bridge.inbox:clear()
    bridge.outbox:clear()
    bridge.logChan:clear()

    bridge.thread = love.thread.newThread("lib/studio/bridge_thread.lua")
    bridge.thread:start({
        httpPort    = cfg_studio.httpPort,
        wsPort      = cfg_studio.wsPort,
        bindAddress = cfg_studio.bindAddress,
        staticRoot  = cfg_studio.staticRoot,
    })

    logInfo("studio.bridge thread started (http:" .. cfg_studio.httpPort ..
            " ws:" .. cfg_studio.wsPort .. ")")
end


--- @public bridge.stop tell the worker thread to exit.
function bridge.stop()
    if bridge.outbox then bridge.outbox:push("__stop__") end
    if bridge.thread then
        bridge.thread:wait()
        bridge.thread = nil
    end
end


--- @public bridge.broadcast push a text message to all connected WS clients.
function bridge.broadcast(msg)
    if bridge.outbox then bridge.outbox:push(msg) end
end


--- @public bridge.setMessageHandler register protocol handler (step 2).
function bridge.setMessageHandler(fn)
    bridge.messageHandler = fn
end


--- @public bridge.update pump channels; called each frame from dispatcher.
function bridge.update()
    if not bridge.inbox then return end

    -- Surface log lines from the worker thread.
    while true do
        local line = bridge.logChan:pop()
        if not line then break end
        local level, text = line:match("^(%u+)|(.*)$")
        if level == "ERROR" then
            logError("[studio] " .. (text or line))
        else
            logInfo("[studio] " .. (text or line))
        end
    end

    -- Pump incoming messages.
    local handler = bridge.messageHandler or defaultHandler
    while true do
        local msg = bridge.inbox:pop()
        if not msg then break end
        local ok, err = pcall(handler, msg)
        if not ok then
            logError("studio.bridge handler error: " .. tostring(err))
        end
    end

    -- Surface thread death, if any.
    if bridge.thread and bridge.thread:isRunning() == false then
        local err = bridge.thread:getError()
        if err then
            logError("studio.bridge thread crashed: " .. tostring(err))
            bridge.thread = nil
        end
    end
end


return bridge
