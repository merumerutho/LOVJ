-- drawing.lua
--
-- Drawing utils

local DrawingUtils = {}

function DrawingUtils.drawCanvasToCanvas(src, dst, x, y, r, sx, sy)
	-- set defaults
	local x = x or 0
	local y = y or 0
	local r = r or 0
	local sx = sx or 0
	local sy = sy or 0
	local currentCanvas = love.graphics.getCanvas()
	-- set canvas, draw and go back to previous canvas
	love.graphics.setCanvas(dst)
	love.graphics.draw(src, x, y, r, sx, sy)
	love.graphics.setCanvas(currentCanvas)
	return dst
end

function DrawingUtils.clearCanvas(c)
	local currentCanvas = love.graphics.getCanvas()
	love.graphics.setCanvas(c)
	love.graphics.clear()
	love.graphics.setCanvas(currentCanvas)
	return c
end

return DrawingUtils