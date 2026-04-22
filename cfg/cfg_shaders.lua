-- cfg_shaders.lua
--
-- Configure and handle shader settings
--

local cfg_timers = lovjRequire("cfg/cfg_timers")
local logging = lovjRequire("lib/utils/logging")
local resources = lovjRequire("lib/resources")

local cfg_shaders = {}

cfg_shaders.OverallParams = {}
cfg_shaders.PostProcessShaders = {}
cfg_shaders.OtherShaders = {}

--- @public enabled boolean to enable or disable shaders
cfg_shaders.enabled = true

-- Parse a @param default value into a number or a list of numbers.
-- Accepts: "1.5", "-0.1", "{0.0, 1.0, 0.0, 1.0}", "{-0.1, 0.1}".
-- Returns nil on anything that doesn't match, so bad input is silently
-- ignored rather than executed.
local function parseParamValue(raw)
	raw = raw:match("^%s*(.-)%s*$")  -- trim
	-- Brace list: {a, b, c, ...}
	local inner = raw:match("^{%s*(.-)%s*}$")
	if inner then
		local values = {}
		for num in inner:gmatch("[^,]+") do
			local n = tonumber(num:match("^%s*(.-)%s*$"))
			if not n then return nil end
			table.insert(values, n)
		end
		return values
	end
	-- Scalar number
	return tonumber(raw)
end

-- Parse parameters from shader content
local function parseShaderParams(shaderContent)
	local params = {}
	for line in shaderContent:gmatch("[^\r\n]+") do
		local param_type, param_name, param_value = string.match(line, "//%s+@param%s+([%a%d_]*)%s+([%a_]*)%s+([%-%d%.{},%s]*)%s*//")
		if param_name and param_type and param_value then
			local parsed = parseParamValue(param_value)
			if parsed ~= nil then
				params[param_name] = parsed
			else
				logError("cfg_shaders: could not parse @param value for '" .. param_name .. "': " .. tostring(param_value))
			end
		end
	end
	return params
end

function cfg_shaders.init()
	local input_files = love.filesystem.getDirectoryItems("lib/shaders/source/postProcess/")
	for i=1, #input_files do
			local name = string.match(input_files[i], "(.*).glsl")
			if name then
			local shaderContent = love.filesystem.read("lib/shaders/source/postProcess/" .. input_files[i])
			table.insert(cfg_shaders.PostProcessShaders, { name = name, value = shaderContent })
			-- Parse GLSL to find parameters and their initial value
			local parsed_params = parseShaderParams(shaderContent)
			cfg_shaders.OverallParams[name] = parsed_params
		end
	end

	input_files = love.filesystem.getDirectoryItems("lib/shaders/source/other/")
	for i=1,#input_files do
		local name = string.match(input_files[i], "(.*).glsl")
		if name then
			local shaderContent = love.filesystem.read("lib/shaders/source/other/" .. input_files[i])
			table.insert(cfg_shaders.OtherShaders, {name = name, value = shaderContent})
			-- Parse GLSL to find parameters and their initial value
			local parsed_params = parseShaderParams(shaderContent)
			cfg_shaders.OverallParams[name] = parsed_params
		end
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
	for i=1, 10 do
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
			s:setName(counter, full_param_name)
			s:set(full_param_name, param_value)
			-- increase index counter
			counter = counter + 1
		end
	end
end


--- @public updateTime updates the time for shaders that require it using the globalTimer
function cfg_shaders.updateTime(p_slot)
	local s = patchSlots[p_slot].shaderext
		for idx = 1, #s do
		local name = s:getName(idx)
		if string.match(name, "_time") then 
			s:setByIdx(idx, cfg_timers.globalTimer.T) 
		end
	end
end


--- @public selectShader select the post processing shader to apply
function cfg_shaders.selectPPShader(p_slot, s_slot, curShader)
	local s = patchSlots[p_slot].shaderext
	local idx = s:get("shaderSlot" .. s_slot)
	local newShader = idx and cfg_shaders.PostProcessShaders[idx] or cfg_shaders.PostProcessShaders[1]
	if not newShader then return curShader end
	if newShader.name == curShader.name then
		if not curShader.object then return curShader end
		-- same shader, just update params
	else
		if newShader.name == "00_default" then
			return {name = "00_default", object = nil}
		end
		curShader = {name = newShader.name, object = love.graphics.newShader(newShader.value)}
	end

	local pg = cfg_shaders.OverallParams[curShader.name]
	if pg and curShader.object then
		for param_name, _ in pairs(pg) do
			curShader.object:send(param_name, s:get(curShader.name .. "_" .. param_name))
		end
	end
	return curShader
end

return cfg_shaders