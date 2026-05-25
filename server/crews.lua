-- server/crews.lua

local CooldownCache = {}   -- [player_db_id] = unix timestamp of last crew change

local function GetLastCrewChange(playerId)
    if CooldownCache[playerId] then return CooldownCache[playerId] end
    local ts = MySQL.scalar.await("SELECT last_crew_change FROM players WHERE id = ? LIMIT 1", { playerId })
    CooldownCache[playerId] = ts or 0
    return CooldownCache[playerId]
end

local function SetLastCrewChange(playerId)
    local now = os.time()
    CooldownCache[playerId] = now
    MySQL.update.await("UPDATE players SET last_crew_change = ? WHERE id = ?", { now, playerId })
end

AddEventHandler("SPZ:playerDisconnected", function(src)
    local profile = exports["spz-identity"]:GetProfile(src)
    if profile then CooldownCache[profile.id] = nil end
end)

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function CheckCooldown(profile)
    local cooldown = Config.CrewCooldownSeconds or 0
    if cooldown <= 0 then return true, 0 end
    local last    = GetLastCrewChange(profile.id)
    local elapsed = os.time() - last
    if elapsed < cooldown then
        return false, math.ceil(cooldown - elapsed)
    end
    return true, 0
end

-- ── Public API ────────────────────────────────────────────────────────────────

---@param crewId number
---@return table|nil
local function GetCrew(crewId)
    if not crewId then return nil end
    return MySQL.single.await("SELECT * FROM crews WHERE id = ? LIMIT 1", { crewId })
end

---@param crewId number
---@return table   list of server source ids (online members)
local function GetOnlineCrewMembers(crewId)
    local members = {}
    for _, src in ipairs(GetPlayers()) do
        local source  = tonumber(src)
        local profile = exports["spz-identity"]:GetProfile(source)
        if profile and profile.crew_id == crewId then
            table.insert(members, source)
        end
    end
    return members
end

---@param source number
---@param name string
---@param tag string
---@return number|nil, string|nil   crewId, errorMsg
local function CreateCrew(source, name, tag)
    local profile = exports["spz-identity"]:GetProfile(source)
    if not profile then return nil, "No profile" end

    local minLen = Config.CrewTagMinLength or 2
    local maxLen = Config.CrewTagMaxLength or 4
    if not tag or #tag < minLen or #tag > maxLen then
        return nil, ("Tag must be %d–%d characters"):format(minLen, maxLen)
    end
    if tag ~= tag:upper() then return nil, "Tag must be uppercase" end

    local existing = MySQL.scalar.await("SELECT id FROM crews WHERE name = ? OR tag = ? LIMIT 1", { name, tag })
    if existing then return nil, "Name or tag already taken" end

    local crewId = MySQL.insert.await(
        "INSERT INTO crews (name, tag, owner_id) VALUES (?, ?, ?)",
        { name, tag, profile.id }
    )
    if not crewId then return nil, "Database error" end

    -- No cooldown on create — joining own crew counts as a change
    SetLastCrewChange(profile.id)
    exports["spz-identity"]:UpdateProfile(source, { crew_id = crewId })
    TriggerEvent("SPZ:crewChanged", source, nil, crewId)
    return crewId
end

---@param source number
---@param crewId number
---@return boolean, string|number   success, errorMsg or cooldown seconds remaining
local function JoinCrew(source, crewId)
    local profile = exports["spz-identity"]:GetProfile(source)
    if not profile then return false, "No profile" end
    if profile.crew_id then return false, "Already in a crew" end

    local allowed, remaining = CheckCooldown(profile)
    if not allowed then return false, remaining end   -- remaining = seconds

    local crew = GetCrew(crewId)
    if not crew then return false, "Crew not found" end

    local oldCrewId = profile.crew_id
    local updated   = exports["spz-identity"]:UpdateProfile(source, { crew_id = crewId })
    if not updated then return false, "Update failed" end

    SetLastCrewChange(profile.id)
    TriggerEvent("SPZ:crewChanged", source, oldCrewId, crewId)
    return true
end

---@param source number
---@return boolean, string|number   success, errorMsg or cooldown seconds remaining
local function LeaveCrew(source)
    local profile = exports["spz-identity"]:GetProfile(source)
    if not profile or not profile.crew_id then return false, "Not in a crew" end

    local allowed, remaining = CheckCooldown(profile)
    if not allowed then return false, remaining end

    local crewId     = profile.crew_id
    local crewOwnerId = MySQL.scalar.await("SELECT owner_id FROM crews WHERE id = ? LIMIT 1", { crewId })

    if crewOwnerId == profile.id then
        local next = MySQL.single.await(
            "SELECT id FROM players WHERE crew_id = ? AND id != ? LIMIT 1",
            { crewId, profile.id }
        )
        if next then
            MySQL.update.await("UPDATE crews SET owner_id = ? WHERE id = ?", { next.id, crewId })
        else
            MySQL.query.await("DELETE FROM crews WHERE id = ?", { crewId })
        end
    end

    local updated = exports["spz-identity"]:UpdateProfile(source, { crew_id = nil })
    if not updated then return false, "Update failed" end

    SetLastCrewChange(profile.id)
    TriggerEvent("SPZ:crewChanged", source, crewId, nil)
    return true
end

---@param source number
---@return string|nil
local function GetCrewTag(source)
    local profile = exports["spz-identity"]:GetProfile(source)
    return profile and profile.crew_tag or nil
end

-- ── Exports ───────────────────────────────────────────────────────────────────

local function GetCrewCooldownSeconds()
    return Config.CrewCooldownSeconds or 0
end

exports("GetCrew",                  GetCrew)
exports("GetCrewCooldownSeconds",   GetCrewCooldownSeconds)
exports("GetOnlineCrewMembers", GetOnlineCrewMembers)
exports("CreateCrew",           CreateCrew)
exports("JoinCrew",             JoinCrew)
exports("LeaveCrew",            LeaveCrew)
exports("GetCrewTag",           GetCrewTag)
