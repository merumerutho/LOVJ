-- cfg_studio.lua
--
-- Configuration for the studio bridge (M1+).
-- The bridge runs an HTTP server (for the web app) and a WebSocket server
-- (for the authoring traffic) in a separate love.thread.
--

local machine = require("lib/machine")

local cfg_studio = {}

-- Set to false to disable the studio bridge entirely.
cfg_studio.enabled = true

-- Bind address. 0.0.0.0 accepts connections from the whole LAN (Deck from a
-- laptop/tablet, external control of a headless box). Set to 127.0.0.1 — e.g. in
-- a machine profile — to restrict access to the local machine.
cfg_studio.bindAddress = "0.0.0.0"

-- Port for the built web app (static files).
cfg_studio.httpPort = 8080

-- Port for WebSocket authoring traffic.
cfg_studio.wsPort = 8765

-- Root for static file serving. Relative to LÖVE's source directory.
cfg_studio.staticRoot = "studio/dist"

return machine.apply("cfg_studio", cfg_studio)
