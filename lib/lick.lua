-- lick.lua
-- credits to usysrc
--
-- simple LIVECODING library for Löve
-- defines reset functions which are called when the code is modified
-- overwrites love.run, pressing all errors to the terminal/console
--

require("lib/utils/logging")

local lick = {}

local MAIN_FILE = "main.lua"

-- reset types
lick.HARD_RESET = "HARD RESET"
lick.SOFT_RESET = "SOFT RESET"
lick.PATCH_RESET = "PATCH RESET"

-- list containing structures as:
-- { name: "filename",
--   modtime: "last modification time",
--   resetType: "type of reset to apply"
-- }
-- by default contains the main.lua

lick.resetList = {}
lick.resetList["main"] = {time=0,
                          resetType=lick.HARD_RESET}

lick.debug = false
lick.clearFlag = false
lick.sleepTime = 0.001

--- @private handle Handle error in lick
local function handle(err)
	return "ERROR: " .. err
end


--- @private checkReset Check list of components for modifications to trigger reset if necessary
local function checkReset()
    for k, v in pairs(lick.resetList) do
        -- Check if file has changed by looking at filesystem modification time
        local modtime = love.filesystem.getInfo(k .. ".lua").modtime
        if modtime ~= v.time then
            v.time = modtime
            return {name=k, time=v.time, resetType=v.resetType}
        end
    end
    return {}
end

--- @private closeUDPThread used to close the UDP threads (if present)
local function closeUDPThread()
    local Connections = require("lib/connections")
    local cfg_connections = require("lib/cfg/cfg_connections")
    if Connections.UdpThreads == nil then return end

    -- If there are UDP_threads open, send them "quitMsg"
	for k,reqCh in pairs(Connections.ReqChannels) do
        logInfo("Closing UDP thread #" .. k)
        reqCh:push(cfg_connections.quitMsg)  -- send request to all channels
    end

    -- Expect quitAck from each thread
    local responses = {}
	for k, rspCh in pairs(Connections.RspChannels) do
        table.insert(responses, rspCh:demand(cfg_connections.TIMEOUT_TIME))  -- expect response from all channels
    end

    -- Release thread
    for k,resp in pairs(responses) do
        if resp == cfg_connections.ackQuit then
            Connections.UdpThreads[k]:release()
            logInfo("UDP Thread #".. k .. " released.")
        end
	end
end


--- @public lick.hardReset Perform hard reset of the program
function lick.hardReset(component)
    logInfo("Hard reset.")
    -- Close UDP socket and thread
    closeUDPThread()
    -- re-load main file
    success, chunk = pcall(love.filesystem.load, MAIN_FILE)
    if not success then
        logError(tostring(chunk))
        lick.debugoutput = chunk .. "\n"
    end
    ok,err = xpcall(chunk, handle)

    if not ok then
        logError(tostring(err))
        if lick.debugoutput then
            lick.debugoutput = (lick.debugoutput .."ERROR: ".. err .. "\n" )
        else
            lick.debugoutput =  err .. "\n"
        end
    else
        logInfo("Reloaded")
        lick.debugoutput = nil
    end

    loadok, err = xpcall(love.load, handle)
    if not loadok then
        logError(tostring(err))
        if lick.debugoutput then
            lick.debugoutput = (lick.debugoutput .."ERROR: ".. err .. "\n" )
        else
            lick.debugoutput =  err .. "\n"
        end
    end
end


--- @private checkForModifications call checkReset, and apply related reset
local function checkForModifications()
	-- check which component is in list for reset
    local resetComponent = checkReset()
	-- if none, return
    if not resetComponent.name then return end
    -- test loading the component (checks if safe to proceed without causing errors)
    if not lovjTest(resetComponent.name) then return end
	-- for components that require a patch-only reset
    if resetComponent.resetType == lick.PATCH_RESET then
        -- unload all patches
        for i=1,#patchSlots do
            logInfo(patchSlots[i].name .. " - patch reset.")
            lovjUnrequire(patchSlots[i].name)
        end
        -- re-load all patches
        for i=1,#patchSlots do
            patchSlots[i].patch = lovjRequire(patchSlots[i].name, lick.PATCH_RESET)
            patchSlots[i].patch.init(i)
        end
	-- for components that require a soft reset
    elseif resetComponent.resetType == lick.SOFT_RESET then
        logInfo(resetComponent.name .. " - soft reset.")
        for component, t in pairs(lick.resetList) do
            if (t.resetType == lick.SOFT_RESET or
                t.resetType == lick.PATCH_RESET) then
                lovjUnrequire(component)
            end
        end
    elseif resetComponent.resetType == lick.HARD_RESET then
		logInfo(resetComponent.name .. " - hard reset.")
        lick.hardReset(resetComponent)
    end
end


--- @private update Update call, also check for modifications of components and eventually resets
local function update(dt)
	-- Check and reset modified components
    checkForModifications()
    updateok, err = pcall(love.update, dt)
    if not updateok and not updateok_old then
        logError(tostring(err))
        if lick.debugoutput then
            lick.debugoutput = (lick.debugoutput .."ERROR: ".. err .. "\n" )
        else
            lick.debugoutput =  err .. "\n"
        end
    end
    updateok_old = not updateok
end


--- @private draw Draw call
local function draw()
    drawok, err = xpcall(love.draw, handle)
    if not drawok and not drawok_old then
        logError(tostring(err))
        if lick.debugoutput then
            lick.debugoutput = (lick.debugoutput .. err .. "\n" )
        else
            lick.debugoutput =  err .. "\n"
        end 
    end

    if lick.debugoutput then
        love.graphics.setColor(1,1,1,0.8)
        love.graphics.printf(lick.debugoutput, 0, 0, love.graphics.getWidth(), "left")
    end

    drawok_old = not drawok
end

--- @public love.run main cycle execution
function love.run()
    math.randomseed(os.time())
    math.random() math.random()

    local dt = 0
    -- Main loop
    while true do
        -- Process events.
        if love.event then
            love.event.pump()
            for e, a, b, c, d in love.event.poll() do
            if e == "quit" then
                if not love.quit or not love.quit() then
                    if love.audio then
                        love.audio.stop()
                        closeUDPThread()
                    end
                return
                end
            end
            love.handlers[e](a, b, c, d)
        end
    end

    -- Update dt, as we'll be passing it to update
    if love.timer then
        love.timer.step()
        dt = love.timer.getDelta()
    end

    -- Call update and draw
    if update then update(dt) end -- will pass 0 if love.timer is disabled
    if love.graphics then
        love.graphics.origin()
        love.graphics.clear(love.graphics.getBackgroundColor())
        if draw then draw() end
    end

    if love.graphics then love.graphics.present() end
  end
end


return lick
