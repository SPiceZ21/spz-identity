-- server/profile.lua

--[[
    Profile Object Shape (in-RAM):
    {
        id             = number,
        identifier     = string,    -- "license:xxxx"
        citizen_id     = string,    -- "SPZ-XXXXX"
        username       = string,
        gender         = number,    -- 0=male 1=female
        first_time     = number,    -- 1 or 0
        playtime       = number,    -- seconds
        xp             = number,
        class_points   = number,    -- points in current class (season-resettable)
        alltime_points = number,    -- cumulative, never reset
        sr             = number,    -- Safety Rating, 2 decimal places
        i_rating       = number,    -- skill rating
        rank           = string,    -- "C-5", "B-3", "S-1" etc.
        license_tier   = number,    -- 0–3
        top3_count     = number,    -- top-3 finishes in current class (for promotion check)
        crew_id        = number,    -- nil if no crew
        crew_tag       = string,    -- "[SPZ]" or nil
        credits        = number,
        banned         = bool,
        avatar_url     = string,
        banner_url     = string,
    }
]]

local ProfileCache = {}

function SyncProfileToStateBag(source, profile)
    if not source or not profile then return end
    
    Player(source).state:set("profile", profile, true)
    Player(source).state:set("citizenId", profile.citizen_id, true)
    Player(source).state:set("username", profile.username, true)
    Player(source).state:set("gender", profile.gender, true)
    Player(source).state:set("licenseTier", profile.license_tier, true)
    Player(source).state:set("rank", profile.rank, true)
    Player(source).state:set("sr", profile.sr, true)
    Player(source).state:set("iRating", profile.i_rating, true)
    Player(source).state:set("crewId", profile.crew_id, true)
    Player(source).state:set("crewTag", profile.crew_tag, true)
    Player(source).state:set("avatarUrl", profile.avatar_url, true)
    Player(source).state:set("firstTime", profile.first_time == 1, true)
    Player(source).state:set("identityReady", true, true)
end

---@param source number
---@param identifier string
---@return table|nil
function CreateProfile(source, identifier)
    local citizen_id = SPZ.GenerateCitizenId()

    local insertId = MySQL.insert.await([[
        INSERT INTO players (identifier, citizen_id, first_time, sr, i_rating, rank, license_tier)
        VALUES (?, ?, 1, ?, ?, ?, ?)
    ]], {
        identifier,
        citizen_id,
        Config.DefaultSR or 2.0,
        Config.DefaultIRating or 1500,
        'C-5',
        0
    })

    if not insertId then
        return nil
    end

    local profile = {
        id = insertId,
        identifier = identifier,
        citizen_id = citizen_id,
        username = nil,
        gender = nil,
        first_time = 1,
        playtime = 0,
        xp = 0,
        class_points = 0,
        alltime_points = 0,
        sr = Config.DefaultSR or 2.0,
        i_rating = Config.DefaultIRating or 1500,
        rank = 'C-5',
        license_tier = 0,
        top3_count = 0,
        crew_id = nil,
        crew_tag = nil,
        credits = 0,
        banned = false,
        avatar_url = nil,
        banner_url = nil,
        state = 'IDLE'
    }

    ProfileCache[source] = profile
    SyncProfileToStateBag(source, profile)

    return profile
end

---@param source number
---@return table|nil
function GetProfile(source)
    if ProfileCache[source] then
        -- Always ensure statebag is synced when GetProfile is called, 
        -- in case the resource restarted but the session persists.
        SyncProfileToStateBag(source, ProfileCache[source])
        return ProfileCache[source]
    end

    -- Fallback to DB read (edge case)
    local identifier = GetPlayerIdentifierByType(source, 'license')
    if not identifier then
        return nil
    end

    local row = MySQL.single.await([[
        SELECT p.*, c.tag as crew_tag
        FROM players p
        LEFT JOIN crews c ON p.crew_id = c.id
        WHERE p.identifier = ?
        LIMIT 1
    ]], { identifier })

    if not row then
        return nil
    end

    local profile = {
        id = row.id,
        identifier = row.identifier,
        citizen_id = row.citizen_id,
        username = row.username,
        gender = row.gender,
        first_time = row.first_time,
        playtime = row.playtime,
        xp = row.xp,
        class_points = row.class_points,
        alltime_points = row.alltime_points,
        sr = row.sr,
        i_rating = row.i_rating,
        rank = row.rank,
        license_tier = row.license_tier,
        top3_count = row.top3_count,
        crew_id = row.crew_id,
        crew_tag = row.crew_tag and ("[%s]"):format(row.crew_tag) or nil,
        credits = row.credits,
        banned = row.banned == 1,
        avatar_url = row.avatar_url,
        banner_url = row.banner_url,
        state = 'IDLE'
    }

    ProfileCache[source] = profile

    -- Sync statebags
    SyncProfileToStateBag(source, profile)

    return profile
end

---@param identifier string
---@return table|nil
function GetProfileByIdentifier(identifier)
    local row = MySQL.single.await([[
        SELECT p.*, c.tag as crew_tag
        FROM players p
        LEFT JOIN crews c ON p.crew_id = c.id
        WHERE p.identifier = ?
        LIMIT 1
    ]], { identifier })

    if not row then
        return nil
    end

    return {
        id = row.id,
        identifier = row.identifier,
        citizen_id = row.citizen_id,
        username = row.username,
        gender = row.gender,
        first_time = row.first_time,
        playtime = row.playtime,
        xp = row.xp,
        class_points = row.class_points,
        alltime_points = row.alltime_points,
        sr = row.sr,
        i_rating = row.i_rating,
        rank = row.rank,
        license_tier = row.license_tier,
        top3_count = row.top3_count,
        crew_id = row.crew_id,
        crew_tag = row.crew_tag,
        credits = row.credits,
        banned = row.banned == 1,
        avatar_url = row.avatar_url,
        banner_url = row.banner_url
    }
end

local WhitelistedProfileKeys = {
    ['username'] = true,
    ['gender'] = true,
    ['first_time'] = true,
    ['rank'] = true,
    ['license_tier'] = true,
    ['top3_count'] = true,
    ['xp'] = true,
    ['class_points'] = true,
    ['alltime_points'] = true,
    ['sr'] = true,
    ['i_rating'] = true,
    ['credits'] = true,
    ['crew_id'] = true,
    ['avatar_url'] = true,
    ['banner_url'] = true
}

---@param source number
---@param changes table
---@return boolean
local function UpdateProfile(source, changes)
    local profile = GetProfile(source)
    if not profile then
        return false
    end

    local changedSubset = {}
    for key, value in pairs(changes) do
        if WhitelistedProfileKeys[key] then
            profile[key] = value
            changedSubset[key] = value

            -- Special case: update crew_tag when crew_id changes
            if key == "crew_id" then
                if value == nil then
                    profile.crew_tag = nil
                    changedSubset.crew_tag = nil
                else
                    local tag = MySQL.scalar.await("SELECT tag FROM crews WHERE id = ? LIMIT 1", { value })
                    profile.crew_tag = tag and ("[%s]"):format(tag) or nil
                    changedSubset.crew_tag = profile.crew_tag
                end
            end

            -- Special case: Derived names for client sync
            if key == "rank" then
                changedSubset.rank_name = exports["spz-identity"]:GetRankName(value)
                Player(source).state:set("rank", value, true)
            end

            if key == "license_tier" then
                changedSubset.license_name = SPZ.LicenseNames[value] or "Unknown"
                Player(source).state:set("licenseTier", value, true)
            end

            if key == "username" then Player(source).state:set("username", value, true) end
            if key == "gender" then Player(source).state:set("gender", value, true) end
            if key == "sr" then Player(source).state:set("sr", value, true) end
            if key == "i_rating" then Player(source).state:set("iRating", value, true) end
            if key == "crew_id" then Player(source).state:set("crewId", value, true) end
            if key == "first_time" then Player(source).state:set("firstTime", value == 1, true) end
        end
    end

    -- Update full profile statebag
    Player(source).state:set("profile", profile, true)

    if next(changedSubset) then
        profile._dirty = true
        TriggerClientEvent('SPZ:syncProfile', source, changedSubset)
        return true
    end

    return false
end

---@param source number
---@return boolean
local function SaveProfile(source)
    local profile = ProfileCache[source]
    if not profile or not profile._dirty then
        return false
    end

    local success = MySQL.update.await([[
        UPDATE players SET
            username = ?,
            gender = ?,
            first_time = ?,
            playtime = ?,
            xp = ?,
            class_points = ?,
            alltime_points = ?,
            sr = ?,
            i_rating = ?,
            rank = ?,
            license_tier = ?,
            top3_count = ?,
            crew_id = ?,
            credits = ?,
            banned = ?,
            avatar_url = ?,
            banner_url = ?
        WHERE id = ?
    ]], {
        profile.username,
        profile.gender,
        profile.first_time,
        profile.playtime,
        profile.xp,
        profile.class_points,
        profile.alltime_points,
        profile.sr,
        profile.i_rating,
        profile.rank,
        profile.license_tier,
        profile.top3_count,
        profile.crew_id,
        profile.credits,
        profile.banned and 1 or 0,
        profile.avatar_url,
        profile.banner_url,
        profile.id
    })

    if success then
        profile._dirty = false
        return true
    end

    return false
end

---@param source number
---@param reason string
---@return boolean
local function BanPlayer(source, reason)
    local profile = GetProfile(source)
    if not profile then
        return false
    end

    profile.banned = true
    profile.ban_reason = reason
    profile._dirty = true

    -- Immediate DB update for bans
    local success = MySQL.update.await([[
        UPDATE players SET banned = 1, ban_reason = ? WHERE id = ?
    ]], { reason, profile.id })

    if success then
        DropPlayer(source, ("You have been banned: %s"):format(reason))
        return true
    end

    return false
end

---@param source number
---@return number
local function GetPlaytime(source)
    local profile = GetProfile(source)
    if not profile then
        return 0
    end

    local sessionPlaytime = 0
    if profile.joinedAt then
        sessionPlaytime = os.time() - profile.joinedAt
    end

    return profile.playtime + sessionPlaytime
end

-- --- Background Tasks ---

-- Periodic Batch Save
CreateThread(function()
    while true do
        Wait((Config.SaveInterval or 60) * 1000)
        
        for source, profile in pairs(ProfileCache) do
            if profile._dirty then
                SaveProfile(source)
            end
        end
    end
end)

-- --- Event Handlers ---

-- playerDisconnected handler (fired by spz-core)
AddEventHandler("SPZ:playerDisconnected", function(source)
    local profile = ProfileCache[source]
    if not profile then
        return
    end

    -- 1. Finalize playtime
    if profile.joinedAt then
        local sessionDuration = os.time() - profile.joinedAt
        profile.playtime = profile.playtime + sessionDuration
        profile._dirty = true
    end

    -- 2. Flush to DB
    SaveProfile(source)

    -- 3. Clear cache
    ProfileCache[source] = nil
end)

RegisterNetEvent("SPZ:identity:setPlayerState", function(state)
    SetPlayerState(source, state)
end)

-- --- Exports ---

---@param profile table
---@return table
function GetSyncSubset(profile)
    return {
        citizen_id     = profile.citizen_id,
        username       = profile.username,
        gender         = profile.gender,
        rank           = profile.rank,
        rank_name      = exports["spz-identity"]:GetRankName(profile.rank),
        license_tier   = profile.license_tier,
        license_name   = SPZ.LicenseNames[profile.license_tier] or "Unknown",
        crew_tag       = profile.crew_tag,
        xp             = profile.xp,
        class_points   = profile.class_points,
        alltime_points = profile.alltime_points,
        sr             = profile.sr,
        i_rating       = profile.i_rating,
        avatar_url     = profile.avatar_url,
        banner_url     = profile.banner_url,
    }
end

exports("CreateProfile", CreateProfile)
exports("UpdateProfile", UpdateProfile)
exports("SaveProfile", SaveProfile)
exports("BanPlayer", BanPlayer)
exports("GetPlaytime", GetPlaytime)
exports("GetSyncSubset", GetSyncSubset)
