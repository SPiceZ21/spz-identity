-- server/ranks.lua

SPZ = SPZ or {}
SPZ.Ranks = {}

local RankRanges = {
    [0] = { -- Class C
        { threshold = 400, rank = "C-1" },
        { threshold = 300, rank = "C-2" },
        { threshold = 200, rank = "C-3" },
        { threshold = 100, rank = "C-4" },
        { threshold = 0,   rank = "C-5" },
    },
    [1] = { -- Class B
        { threshold = 800, rank = "B-1" },
        { threshold = 600, rank = "B-2" },
        { threshold = 400, rank = "B-3" },
        { threshold = 200, rank = "B-4" },
        { threshold = 0,   rank = "B-5" },
    },
    [2] = { -- Class A
        { threshold = 1600, rank = "A-1" },
        { threshold = 1200, rank = "A-2" },
        { threshold = 800,  rank = "A-3" },
        { threshold = 400,  rank = "A-4" },
        { threshold = 0,    rank = "A-5" },
    },
    [3] = { -- Class S
        { threshold = 2000, rank = "S-1" },
        { threshold = 1500, rank = "S-2" },
        { threshold = 1000, rank = "S-3" },
        { threshold = 500,  rank = "S-4" },
        { threshold = 0,    rank = "S-5" },
    }
}

---@param license_tier number
---@param class_points number
---@return string
function SPZ.Ranks.Compute(license_tier, class_points)
    local ranges = RankRanges[license_tier]
    if not ranges then
        return "C-5"
    end

    for _, data in ipairs(ranges) do
        if class_points >= data.threshold then
            return data.rank
        end
    end

    return ranges[#ranges].rank
end

---@param rankCode string
---@return string
local function GetRankName(rankCode)
    return SPZ.RankNames[rankCode] or "Unknown"
end

exports("GetRankName", GetRankName)
