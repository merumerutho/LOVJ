local Keypress = {}

Keypress.currentlyPressed = {}

-- local scope
local function checkSinglePress(key, onrelease)
    -- If some key is pressed
    if love.keyboard.isDown(key) then
        local was_pressed = false
        -- check if previously pressed
        for k,v in pairs(Keypress.currentlyPressed) do
            if v == key then
                was_pressed = true
            end
        end
        -- If not previously pressed
        if not was_pressed then
            table.insert(Keypress.currentlyPressed, key)
            return (not onrelease)
        end
        return false
    else
        for k,v in pairs(Keypress.currentlyPressed) do
            if v == key then
                table.remove(Keypress.currentlyPressed, k)
                return onrelease
            end
        end
    end
    return false
end

-- global scope
function Keypress.keypressOnAttack(key)
    return checkSinglePress(key, false)
end

function Keypress.keypressOnRelease(key)
    return checkSinglePress(key, true)
end

function Keypress.isDown(key)
    return love.keyboard.isDown(key)
end

return Keypress