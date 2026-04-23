local ffi = require("ffi")

local POOL_SIZE = 8

local VideoSampler = {}
VideoSampler.__index = VideoSampler

function VideoSampler:new()
    local o = setmetatable({}, self)
    o.state = "closed"
    o.position = 0
    o.speed = 1.0
    o.loopStart = 0
    o.loopEnd = nil
    o.playing = false
    o.width = 0
    o.height = 0
    o.duration = 0
    o.frameDuration = 1 / 30
    o.currentPts = -1
    o.currentBuf = nil
    return o
end

function VideoSampler:open(path)
    if self.state ~= "closed" then self:close() end

    self.cmdChannel = love.thread.newChannel()
    self.frameChannel = love.thread.newChannel()
    self.recycleChannel = love.thread.newChannel()

    self.thread = love.thread.newThread("lib/video/decode_thread.lua")
    local sourcePath = love.filesystem.getSource()
    self.thread:start(sourcePath, self.cmdChannel, self.frameChannel, self.recycleChannel)

    self.cmdChannel:push("open")
    self.cmdChannel:push(path)

    -- Wait for info response
    local response = self.frameChannel:demand(5)
    if response == "error" then
        local msg = self.frameChannel:demand()
        logError("VideoSampler: " .. msg)
        self:close()
        return false
    end
    if response ~= "info" then
        logError("VideoSampler: unexpected response: " .. tostring(response))
        self:close()
        return false
    end

    self.width = self.frameChannel:demand()
    self.height = self.frameChannel:demand()
    self.duration = self.frameChannel:demand()
    self.frameDuration = self.frameChannel:demand()
    local frameSize = self.width * self.height * 4

    -- Create frame pool
    self.pool = {}
    for i = 1, POOL_SIZE do
        local buf = love.data.newByteData(frameSize)
        self.pool[i] = buf
        self.recycleChannel:push(buf)
    end

    -- Create persistent ImageData and Image for GPU upload
    self.imageData = love.image.newImageData(self.width, self.height, "rgba8")
    self.imageDataPtr = ffi.cast("uint8_t*", self.imageData:getFFIPointer())
    self.image = love.graphics.newImage(self.imageData)
    self.frameSize = frameSize

    self.state = "open"
    self.position = 0
    self.currentPts = -1
    self.currentBuf = nil

    logInfo("VideoSampler: opened " .. path ..
        " (" .. self.width .. "x" .. self.height ..
        ", " .. string.format("%.1f", self.duration) .. "s)")
    return true
end

function VideoSampler:_drainFrames()
    while self.frameChannel:getCount() > 0 do
        local msg = self.frameChannel:pop()
        if msg == "frame" then
            local pts = self.frameChannel:demand()
            local buf = self.frameChannel:demand()
            self.recycleChannel:push(buf)
        end
    end
end

function VideoSampler:_consumeFrames()
    local bestPts = nil
    local bestBuf = nil

    while self.frameChannel:getCount() > 0 do
        local msg = self.frameChannel:pop()
        if msg == "frame" then
            local pts = self.frameChannel:demand()
            local buf = self.frameChannel:demand()

            if bestBuf then
                self.recycleChannel:push(bestBuf)
            end

            if pts <= self.position + self.frameDuration then
                bestPts = pts
                bestBuf = buf
            else
                bestPts = pts
                bestBuf = buf
                break
            end
        elseif msg == "flush" then
            if bestBuf then
                self.recycleChannel:push(bestBuf)
                bestBuf = nil
                bestPts = nil
            end
        elseif msg == "eof" then
            self.eof = true
        end
    end

    if bestBuf then
        local srcPtr = ffi.cast("const uint8_t*", bestBuf:getFFIPointer())
        ffi.copy(self.imageDataPtr, srcPtr, self.frameSize)
        self.image:replacePixels(self.imageData)
        self.currentPts = bestPts

        if self.currentBuf then
            self.recycleChannel:push(self.currentBuf)
        end
        self.currentBuf = bestBuf
    end
end

function VideoSampler:play()
    if self.state ~= "open" then return end
    self.playing = true
    self.eof = false
    self.cmdChannel:push("play")
end

function VideoSampler:pause()
    if self.state ~= "open" then return end
    self.playing = false
    self.cmdChannel:push("pause")
end

function VideoSampler:stop()
    self:pause()
    self:seek(0)
end

function VideoSampler:seek(seconds)
    if self.state ~= "open" then return end
    self.position = math.max(0, seconds)
    self.eof = false
    self.cmdChannel:push("seek")
    self.cmdChannel:push(self.position)
    self.cmdChannel:push("play")
end

function VideoSampler:setSpeed(speed)
    self.speed = speed
    if self.state == "open" then
        self.cmdChannel:push("speed")
        self.cmdChannel:push(speed)
    end
end

function VideoSampler:setLoopPoints(loopStart, loopEnd)
    self.loopStart = loopStart or 0
    self.loopEnd = loopEnd
end

function VideoSampler:update(dt)
    if self.state ~= "open" then return end

    if self.playing then
        self.position = self.position + dt * self.speed

        local effectiveEnd = self.loopEnd or self.duration
        if effectiveEnd > 0 then
            if self.speed >= 0 and self.position >= effectiveEnd then
                self.position = self.loopStart
                self:seek(self.position)
                return
            elseif self.speed < 0 and self.position <= self.loopStart then
                self.position = effectiveEnd
                self:seek(self.position)
                return
            end
        end

        if self.eof and self.speed >= 0 then
            self.position = self.loopStart
            self:seek(self.position)
            return
        end
    end

    self:_consumeFrames()
end

function VideoSampler:getImage()
    return self.image
end

function VideoSampler:close()
    if self.thread then
        self.cmdChannel:push("quit")
        self.thread:wait()
        self.thread = nil
    end
    if self.currentBuf then
        self.currentBuf = nil
    end
    self.pool = nil
    self.image = nil
    self.imageData = nil
    self.imageDataPtr = nil
    self.cmdChannel = nil
    self.frameChannel = nil
    self.recycleChannel = nil
    self.state = "closed"
    self.playing = false
end

return VideoSampler
