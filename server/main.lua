-- server/main.lua

-- Handle character creation form from the NUI (spz-menu)
RegisterNetEvent("SPZ:characterCreated", function(gender, username)
    local source = source
    local profile = exports['spz-identity']:GetProfile(source)

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

    -- 3. Update memory state
    profile.username = username
    profile.gender = gender
    profile.first_time = 0
    profile.joinedAt = os.time() -- Start tracking playtime now that they are officially in

    -- 4. Flush changes to the physical DB so spz-core gets the fresh data immediately 
    MySQL.update.await([[
        UPDATE players 
        SET username = ?, gender = ?, first_time = 0
        WHERE id = ?
    ]], {
        profile.username,
        profile.gender,
        profile.id
    })

    -- 5. Send initial profile sync block 
    local syncData = exports["spz-identity"]:GetSyncSubset(profile)
    TriggerClientEvent("SPZ:syncProfile", source, syncData)

    -- 6. Tell the interface we succeed
    TriggerClientEvent("SPZ:characterCreateCompleted", source, true, "Welcome to SPiceZ Racing!")

    -- 7. Advise spz-core to deploy the player to Freeroam properly
    SetTimeout(100, function()
        TriggerEvent("SPZ:playerReady", source, profile)
    end)
end)
