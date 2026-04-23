-- spout.lua
--
-- Interfacing with spout library for video texture sharing (server/client)
-- Calls SpoutLibrary.dll directly via C++ vtable (no SpoutWrapper needed)

local spout = {}

local ffi = require("ffi")
local string = require("string")

local log = lovjRequire("lib/utils/logging")
local screen = lovjRequire("lib/screen")
local drawingUtils = lovjRequire("lib/utils/drawing")

local cfgScreen = lovjRequire("cfg/cfg_screen")

ffi.cdef[[
	typedef struct SPOUTLIBRARY SPOUTLIBRARY;
	typedef SPOUTLIBRARY* SPOUTHANDLE;
	SPOUTHANDLE __stdcall GetSpout(void);

	// OpenGL types for framebuffer queries
	typedef uint32_t GLuint;
	typedef int32_t GLint;
	typedef uint32_t GLenum;
	void glGetFramebufferAttachmentParameteriv(GLenum target, GLenum attachment,
	                                           GLenum pname, GLint *params);
	typedef void (*type_glGetFramebufferAttachmentParameteriv)(GLenum target, GLenum attachment,
	                                                           GLenum pname, GLint *params);

	typedef const char CHAR;
	typedef CHAR *LPSTR;
	typedef LPSTR LPCSTR;
	typedef void VOID;
	typedef VOID *LPVOID;
	typedef LPVOID PROC;
	PROC wglGetProcAddress(LPCSTR lpszProc);
]]

-- Vtable method types for the functions we use
local vtable_types = {
	SetSenderName     = ffi.typeof("void (__thiscall *)(SPOUTLIBRARY*, const char*)"),
	SendTexture       = ffi.typeof("bool (__thiscall *)(SPOUTLIBRARY*, unsigned int, unsigned int, unsigned int, unsigned int, bool, unsigned int)"),
	SendImage         = ffi.typeof("bool (__thiscall *)(SPOUTLIBRARY*, const unsigned char*, unsigned int, unsigned int, unsigned int, bool)"),
	SendFbo           = ffi.typeof("bool (__thiscall *)(SPOUTLIBRARY*, unsigned int, unsigned int, unsigned int, bool)"),
	SetReceiverName   = ffi.typeof("void (__thiscall *)(SPOUTLIBRARY*, const char*)"),
	ReceiveImage      = ffi.typeof("bool (__thiscall *)(SPOUTLIBRARY*, unsigned char*, unsigned int, bool, unsigned int)"),
	IsUpdated         = ffi.typeof("bool (__thiscall *)(SPOUTLIBRARY*)"),
	IsConnected       = ffi.typeof("bool (__thiscall *)(SPOUTLIBRARY*)"),
	IsFrameNew        = ffi.typeof("bool (__thiscall *)(SPOUTLIBRARY*)"),
	GetSenderName     = ffi.typeof("const char* (__thiscall *)(SPOUTLIBRARY*)"),
	GetSenderWidth    = ffi.typeof("unsigned int (__thiscall *)(SPOUTLIBRARY*)"),
	GetSenderHeight   = ffi.typeof("unsigned int (__thiscall *)(SPOUTLIBRARY*)"),
	GetSenderFrame    = ffi.typeof("long (__thiscall *)(SPOUTLIBRARY*)"),
	ReleaseSender     = ffi.typeof("void (__thiscall *)(SPOUTLIBRARY*, unsigned int)"),
	ReleaseReceiver   = ffi.typeof("void (__thiscall *)(SPOUTLIBRARY*)"),
}

-- Vtable slot indices (from SpoutLibrary.h declaration order)
local vtable_slots = {
	SetSenderName     = 0,
	ReleaseSender     = 2,
	SendFbo           = 3,
	SendTexture       = 4,
	SendImage         = 5,
	SetReceiverName   = 16,
	ReleaseReceiver   = 18,
	ReceiveImage      = 20,
	IsUpdated         = 21,
	IsConnected       = 22,
	IsFrameNew        = 23,
	GetSenderName     = 24,
	GetSenderWidth    = 25,
	GetSenderHeight   = 26,
	GetSenderFrame    = 29,
}

-- Read a vtable function pointer from a C++ object
local function vtable_call(obj, name)
	local vt = ffi.cast("void***", obj)[0]
	local slot = vtable_slots[name]
	local fn = ffi.cast(vtable_types[name], vt[slot])
	return fn
end


local TYPEOF_GLINT_PTR = ffi.typeof('GLint[1]')

local libs = ffi_OpenGL_libs or {
	OSX     = { x86 = "OpenGL.framework/OpenGL", x64 = "OpenGL.framework/OpenGL" },
	Windows = { x86 = "OPENGL32.DLL",            x64 = "OPENGL32.DLL" },
	Linux   = { x86 = "libGL.so",                x64 = "libGL.so", arm = "libGL.so" },
	BSD     = { x86 = "libGL.so",                x64 = "libGL.so" },
	POSIX   = { x86 = "libGL.so",                x64 = "libGL.so" },
	Other   = { x86 = "libGL.so",                x64 = "libGL.so" },
}
local gl = ffi.load(libs[ffi.os][ffi.arch])

local function getGLFBAttachParam()
	local p = gl.wglGetProcAddress('glGetFramebufferAttachmentParameteriv')
	return ffi.cast('type_glGetFramebufferAttachmentParameteriv', p)
end

local GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = 0x8CD1
local GL_COLOR_ATTACHMENT0 = 0x8CE0
local GL_FRAMEBUFFER = 0x8D40
local GL_TEXTURE_2D = 0x0DE1
local GL_RGBA = 0x1908


spout.SpoutSender = {}
spout.SpoutReceiver = {}

function spout.SpoutSender:new(o, name, w, h)
	local o = {} or o
	setmetatable(o, self)
	self.__index = self
	o.name = name
	o.width, o.height = w, h
	o.textureId = 0
	o.canvas = love.graphics.newCanvas(w, h)
	return o
end

function spout.SpoutReceiver:new(o, name)
	local o = {} or o
	setmetatable(o, self)
	self.__index = self
	o.name = name
	o.connected = false
	return o
end

function spout.SpoutSender:init()
	local name = self.name
	self.spoutLib = ffi.load("dynlib/SpoutLibrary.dll")
	self.handle = self.spoutLib.GetSpout()
	vtable_call(self.handle, "SetSenderName")(self.handle, name)
	self.canvas = love.graphics.newCanvas(self.width, self.height)
	logInfo("SPOUT SENDER initialized: " .. name)
end

function spout.SpoutSender:reinit()
	if not self.spoutLib then
		self.canvas = love.graphics.newCanvas(self.width, self.height)
		return
	end
	if self.handle then
		pcall(function()
			vtable_call(self.handle, "ReleaseSender")(self.handle, 0)
		end)
	end
	self.handle = self.spoutLib.GetSpout()
	vtable_call(self.handle, "SetSenderName")(self.handle, self.name)
	self.canvas = love.graphics.newCanvas(self.width, self.height)
	self.textureId = 0
	logInfo("SPOUT SENDER reinitialized: " .. self.name)
end

function spout.SpoutReceiver:init()
	local name = self.name
	self.spoutLib = ffi.load("dynlib/SpoutLibrary.dll")
	self.handle = self.spoutLib.GetSpout()
	vtable_call(self.handle, "SetReceiverName")(self.handle, name)

	vtable_call(self.handle, "ReceiveImage")(self.handle, nil, GL_RGBA, false, 0)
	if vtable_call(self.handle, "IsUpdated")(self.handle) then
		self.width = vtable_call(self.handle, "GetSenderWidth")(self.handle)
		self.height = vtable_call(self.handle, "GetSenderHeight")(self.handle)
		if self.width == 0 or self.height == 0 then return end
		self.data = love.data.newByteData(4 * self.width * self.height)
		self.dataPtr = ffi.cast('const char *', self.data:getFFIPointer())
		self.connected = true
		local sname = vtable_call(self.handle, "GetSenderName")(self.handle)
		self.senderName = ffi.string(sname)
		logInfo("SPOUT RECEIVER initialized: " .. self.senderName .. " - size: " .. self.width .. "x" .. self.height)
	end
end

function spout.SpoutSender:SendCanvas(input_canvas, wf, hf)
	wf = wf or 1
	hf = hf or 1
	self.textureId = self:getTextureId()
	drawingUtils.clearCanvas(self.canvas)
	drawingUtils.drawCanvasToCanvas(input_canvas, self.canvas, 0, 0, 0, wf, hf)
	local cur_canvas = love.graphics.getCanvas()
	love.graphics.setCanvas(self.canvas)
	if self.textureId then
		vtable_call(self.handle, "SendTexture")(self.handle, self.textureId, GL_TEXTURE_2D, self.width, self.height, false, 0)
	end
	love.graphics.setCanvas(cur_canvas)
end

function spout.SpoutReceiver:ReceiveImage()
	local img = nil
	local ret = false
	if self.connected then
		if vtable_call(self.handle, "IsFrameNew")(self.handle) then
			ret = vtable_call(self.handle, "ReceiveImage")(self.handle, ffi.cast("unsigned char*", self.dataPtr), GL_RGBA, false, 0)
			if self.dataPtr ~= nil then
				local imgData = love.image.newImageData(self.width, self.height, "rgba8", self.data)
				img = love.graphics.newImage(imgData)
			end
		end
	end
	return ret, img
end

function spout.SpoutReceiver:draw()
	local dummy_imgData = love.image.newImageData(1, 1, "rgba8", "\0\0\0\0")
	local img = love.graphics.newImage(dummy_imgData)
	local ret = false
	if self.connected then
		ret, recv_img = self:ReceiveImage()
		self.connected = ret
		if ret then img = recv_img end
	end
	return img
end

function spout.SpoutReceiver:update()
	if not self.connected then
		self:init()
	end
end

function spout.SpoutSender:getTextureId()
	local textureId = nil
	local cur_canvas = love.graphics.getCanvas()
	love.graphics.setCanvas(self.canvas)
	local tempName = TYPEOF_GLINT_PTR()
	local glFunc = getGLFBAttachParam()
	glFunc(GL_FRAMEBUFFER,
		   GL_COLOR_ATTACHMENT0,
		   GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME,
		   tempName)
	textureId = tempName[0]
	love.graphics.setCanvas(cur_canvas)
	return textureId
end

return spout
