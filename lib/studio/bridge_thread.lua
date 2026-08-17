-- bridge_thread.lua
--
-- Runs inside a love.thread. Hosts:
--   1. An HTTP listener serving the built Svelte app from studio/dist/
--   2. A WebSocket listener for authoring traffic
--
-- Communication with main thread goes through three channels:
--   studio:inbox   messages received from WS clients (strings, usually JSON)
--   studio:outbox  messages to broadcast to all WS clients (strings)
--   studio:log     log lines for the main thread to surface (level|text)
--
-- Control messages (from main):
--   studio:outbox.push("__stop__") tells the thread to exit cleanly.
--

local initParams = { ... }
local cfg = initParams[1] or {}

local socket = require "socket"
local ws = require "lib/studio/websocket"
local http = require "lib/studio/http"

local HTTP_PORT     = cfg.httpPort     or 8080
local WS_PORT       = cfg.wsPort       or 8765
local BIND_ADDRESS  = cfg.bindAddress  or "127.0.0.1"
local STATIC_ROOT   = cfg.staticRoot   or "studio/dist"
local ACCEPT_TIMEOUT = 0.005

local inbox   = love.thread.getChannel("studio:inbox")
local outbox  = love.thread.getChannel("studio:outbox")
local logChan = love.thread.getChannel("studio:log")


local function log(level, msg)
    logChan:push(level .. "|" .. msg)
end


-- Bind a listening TCP socket, or return nil + error.
local function listen(port)
    local server, err = socket.bind(BIND_ADDRESS, port)
    if not server then return nil, err end
    server:settimeout(0)  -- non-blocking accept
    return server
end


local httpServer, err = listen(HTTP_PORT)
if not httpServer then
    log("ERROR", "studio.http bind " .. BIND_ADDRESS .. ":" .. HTTP_PORT .. " failed: " .. tostring(err))
    return
end
log("INFO", "studio.http listening on " .. BIND_ADDRESS .. ":" .. HTTP_PORT)

local wsServer, wserr = listen(WS_PORT)
if not wsServer then
    log("ERROR", "studio.ws bind " .. BIND_ADDRESS .. ":" .. WS_PORT .. " failed: " .. tostring(wserr))
    return
end
log("INFO", "studio.ws  listening on " .. BIND_ADDRESS .. ":" .. WS_PORT)


-- Client state
-- For HTTP:  { kind="http", sock=.., buf="", out="", closing=bool }
-- For WS:    { kind="ws",   sock=.., buf="", out="", state="handshake"|"open" }
local clients = {}

-- Never let a stalled client hold unbounded memory.
local MAX_OUT_BUFFER = 4 * 1024 * 1024


local function closeClient(c, reason)
    pcall(function() c.sock:close() end)
    clients[c] = nil
    if reason then log("DEBUG", "client closed: " .. reason) end
end


-- Queue outgoing bytes. Sockets are non-blocking, so writes MUST go through
-- this buffer — a raw sock:send() silently drops whatever didn't fit in the
-- kernel buffer (truncated HTTP bodies, corrupted WS frame streams).
local function queueOut(c, data)
    c.out = c.out .. data
    if #c.out > MAX_OUT_BUFFER then
        closeClient(c, "outgoing buffer overflow")
    end
end


-- Push as much of the pending outgoing buffer as the socket accepts.
-- Returns false when the connection is dead.
local function flushOut(c)
    if #c.out == 0 then return true end
    local ok, err, lastSent = c.sock:send(c.out)
    local sent = ok or lastSent or 0
    if sent > 0 then c.out = c.out:sub(sent + 1) end
    if not ok and err ~= "timeout" then return false end
    return true
end


-- Try to read all available data from a socket; returns appended buffer or
-- nil if the socket has been closed by the peer.
local function readAvailable(c)
    while true do
        local chunk, err, partial = c.sock:receive(4096)
        if chunk then
            c.buf = c.buf .. chunk
        elseif partial and #partial > 0 then
            c.buf = c.buf .. partial
            if err == "closed" then return nil end
            return c.buf
        else
            if err == "timeout" then return c.buf end
            if err == "closed" then return nil end
            -- some other error
            return nil
        end
    end
end


local function handleHttp(c)
    local buf = readAvailable(c)
    if buf == nil then closeClient(c, "http peer closed"); return end
    -- Wait until we have the request headers terminator
    if not c.buf:find("\r\n\r\n", 1, true) then
        -- cap buffer to prevent abuse
        if #c.buf > 16384 then closeClient(c, "http headers too large") end
        return
    end
    local resp = http.handle(c.buf, STATIC_ROOT)
    queueOut(c, resp)
    c.closing = true  -- closed by tick() once the response has fully drained
end


local function handleWsHandshake(c)
    local buf = readAvailable(c)
    if buf == nil then closeClient(c, "ws peer closed during handshake"); return end
    if not c.buf:find("\r\n\r\n", 1, true) then
        if #c.buf > 16384 then closeClient(c, "ws handshake too large") end
        return
    end

    local method, path, headers = ws.parseRequest(c.buf)
    if not method or not headers or not headers["sec-websocket-key"] then
        queueOut(c, "HTTP/1.1 400 Bad Request\r\nContent-Length: 0\r\n\r\n")
        c.closing = true
        log("DEBUG", "ws bad handshake")
        return
    end

    queueOut(c, ws.handshakeResponse(headers["sec-websocket-key"]))
    c.state = "open"
    c.buf = c.buf:sub((c.buf:find("\r\n\r\n", 1, true) or 0) + 4)
    log("INFO", "studio.ws client connected")
end


local function handleWsFrames(c)
    local buf = readAvailable(c)
    if buf == nil then closeClient(c, "ws peer closed"); return end

    while true do
        local opcode, payload, remaining, fin = ws.decodeFrame(c.buf)
        if not opcode then
            if payload == "need-more" then return end
            -- protocol error
            queueOut(c, ws.encodeClose(1002, payload or "proto"))
            c.closing = true
            log("DEBUG", "ws proto error: " .. tostring(payload))
            return
        end

        c.buf = remaining

        if opcode == ws.OP_TEXT then
            -- Push raw text to inbox. The main-thread protocol layer parses
            -- JSON and dispatches commands; responses go out via the outbox
            -- broadcast channel.
            inbox:push(payload)
        elseif opcode == ws.OP_PING then
            queueOut(c, ws.encodePong(payload))
        elseif opcode == ws.OP_PONG then
            -- Ignore.
        elseif opcode == ws.OP_CLOSE then
            queueOut(c, ws.encodeClose(1000))
            c.closing = true
            log("DEBUG", "ws close")
            return
        end
    end
end


local function acceptIncoming(server, kind)
    while true do
        local client, aerr = server:accept()
        if not client then break end
        client:settimeout(0)
        -- Nagle + delayed ACK adds up to ~200ms per small frame on Windows
        -- loopback; a control surface wants its frames out immediately.
        pcall(function() client:setoption("tcp-nodelay", true) end)
        clients[{sock = client, kind = kind, buf = "", out = "", state = (kind == "ws") and "handshake" or "http"}] = true
        -- clients table indexed by the client-state table itself; iterate below.
    end
end


local function tick()
    acceptIncoming(httpServer, "http")
    acceptIncoming(wsServer, "ws")

    for c, _ in pairs(clients) do
        if c.closing then
            -- response queued; just draining — stop reading
        elseif c.kind == "http" then
            handleHttp(c)
        else
            if c.state == "handshake" then
                handleWsHandshake(c)
            else
                handleWsFrames(c)
            end
        end
    end

    -- Drain outbox: broadcast outgoing frames to all open ws clients.
    while true do
        local msg = outbox:pop()
        if not msg then break end
        if msg == "__stop__" then
            for c, _ in pairs(clients) do closeClient(c) end
            httpServer:close()
            wsServer:close()
            return false
        end
        local frame = ws.encodeText(msg)
        for c, _ in pairs(clients) do
            if c.kind == "ws" and c.state == "open" and not c.closing then
                queueOut(c, frame)
            end
        end
    end

    -- Push pending outgoing data; drop dead peers, close drained closers.
    for c, _ in pairs(clients) do
        if not flushOut(c) then
            closeClient(c, "send failed")
        elseif c.closing and #c.out == 0 then
            closeClient(c)
        end
    end

    return true
end


-- Main loop.
while true do
    local ok, cont = pcall(tick)
    if not ok then
        log("ERROR", "studio.bridge tick failed: " .. tostring(cont))
    elseif cont == false then
        log("INFO", "studio.bridge stopping")
        return
    end
    -- Small sleep so we don't spin at 100% CPU.
    socket.sleep(ACCEPT_TIMEOUT)
end
