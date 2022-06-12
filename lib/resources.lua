-- resources.lua
--
-- Generate and handle patch resources
--
-- Resources are general parameters which control a scene:
--  - Global resources are used to handle controls for navigation in the menu, launching patches etc.
--  - Elements represent
--  - Specifics represent ...

resources = {}
-- subdivided in three sections:
resources.elements = {}
resources.specific = {}
resources.global = {}

resources.N_ELEMENTS = 32
resources.N_PARAMETERS = 32


-- Initialize parameters table
function resources.Init()
    -- Populate list of 'elements'
    for i=1, resources.N_ELEMENTS do
        resources.AddElement()
    end
end


-- Insert additional table to parameters
function resources.AddElement()
	local element = {}
	for i=1, resources.N_PARAMETERS do
		table.insert(element, 1) -- default value
	end
	table.insert(resources.elements, element)
end


function resources.Update(update_msg)
    for k, msg in pairs(update_msg) do
        local destination = msg[1] -- destination (osc)
        local content = msg[2] -- content of packet (osc)
        if true then end -- pass
    end
    return resources
end

return resources