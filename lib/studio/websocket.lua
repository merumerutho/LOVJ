-- websocket.lua
--
-- RFC 6455 helpers, scoped to what LOVJ's studio bridge actually needs:
--   * HTTP request parsing (just enough to pluck Sec-WebSocket-Key)
--   * Handshake response
--   * Text frame encode (server -> client, unmasked)
--   * Close + pong frame encode
--   * Frame decode (handles control frames, masking, 16- and 64-bit lengths)
--
-- Limitations (by design for M1):
--   * No fragmentation support for outgoing frames (single-fragment only).
--   * 64-bit payload sizes beyond 2^31 are not handled.
--   * No permessage-deflate / extensions.
--

local crypto = require "lib/studio/crypto"
local bit = require "bit"
local band, bor, bxor = bit.band, bit.bor, bit.bxor
local lshift, rshift = bit.lshift, bit.rshift

local M = {}

local MAGIC = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

M.OP_CONT   = 0x0
M.OP_TEXT   = 0x1
M.OP_BINARY = 0x2
M.OP_CLOSE  = 0x8
M.OP_PING   = 0x9
M.OP_PONG   = 0xA


--- Parse an HTTP request. Returns (method, path, headers) or nil.
--- Headers table is keyed by lowercased field name.
function M.parseRequest(request)
    local firstEnd = request:find("\r\n", 1, true)
    if not firstEnd then return nil end

    local reqLine = request:sub(1, firstEnd - 1)
    local method, path = reqLine:match("^(%S+)%s+(%S+)")
    if not method then return nil end

    local headers = {}
    local pos = firstEnd + 2
    while true do
        local lineEnd = request:find("\r\n", pos, true)
        if not lineEnd then break end
        if lineEnd == pos then break end  -- empty line: end of headers
        local line = request:sub(pos, lineEnd - 1)
        local k, v = line:match("^([^:]+):%s*(.*)$")
        if k then headers[k:lower()] = v end
        pos = lineEnd + 2
    end

    return method, path, headers
end


--- Build a WebSocket handshake response given the client's key.
function M.handshakeResponse(clientKey)
    local accept = crypto.base64(crypto.sha1(clientKey .. MAGIC))
    return "HTTP/1.1 101 Switching Protocols\r\n" ..
           "Upgrade: websocket\r\n" ..
           "Connection: Upgrade\r\n" ..
           "Sec-WebSocket-Accept: " .. accept .. "\r\n\r\n"
end


--- Encode a text frame.
function M.encodeText(payload)
    local len = #payload
    local header
    if len < 126 then
        header = string.char(0x81, len)
    elseif len < 65536 then
        header = string.char(0x81, 126,
            band(rshift(len, 8), 0xff),
            band(len, 0xff))
    else
        header = string.char(0x81, 127,
            0, 0, 0, 0,
            band(rshift(len, 24), 0xff),
            band(rshift(len, 16), 0xff),
            band(rshift(len, 8),  0xff),
            band(len,             0xff))
    end
    return header .. payload
end


--- Encode a close frame.
function M.encodeClose(code, reason)
    code = code or 1000
    reason = reason or ""
    local payload = string.char(band(rshift(code, 8), 0xff), band(code, 0xff)) .. reason
    return string.char(0x88, #payload) .. payload
end


--- Encode a pong frame echoing the given payload.
function M.encodePong(payload)
    payload = payload or ""
    return string.char(0x8A, #payload) .. payload
end


--- Decode one frame from the start of `buf`.
--- Returns (opcode, payload, remainingBuffer, fin) on success,
--- or (nil, "need-more") if more data is required,
--- or (nil, errorMessage) on protocol error.
function M.decodeFrame(buf)
    if #buf < 2 then return nil, "need-more" end
    local b1, b2 = buf:byte(1, 2)
    local fin    = band(b1, 0x80) ~= 0
    local opcode = band(b1, 0x0f)
    local masked = band(b2, 0x80) ~= 0
    local len    = band(b2, 0x7f)
    local headerLen = 2

    if len == 126 then
        if #buf < 4 then return nil, "need-more" end
        len = bor(lshift(buf:byte(3), 8), buf:byte(4))
        headerLen = 4
    elseif len == 127 then
        if #buf < 10 then return nil, "need-more" end
        -- We ignore the high 4 bytes and require the length to fit in 32 bits.
        local b7, b8, b9, b10 = buf:byte(7, 10)
        len = bor(bor(lshift(b7, 24), lshift(b8, 16)),
                  bor(lshift(b9, 8),  b10))
        headerLen = 10
    end

    if not masked then
        return nil, "client frame not masked"
    end

    local maskStart = headerLen + 1
    if #buf < maskStart + 3 + len then return nil, "need-more" end
    local m1, m2, m3, m4 = buf:byte(maskStart, maskStart + 3)
    local mask = {m1, m2, m3, m4}

    local payloadStart = maskStart + 4
    local pieces = {}
    for i = 0, len - 1 do
        pieces[i + 1] = string.char(bxor(buf:byte(payloadStart + i), mask[(i % 4) + 1]))
    end

    return opcode, table.concat(pieces), buf:sub(payloadStart + len), fin
end


return M
