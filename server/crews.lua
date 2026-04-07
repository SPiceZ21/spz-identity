-- server/crews.lua

---@param source number
---@param name string
---@param tag string
---@return number|nil
local function CreateCrew(source, name, tag)
    local profile = exports["spz-identity"]:GetProfile(source)
    if not profile then return nil end

    -- Validation
    if not tag or tag:len() < (Config.CrewTagMinLength or 2) or tag:len() > (Config.CrewTagMaxLength or 4) then
        return nil
    end

    if tag ~= tag:upper() then
        return nil
    end

    -- Check for unique name
    local existing = MySQL.scalar.await("SELECT id FROM crews WHERE name = ? LIMIT 1", { name })
    if existing then
        return nil
    end

    -- Insert crew
    local crewId = MySQL.insert.await([[
        INSERT INTO crews (name, tag, owner_id)
        VALUES (?, ?, ?)
    ]], { name, tag, profile.id })

    if not crewId then
        return nil
    end

    -- Join the crew
    exports["spz-identity"]:UpdateProfile(source, { crew_id = crewId })
    return crewId
end

---@param source number
---@param crewId number
---@return boolean
local function JoinCrew(source, crewId)
    local profile = exports["spz-identity"]:GetProfile(source)
    if not profile then return false end

    local oldCrewId = profile.crew_id
    
    -- Update profile
    local updated = exports["spz-identity"]:UpdateProfile(source, { crew_id = crewId })
    if updated then
        TriggerEvent("SPZ:crewChanged", source, oldCrewId, crewId)
        return true
    end

    return false
end

---@param source number
---@return boolean
local function LeaveCrew(source)
    local profile = exports["spz-identity"]:GetProfile(source)
    if not profile or not profile.crew_id then return false end

    local crewId = profile.crew_id
    local oldCrewId = crewId

    -- Find crew owner
    local crewOwnerId = MySQL.scalar.await("SELECT owner_id FROM crews WHERE id = ? LIMIT 1", { crewId })
    
    if crewOwnerId == profile.id then
        -- Owner is leaving, transfer ownership or delete
        local nextMember = MySQL.single.await("SELECT id FROM players WHERE crew_id = ? AND id != ? LIMIT 1", { crewId, profile.id })
        
        if nextMember then
            -- Transfer ownership
            MySQL.update.await("UPDATE crews SET owner_id = ? WHERE id = ?", { nextMember.id, crewId })
        else
            -- Delete crew (last member)
            MySQL.query.await("DELETE FROM crews WHERE id = ?", { crewId })
        end
    end

    -- Update profile
    local updated = exports["spz-identity"]:UpdateProfile(source, { crew_id = nil })
    if updated then
        TriggerEvent("SPZ:crewChanged", source, oldCrewId, nil)
        return true
    end

    return false
end

---@param source number
---@return string|nil
local function GetCrewTag(source)
    local profile = exports["spz-identity"]:GetProfile(source)
    return profile and profile.crew_tag or nil
end

---@param crewId number
---@return table
local function GetCrewMembers(crewId)
    local members = {}
    -- Note: ProfileCache is local to profile.lua, but we can iterate through connected players
    local players = GetPlayers()
    for _, src in ipairs(players) do
        local source = tonumber(src)
        local profile = exports["spz-identity"]:GetProfile(source)
        if profile and profile.crew_id == crewId then
            table.insert(members, source)
        end
    end
    return members
end

exports("CreateCrew", CreateCrew)
exports("JoinCrew", JoinCrew)
exports("LeaveCrew", LeaveCrew)
exports("GetCrewTag", GetCrewTag)
exports("GetCrewMembers", GetCrewMembers)
