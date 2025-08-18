-- error_handler.lua
--
-- Robust error handling for patch operations with visual feedback
--

local ErrorHandler = {}

-- Error state tracking per patch
ErrorHandler.patchErrors = {}
ErrorHandler.lastError = nil

-- Error display settings
local ERROR_DISPLAY_TIME = 5.0  -- seconds to show error overlay
local ERROR_FONT_SIZE = 16

-- Create error overlay font (fallback to default if needed)
local errorFont
local function getErrorFont()
    if not errorFont then
        local ok, font = pcall(love.graphics.newFont, ERROR_FONT_SIZE)
        errorFont = ok and font or love.graphics.getFont()
    end
    return errorFont
end

-- Safe patch operation wrapper
function ErrorHandler.safePatchCall(patchSlot, operation, func, ...)
    if not func then
        logError("ErrorHandler: nil function passed for " .. operation)
        return false
    end
    
    local success, result = pcall(func, ...)
    
    if success then
        -- Clear error state on successful operation
        if ErrorHandler.patchErrors[patchSlot] and ErrorHandler.patchErrors[patchSlot].operation == operation then
            ErrorHandler.patchErrors[patchSlot] = nil
        end
        return true, result
    else
        -- Handle error
        local errorInfo = {
            operation = operation,
            message = tostring(result),
            timestamp = love.timer.getTime(),
            patchSlot = patchSlot,
            patchName = (patchSlots and patchSlots[patchSlot] and patchSlots[patchSlot].name) or "unknown"
        }
        
        ErrorHandler.patchErrors[patchSlot] = errorInfo
        ErrorHandler.lastError = errorInfo
        
        -- Log to console
        logError(string.format("Patch %d (%s) %s error: %s", 
            patchSlot, errorInfo.patchName, operation, errorInfo.message))
        
        return false, result
    end
end

-- Draw error overlay for patches with errors
function ErrorHandler.drawErrorOverlay()
    local currentTime = love.timer.getTime()
    local font = getErrorFont()
    local oldFont = love.graphics.getFont()
    
    love.graphics.setFont(font)
    love.graphics.push()
    
    local yOffset = 10
    for slot, error in pairs(ErrorHandler.patchErrors) do
        if currentTime - error.timestamp < ERROR_DISPLAY_TIME then
            -- Semi-transparent background
            love.graphics.setColor(0, 0, 0, 0.8)
            love.graphics.rectangle("fill", 5, yOffset - 5, love.graphics.getWidth() - 10, 80)
            
            -- Error text
            love.graphics.setColor(1, 0.2, 0.2, 1)  -- Red
            local errorText = string.format("PATCH %d ERROR (%s %s):\n%s", 
                slot, error.patchName, error.operation, error.message)
            love.graphics.printf(errorText, 10, yOffset, love.graphics.getWidth() - 20, "left")
            
            yOffset = yOffset + 90
        else
            -- Remove expired errors
            ErrorHandler.patchErrors[slot] = nil
        end
    end
    
    love.graphics.pop()
    love.graphics.setFont(oldFont)
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color
end

-- Create a safe fallback patch for error states
function ErrorHandler.createFallbackPatch(patchSlot)
    local fallbackPatch = {}
    
    function fallbackPatch.init(slot, globals, shaderext)
        -- Minimal safe initialization
    end
    
    function fallbackPatch.draw()
        local canvas = love.graphics.newCanvas(screen.InternalRes.W, screen.InternalRes.H)
        love.graphics.setCanvas(canvas)
        
        -- Draw error indicator
        love.graphics.setColor(0.2, 0, 0, 1)  -- Dark red background
        love.graphics.rectangle("fill", 0, 0, screen.InternalRes.W, screen.InternalRes.H)
        
        love.graphics.setColor(1, 0.5, 0.5, 1)  -- Light red text
        local font = getErrorFont()
        local oldFont = love.graphics.getFont()
        love.graphics.setFont(font)
        
        local errorText = "PATCH " .. patchSlot .. " ERROR\nCheck console for details"
        love.graphics.printf(errorText, 0, screen.InternalRes.H/2 - 20, screen.InternalRes.W, "center")
        
        love.graphics.setFont(oldFont)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setCanvas()
        
        return canvas
    end
    
    function fallbackPatch.update()
        -- Safe empty update
    end
    
    return fallbackPatch
end

-- Get error status for a patch
function ErrorHandler.hasError(patchSlot)
    return ErrorHandler.patchErrors[patchSlot] ~= nil
end

-- Clear error for a patch
function ErrorHandler.clearError(patchSlot)
    ErrorHandler.patchErrors[patchSlot] = nil
end

-- Clear all errors
function ErrorHandler.clearAllErrors()
    ErrorHandler.patchErrors = {}
    ErrorHandler.lastError = nil
end

return ErrorHandler