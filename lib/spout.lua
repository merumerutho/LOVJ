local spout = {}

local ffi = require("ffi")
local string = require("string")

local log = lovjRequire("lib/utils/logging")
local screen = lovjRequire("lib/screen")
local drawingUtils = lovjRequire("lib/utils/drawing")

local cfgScreen = lovjRequire("cfg/cfg_screen")

ffi.cdef[[
void SetSenderNameWrapper(const char* senderName);
bool SendImageWrapper(const unsigned char* pixels, unsigned int width, unsigned int height, unsigned int glFormat, bool bInvert);
bool SendTextureWrapper(unsigned int TextureID, unsigned int TextureTarget, unsigned int width, unsigned int height, bool bInvert, unsigned int HostFbo);
bool SendFboWrapper(unsigned int fboId, unsigned int width, unsigned int height, bool bInvert);
void SetReceiverNameWrapper(const char * SenderName);
bool IsConnectedWrapper();
bool IsUpdatedWrapper();
bool IsFrameNewWrapper();
unsigned int GetSenderWidthWrapper();
unsigned int GetSenderHeightWrapper();
long GetSenderFrameWrapper();
const char * GetSenderNameWrapper();
bool ReceiveImageWrapper(const unsigned char* pixels, unsigned int glFormat, bool bInvert, unsigned int hostFbo);
]]

local GL_RGBA = 0x1908

-- credits to RNavega for the trick on getting the canvas texture id and pointer
-- and to s-ol for showing me this clever hack
-- https://love2d.org/forums/viewtopic.php?t=96388

ffi.cdef([[
    // https://github.com/malkia/luajit-winapi/blob/master/ffi/winapi/headers/common.lua#L104C3-L106C32
    // Cheating by making it 'const' or else LuaJIT doesn't do auto-conversion from a Lua string.
    typedef const char CHAR;
    typedef CHAR *LPSTR; //Pointer
    typedef LPSTR LPCSTR; //Alias

    // https://github.com/malkia/luajit-winapi/blob/master/ffi/winapi/headers/common.lua#L28C3-L29C34
    typedef void VOID; //Alias
    typedef VOID *LPVOID; //Pointer
    // https://github.com/malkia/luajit-winapi/blob/master/ffi/winapi/windows/opengl32.lua#L6
    typedef LPVOID PROC; //Alias

    // https://github.com/malkia/luajit-winapi/blob/master/ffi/winapi/windows/opengl32.lua#L54
    PROC wglGetProcAddress(LPCSTR lpszProc);

    typedef uint32_t GLuint;
    typedef int32_t GLint;
    typedef uint32_t GLenum;
    void glGetFramebufferAttachmentParameteriv(GLenum target, GLenum attachment,
                                               GLenum pname, GLint *params);
    typedef void (*type_glGetFramebufferAttachmentParameteriv)(GLenum target, GLenum attachment,
                                                               GLenum pname, GLint *params);
]])


local TYPEOF_GLINT_PTR = ffi.typeof('GLint[1]')

local SDL = (jit.os == "Windows") and ffi.load("SDL2") or ffi.C

-- OpenGL binding from malkia's UFO:
-- https://github.com/malkia/ufo/blob/master/ffi/OpenGL.lua
local libs = ffi_OpenGL_libs or {
   OSX     = { x86 = "OpenGL.framework/OpenGL", x64 = "OpenGL.framework/OpenGL" },
   Windows = { x86 = "OPENGL32.DLL",            x64 = "OPENGL32.DLL" },
   Linux   = { x86 = "libGL.so",                x64 = "libGL.so", arm = "libGL.so" },
   BSD     = { x86 = "libGL.so",                x64 = "libGL.so" },
   POSIX   = { x86 = "libGL.so",                x64 = "libGL.so" },
   Other   = { x86 = "libGL.so",                x64 = "libGL.so" },
}
local gl = ffi.load(libs[ffi.os][ffi.arch])
local proc = gl.wglGetProcAddress('glGetFramebufferAttachmentParameteriv')
local glGetFramebufferAttachmentParameteriv = ffi.cast('type_glGetFramebufferAttachmentParameteriv', proc)

-- https://github.com/KhronosGroup/OpenGL-Registry/blob/main/api/GLES2/gl2.h#L348
GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = 0x8CD1
-- https://github.com/KhronosGroup/OpenGL-Registry/blob/main/api/GLES2/gl2.h#L351
GL_COLOR_ATTACHMENT0 = 0x8CE0
-- https://github.com/KhronosGroup/OpenGL-Registry/blob/main/api/GLES2/gl2.h#L331
GL_FRAMEBUFFER = 0x8D40
GL_TEXTURE_2D = 0x0DE1

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
	o.nameMem = love.data.newByteData(2^8)
  o.textureId = 0
  o.canvas = love.graphics.newCanvas(w, h)
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
--- Initialize SpoutSender with associated Canvas / Texture
function spout.SpoutSender:init()
	local name = self.name
	self.handle = ffi.load("SpoutWrapper.dll")

	-- Transcribe sender name to memory
	local senderNamePtr = ffi.cast('char *', self.nameMem:getFFIPointer())
	for i=1,(#name) do
		senderNamePtr[i-1] = string.byte(name:sub(i,i))
	end
	-- Add termination character
	senderNamePtr[#name] = string.byte('\0')
	self.handle.SetSenderNameWrapper(senderNamePtr)
  
  -- Done
  logInfo("SPOUT_SENDER: " .. name .. " - Enabled.")
end

--- @public spout.SpoutReceiver:init
--- Initialize SpoutReceiver
function spout.SpoutReceiver:init()
	local ptr
	local name = self.name
	self.handle = ffi.load("SpoutWrapper.dll")

	-- Transcribe receiver name to memory
	local receiverNamePtr = ffi.cast('char *', self.nameMem:getFFIPointer())
	for i=1,(#name) do
		receiverNamePtr[i-1] = string.byte(name:sub(i,i))
	end
	-- Add termination character
	receiverNamePtr[#name] = string.byte('\0')

	-- Set name
	self.handle.SetReceiverNameWrapper(receiverNamePtr)

	-- Handle first reception
	self.handle.ReceiveImageWrapper(ptr, GL_RGBA, false, 0)
	if (self.handle.IsUpdatedWrapper()) then
		self.width = self.handle.GetSenderWidthWrapper()
		self.height = self.handle.GetSenderHeightWrapper()
		-- Allocate img data and pointer
		self.data = love.data.newByteData(4 * self.width * self.height)
		self.dataPtr = ffi.cast('const char *', self.data:getFFIPointer())
		-- Set receiver as 'connected'
		self.connected = true
		local name = self.handle.GetSenderNameWrapper()
		self.senderName = ffi.string(name)
		logInfo("SPOUT_RECEIVER: " .. self.senderName .. " - size: " .. self.width .. "x" .. self.height)
	end
end

--- @public spout.SpoutSender:SendCanvas
--- Send Canvas as Texture
function spout.SpoutSender:SendCanvas(input_canvas, wf, hf)
  -- Draw to self.canvas with correct scaling
  self.textureId = self:getTextureId()
  drawingUtils.clearCanvas(self.canvas)
  drawingUtils.drawCanvasToCanvas(input_canvas, self.canvas, 0, 0, 0, wf, hf)
  local cur_canvas = love.graphics.getCanvas()
  love.graphics.setCanvas(self.canvas)
  -- Send texture
  if self.textureId then
    -- Send picture
    self.handle.SendTextureWrapper(self.textureId, GL_TEXTURE_2D, self.width, self.height, false, 0)
  end
  love.graphics.setCanvas(cur_canvas)
  return
end

--- @private spout.SpoutReceiver:ReceiveImage
--- Receive Image
function spout.SpoutReceiver:ReceiveImage()
	local img = nil
	local ret = false
	if (self.connected == true) then
		if (self.handle.IsFrameNewWrapper()) then
			ret = self.handle.ReceiveImageWrapper(self.dataPtr, GL_RGBA, false, 0)
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

--- @public spout.SpoutSender:getTextureId
--- Retrieve Texture ID from Canvas
function spout.SpoutSender:getTextureId()
  -- get texture ID 
  local textureId = nil
  local cur_canvas = love.graphics.getCanvas()
  love.graphics.setCanvas(self.canvas)
  local tempName = TYPEOF_GLINT_PTR()
  glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER,
                                            GL_COLOR_ATTACHMENT0,
                                            GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME,
                                            tempName)
  textureId = tempName[0]
  love.graphics.setCanvas(cur_canvas)  
  return textureId
end

return spout