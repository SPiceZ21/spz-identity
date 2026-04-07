-- server/profile.lua

--[[
    Profile Object Shape (in-RAM):
    {
        id             = number,
        identifier     = string,    -- "license:xxxx"
        name           = string,
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
    }
]]

local ProfileCache = {}

---@param source number
---@param identifier string
---@param name string
---@return table|nil
local function CreateProfile(source, identifier, name)
    local insertId = MySQL.insert.await([[
        INSERT INTO players (identifier, name, sr, i_rating, rank, license_tier)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        identifier,
        name,
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
        name = name,
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
        banned = false
    }

    ProfileCache[source] = profile
    return profile
end

exports("CreateProfile", CreateProfile)
