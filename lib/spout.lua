local spout = {}

local ffi = require("ffi")
local string = require("string")

ffi.cdef[[
typedef int GLint;
typedef unsigned int GLuint;
typedef unsigned int GLenum;
typedef void* SPOUTHANDLE;
char senderName[255];
void SetSenderName_w(SPOUTHANDLE handle, const char* sendername);
bool SendImage_w(SPOUTHANDLE spInst, const unsigned char* pixels, unsigned int width, unsigned int height, unsigned int glFormat, bool bInvert);
bool SendFbo_w(SPOUTHANDLE spInst, unsigned int fboId, unsigned int width, unsigned int height, bool bInvert);
bool ReceiveImage_w(SPOUTHANDLE spInst, const unsigned char* pixels, unsigned int glFormat, bool bInvert, unsigned int hostFbo);
void* GetSpout(void);
]]

spout.senderName = "LOVJ SPOUT SENDER"
spout.senderNameMem = love.data.newByteData(2^8)

function spout.init()
    spout.handle = ffi.load("SpoutLibrary.dll")
    spout.sender = spout.handle.GetSpout()
	-- Transcribe name to memory 
	local ptr = ffi.cast('char *', spout.senderNameMem:getFFIPointer())
	for i=1,(#spout.senderName) do
		ptr[i-1] = string.byte(spout.senderName:sub(i,i))
	end
	-- Add termination character
	ptr[#spout.senderName] = string.byte('\0')
	-- Set name
	spout.handle.SetSenderName_w(spout.sender, ptr)
end

function spout.SendCanvas(canvas, width, height)
	-- ensure resetting to main canvas before doing anything
	love.graphics.setCanvas()
	-- create picture
    local img = canvas:newImageData(nil, 1, 0, 0, width, height)
    local imgptr = img:getFFIPointer()
	-- send picture
    return spout.handle.SendImage_w(spout.sender, imgptr, width, height, 0x1908, false)
end

return spout