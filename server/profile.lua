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
