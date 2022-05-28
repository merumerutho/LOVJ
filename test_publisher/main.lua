--lick = require "lick"
--lick.reset = true

-- NETWORK SETTINGS
local socket = require "comm"
local address, port = "127.0.0.1", 55555
start = love.timer.getTime()
i=0
love.window.setVSync(false)
function love.load()
	udp = socket.udp()
	udp:settimeout(0.001)
	udp:setpeername(address, port)
	--udp:send("test")
end

function love.draw()
	love.graphics.print(i)
end


function love.update()
	i=i+1
	udp:send("Success!")
end