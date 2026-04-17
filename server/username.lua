-- server/username.lua

--- Check if username is already taken by another profile
--- @param username string
--- @return boolean
local function IsUsernameTaken(username)
    local result = MySQL.query.await(
        "SELECT id FROM players WHERE username = ?",
        { username }
    )
    return result and #result > 0
end

--- Validate the format of a requested username
--- @param name string
--- @return boolean is_valid, string|nil error_message
local function ValidateUsername(name)
    if not name or type(name) ~= 'string' then
        return false, "Username must be a string"
    end
    if #name < 3 or #name > 20 then
        return false, "Username must be 3–20 characters"
    end
    if not name:match("^[a-zA-Z0-9_]+$") then
        return false, "Letters, numbers and underscores only"
    end
    return true, nil
end

--- Get a sanitized suggested platform name
--- @param source integer
--- @return string
local function GetPlatformName(source)
    local name = GetPlayerName(source) or ""
    name = name:lower()
               :gsub("%s+", "_")
               :gsub("[^a-z0-9_]", "")
               :sub(1, 20)
    return name ~= "" and name or "racer"
end

--- Get the current username mapped to the player connection
--- @param source integer
--- @return string|nil
local function GetUsername(source)
    local profile = exports['spz-identity']:GetProfile(source)
    return profile and profile.username or nil
end

-- expose for internal server usage
SPZ = SPZ or {}
SPZ.IsUsernameTaken = IsUsernameTaken
SPZ.ValidateUsername = ValidateUsername
SPZ.GetPlatformName = GetPlatformName

exports('GetUsername', GetUsername)
exports('GetPlatformName', GetPlatformName)
