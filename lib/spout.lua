local spout = {}

local ffi = require("ffi")

ffi.cdef[[
typedef int GLint;
typedef unsigned int GLuint;
typedef unsigned int GLenum;
typedef void* SPOUTHANDLE;
bool SendImage_w(SPOUTHANDLE spInst, const unsigned char* pixels, unsigned int width, unsigned int height, unsigned int glFormat, bool bInvert);
bool SendFbo_w(SPOUTHANDLE spInst, unsigned int fboId, unsigned int width, unsigned int height, bool bInvert);
bool ReceiveImage_w(SPOUTHANDLE spInst, const unsigned char* pixels, unsigned int glFormat, bool bInvert, unsigned int hostFbo);
void* GetSpout(void);
]]

function spout.init()
    spout.handle = ffi.load("SpoutLibrary.dll")
    spout.sender = spout.handle.GetSpout()
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