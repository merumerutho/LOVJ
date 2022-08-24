CmdMenu = {}

-- default state
CmdMenu.isOpen = false

--- @public handleCmdMenu cmd menu handler
function CmdMenu.handleCmdMenu()
	CmdMenu.isOpen = (not CmdMenu.isOpen)
	print("Cmd menu is open:" .. CmdMenu.isOpen)
end

return CmdMenu