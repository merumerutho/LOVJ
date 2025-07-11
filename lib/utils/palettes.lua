-- palettes.lua
--
-- Table of palettes inspired by or taken from several systems.

-- TODO:[nice2have] Add more palettes :)

local Palettes = {}

Palettes.BW = 	{
	{0, 0, 0},			-- black
	{255, 255, 255}  	-- white
}

Palettes.PICO8 = {
	{0, 0, 0},			-- black
	{29, 43, 83},		-- blue
	{126, 37, 83}, 		-- burgundy
	{ 0, 135, 81}, 		-- green
	{ 171, 82, 54}, 	-- brown
	{ 95, 87, 79}, 		-- dark grey
	{194, 195, 199}, 	-- light grey
	{255, 241, 232}, 	-- white
	{255, 0, 77}, 		-- red
	{255, 163, 0}, 		-- orange
	{255, 236, 39}, 	-- yellow
	{0, 228, 54}, 		-- light green
	{41, 173, 255}, 	-- light blue
	{131, 118, 156}, 	-- purple
	{255, 119, 168}, 	-- pink
	{255, 204, 170} 	-- cream
}

Palettes.TIC80 =  {
	{26,28,44}, 		-- black
	{93,39,93}, 		-- purple
	{177,62,83},		-- red
	{239,125,87},		-- orange
	{255,205,117},		-- yellow
	{167,240,112},		-- light green
	{56,183,100},		-- green
	{37,113,121},		-- dark green
	{41,54,111},		-- dark blue
	{59,93,201},		-- blue
	{65,166,246},		-- light blue
	{115,239,247},		-- cyan
	{244,244,244},		-- white
	{148,176,194},		-- light grey
	{86,108,134},		-- grey
	{51,60,87}			-- dark grey
}

function Palettes.getColor(p, idx)
	return {p[idx][1] / 255, p[idx][2] / 255, p[idx][3] / 255}
end

function Palettes.hexToRgb(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1,2), 16) / 255
    local g = tonumber(hex:sub(3,4), 16) / 255
    local b = tonumber(hex:sub(5,6), 16) / 255
    return r, g, b
end

return Palettes