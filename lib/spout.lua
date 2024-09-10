local spout = {}

local ffi = require("ffi")
local string = require("string")

local log = lovjRequire("lib/utils/logging")
local screen = lovjRequire("lib/screen")
local drawingUtils = lovjRequire("lib/utils/drawing")

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
void SetReceiverName_w(SPOUTHANDLE handle, const char * SenderName);
bool IsConnected_w(SPOUTHANDLE handle);
bool IsUpdated_w(SPOUTHANDLE handle);
bool IsFrameNew_w(SPOUTHANDLE handle);
unsigned int GetSenderWidth_w(SPOUTHANDLE handle);
unsigned int GetSenderHeight_w(SPOUTHANDLE handle);
long GetSenderFrame_w(SPOUTHANDLE handle);
const char * GetSenderName_w(SPOUTHANDLE handle);
bool ReceiveImage_w(SPOUTHANDLE spInst, const unsigned char* pixels, unsigned int glFormat, bool bInvert, unsigned int hostFbo);
//
void* GetSpout(void);
]]

local GL_RGBA = 0x1908

spout.SpoutSender = {}
spout.SpoutReceiver = {}

--- @public spout.SpoutSender:new
--- Create a new SpoutSender
function spout.SpoutSender:new(o, name, w, h)
    local o = {} or o
    setmetatable(o, self)
    self.__index = self
    o.name = name
    o.width, o.height = w, h
	o.outCanvas = love.graphics.newCanvas(w, h)
	o.nameMem = love.data.newByteData(2^8)
	return o
end

--- @public spout.SpoutReceiver:new
--- Create a new SpoutReceiver
function spout.SpoutReceiver:new(o, name)
	local o = {} or o
    setmetatable(o, self)
    self.__index = self
    o.name = name
	o.nameMem = love.data.newByteData(2^8)
	o.connected = false
	return o
end

--- @public spout.SpoutSender:init
--- Initialize SpoutSender
function spout.SpoutSender:init()
	local name = self.name
	self.handle = ffi.load("SpoutLibrary.dll")
    self.object = self.handle.GetSpout()

	-- Transcribe sender name to memory
	local senderNamePtr = ffi.cast('char *', self.nameMem:getFFIPointer())
	for i=1,(#name) do
		senderNamePtr[i-1] = string.byte(name:sub(i,i))
	end
	-- Add termination character
	senderNamePtr[#name] = string.byte('\0')
	self.handle.SetSenderName_w(self.object, senderNamePtr)

	logInfo("SPOUT_SENDER: " .. name .. " - Enabled.")
end

--- @public spout.SpoutReceiver:init
--- Initialize SpoutReceiver
function spout.SpoutReceiver:init()
	local ptr
	local name = self.name
	self.handle = ffi.load("SpoutLibrary.dll")
    self.object = self.handle.GetSpout()

	-- Transcribe receiver name to memory
	local receiverNamePtr = ffi.cast('char *', self.nameMem:getFFIPointer())
	for i=1,(#name) do
		receiverNamePtr[i-1] = string.byte(name:sub(i,i))
	end
	-- Add termination character
	receiverNamePtr[#name] = string.byte('\0')

	-- Set name
	self.handle.SetReceiverName_w(self.object, receiverNamePtr)

	-- Handle first reception
	self.handle.ReceiveImage_w(self.object, ptr, GL_RGBA, false, 0)
	if (self.handle.IsUpdated_w(self.object)) then
		self.width = self.handle.GetSenderWidth_w(self.object)
		self.height = self.handle.GetSenderHeight_w(self.object)
		-- Allocate img data and pointer
		self.data = love.data.newByteData(4 * self.width * self.height)
		self.dataPtr = ffi.cast('const char *', self.data:getFFIPointer())
		-- Set receiver as 'connected'
		self.connected = true
		local name = self.handle.GetSenderName_w(self.object)
		self.senderName = ffi.string(name)
		logInfo("SPOUT_RECEIVER: " .. self.senderName .. " - size: " .. self.width .. "x" .. self.height)
	end
end

--- @public spout.SpoutSender:SendCanvas
--- Send Canvas as Image
function spout.SpoutSender:SendCanvas(canvas)
	-- Rescale to spout_out
	local w, h = self.width, self.height
	local wf, hf = (w / screen.InternalRes.W), (h / screen.InternalRes.H)
	drawingUtils.drawCanvasToCanvas(canvas, self.outCanvas, 0, 0, 0, wf, hf)

	-- Create picture from spout_out
    local img = self.outCanvas:newImageData(nil, 1, 0, 0, w, h)
    local imgptr = img:getFFIPointer()
	love.graphics.setCanvas()

	-- Send picture
    return self.handle.SendImage_w(self.object, imgptr, w, h, GL_RGBA, false)
end

--- @private spout.SpoutReceiver:ReceiveImage
--- Receive Image
function spout.SpoutReceiver:ReceiveImage()
	local img = nil
	local ret = false
	if (self.connected == true) then
		if (self.handle.IsFrameNew_w(self.object)) then
			ret = self.handle.ReceiveImage_w(self.object, self.dataPtr, GL_RGBA, false, 0)
			if self.dataPtr ~= nil then
				local imgData = love.image.newImageData(self.width, self.height, "rgba8", self.data)
				img = love.graphics.newImage(imgData)
			end
		end
	end
	return ret, img
end

--- @public spout.SpoutReceiver:draw
--- If connected, perform ReceiveImage
function spout.SpoutReceiver:draw()
	-- default dummy picture
    local dummy_imgData = love.graphics.newImageData(1,1, "rgba8", {0,0,0,0})
    local img = love.grahpics.newImage(dummy_imgData)
	local ret = false
    
    -- Receive Image if connected
    if (self.connected) then
        ret, recv_img = self:ReceiveImage()
        self.connected = ret -- update connection state
        if ret then img = recv_img end
    end
	return img
end

--- @public spout.SpoutReceiver:update
--- If disconnected, try connecting
function spout.SpoutReceiver:update()
	if (self.connected == false) then
		self:init()
	end
end

return spout