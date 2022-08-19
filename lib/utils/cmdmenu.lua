CmdMenu = {}

CmdMenu.isOpen = false

function CmdMenu.handleCmdMenu()
	if CmdMenu.isOpen then
		print("closed")
	else
		print("opened")
	end
	CmdMenu.isOpen = (not CmdMenu.isOpen)
end

return CmdMenu