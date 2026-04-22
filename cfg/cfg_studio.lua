-- cfg_studio.lua
--
-- Configuration for the studio bridge (M1+).
-- The bridge runs an HTTP server (for the web app) and a WebSocket server
-- (for the authoring traffic) in a separate love.thread.
--

local cfg_studio = {}

-- Set to false to disable the studio bridge entirely.
cfg_studio.enabled = true

-- Bind address. Keep as 127.0.0.1 to restrict access to the local machine.
-- Only change this if you know what you're doing (e.g. editing from a tablet
-- on the same LAN).
cfg_studio.bindAddress = "127.0.0.1"

-- Port for the built web app (static files).
cfg_studio.httpPort = 8080

-- Port for WebSocket authoring traffic.
cfg_studio.wsPort = 8765

-- Root for static file serving. Relative to LÖVE's source directory.
cfg_studio.staticRoot = "studio/dist"

return cfg_studio
