-- server/connect.lua

local function OnPlayerConnected(source, deferrals)
    if deferrals then
        deferrals.update("Loading your driver profile...")
    end

    local identifier = GetPlayerIdentifierByType(source, 'license')
    print("^2[spz-identity] DEBUG: Processing connection for source " .. tostring(source) .. " (Identifier: " .. tostring(identifier) .. ")^7")
    
    if not identifier then
        if deferrals then deferrals.done("Connection failed: Could not find license identifier.") end
        return
    end

    -- 1. Try to get profile by identifier
    print("^2[spz-identity] DEBUG: Looking up profile...^7")
    local profile = GetProfileByIdentifier(identifier)
    print("^2[spz-identity] DEBUG: Profile lookup completed. Found: " .. tostring(profile ~= nil) .. "^7")
    
    -- 2. If no profile, create it
    if not profile then
        if deferrals then deferrals.update("Creating new driver profile...") end
        profile = CreateProfile(source, identifier)
    end

    if not profile then
        if deferrals then 
            deferrals.done("Connection failed: Could not create/load driver profile.")
        else
            DropPlayer(source, "Connection failed: Could not create/load driver profile.")
        end
        return
    end

    -- 3. Check for ban
    if profile.banned then
        if deferrals then 
            deferrals.done("You are banned from this server. Reason: " .. (profile.ban_reason or "No reason provided.")) 
        else
            DropPlayer(source, "You are banned from this server. Reason: " .. (profile.ban_reason or "No reason provided."))
        end
        return
    end

    -- 4. Check for first time setup
    if profile.first_time == 1 then
        if deferrals then deferrals.done() end
        GetProfile(source)
        SetTimeout(100, function()
            local suggested = exports["spz-identity"]:GetPlatformName(source)
            TriggerClientEvent("SPZ:openCharacterCreation", source, { suggested = suggested })
        end)
        return
    end

    -- 5. Warm session cache & Start playtime tracker
    profile.joinedAt = os.time()
    
    -- Ensure it's in the cache for the current source ID
    GetProfile(source) 

    -- Send initial sync
    local syncData = GetSyncSubset(profile)
    TriggerClientEvent("SPZ:syncProfile", source, syncData)

    -- 6. Finalize connection
    if deferrals then deferrals.done() end

    -- 7. Signal that the player is ready (server-side modules)
    SetTimeout(100, function()
        print("^2[spz-identity] DEBUG: Firing SPZ:playerReady for source " .. tostring(source) .. "^7")
        TriggerEvent("SPZ:playerReady", source, profile)
    end)

    -- 8. Tell the client they are fully loaded so UI can open
    SetTimeout(300, function()
        TriggerClientEvent("SPZ:identityReady", source, {
            citizenId   = profile.citizen_id,
            username    = profile.username,
            rank        = profile.rank,
            licenseTier = profile.license_tier or 0,
        })
    end)
end

AddEventHandler("SPZ:playerConnected", OnPlayerConnected)
