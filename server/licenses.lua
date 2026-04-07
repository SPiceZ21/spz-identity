-- server/licenses.lua

---@param source number
---@return number
local function GetLicenseTier(source)
    local profile = exports["spz-identity"]:GetProfile(source)
    return profile and profile.license_tier or 0
end

exports("GetLicenseTier", GetLicenseTier)

---@param source number
---@param tier number
---@return boolean
local function HasLicense(source, tier)
    return GetLicenseTier(source) >= tier
end

exports("HasLicense", HasLicense)

local TierChars = { [0] = "C", [1] = "B", [2] = "A", [3] = "S" }

---@param source number
---@param tier number
---@param method string
---@return boolean
local function UnlockLicense(source, tier, method)
    local profile = exports["spz-identity"]:GetProfile(source)
    if not profile then
        return false
    end

    local tierChar = TierChars[tier] or "C"
    local newRank = ("%s-5"):format(tierChar)

    -- 1. Update player profile
    local updated = exports["spz-identity"]:UpdateProfile(source, {
        license_tier = tier,
        rank = newRank,
        class_points = 0,
        top3_count = 0
    })

    if not updated then
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

---@param source number
---@return table
local function GetLicenseHistory(source)
    local profile = exports["spz-identity"]:GetProfile(source)
    if not profile then
        return {}
    end

    local rows = MySQL.query.await([[
        SELECT tier, unlocked_at, method
        FROM driver_licenses
        WHERE player_id = ?
        ORDER BY unlocked_at ASC
    ]], { profile.id })

    if not rows then
        return {}
    end

    local history = {}
    for _, row in ipairs(rows) do
        table.insert(history, {
            tier = row.tier,
            tier_name = SPZ.LicenseNames[row.tier] or "Unknown",
            unlocked_at = row.unlocked_at,
            method = row.method
        })
    end

    return history
end

exports("GetLicenseHistory", GetLicenseHistory)
