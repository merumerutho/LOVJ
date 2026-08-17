local cfg_screen = lovjRequire("cfg/cfg_screen")

local Feedback = {}
Feedback.__index = Feedback

function Feedback:new(opts)
    opts = opts or {}
    local fb = setmetatable({}, self)

    local w, h
    if opts.width and opts.height then
        w, h = opts.width, opts.height
    elseif cfg_screen.UPSCALE_MODE == cfg_screen.LOW_RES then
        w, h = 2 * screen.InternalRes.W, 2 * screen.InternalRes.H
    else
        w, h = 2 * screen.ExternalRes.W, 2 * screen.ExternalRes.H
    end

    fb.contentWidth = w
    fb.contentHeight = h

    local diag = math.ceil(math.sqrt(w * w + h * h))
    fb.width = diag
    fb.height = diag
    fb.padX = math.floor((diag - w) / 2)
    fb.padY = math.floor((diag - h) / 2)

    fb.front = love.graphics.newCanvas(diag, diag)
    fb.back = love.graphics.newCanvas(diag, diag)

    fb.rotation = opts.rotation or 0
    fb.scaleX = opts.scaleX or 1.0
    fb.scaleY = opts.scaleY or 1.0
    fb.tint = opts.tint or {1, 1, 1, 0.9}
    fb.clearColor = opts.clearColor or {0, 0, 0, 0}
    fb.shader = opts.shader or nil
    fb.processFn = opts.processFn or nil

    return fb
end

function Feedback:process(contentCanvas, opts)
    opts = opts or {}
    local rot = opts.rotation or self.rotation
    local sx = opts.scaleX or self.scaleX
    local sy = opts.scaleY or self.scaleY
    local tint = opts.tint or self.tint
    local clear = opts.clearColor or self.clearColor
    local shader = opts.shader or self.shader
    local processFn = opts.processFn or self.processFn
    local ox = self.width / 2
    local oy = self.height / 2

    local prev = love.graphics.getCanvas()

    -- back → front with transform (the "echo" step)
    love.graphics.setCanvas(self.front)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setColor(1, 1, 1, 1)
    if shader then love.graphics.setShader(shader) end
    love.graphics.draw(self.back, ox, oy, rot, sx, sy, ox, oy)
    if shader then love.graphics.setShader() end

    -- optional custom processing on front
    if processFn then
        processFn(self.front, self.back, opts)
    end

    -- clear back, copy front onto it with tint, then composite fresh content
    love.graphics.setCanvas(self.back)
    love.graphics.clear(unpack(clear))
    love.graphics.setColor(unpack(tint))
    love.graphics.draw(self.front)
    love.graphics.setColor(1, 1, 1, 1)
    if contentCanvas then
        love.graphics.draw(contentCanvas, self.padX, self.padY)
    end

    love.graphics.setCanvas(prev)
end

function Feedback:getOutput()
    return self.front
end

function Feedback:getDrawOffset()
    return -self.padX, -self.padY
end

function Feedback:resize(w, h)
    self.contentWidth = w
    self.contentHeight = h

    local diag = math.ceil(math.sqrt(w * w + h * h))
    self.width = diag
    self.height = diag
    self.padX = math.floor((diag - w) / 2)
    self.padY = math.floor((diag - h) / 2)

    if self.front then self.front:release() end
    if self.back then self.back:release() end
    self.front = love.graphics.newCanvas(diag, diag)
    self.back = love.graphics.newCanvas(diag, diag)
end

return Feedback
