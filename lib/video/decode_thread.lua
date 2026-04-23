require("love.data")
require("love.timer")
local ffi = require("ffi")

local sourcePath, cmdChannel, frameChannel, recycleChannel = ...

-- Set up package path so we can require project modules
package.path = sourcePath .. "/?.lua;" .. package.path
local ff = require("lib.video.ffmpeg_ffi")

local fmtCtx, codecCtx, swsCtx, frame, packet
local streamIdx, timeBase, width, height, duration, frameDuration
local state = "idle"
local speed = 1.0
local targetPts = 0
local lastDecodedPts = -1
local eof = false

local function cleanup()
    if swsCtx ~= nil then
        ff.swscale.sws_freeContext(swsCtx)
        swsCtx = nil
    end
    if frame ~= nil then
        local fp = ffi.new("AVFrame*[1]", { frame })
        ff.avutil.av_frame_free(fp)
        frame = nil
    end
    if packet ~= nil then
        local pp = ffi.new("AVPacket*[1]", { packet })
        ff.avcodec.av_packet_free(pp)
        packet = nil
    end
    if codecCtx ~= nil then
        local cp = ffi.new("AVCodecContext*[1]", { codecCtx })
        ff.avcodec.avcodec_free_context(cp)
        codecCtx = nil
    end
    if fmtCtx ~= nil then
        local fp = ffi.new("AVFormatContext*[1]", { fmtCtx })
        ff.avformat.avformat_close_input(fp)
        fmtCtx = nil
    end
    state = "idle"
end

local function openVideo(path)
    cleanup()

    local fmtCtxPtr = ffi.new("AVFormatContext*[1]")
    if ff.avformat.avformat_open_input(fmtCtxPtr, path, nil, nil) < 0 then
        frameChannel:push("error")
        frameChannel:push("failed to open " .. path)
        return
    end
    fmtCtx = fmtCtxPtr[0]

    if ff.avformat.avformat_find_stream_info(fmtCtx, nil) < 0 then
        frameChannel:push("error")
        frameChannel:push("failed to find stream info")
        cleanup()
        return
    end

    local codecPtr = ffi.new("const AVCodec*[1]")
    streamIdx = ff.avformat.av_find_best_stream(
        fmtCtx, ff.AVMEDIA_TYPE_VIDEO, -1, -1, codecPtr, 0)
    if streamIdx < 0 then
        frameChannel:push("error")
        frameChannel:push("no video stream found")
        cleanup()
        return
    end

    local stream = fmtCtx.streams[streamIdx]
    local codecpar = stream.codecpar
    timeBase = stream.time_base
    width = codecpar.width
    height = codecpar.height
    duration = tonumber(fmtCtx.duration) / ff.AV_TIME_BASE
    frameDuration = (timeBase.num > 0 and timeBase.den > 0)
        and timeBase.num / timeBase.den or 1 / 30

    codecCtx = ff.avcodec.avcodec_alloc_context3(codecPtr[0])
    ff.avcodec.avcodec_parameters_to_context(codecCtx, codecpar)
    if ff.avcodec.avcodec_open2(codecCtx, codecPtr[0], nil) < 0 then
        frameChannel:push("error")
        frameChannel:push("failed to open codec")
        cleanup()
        return
    end

    swsCtx = ff.swscale.sws_getContext(
        width, height, codecpar.format,
        width, height, ff.AV_PIX_FMT_RGBA,
        ff.SWS_BILINEAR, nil, nil, nil)

    frame = ff.avutil.av_frame_alloc()
    packet = ff.avcodec.av_packet_alloc()
    lastDecodedPts = -1
    eof = false

    frameChannel:push("info")
    frameChannel:push(width)
    frameChannel:push(height)
    frameChannel:push(duration)
    frameChannel:push(frameDuration)

    state = "ready"
end

local function ptsToSeconds(pts)
    if pts == nil then return 0 end
    return tonumber(pts) * timeBase.num / timeBase.den
end

local function secondsToPts(seconds)
    return math.floor(seconds * timeBase.den / timeBase.num)
end

local function decodeOneFrame(buf)
    local dstPtr = ffi.cast("uint8_t*", buf:getFFIPointer())
    local dstSlice = ffi.new("uint8_t*[4]", { dstPtr, nil, nil, nil })
    local dstStride = ffi.new("int[4]", { width * 4, 0, 0, 0 })

    while true do
        local ret = ff.avformat.av_read_frame(fmtCtx, packet)
        if ret < 0 then
            ff.avcodec.av_packet_unref(packet)
            eof = true
            return nil
        end

        if packet.stream_index == streamIdx then
            ret = ff.avcodec.avcodec_send_packet(codecCtx, packet)
            ff.avcodec.av_packet_unref(packet)
            if ret < 0 then return nil end

            ret = ff.avcodec.avcodec_receive_frame(codecCtx, frame)
            if ret == 0 then
                ff.swscale.sws_scale(swsCtx,
                    ffi.cast("const uint8_t *const *", frame.data),
                    frame.linesize, 0, height,
                    dstSlice, dstStride)
                local pts = ptsToSeconds(frame.pts)
                lastDecodedPts = pts
                return pts
            end
        else
            ff.avcodec.av_packet_unref(packet)
        end
    end
end

local function seekTo(seconds)
    if fmtCtx == nil then return end
    seconds = math.max(0, seconds)
    local ts = secondsToPts(seconds)
    ff.avformat.av_seek_frame(fmtCtx, streamIdx, ts, ff.AVSEEK_FLAG_BACKWARD)
    ff.avcodec.avcodec_flush_buffers(codecCtx)
    eof = false
    lastDecodedPts = -1
end

-- Main loop
while true do
    -- Process all pending commands
    local cmd = cmdChannel:pop()
    while cmd do
        if cmd == "open" then
            local path = cmdChannel:demand()
            openVideo(path)
        elseif cmd == "seek" then
            local seconds = cmdChannel:demand()
            seekTo(seconds)
            frameChannel:push("flush")
        elseif cmd == "speed" then
            speed = cmdChannel:demand()
        elseif cmd == "play" then
            if state == "ready" then state = "playing" end
        elseif cmd == "pause" then
            if state == "playing" then state = "ready" end
        elseif cmd == "quit" then
            cleanup()
            return
        end
        cmd = cmdChannel:pop()
    end

    -- Decode ahead if playing and not at EOF
    if state == "playing" and not eof then
        local buf = recycleChannel:pop()
        if buf then
            local pts = decodeOneFrame(buf)
            if pts then
                frameChannel:push("frame")
                frameChannel:push(pts)
                frameChannel:push(buf)
            else
                recycleChannel:push(buf)
                if eof then
                    frameChannel:push("eof")
                end
            end
        else
            love.timer.sleep(0.001)
        end
    else
        love.timer.sleep(0.005)
    end
end
