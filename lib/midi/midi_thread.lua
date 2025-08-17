-- midi_thread.lua
--
-- MIDI input thread that runs in a separate thread
-- Handles MIDI device connection and message reception
-- Communicates with main thread via Love2D channels
--

-- Thread arguments: connectionId, connectionConfig
local connectionId, connectionConfig = ...

-- Try to load lovemidi library
local midi = nil
local midiAvailable = false

-- Attempt to load MIDI library
local function initMIDI()
    local success, result = pcall(require, "luamidi")
    if success then
        midi = result
        midiAvailable = true
        return true
    else
        print("MIDIThread [" .. connectionId .. "]: lovemidi library not available: " .. tostring(result))
        return false
    end
end

-- Find MIDI input device by name or index
local function findMIDIDevice(deviceName)
    if not midiAvailable then return nil end
    
    local inputCount = midi.getinportcount()
    print("MIDIThread [" .. connectionId .. "]: Found " .. inputCount .. " MIDI input devices")
    
    -- List all available devices
    for i = 0, inputCount - 1 do
        local portName = midi.getinportname(i)
        print("MIDIThread [" .. connectionId .. "]: Device " .. i .. ": " .. (portName or "Unknown"))
        
        -- Match by name (case insensitive) or exact index
        if deviceName then
            if type(deviceName) == "number" and deviceName == i then
                return i
            elseif type(deviceName) == "string" and portName and portName:lower():find(deviceName:lower()) then
                return i
            end
        end
    end
    
    -- If no specific device requested, use first available
    if not deviceName and inputCount > 0 then
        return 0
    end
    
    return nil
end

-- Convert MIDI message to string format for transmission
local function formatMIDIMessage(status, data1, data2)
    local msgType = ""
    local channel = (status & 0x0F) + 1  -- MIDI channels are 1-based in our system
    
    local statusType = status & 0xF0
    
    if statusType == 0x80 then -- Note Off
        msgType = "noteOff"
    elseif statusType == 0x90 then -- Note On
        msgType = "noteOn"
        -- Handle Note On with velocity 0 as Note Off
        if data2 == 0 then
            msgType = "noteOff"
        end
    elseif statusType == 0xB0 then -- Control Change
        msgType = "cc"
    elseif statusType == 0xC0 then -- Program Change
        msgType = "program"
    elseif statusType == 0xE0 then -- Pitch Bend
        msgType = "pitchbend"
        -- Combine data1 and data2 for 14-bit pitch bend value
        data1 = data1 + (data2 * 128)
        data2 = 0
    else
        msgType = "unknown"
    end
    
    return msgType .. " " .. channel .. " " .. data1 .. " " .. (data2 or 0)
end

-- Main MIDI thread function
local function runMIDIThread()
    print("MIDIThread [" .. connectionId .. "]: Starting MIDI thread")
    
    -- Initialize MIDI library
    if not initMIDI() then
        print("MIDIThread [" .. connectionId .. "]: Failed to initialize MIDI library")
        return
    end
    
    -- Find and open MIDI device
    local deviceIndex = findMIDIDevice(connectionConfig.device)
    if not deviceIndex then
        print("MIDIThread [" .. connectionId .. "]: Could not find MIDI device: " .. tostring(connectionConfig.device))
        return
    end
    
    print("MIDIThread [" .. connectionId .. "]: Using MIDI device " .. deviceIndex .. ": " .. (midi.getinportname(deviceIndex) or "Unknown"))
    
    -- Open MIDI input port
    local success = midi.openinport(deviceIndex)
    if not success then
        print("MIDIThread [" .. connectionId .. "]: Failed to open MIDI input port " .. deviceIndex)
        return
    end
    
    print("MIDIThread [" .. connectionId .. "]: MIDI input port opened successfully")
    
    -- Create channel for communication with main thread
    local channelName = "midiChannel_" .. connectionId
    local channel = love.thread.getChannel(channelName)
    
    -- Register this channel with the dispatcher
    local dispatcherChannel = love.thread.getChannel("midiDispatcherRegister")
    dispatcherChannel:push(channelName)
    
    print("MIDIThread [" .. connectionId .. "]: Registered channel " .. channelName)
    
    -- Main MIDI input loop
    local running = true
    while running do
        -- Check for MIDI messages
        if midi.getmessage then
            local status, data1, data2, timestamp = midi.getmessage()
            if status then
                -- Format and send MIDI message
                local formattedMsg = formatMIDIMessage(status, data1, data2)
                channel:push(formattedMsg)
                print("MIDIThread [" .. connectionId .. "]: " .. formattedMsg)
            end
        end
        
        -- Check for quit signal
        local quitChannel = love.thread.getChannel("midiQuit_" .. connectionId)
        local quitSignal = quitChannel:pop()
        if quitSignal then
            print("MIDIThread [" .. connectionId .. "]: Received quit signal")
            running = false
        end
        
        -- Small delay to prevent excessive CPU usage
        love.timer.sleep(0.001) -- 1ms delay
    end
    
    -- Cleanup
    if midi.closeinport then
        midi.closeinport()
    end
    
    if midi.gc then
        midi.gc()
    end
    
    -- Unregister channel
    local unregisterChannel = love.thread.getChannel("midiDispatcherUnregister")
    unregisterChannel:push(channelName)
    
    print("MIDIThread [" .. connectionId .. "]: MIDI thread terminated")
end

-- Start the MIDI thread
runMIDIThread()