-- http.lua
--
-- Tiny HTTP/1.1 server for serving the built Svelte app from studio/dist/.
-- GET-only, no directory listings, no range requests. Anything else → 405/404.
-- Files are read via love.filesystem.read which (crucially) works from the
-- LÖVE thread state without needing a love.graphics context.
--

local M = {}

local MIME = {
    html = "text/html; charset=utf-8",
    htm  = "text/html; charset=utf-8",
    js   = "application/javascript; charset=utf-8",
    mjs  = "application/javascript; charset=utf-8",
    css  = "text/css; charset=utf-8",
    json = "application/json; charset=utf-8",
    svg  = "image/svg+xml",
    png  = "image/png",
    jpg  = "image/jpeg",
    jpeg = "image/jpeg",
    ico  = "image/x-icon",
    txt  = "text/plain; charset=utf-8",
    wasm = "application/wasm",
    map  = "application/json; charset=utf-8",
}


local function mimeFor(path)
    local ext = path:match("%.([%w]+)$")
    return (ext and MIME[ext:lower()]) or "application/octet-stream"
end


local function response(status, statusText, body, contentType)
    body = body or ""
    return string.format(
        "HTTP/1.1 %d %s\r\nContent-Type: %s\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s",
        status, statusText,
        contentType or "text/plain; charset=utf-8",
        #body, body)
end


--- Resolve a URL path against a root directory and return the file contents,
--- or nil if the path is unsafe or missing.
local function readStaticFile(root, urlPath)
    -- Strip query string
    local q = urlPath:find("?", 1, true)
    if q then urlPath = urlPath:sub(1, q - 1) end

    -- Default document
    if urlPath == "/" or urlPath == "" then urlPath = "/index.html" end

    -- Refuse traversal. We only allow [A-Za-z0-9._/-] in the path.
    if urlPath:match("[^%w%._/%-]") or urlPath:find("%.%.") then
        return nil, "bad path"
    end

    local fullPath = root .. urlPath
    local info = love.filesystem.getInfo(fullPath)
    if not info or info.type ~= "file" then return nil, "not found" end

    local contents, err = love.filesystem.read(fullPath)
    if not contents then return nil, err or "read failed" end
    return contents, fullPath
end


--- Handle a single HTTP request. `request` is the raw request string,
--- `root` is the static-file root. Returns the full response as a string.
function M.handle(request, root)
    local method, path = request:match("^(%S+)%s+(%S+)")
    if not method or not path then
        return response(400, "Bad Request", "Bad Request")
    end

    if method ~= "GET" then
        return response(405, "Method Not Allowed", "Only GET is supported")
    end

    local body, detail = readStaticFile(root, path)
    if not body then
        return response(404, "Not Found", "Not Found: " .. tostring(detail))
    end

    return response(200, "OK", body, mimeFor(detail))
end


return M
