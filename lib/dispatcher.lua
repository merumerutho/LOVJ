-- dispatcher.lua
--
-- dispatch the content of a received msg to relative section

losc = require "losc"
resources = require "resources"
dispatcher = {}

-- update the dispatcher
function dispatcher.update(data)
    for k,v in pairs(data) do  -- each entry provided by different UDP connections
        for kk,vv in pairs(v) do  -- each entry is a different message
            local msg = losc.Message.unpack(vv)  -- evaluate message
            print(msg)  -- placeholder
            -- TODO evaluate msg address and redirect to correct section (i.e. correct resource)
        end
    end
end

return dispatcher