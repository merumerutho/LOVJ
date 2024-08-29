-- signal_math.lua
--
-- Math utility functions to handle signals
--

local SMath = {}

--- @public fract return fractional part
function SMath.fract(x)
	_, y = math.modf(x)
	return y
end

--- @public b2n boolean to number conversion
function SMath.b2n(b)
    return b and 1 or 0
end

--- @public b2n boolean to number conversion
function SMath.b2n_2(b, h, l)
    return b and h or l
end

--- @public sign get sign of number
function SMath.sign(x)
    return SMath.b2n_2(x>0, 1, -1)
end

--- @public step calculate step function on variable x
function SMath.step(x)
    return SMath.b2n(x>0)
end

--- @public rect calculate rectangle function on variable x 
--- note: not the same as square waveform! (this is symmetric, aperiodic)
function SMath.rect(x)
	return SMath.b2n(math.abs(x)<.5)
end

--- @public tri calculate triangular waveform on variable x
function SMath.tri(x)
	return math.abs(2*(SMath.fract(x))-1)
end

--- @public saw calculate sawtooth waveform on variable x
function SMath.saw(x)
	return SMath.fract(x)
end

--- @public pulse calculate pulse waveform on variable x
function SMath.pulse(x, pw)
	return SMath.b2n(SMath.fract(x)<SMath.sign(x)*.5)
end

--- @public square calculate square waveform on variable x (50% duty cycle)
--- note: not the same as rect function! (this is asymmetric, periodic)
function SMath.square(x)
    return SMath.pulse(x, .5)
end

--- @public sin sine wrapper
function SMath.sin(x)
	return math.sin(x)
end

--- @public cos cosine wrapper
function SMath.cos(x)
	return math.cos(x)
end

return SMath