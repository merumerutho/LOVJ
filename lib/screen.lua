-- screen.lua
--
-- Graphical settings

INNER_WIDTH = 240
INNER_RATIO = 4/3

OUTER_WIDTH = 800
OUTER_RATIO = 4/3

screen = {}


function set_internal_res(w,r)
	screen.inner = {}
	screen.inner.w = w
	screen.inner.ratio = 1/r
	screen.inner.h = math.floor(w/r)
end


function set_external_res(w,r)
	screen.outer = {}
	screen.outer.w = w
	screen.outer.ratio = 1/r
	screen.outer.h = math.floor(w/r)
end


function set_screen_additional()
	love.graphics.setDefaultFilter("linear", "nearest")
	love.window.setVSync(false)
end


function calculate_scaling()
	screen.scale = {}
	screen.scale.x = screen.outer.w / screen.inner.w
	screen.scale.y = screen.outer.h / screen.inner.h
end


function screen.init()
	-- Set resolution
	set_internal_res(INNER_WIDTH, INNER_RATIO)
	set_external_res(OUTER_WIDTH, OUTER_RATIO)
	calculate_scaling()
	set_screen_additional()
	
	return screen.inner.w, screen.inner.h
end

return screen