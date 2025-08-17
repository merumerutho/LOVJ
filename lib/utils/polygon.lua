-- polygon.lua
--
-- A utility library for polygon handling
--


local Polygon = {}
Polygon.__index = Polygon


-- Build new polygon from vertices
function Polygon:NewFromVertices(vertices)
    local self = setmetatable({}, Polygon)

    self.vertices = vertices
    self.centroid = updateCentroid()
    
    return self
end


-- Build new regular polygon
function Polygon:NewRegular(center, size, n, angle)
    local vertices = {}
    local one_over_n = 1/n
    local TAU = 2*math.pi
    for i = 0,1,one_over_n do
        table.insert(vertices, size*math.cos(TAU*(i+angle)))  -- x
        table.insert(vertices, size*math.sin(TAU*(i+angle)))  -- y
    end
    
    self.vertices = vertices
    self.centroid = center
    
    return self
end


-- Calculate centroid
local function updateCentroid()
    local x_values, y_values = unpackXY(self.vertices)
    
    local cx = table.reduce(x_values, function(a,b) return a+b end) / #x_values
    local cy = table.reduce(y_values, function(a,b) return a+b end) / #y_values
    
    return {x=cx, y=cy}
end


-- Core rotation function
local function rotateCore(vx, vy, angle, cx, cy)
    local TAU = 2*math.pi
    local cosa, sina = math.cos(TAU*angle), math.sin(TAU*angle)
    
    -- translate
    local vx_t = table.map(vx, function(v) return v - cx end)
    local vy_t = table.map(vy, function(v) return v - cy end)
    
    -- rotation matrix
    local vx_r = table.zipmap(vx_t, vy_t, function(x,y) return x*cosa - y*sina end)
    local vy_r = table.zipmap(vx_t, vy_t, function(x,y) return x*sina + y*cosa end)
    
    -- retranslate
    vx_r = table.map(vx_r, function(v) return v + cx end)
    vy_r = table.map(vy_r, function(v) return v + cy end)
    
    return packXY(vx_r, vy_r)
end


-- Rotate around centroid
function Polygon:RotateAroundCentroid(angle, permanent)
    permanent = False or permanent
    
    local vx, vy = unpackXY(self.vertices)
    local rotated = rotateCore(vx, vy, angle, self.centroid.x, self.centroid.y)
    
    if permanent then
        self.vertices = rotated  -- centroid kept constant -> no need to update
    end
    
    return rotated
end


-- Rotate around generic point
function Polygon:RotatedAroundPoint(angle, point)
    local vx, vy = unpackXY(vertices)
    local rotated = rotateCore(vx, vy, angle, point.x, point.y)
    
    if permanent then
        self.vertices = rotated
        self.centroid = updateCentroid()  -- update centroid after this
    end
    
    return rotated
end


-- Resize
function Polygon:Resize(factor, permanent)
    permanent = False or permanent
    local vx, vy = unpackXY(self.vertices)
    local cx, cy = self.centroid.x, self.centroid.y

    -- translate, resize, retranslate
    local vx_r = table.map(vx, function(x) return ((x-cx)*factor)+cx end)
    local vy_r = table.map(vy, function(y) return ((y-cy)*factor)+cy end)
    
    local resized = packXY(vx_r, vy_r)
    
    if permanent then
        self.vertices = resized  -- centroid kept constant -> no need to update
    end
    
    return resized
end


-- Translate
function Polygon:Translate(point, permanent)
    permanent = False or permanent
    local vx, vy = unpackXY(self.vertices)
    
    -- translate
    local vx_t = table.map(vx, function(x) return (x-point.x) end)
    local vy_t = table.map(vy, function(y) return (y-point.y) end)
    
    local translated = packXY(vx_t, vy_t)
    
    if permanent then
        self.vertices = translated
        self.centroid = updateCentroid() -- update centroid after this
    end
    
    return translated
end


return Polygon