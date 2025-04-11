-- controls.lua
--
-- A generalized controls manager for handling multiple input sources in LOVJ.
-- Supports keyboard, mouse, gamepad.

log = lovjRequire("lib/utils/logging")

local Controls = {}

-- Table to track pressed states
Controls.PreviouslyPressed = {}
Controls.NowPressed = {}

-- List of bound actions
Controls.actionsList = {}


-- Check if key combinations match entirely
local function checkMatchingKeyCombination(kc1, kc2)
	for _, k1 in ipairs(kc1) do
		local found = false
		for _, k2 in ipairs(kc2) do
			found = found or (k1 == k2)
		end
		if not found then 
			return false
		end
	end
	return true
end


local function checkMatchingArguments(args1, args2)
	local ret = true
	-- Check length
	if #args1 ~= #args2 then return false end
	-- Check content if length is the same
	for i, _ in ipairs(args1) do
		ret = ret and (args1[i] == args2[i])
	end
	return ret
end


-- Primitive binding function
function Controls.bind(actionFunc, actionArgs, checkFunc, keyCombination)
	if not actionFunc then logError("ActionFunc is nil") return end
	if not checkFunc then logError("CheckFunc is nil") return end
	for i=1, #Controls.actionsList do
		-- If entry found (already existing)
		if (Controls.actionsList[i]["func"] == action and
			Controls.actionsList[i]["check"] == checkFunc and
			checkMatchingArguments(actionArgs, Controls.actionsList[i]["args"])) then
			-- Check if key-combination is also already present
			local found = false
			for _, listed_kc in ipairs(Controls.actionsList[i]["keyCombs"]) do
				found = found or checkMatchingKeyCombination(listed_kc, keyCombination)
			end
		  -- If key-combination was not present, add it
			if not found then
				table.insert(Controls.actionsList[i]["keyCombs"], keyCombination)
			end
		end
	end
	-- else (if entry not found)
	-- create entry
	table.insert(Controls.actionsList, { func = actionFunc, args = actionArgs, check = checkFunc, keyCombs = {keyCombination}})
end


-- Check if an action is currently pressed
function Controls.checkPressed(keyCombs)
	local ret = false
	-- evaluate all key combinations associated
	for _, kc in ipairs(keyCombs) do
		-- evaluate all 
		local combo = true
		for _, key in ipairs(kc) do
		  combo = combo and love.keyboard.isDown(key)  -- AND statement means all keys in key combination must be pressed
		end
		ret = ret or combo  -- OR statement means at least on key combination must be pressed
	end
	return ret 
end

-- Detect if an action was just pressed (on key attack)
function Controls.onPress(keyCombs)
	return (Controls.NowPressed[keyCombs] and not Controls.PreviouslyPressed[keyCombs])
end

-- Detect if an action was just released (on key release)
function Controls.onRelease(keyCombs)
	return (not Controls.NowPressed[keyCombs] and Controls.PreviouslyPressed[keyCombs])
end

function Controls.update(dt)
  
	-- Update NowPressed for action bindings
	for i=1, #Controls.actionsList do
		local keyCombs = Controls.actionsList[i]["keyCombs"]
		Controls.NowPressed[keyCombs] = Controls.checkPressed(keyCombs)
	end
  
	-- Perform functions related to actions that satisfy the checks
	for i=1, #Controls.actionsList do
		local action = Controls.actionsList[i]
		local action_func = Controls
		-- If button check is activated, trigger the action
		if action["check"](action["keyCombs"]) then
			action["func"](unpack(action["args"]))
			break  	-- Stop the loop here (only one function can be executed per cycle)
		end
	end
  
	-- Update PreviouslyPressed for action bindings  
	for i=1, #Controls.actionsList do
		local keyCombs = Controls.actionsList[i]["keyCombs"]
		Controls.PreviouslyPressed[keyCombs] = Controls.NowPressed[keyCombs]
	end
end

-- Function to retrieve maximum number of keys used for an action
local function keyCount(action)
	local kcs = action["keyCombs"]
	local max_val = 0
	for i=1, #kcs do
		max_val = math.max(max_val, #kcs[i])
	end
	return max_val
end


function Controls.sort()
	-- sorting based on keycount: higher keycount first
	table.sort(Controls.actionsList, function (a, b) return keyCount(a) > keyCount(b) end)
end

return Controls
