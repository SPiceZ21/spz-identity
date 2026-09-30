-- server/main.lua

-- Schema (the players columns this resource reads) is owned by
-- spz-core/migrations/ — see 004_identity_columns.sql.

-- Handle character creation form from the NUI (spz-menu)
RegisterNetEvent("SPZ:characterCreated", function(gender, username, nation, raceNumber, plate)
    local source = source
    local profile = GetProfile(source)

    if not profile then
        TriggerClientEvent("SPZ:characterCreateCompleted", source, false, "Could not locate your active profile. Please reconnect.")
        return
    end

    if profile.first_time ~= 1 then
        TriggerClientEvent("SPZ:characterCreateCompleted", source, false, "You have already created a character.")
        return
    end

    -- 1. Validate the username string
    local isValid, errorMsg = SPZ.ValidateUsername(username)
    if not isValid then
        TriggerClientEvent("SPZ:characterCreateCompleted", source, false, errorMsg)
        return
    end

    -- 2. Verify uniqueness
    if SPZ.IsUsernameTaken(username) then
        TriggerClientEvent("SPZ:characterCreateCompleted", source, false, "That username is already taken by another racer.")
        return
    end

    -- 2b. Nation: ISO 3166-1 alpha-2, lowercase (drives the flag everywhere)
    nation = type(nation) == "string" and nation:lower() or nil
    if not nation or not nation:match("^%l%l$") then
        TriggerClientEvent("SPZ:characterCreateCompleted", source, false, "Pick your nation.")
        return
    end

    -- 2c. Race number: 1-999, unique across all racers.
    --
    -- Was 1-99 (F1 rules), which gives the whole server 99 identities and runs
    -- out. Three digits is the widest a number reads cleanly at on a livery.
    raceNumber = tonumber(raceNumber)
    if not raceNumber or raceNumber < 1 or raceNumber > 999 or raceNumber % 1 ~= 0 then
        TriggerClientEvent("SPZ:characterCreateCompleted", source, false, "Race number must be 1-999.")
        return
    end
    local taken = MySQL.scalar.await(
        "SELECT id FROM players WHERE race_number = ? AND id != ? LIMIT 1",
        { raceNumber, profile.id }
    )
    if taken then
        TriggerClientEvent("SPZ:characterCreateCompleted", source, false,
            ("#%d is already taken by another racer — pick a different number."):format(raceNumber))
        return
    end

    -- 2c. Plate: optional. Validated here so a bad one is reported on the
    -- creation screen alongside the other fields, rather than silently dropped
    -- and only noticed later when the first car spawns with a random plate.
    local plateText = nil
    if type(plate) == "string" and plate:gsub("%s", "") ~= "" then
        local ok, normalised = pcall(function()
            return exports["spz-identity"]:NormalisePlate(plate)
        end)
        if not ok or not normalised then
            TriggerClientEvent("SPZ:characterCreateCompleted", source, false,
                "That number plate is not allowed - up to 8 letters, numbers or spaces.")
            return
        end
        plateText = normalised
    end

    -- 3. Update memory state
    profile.username = username
    profile.gender = gender
    profile.nation = nation
    profile.race_number = raceNumber
    profile.first_time = 0
    profile.joinedAt = os.time() -- Start tracking playtime now that they are officially in

    -- 4. Flush changes to the physical DB so spz-core gets the fresh data immediately
    MySQL.update.await([[
        UPDATE players
        SET username = ?, gender = ?, nation = ?, race_number = ?, first_time = 0
        WHERE id = ?
    ]], {
        profile.username,
        profile.gender,
        profile.nation,
        profile.race_number,
        profile.id
    })

    -- 4b. Claim the plate, if one was chosen. Deliberately AFTER the main
    -- write and non-fatal: the character already exists at this point, so a
    -- plate someone else grabbed in the meantime must not fail creation and
    -- strand a player with no character. They are told, and can retry with
    -- /plate.
    if plateText then
        local pOk, pRes = pcall(function()
            return exports["spz-identity"]:SetPlate(source, plateText)
        end)
        if not pOk or pRes == false then
            TriggerClientEvent("ox_lib:notify", source, {
                title = "Plate",
                description = ("'%s' was already taken - set another with /plate."):format(plateText),
                type = "error",
            })
        end
    end

    -- 5. Republish the profile.
    --
    -- The statebags still say first_time = true at this point, and everything
    -- downstream gates on that: the client's own play-menu request checks
    -- LocalPlayer.state.firstTime and would refuse forever, leaving a player who
    -- had just finished creating a character with no way into the world. The
    -- memory and DB writes above are not visible until this runs.
    SyncProfileToStateBag(source, profile)

    local syncData = exports["spz-identity"]:GetSyncSubset(profile)
    TriggerClientEvent("SPZ:syncProfile", source, syncData)

    -- 6. Tell the interface we succeed
    TriggerClientEvent("SPZ:characterCreateCompleted", source, true, "Welcome to SPiceZ Racing!")

    -- 7. Announce the completed identity.
    --
    -- This is the FIRST playerReady a new player gets: the connect handshake
    -- deliberately withholds it for first-timers, because until now this profile
    -- had no username and every consumer of the event would have been handed a
    -- half-built one. The client asks for its route on its own once the
    -- appearance editor closes, so nothing is pushed at it here.
    SetTimeout(100, function()
        TriggerEvent("SPZ:characterReady", source)
        TriggerEvent("SPZ:playerReady", source, profile)
    end)
end)
