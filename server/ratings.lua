-- server/ratings.lua

SPZ = SPZ or {}
SPZ.Ratings = {}

---@param currentSR number
---@param change number
---@return number
function SPZ.Ratings.ClampSR(currentSR, change)
    local newSR = currentSR + change
    if newSR > 5.0 then return 5.0 end
    if newSR < 0.0 then return 0.0 end
    -- Round to 2 decimal places
    return math.floor(newSR * 100 + 0.5) / 100
end

---@param currentIRating number
---@param change number
---@return number
function SPZ.Ratings.ClampIRating(currentIRating, change)
    local newIRating = currentIRating + change
    if newIRating < 0 then return 0 end
    return math.floor(newIRating + 0.5)
end

-- This file primarily serves as a utility for spz-progression 
-- to ensure ratings stay within valid bounds when using UpdateProfile.
