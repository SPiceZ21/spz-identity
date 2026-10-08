-- server/licenses.lua

local TierChars = { [0] = "C", [1] = "B", [2] = "A", [3] = "S" }

---@param source number
---@param tier number
---@param method string
---@param rank string|nil  rank string at the moment of promotion (spz-progression
---                        derives it from rank points); defaults to "<tier>-5"
---@return boolean
--- Stores a class (licence) promotion. Single emitter of SPZ:licenseUnlocked.
--- It no longer wipes class_points / top3_count: that reset made the old top-3
--- gates stack (10 + 20 + 30) and threw away progress on every promotion.
local function UnlockLicense(source, tier, method, rank)
    local profile = exports["spz-identity"]:GetProfile(source)
    if not profile then
        return false
    end

    local tierChar = TierChars[tier] or "C"
    local newRank = rank or ("%s-5"):format(tierChar)

    -- 1. Update player profile
    local updated = exports["spz-identity"]:UpdateProfile(source, {
        license_tier = tier,
        rank = newRank,
    })

    if not updated and (profile.license_tier ~= tier or profile.rank ~= newRank) then
        return false
    end

    -- 2. Insert audit log
    MySQL.insert.await([[
        INSERT INTO driver_licenses (player_id, tier, method)
        VALUES (?, ?, ?)
    ]], { profile.id, tier, method })

    -- 3. Fire events
    local tierName = SPZ.LicenseNames[tier] or "Unknown"
    TriggerEvent("SPZ:licenseUnlocked", source, tier, tierName)
    TriggerClientEvent("SPZ:licenseUnlocked", source, tier, tierName)

    return true
end

exports("UnlockLicense", UnlockLicense)

