Automation = {}

Automation.__idx = Automation

function Automation:new(a)
    a = a or {}
    setmetatable(a, self)

    a.trigger = nil  -- input trigger
    a.output = nil  -- output control

    return a
end

return Automation