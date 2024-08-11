local spout = {}

local ffi = require("ffi")
local string = require("string")

ffi.cdef[[
typedef int GLint;
typedef unsigned int GLuint;
typedef unsigned int GLenum;
typedef void* SPOUTHANDLE;
//
void SetSenderName_w(SPOUTHANDLE handle, const char* sendername);
bool SendImage_w(SPOUTHANDLE spInst, const unsigned char* pixels, unsigned int width, unsigned int height, unsigned int glFormat, bool bInvert);
bool SendFbo_w(SPOUTHANDLE spInst, unsigned int fboId, unsigned int width, unsigned int height, bool bInvert);
//
bool ReceiveImage_w(SPOUTHANDLE spInst, const unsigned char* pixels, unsigned int glFormat, bool bInvert, unsigned int hostFbo);
void SetReceiverName_w(SPOUTHANDLE handle, const char * SenderName);
bool IsUpdated_w(SPOUTHANDLE handle);
bool IsFrameNew_w(SPOUTHANDLE handle);
unsigned int GetSenderWidth_w(SPOUTHANDLE handle);
unsigned int GetSenderHeight_w(SPOUTHANDLE handle);
//
void* GetSpout(void);
]]

local GL_RGBA = 0x1908

spout.sender = {}
spout.receiver = {}

spout.sender.name = "LOVJ_SPOUT_SENDER"
spout.sender.nameMem = love.data.newByteData(2^8)

spout.receiver.name = "Avenue - Avenue_FBK"
spout.receiver.nameMem = love.data.newByteData(2^8)

spout.receiver.width = 0
spout.receiver.height = 0


bit = require "bit"

function spout.init()
    spout.sender.handle = ffi.load("SpoutLibrary.dll")
    spout.sender.object = spout.sender.handle.GetSpout()
	
	spout.receiver.handle = ffi.load("SpoutLibrary.dll")
    spout.receiver.object = spout.receiver.handle.GetSpout()
	
	-- Transcribe sender name to memory 
	local senderNamePtr = ffi.cast('char *', spout.sender.nameMem:getFFIPointer())
	for i=1,(#spout.sender.name) do
		senderNamePtr[i-1] = string.byte(spout.sender.name:sub(i,i))
	end
	-- Add termination character
	senderNamePtr[#spout.sender.name] = string.byte('\0')
	
	-- Transcribe receiver name to memory 
	local receiverNamePtr = ffi.cast('char *', spout.receiver.nameMem:getFFIPointer())
	for i=1,(#spout.receiver.name) do
		receiverNamePtr[i-1] = string.byte(spout.receiver.name:sub(i,i))
	end
	-- Add termination character
	receiverNamePtr[#spout.receiver.name] = string.byte('\0')
	
	-- Set names
	spout.sender.handle.SetSenderName_w(spout.sender.object, senderNamePtr)
	spout.receiver.handle.SetReceiverName_w(spout.receiver.object, receiverNamePtr)
	
	-- Handle first reception
	spout.receiver.handle.ReceiveImage_w(spout.receiver.object, ptr, GL_RGBA, false, 0)
	if (spout.receiver.handle.IsUpdated_w(spout.receiver.object)) then
		spout.receiver.width = spout.receiver.handle.GetSenderWidth_w(spout.receiver.object)
		spout.receiver.height = spout.receiver.handle.GetSenderHeight_w(spout.receiver.object)
		print("Receiver connected", spout.receiver.width, "x", spout.receiver.height)
		-- Allocate img data and pointer
		spout.receiver.data = love.data.newByteData(4 * spout.receiver.width * spout.receiver.height)
		spout.receiver.dataPtr = ffi.cast('const char *', spout.receiver.data:getFFIPointer())
		print(spout.receiver.dataPtr)
	end
end

function spout.SendCanvas(canvas, width, height)
	-- ensure resetting to main canvas before doing anything
	love.graphics.setCanvas()
	-- create picture
    local img = canvas:newImageData(nil, 1, 0, 0, width, height)
    local imgptr = img:getFFIPointer()
	-- send picture
    return spout.sender.handle.SendImage_w(spout.sender.object, imgptr, width, height, GL_RGBA, false)
end

function spout.ReceiveImage()
	if (spout.receiver.handle.IsFrameNew_w(spout.receiver.object)) then
		local val = spout.receiver.handle.ReceiveImage_w(spout.receiver.object, spout.receiver.dataPtr, GL_RGBA, false, 0)
		if spout.receiver.dataPtr ~= nil then
			local imgData = love.image.newImageData(spout.receiver.width, spout.receiver.height, "rgba8", spout.receiver.data)
			img = love.graphics.newImage(imgData)
		end
	end
	return img
end

return spout