N_PARAMETERS = 256

params = {}

-- Initialize parameters with ONE table
function params.init(p)
	params.addPage()
	for i=1,#p do
		params[1][i] = p[i]
	end
end

-- Insert additional table to parameters
function params.addPage()
	local page = {}
	for i=0,N_PARAMETERS do
		table.insert(page, 0)
	end
	table.insert(params, page)
end

return params