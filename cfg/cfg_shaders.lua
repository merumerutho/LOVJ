-- cfg_shaders.lua
--
-- Configure and handle shader settings
--

local cfg_timers = lovjRequire("cfg/cfg_timers")
local logging = lovjRequire("lib/utils/logging")
local resources = lovjRequire("lib/resources")

local cfg_shaders = {}

cfg_shaders.OverallParams = {}


-- Parse parameters from shader content
local function parseShaderParams(shaderContent)
	local params = {}
	for line in shaderContent:gmatch("[^\r\n]+") do
		local param_name, param_value = string.match(line, "//%s*@param%s+(%w+)%s+([%d%.%-]+)")
		if param_name and param_value then
			params[param_name] = tonumber(param_value)
		end
	end
	return params
end

--- @public enabled boolean to enable or disable shaders
cfg_shaders.enabled = true


--- @public PostProcessShaders list of shaders extracted from "lib/shaders/postProcess/" folder
cfg_shaders.PostProcessShaders = {}
local input_files = love.filesystem.getDirectoryItems("lib/shaders/postProcess/")
for i=1, #input_files do
	local name = string.match(input_files[i], "(.*).glsl")
	if name then
		local shaderContent = love.filesystem.read("lib/shaders/postProcess/" .. input_files[i])
		table.insert(cfg_shaders.PostProcessShaders, { name = name, value = shaderContent })
		-- Parse GLSL to find parameters and their initial value
		local parsed_params = parseShaderParams(shaderContent)
		cfg_shaders.OverallParams[name] = parsed_params
	end
end

print("PostProcess shaders: " .. #cfg_shaders.PostProcessShaders)


--- @public OtherShaders list of shaders extracted from "lib/shaders/other" folder
cfg_shaders.OtherShaders = {}
input_files = love.filesystem.getDirectoryItems("lib/shaders/other/")
for i=1,#input_files do
	local name = string.match(input_files[i], "(.*).glsl")
	if name then
		local shaderContent = love.filesystem.read("lib/shaders/other/" .. input_files[i])
		table.insert(cfg_shaders.OtherShaders, {name = name, value = shaderContent})
		-- Parse GLSL to find parameters and their initial value
		local parsed_params = parseShaderParams(shaderContent)
		cfg_shaders.OverallParams[name] = parsed_params
	end
end


--- @public toggleShaders enable / disable shaders
function cfg_shaders.toggleShaders()
    cfg_shaders.enabled = not cfg_shaders.enabled
end


function cfg_shaders.initShaderExt(slot)
	local s = patchSlots[slot].shaderext
	local counter = 1
	
	-- Allocate shader slots
	for i=1, 3 do
		s:setName(counter, "shaderSlot" .. i)
		s:set("shaderSlot" .. i, 1)
		counter = counter + 1
	end
	
	-- Parse OverallParams
	local paramGroups = cfg_shaders.OverallParams
	for pg_name, pg_val in pairs(paramGroups) do
		for param_name, param_value in pairs(pg_val) do
			-- compose full name
			local full_param_name = pg_name .. "_" .. param_name
			-- set name and value
			s:setName(counter, param_name)
			s:set(full_param_name, param_value)
			-- increase index counter
			counter = counter + 1
		end
	end
end


--- @public selectShader select the post processing shader to apply
function cfg_shaders.selectPPShader(p_slot, s_slot, curShader)
    local s = patchSlots[p_slot].shaderext
	local shader

    -- select shader
	local newShader = cfg_shaders.PostProcessShaders[s:get("shaderSlot" .. s_slot)]
	-- if shader changed, create new shader
	if newShader.name ~= curShader.name then
		shader = {name = newShader.name, object = love.graphics.newShader(newShader.value)}
	else
		shader = curShader
	end
	
	-- Update all parameters
	local paramGroups = cfg_shaders.OverallParams
	for pg_name, pg_val in pairs(paramGroups) do
		-- if the selected shader matches the name of the param group
		if pg_name == shader.name then
			-- update all parameters
			for param_name, default_value in pairs(pg_val) do
				local full_param_name = pg_name .. "_" .. param_name
				-- send new value
				shader.object:send(param, s:get(full_param_name))
			end
		end
	end
		
	return shader
end


return cfg_shaders