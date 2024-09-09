local spout = {}

spout.SpoutSender = {}
spout.SpoutReceiver = {}

--- @public spout.SpoutSender:new
--- (stubbed) Create a new SpoutSender:
--- maintain interface compatibility 
function spout.SpoutSender:new(o, name, w, h)
    local o = {} or o
    setmetatable(o, self)
    self.__index = self
    o.name = name
    o.width, o.height = w, h
	o.outCanvas = nil -- not necessary
	o.nameMem = nil -- not necessary
	return o
end

--- @public spout.SpoutReceiver:new
--- (stubbed) Create a new SpoutReceiver:
--- maintain interface compatibility 
function spout.SpoutReceiver:new(o, name)
	local o = {} or o
    setmetatable(o, self)
    self.__index = self
    o.name = name
	o.nameMem = nil -- not necessary 
	o.connected = false
	return o
end

--- @public spout.SpoutSender:init
--- (stubbed) Initialize SpoutSender:
--- do nothing, warn user
function spout.SpoutSender:init()
	logInfo("SPOUT_STUB_SENDER | Spout support is Windows-only | " .. self.name .. " cannot be initialized.")
end

--- @public spout.SpoutReceiver:init
--- (stubbed) Initialize SpoutReceiver:
--- do nothing, warn user
function spout.SpoutReceiver:init()
	logInfo("SPOUT_STUB_RECEIVER | Spout support is Windows-only | " .. self.name .. " cannot be initialized.")
end

--- @public spout.SpoutSender:SendCanvas
--- (stubbed) Send image:
--- do nothing
function spout.SpoutSender:SendCanvas(canvas)
	return true
end

--- @private spout.SpoutReceiver:ReceiveImage
--- (stubbed) Receive Image: 
--- receive empty 1x1 pixel
function spout.SpoutReceiver:ReceiveImage()
	local imgData = love.image.newImageData(1, 1, "rgba8", {0,0,0,0})
	local img = love.graphics.newImage(imgData)
	return true, img
end

--- @public spout.SpoutReceiver:update
--- (stubbed) Update Receiver: 
--- return stubbed "ReceiveImage" function
function spout.SpoutReceiver:draw(receiver)
	_, i = self:ReceiveImage()
	return i
end

--- @public spout.SpoutReceiver:update
--- (stubbed) Update Receiver:
--- do nothing
function spout.SpoutReceiver:update()
	return
end


return spout