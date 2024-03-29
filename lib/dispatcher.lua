-- dispatcher.lua
--
-- dispatch the content of a received msg to the relative section
--

local losc = require "losc"
local resources = lovjRequire("lib/resources")

local dispatcher = {}

--- @public update Dispatch data received to the various destinations
function dispatcher.update(data)
    -- for k,v in pairs(data) do  -- each entry provided by different UDP connections
        -- for kk,vv in pairs(v) do  -- each entry is a different message
            -- local msg = losc.Message.unpack(vv)  -- evaluate message
            -- print(v[1])  -- placeholder
            -- TODO evaluate msg address and redirect to correct section (i.e. correct resource)
        --end
    --end
end

return dispatcher