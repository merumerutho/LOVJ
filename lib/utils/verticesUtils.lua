-- pack xy 
function packXY(vx, vy)
    local v = {}
    for i=1,#vx do
        v[i*2-1] = vx[i]
    end
    for i=1,#vy do
        v[i*2] = vy[i]
    end
    return v
end


-- unpack xy
function unpackXY(v)
    local x = table.filter(v, function(i,x) return (i//2 == 1) end)
    local y = table.filter(v, function(i,x) return (i//2 == 0) end)
    return x, y
end