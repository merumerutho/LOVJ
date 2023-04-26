-- automation_math.lua
--
-- Math utility functions to handle automations
--

local Amath = {}

--- @public sign get sign of number
function Amath.sign(x)
    return (x>0) and 1 or -1
end

--- @public b2n boolean to number conversion
function Amath.b2n(b)
    return b and 1 or 0
end

--- @public step calculate step function on variable x
function Amath.step(x)
    return (x>0) and 1 or 0
end

--- @public rect calculate rect function on variable x
function Amath.rect(x)
    return (math.abs(x)<1/2) and 1 or 0
end

return Amath