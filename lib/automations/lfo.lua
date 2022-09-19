local Automation = require "lib/automations/automation"

Lfo = {}

Lfo.__idx = Lfo

function Lfo:new(l)
    l = {} or l
    l = Automation:new(l)  -- inherit from Automation (parent)
    l.parent = Automation:new(l)  -- maintain a copy of the parent for "super" methods
    setmetatable(l, self)

    return l
end

return Lfo