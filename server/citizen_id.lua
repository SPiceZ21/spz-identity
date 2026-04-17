-- server/citizen_id.lua

--- Generate a new citizen ID
--- @return string
local function GenerateCitizenId()
    local result = MySQL.query.await(
        "SELECT MAX(CAST(SUBSTRING(citizen_id, 5) AS UNSIGNED)) AS max_id FROM players"
    )
    local nextId = ((result and result[1] and result[1].max_id) or 0) + 1
    return string.format("SPZ-%05d", nextId)
end

--- Get the Citizen ID for an active player source
--- @param source integer
--- @return string|nil
local function GetCitizenId(source)
    local profile = exports['spz-identity']:GetProfile(source)
    return profile and profile.citizen_id or nil
end

--- Get a player profile from the database by their Citizen ID
--- @param cid string
--- @return table|nil
local function GetByCitizenId(cid)
    local row = MySQL.single.await([[
        SELECT p.*, c.tag as crew_tag
        FROM players p
        LEFT JOIN crews c ON p.crew_id = c.id
        WHERE p.citizen_id = ?
        LIMIT 1
    ]], { cid })

    if not row then return nil end

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
        banned = row.banned == 1
    }
end

-- internal module usage
SPZ = SPZ or {}
SPZ.GenerateCitizenId = GenerateCitizenId

exports('GetCitizenId', GetCitizenId)
exports('GetByCitizenId', GetByCitizenId)
