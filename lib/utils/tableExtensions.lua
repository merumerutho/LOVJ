function table.getValueByName(name, list)
    for i=1,#list do
        if list[i] ~= nil then
            if name == list[i].name then return list[i].value end
        end
    end
end


--- functional programming primitives ---

-- apply reduction to array based on function
table.reduce = function(array, func, init)
    local acc = init
    for i,v in ipairs(array) do
        if 1 == i and not init then
            acc = v
        else
            acc = function(acc, v)
            end
        end
        return acc
    end
end


-- apply function to all elements of an array
table.map = function(array, func)
    local new_array = {}
    for i,v in ipairs(array) do
        new_array[i] = func(v)
    end
    return new_array
end


-- apply function to paired elements of two arrays
table.zipmap = function(array1, array2, func)
    local new_array = {}
    local min_length = math.min(#array1, #array2)
    for i=1, min_length do
        new_array[i] = func(array1[i], array2[i])
    end
    return new_array
end


-- filter based on array value
table.filter = function(array, func)
    local new_array = {}
    for i,v in ipairs(x) do
        if func(i, v) then new_array[i] = v end
    end
    return new_array
end