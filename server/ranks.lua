-- server/ranks.lua

SPZ = SPZ or {}
SPZ.Ranks = {}

-- Rank strings are derived from rank points by spz-progression
-- (domain/rank.lua). The old per-class threshold table that used to live here
-- was a second, disagreeing copy of the rank rules and had no callers.

---@param rankCode string
---@return string
local function GetRankName(rankCode)
    return SPZ.RankNames[rankCode] or "Unknown"
end

exports("GetRankName", GetRankName)
