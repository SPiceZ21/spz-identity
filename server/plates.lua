-- server/plates.lua — personal vanity number plates
--
-- One plate per player, applied to every car they spawn (spz-vehicles reads it
-- at the end of the spawn sequence). NULL means "no custom plate" and the car
-- keeps whatever the game or its saved customization preset gave it.
--
-- This is the single writer for players.plate. The column carries a UNIQUE
-- index, so claiming has to be atomic against other players doing the same
-- thing; see the note in profile.lua for why it is kept out of the normal
-- UpdateProfile/SaveProfile path.

local MAX_LEN = 8          -- GTA renders 8 characters; more is truncated by the engine

-- Plates are A-Z, 0-9 and spaces. Lower case is accepted and upper-cased,
-- because that is what the game displays either way.
local PATTERN = "^[A-Z0-9 ]+$"

-- Text that would let someone impersonate staff or a system vehicle. Matched on
-- the normalised plate with spaces stripped, so "P D 1" is caught as "PD1".
local RESERVED = {
    ["ADMIN"] = true, ["STAFF"] = true, ["MOD"] = true, ["OWNER"] = true,
    ["POLICE"] = true, ["SPZ"] = true, ["SYSTEM"] = true, ["SERVER"] = true,
}

--- Normalise user input to what will actually be stored and rendered.
--- Returns nil plus a reason when the text cannot be a plate.
---@param raw string
---@return string|nil, string|nil
local function Normalise(raw)
    if type(raw) ~= "string" then return nil, "No plate text given." end

    -- Collapse runs of whitespace and trim: a plate of "AB    12" renders with
    -- the run intact and looks broken, and trailing spaces are invisible to the
    -- player but count against the 8-character limit and against uniqueness.
    local text = raw:upper():gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")

    if text == "" then return nil, "Plate cannot be empty." end
    if #text > MAX_LEN then
        return nil, ("Plate is too long (%d characters, max %d)."):format(#text, MAX_LEN)
    end
    if not text:match(PATTERN) then
        return nil, "Plate can only contain letters, numbers and spaces."
    end
    if RESERVED[(text:gsub(" ", ""))] then
        return nil, "That plate is reserved."
    end

    return text
end

exports("NormalisePlate", Normalise)

--- Read a player's current plate, or nil.
---@param source number
---@return string|nil
local function GetPlate(source)
    local ok, profile = pcall(function() return exports["spz-identity"]:GetProfile(source) end)
    if not ok or not profile then return nil end
    return profile.plate
end

exports("GetPlate", GetPlate)

--- Claim a plate for a player.
--- Returns ok, plateOrError.
---@param source number
---@param raw string
---@return boolean, string
local function SetPlate(source, raw)
    local profile
    local ok, err = pcall(function() profile = exports["spz-identity"]:GetProfile(source) end)
    if not ok or not profile then return false, "Profile not ready." end

    local text, why = Normalise(raw)
    if not text then return false, why end

    if profile.plate == text then return true, text end   -- already theirs, nothing to do

    -- Claim it in one statement. Checking "is it taken?" and then writing would
    -- be a race: two players can both pass the check before either writes, and
    -- the second write then fails on the unique index anyway. The WHERE NOT
    -- EXISTS makes the check and the write the same operation, so exactly one
    -- of them gets it and the loser is told cleanly instead of hitting a
    -- database error.
    local affected = MySQL.update.await([[
        UPDATE players SET plate = ?
        WHERE id = ?
          AND NOT EXISTS (
            SELECT 1 FROM (SELECT id FROM players WHERE plate = ?) AS taken
            WHERE taken.id <> ?
          )
    ]], { text, profile.id, text, profile.id })

    if not affected or affected == 0 then
        return false, ("Plate '%s' is already taken."):format(text)
    end

    profile.plate = text          -- keep the cache honest; SaveProfile never writes this column
    return true, text
end

exports("SetPlate", SetPlate)

--- Clear a player's plate, freeing the text for someone else.
---@param source number
---@return boolean
local function ClearPlate(source)
    local ok, profile = pcall(function() return exports["spz-identity"]:GetProfile(source) end)
    if not ok or not profile then return false end

    MySQL.update.await("UPDATE players SET plate = NULL WHERE id = ?", { profile.id })
    profile.plate = nil
    return true
end


-- ── Command ─────────────────────────────────────────────────────────────────

local function notify(src, msg, t)
    TriggerClientEvent("ox_lib:notify", src, {
        title = "Plate", description = msg, type = t or "inform",
    })
end

RegisterCommand("plate", function(source, args)
    if source == 0 then return end   -- console has no profile

    local arg = table.concat(args or {}, " ")

    if arg == "" then
        local cur = GetPlate(source)
        notify(source, cur
            and ("Your plate is '%s'. /plate <text> to change it, /plate clear to remove it."):format(cur)
            or  "You have no custom plate. /plate <text> to set one (max 8 characters).", "inform")
        return
    end

    if arg:lower() == "clear" then
        ClearPlate(source)
        notify(source, "Custom plate removed. Spawned cars keep their default plate.", "success")
        return
    end

    local ok, result = SetPlate(source, arg)
    if ok then
        notify(source, ("Plate set to '%s'. It is applied to cars you spawn from now on."):format(result), "success")
    else
        notify(source, result, "error")
    end
end, false)
