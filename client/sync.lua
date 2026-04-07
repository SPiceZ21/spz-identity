-- client/sync.lua

local CurrentProfile = nil

---@param data table
RegisterNetEvent("SPZ:syncProfile", function(data)
    local isInitialSync = (CurrentProfile == nil)

    if isInitialSync then
        CurrentProfile = data
        TriggerEvent("SPZ:identityReady", CurrentProfile)
    else
        -- Partial update: merge data into existing profile
        for key, value in pairs(data) do
            CurrentProfile[key] = value
        end
    end
end)

---@return table|nil
local function GetClientProfile()
    return CurrentProfile
end

exports("GetClientProfile", GetClientProfile)
