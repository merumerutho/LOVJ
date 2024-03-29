-- cmdmenu.lua
--
-- Handler of command menu
--

local CmdMenu = {}
local utf8 = require "utf8"
local kp = lovjRequire("lib/utils/keypress")

-- default state
CmdMenu.isOpen = false
-- current command buffer
CmdMenu.buffer = ""
-- history
CmdMenu.history = {}
-- idx to history
CmdMenu.idx_history = 0
-- supported commands
CmdMenu.commands = {
	{"debug", debug.debug} -- debug
}

--- @public handleCmdMenu cmd menu handler
function CmdMenu.handleCmdMenu()
	CmdMenu.isOpen = (not CmdMenu.isOpen)
	if CmdMenu.isOpen then patch.draw = CmdMenu.update else patch.draw = patch.defaultDraw end
	-- clear cmd buffer, regardless
	patch.canvases.cmd:renderTo(love.graphics.clear)
end

--- @public textinput called when a key for text is pressed
function love.textinput(t)
	if CmdMenu.isOpen then CmdMenu.buffer = CmdMenu.buffer .. t end
end

--- @private cmdMenu_flush execute command
local function cmdMenu_flush()
	logInfo("Flushing " .. CmdMenu.buffer) -- TODO implement actual execution
	-- Check if command is in CmdMenu.commands
	for k,v in pairs(CmdMenu.commands) do
		if CmdMenu.buffer == v[1] then
			loadstring(v[2])
		end
	end

	-- Check if command is in patch.commands
	patch.commands(CmdMenu.buffer)

	-- add to history
	table.insert(CmdMenu.history, CmdMenu.buffer)
	CmdMenu.idx_history = 0  -- reset idx to 0
	CmdMenu.buffer = "" -- delete buffer

end

--- @private cmdMenu_handleKeysHistory handle keys to browse command history
local function cmdMenu_handleKeysHistory()
	if kp.keypressOnAttack("up") then
		if CmdMenu.idx_history < #CmdMenu.history then
			CmdMenu.idx_history = CmdMenu.idx_history + 1 -- increase
			CmdMenu.buffer = CmdMenu.history[#CmdMenu.history - CmdMenu.idx_history + 1] -- set buffer to history
		end
	end

	if kp.keypressOnAttack("down") then
		if CmdMenu.idx_history > 0 then
			CmdMenu.idx_history = CmdMenu.idx_history - 1 -- decrease
		end
		-- if end is reached, erase buffer anyway
		if CmdMenu.idx_history == 0 then
			CmdMenu.buffer = ""
		else
			CmdMenu.buffer = CmdMenu.history[#CmdMenu.history - CmdMenu.idx_history + 1] -- set buffer to history
		end
	end
end

--- @private cmdMenu_draw print the cmd menu on screen (on separate canvas)
local function cmdMenu_draw()
	love.graphics.setCanvas(patch.canvases.cmd) -- draw on specific canvas
	patch.canvases.cmd:renderTo(love.graphics.clear)

	-- console line
	love.graphics.setColor(.5, .5, .5, .5)
	love.graphics.rectangle("fill", 0, 0, screen.ExternalRes.W, 8)

	-- print text
	love.graphics.setFont(love.graphics.newFont(7))
	love.graphics.setColor(1,1,1,1)
	love.graphics.print(CmdMenu.buffer,0,0)

	-- reset back
	love.graphics.setColor(1,1,1,1)
	love.graphics.setCanvas()
end

--- @private cmdMenu_handleKeys handle key controls for cmd menu
local function cmdMenu_handleKeys()
	-- handle history
	cmdMenu_handleKeysHistory()

	-- delete (hold shift to delete faster)
	if (kp.keypressOnAttack("backspace")) or (kp.isDown("lctrl") and kp.isDown("backspace")) then
		local byteOffset = utf8.offset(CmdMenu.buffer, -1)
		if byteOffset then
			CmdMenu.buffer = string.sub(CmdMenu.buffer, 1, byteOffset - 1)
		end
	end

	-- flush
	if kp.keypressOnAttack("return") and (#CmdMenu.buffer > 0) then
		cmdMenu_flush()
	end

end

--- @public update main execution of the command menu
function CmdMenu.update()
	-- handle key controls
	cmdMenu_handleKeys()
	-- draw patch
	patch.defaultDraw()
	-- draw cmd menu on top
	cmdMenu_draw()
end

return CmdMenu