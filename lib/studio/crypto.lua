-- crypto.lua
--
-- Minimal SHA-1 + Base64 helpers, enough for the RFC 6455 handshake.
-- Pure Lua + LuaJIT bit ops. 32-bit arithmetic is enforced via `band`
-- with 0xffffffff after every addition.
--

local bit = require "bit"
local band, bor, bxor = bit.band, bit.bor, bit.bxor
local bnot = bit.bnot
local lshift, rshift = bit.lshift, bit.rshift

local M = {}

local function rol(x, n)
    return bor(lshift(x, n), rshift(x, 32 - n))
end

--- SHA-1. Returns 20-byte binary digest.
--- Message must be under 2^29 bytes (high 32 bits of bit-length are zero).
function M.sha1(msg)
    local origLen = #msg
    msg = msg .. string.char(0x80)
    while #msg % 64 ~= 56 do
        msg = msg .. "\0"
    end
    local bitLen = origLen * 8
    msg = msg .. "\0\0\0\0" .. string.char(
        band(rshift(bitLen, 24), 0xff),
        band(rshift(bitLen, 16), 0xff),
        band(rshift(bitLen, 8),  0xff),
        band(bitLen,             0xff))

    local h0, h1, h2, h3, h4 =
        0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0

    for chunkStart = 1, #msg, 64 do
        local w = {}
        for i = 0, 15 do
            local b = chunkStart + i * 4
            w[i] = bor(bor(lshift(msg:byte(b), 24), lshift(msg:byte(b + 1), 16)),
                       bor(lshift(msg:byte(b + 2), 8), msg:byte(b + 3)))
        end
        for i = 16, 79 do
            w[i] = rol(bxor(bxor(w[i - 3], w[i - 8]),
                            bxor(w[i - 14], w[i - 16])), 1)
        end

        local a, b_, c, d, e = h0, h1, h2, h3, h4
        for i = 0, 79 do
            local f, k
            if i < 20 then
                f = bor(band(b_, c), band(bnot(b_), d))
                k = 0x5A827999
            elseif i < 40 then
                f = bxor(bxor(b_, c), d)
                k = 0x6ED9EBA1
            elseif i < 60 then
                f = bor(bor(band(b_, c), band(b_, d)), band(c, d))
                k = 0x8F1BBCDC
            else
                f = bxor(bxor(b_, c), d)
                k = 0xCA62C1D6
            end
            local temp = band(rol(a, 5) + f + e + k + w[i], 0xffffffff)
            e, d, c, b_, a = d, c, rol(b_, 30), a, temp
        end

        h0 = band(h0 + a,  0xffffffff)
        h1 = band(h1 + b_, 0xffffffff)
        h2 = band(h2 + c,  0xffffffff)
        h3 = band(h3 + d,  0xffffffff)
        h4 = band(h4 + e,  0xffffffff)
    end

    local function u32toBytes(n)
        return string.char(
            band(rshift(n, 24), 0xff),
            band(rshift(n, 16), 0xff),
            band(rshift(n, 8),  0xff),
            band(n,             0xff))
    end

    return u32toBytes(h0) .. u32toBytes(h1) .. u32toBytes(h2)
        .. u32toBytes(h3) .. u32toBytes(h4)
end


local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

--- Base64 encode a binary string.
function M.base64(data)
    local out = {}
    local len = #data
    local i = 1
    while i <= len do
        local b1 = data:byte(i)
        local b2 = data:byte(i + 1) or 0
        local b3 = data:byte(i + 2) or 0
        local n = bor(bor(lshift(b1, 16), lshift(b2, 8)), b3)

        out[#out + 1] = B64:sub(band(rshift(n, 18), 0x3F) + 1, band(rshift(n, 18), 0x3F) + 1)
        out[#out + 1] = B64:sub(band(rshift(n, 12), 0x3F) + 1, band(rshift(n, 12), 0x3F) + 1)
        if i + 1 <= len then
            out[#out + 1] = B64:sub(band(rshift(n, 6), 0x3F) + 1, band(rshift(n, 6), 0x3F) + 1)
        else
            out[#out + 1] = "="
        end
        if i + 2 <= len then
            out[#out + 1] = B64:sub(band(n, 0x3F) + 1, band(n, 0x3F) + 1)
        else
            out[#out + 1] = "="
        end
        i = i + 3
    end
    return table.concat(out)
end


return M
