-- OSCThread.lua
--
-- OSC (Open Sound Control) message receiver thread
-- Listens for OSC messages over UDP and forwards them to the main dispatcher
--
local initParams = { ... }
local oscConnectionId = initParams[1]
local oscConnectionConfig = initParams[2]
local oscServerIP = oscConnectionConfig.address
local oscServerPort = oscConnectionConfig.port

-- include libs
local socket = require "socket"
local bit = require "bit"  -- LuaJIT bitwise operations

-- Create UDP socket for OSC message reception
local oscSocket = socket.udp()
oscSocket:settimeout(0.001)
local success, err = oscSocket:setsockname(oscServerIP, oscServerPort)

if not success then
    print("OSC Thread " .. oscConnectionId .. " failed to bind to " .. oscServerIP .. ":" .. oscServerPort .. " - " .. (err or "unknown error"))
    return
end

-- Set up OSC communication channels
local oscChannelName = "oscChannel_" .. oscConnectionId
local oscMessageChannel = love.thread.getChannel(oscChannelName)
local oscFeedbackChannel = love.thread.getChannel("oscFeedback")

print("OSC Thread " .. oscConnectionId .. " listening for OSC messages on " .. oscServerIP .. ":" .. oscServerPort)

-- OSC packet parser for standard OSC protocol messages
local function parseOSCPacket(oscPacket)
    -- Parse standard OSC format: "/address\0,type\0\0<data_bytes>"
    -- This handles basic OSC messages with float (f), integer (i), and string (s) types
    
    -- Extract OSC address (null-terminated string at start)
    local nullPos = oscPacket:find('\0')
    if nullPos then
        local oscAddress = oscPacket:sub(1, nullPos - 1)
        
        -- Look for OSC type tag (starts with comma)
        local typeStart = nullPos + 1
        local typeEnd = oscPacket:find('\0', typeStart)
        if typeEnd then
            local oscTypeTag = oscPacket:sub(typeStart, typeEnd - 1)
            
            if oscTypeTag == ",f" or oscTypeTag == ",i" or oscTypeTag == ",s" then
                -- Extract OSC value data (padded to 4-byte boundaries)
                local valueStart = typeEnd + 1
                while valueStart <= #oscPacket and oscPacket:byte(valueStart) == 0 do
                    valueStart = valueStart + 1
                end
                
                if valueStart <= #oscPacket then
                    local oscValue
                    if oscTypeTag == ",f" then
                        -- OSC float (4 bytes, big-endian IEEE 754)
                        -- Use simplified approach: extract 4 bytes and reconstruct using bit ops
                        if valueStart + 3 <= #oscPacket then
                            local b1, b2, b3, b4 = oscPacket:byte(valueStart, valueStart + 3)
                            -- Combine bytes using LuaJIT bit operations
                            local intBits = bit.bor(
                                bit.lshift(b1, 24),
                                bit.lshift(b2, 16),
                                bit.lshift(b3, 8),
                                b4
                            )
                            
                            -- For simplicity, use a basic conversion approach
                            -- Real OSC implementations should use proper IEEE 754 decoding
                            if intBits == 0 then
                                oscValue = 0.0
                            else
                                -- Extract components using bit operations
                                local sign = bit.rshift(intBits, 31)
                                local exponent = bit.band(bit.rshift(intBits, 23), 0xFF)
                                local mantissa = bit.band(intBits, 0x7FFFFF)
                                
                                -- Simplified float reconstruction (handles most common cases)
                                if exponent == 0 then
                                    oscValue = 0.0
                                elseif exponent == 0xFF then
                                    oscValue = (sign == 1) and -math.huge or math.huge
                                else
                                    local realExponent = exponent - 127
                                    local fraction = 1.0 + mantissa / (2^23)
                                    oscValue = ((-1)^sign) * fraction * (2^realExponent)
                                end
                            end
                        end
                    elseif oscTypeTag == ",i" then
                        -- OSC integer (4 bytes, big-endian)
                        if valueStart + 3 <= #oscPacket then
                            local b1, b2, b3, b4 = oscPacket:byte(valueStart, valueStart + 3)
                            -- Combine bytes using LuaJIT bit operations
                            oscValue = bit.bor(
                                bit.lshift(b1, 24),
                                bit.lshift(b2, 16),
                                bit.lshift(b3, 8),
                                b4
                            )
                            -- Handle signed integers (two's complement)
                            if oscValue > 2147483647 then
                                oscValue = oscValue - 4294967296
                            end
                        end
                    elseif oscTypeTag == ",s" then
                        -- OSC string (null-terminated, padded to 4-byte boundary)
                        local stringEnd = oscPacket:find('\0', valueStart)
                        if stringEnd then
                            oscValue = oscPacket:sub(valueStart, stringEnd - 1)
                        end
                    end
                    
                    if oscValue ~= nil then
                        return oscAddress, oscValue
                    end
                end
            end
        end
    end
    
    -- Fallback: try simple text format for testing "address value"
    local oscAddress, valueStr = oscPacket:match("([^ ]+) (.+)")
    if oscAddress and valueStr then
        local oscValue = tonumber(valueStr) or valueStr
        return oscAddress, oscValue
    end
    
    return nil
end

-- Main OSC message reception loop
while true do
    local oscPacket, senderIP, senderPort = oscSocket:receivefrom()
    if oscPacket then
        -- Parse incoming OSC packet
        local oscAddress, oscValue = parseOSCPacket(oscPacket)
        if oscAddress and oscValue ~= nil then
            -- Forward parsed OSC message to main thread dispatcher
            local oscMessage = oscAddress .. " " .. tostring(oscValue)
            oscMessageChannel:push(oscMessage)
        else
            -- Forward raw packet if OSC parsing fails (for debugging)
            oscMessageChannel:push(oscPacket)
        end
    end
    
    -- Handle OSC feedback/response messages (optional bidirectional OSC)
    local oscFeedback = oscFeedbackChannel:pop()
    if oscFeedback and senderIP then
        -- Send OSC feedback as simple text format to original sender
        for oscAddr, oscVal in pairs(oscFeedback) do
            local oscResponse = oscAddr .. " " .. tostring(oscVal)
            oscSocket:sendto(oscResponse, senderIP, senderPort)
        end
    end
end