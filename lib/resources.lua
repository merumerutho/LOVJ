-- resources.lua
--
-- Generate and handle patch resources (parameters etc.)

resources = {}
-- subdivided in three sections:
resources.elements = {}
resources.specific = {}
resources.global = {}

resources.N_ELEMENTS = 32
resources.N_PARAMETERS = 32


-- Initialize parameters table
function resources.init()
    -- Populate list of 'elements'
    for i=1, resources.N_ELEMENTS do
        resources.addElement()
    end
end


-- Insert additional table to parameters
function resources.addElement()
	local element = {}
	for i=1, resources.N_PARAMETERS do
		table.insert(element, 1) -- default value
	end
	table.insert(resources.elements, element)
end


function resources.update(update_msg)
    for k, msg in pairs(update_msg) do
        local destination = msg[1] -- destination (osc)
        local content = msg[2] -- content of packet (osc)
        if true then end -- pass
    end
    return resources
end

return resources