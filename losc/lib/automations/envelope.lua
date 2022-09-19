Automation = require "lib/automations/automation"

Envelope = {}

Envelope.__idx = Envelope

function Envelope:new(e)
    e = {} or e
    e = Automation:new(e)  -- inherit from Automation (parent)
    e.parent = Automation:new(e)  -- maintain a copy of the parent for "super" methods
    setmetatable(e, self)

    return e
end

