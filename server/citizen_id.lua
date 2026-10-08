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

-- internal module usage
SPZ = SPZ or {}
SPZ.GenerateCitizenId = GenerateCitizenId

