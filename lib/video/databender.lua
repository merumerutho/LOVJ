local ffi = require("ffi")
local bit = require("bit")

local AV_PKT_FLAG_KEY = 0x0001

local DataBender = {}
DataBender.__index = DataBender

function DataBender:new()
    math.randomseed(os.time())
    return setmetatable({
        mode = "off",
        intensity = 0.5,
        frameCount = 0,
        lastPFrameData = nil,
        lastPFrameSize = 0,
        meltCounter = 0,
        bloomRepeatCount = 0,
        hadFirstKeyframe = false,
    }, self)
end

function DataBender:setMode(mode)
    if mode ~= self.mode then
        print("[DataBender] mode: " .. tostring(mode))
        self.mode = mode
        self.frameCount = 0
        self.meltCounter = 0
        self.bloomRepeatCount = 0
        self.lastPFrameData = nil
        self.lastPFrameSize = 0
        self.hadFirstKeyframe = false
    end
end

function DataBender:onSeek()
    self.hadFirstKeyframe = false
end

function DataBender:setIntensity(intensity)
    self.intensity = math.max(0, intensity)
end

function DataBender:isKeyframe(packet)
    return bit.band(packet.flags, AV_PKT_FLAG_KEY) ~= 0
end

function DataBender:processPacket(packet)
    if self.mode == "off" then return "decode" end

    self.frameCount = self.frameCount + 1

    if self.mode == "melt" then
        return self:_melt(packet)
    elseif self.mode == "crush" then
        return self:_crush(packet)
    elseif self.mode == "corrupt" then
        return self:_corrupt(packet)
    elseif self.mode == "bloom" then
        return self:_bloom(packet)
    end

    return "decode"
end

--- Melt: remove I-frames so P-frames apply deltas to stale references.
--- At intensity 1, ~50 keyframes skipped before reset. No upper clamp.
function DataBender:_melt(packet)
    if self:isKeyframe(packet) then
        if not self.hadFirstKeyframe then
            self.hadFirstKeyframe = true
            return "decode"
        end
        self.meltCounter = self.meltCounter + 1
        local skipCount = math.max(1, math.floor(self.intensity * 200))
        if self.meltCounter > skipCount then
            self.meltCounter = 0
            return "decode"
        end
        return "skip"
    end
    return "decode"
end

--- Crush: corrupt I-frame data so the decoder builds a garbled reference,
--- then P-frames apply motion deltas on top of the garbage.
function DataBender:_crush(packet)
    if self:isKeyframe(packet) then
        if not self.hadFirstKeyframe then
            self.hadFirstKeyframe = true
            return "decode"
        end
        self.meltCounter = self.meltCounter + 1
        local skipCount = math.max(1, math.floor(self.intensity * 50))
        if self.meltCounter > skipCount then
            self.meltCounter = 0
            return "decode"
        end
        if packet.size > 32 then
            local start = 16
            local range = packet.size - start
            local numCorrupt = math.max(1, math.floor(range * 0.3 * math.min(self.intensity, 1)))
            for i = 1, numCorrupt do
                local pos = start + math.random(0, range - 1)
                packet.data[pos] = 0
            end
        end
        return "decode"
    end
    return "decode"
end

--- Corrupt: copy/shift memory blocks within the packet data.
--- Produces macro-block displacement artifacts rather than random noise.
--- Only touches non-keyframe packets to avoid decoder crashes.
function DataBender:_corrupt(packet)
    if packet.size < 64 then return "decode" end
    if self:isKeyframe(packet) then return "decode" end

    local safeOffset = 16
    local range = packet.size - safeOffset
    if range < 32 then return "decode" end

    local numOps = math.max(1, math.floor(self.intensity * 8))
    local maxBlock = math.max(8, math.min(math.floor(range / 2), math.floor(self.intensity * 256)))

    pcall(function()
        for i = 1, numOps do
            local op = math.random(1, 3)
            if op == 1 then
                local blockSize = math.random(8, maxBlock)
                local src = safeOffset + math.random(0, range - blockSize - 1)
                local dst = safeOffset + math.random(0, range - blockSize - 1)
                ffi.copy(packet.data + dst, packet.data + src, blockSize)
            elseif op == 2 then
                local blockSize = math.random(16, maxBlock)
                local pos = safeOffset + math.random(0, range - blockSize - 1)
                local shift = math.random(1, math.min(math.floor(self.intensity * 64), blockSize))
                ffi.C.memmove(packet.data + pos + shift, packet.data + pos, blockSize - shift)
            else
                local patternPos = safeOffset + math.random(0, range - 5)
                local fillSize = math.random(4, math.min(maxBlock, range - (patternPos - safeOffset)))
                local byte = packet.data[patternPos]
                ffi.fill(packet.data + patternPos, fillSize, byte)
            end
        end
    end)

    return "decode"
end

--- Bloom: re-send the same P-frame repeatedly for pixel streak effects.
--- Bloom: skip I-frames (like melt) AND repeat the same P-frame.
--- The repeated motion vectors accumulate on a stale reference,
--- creating progressive pixel streaking/bleeding.
function DataBender:_bloom(packet)
    if self:isKeyframe(packet) then
        if not self.hadFirstKeyframe then
            self.hadFirstKeyframe = true
            return "decode"
        end
        -- Skip I-frames so the reference stays stale
        return "skip"
    end

    -- Capture first P-frame we see
    if not self.lastPFrameData then
        self.lastPFrameData = ffi.new("uint8_t[?]", packet.size)
        ffi.copy(self.lastPFrameData, packet.data, packet.size)
        self.lastPFrameSize = packet.size
        self.bloomRepeatCount = 0
        return "decode"
    end

    self.bloomRepeatCount = self.bloomRepeatCount + 1
    local repeatTarget = math.max(2, math.floor(self.intensity * 60))

    if self.bloomRepeatCount < repeatTarget then
        -- Overwrite this packet with the captured P-frame's data
        local copySize = math.min(self.lastPFrameSize, packet.size)
        ffi.copy(packet.data, self.lastPFrameData, copySize)
        return "decode"
    else
        -- Capture a new P-frame
        self.lastPFrameData = ffi.new("uint8_t[?]", packet.size)
        ffi.copy(self.lastPFrameData, packet.data, packet.size)
        self.lastPFrameSize = packet.size
        self.bloomRepeatCount = 0
        return "decode"
    end
end

return DataBender
