-- server/connect.lua

local function OnPlayerConnected(source, deferrals)
    if deferrals then
        deferrals.update("Loading your driver profile...")
    end

    local identifier = GetPlayerIdentifierByType(source, 'license')
    if not identifier then
        if deferrals then deferrals.done("Connection failed: Could not find license identifier.") end
        return
    end

    -- 1. Try to get profile by identifier
    local profile = exports["spz-identity"]:GetProfileByIdentifier(identifier)
    
    -- 2. If no profile, create it
    if not profile then
        if deferrals then deferrals.update("Creating new driver profile...") end
        profile = exports["spz-identity"]:CreateProfile(source, identifier)
    end

    if not profile then
        deferrals.done("Connection failed: Could not create/load driver profile.")
        return
    end

    -- 3. Check for ban
    if profile.banned then
        if deferrals then deferrals.done("You are banned from this server. Reason: " .. (profile.ban_reason or "No reason provided.")) end
        return
    end

    -- 4. Check for first time setup
    if profile.first_time == 1 then
        if deferrals then deferrals.done() end
        exports["spz-identity"]:GetProfile(source)
        SetTimeout(100, function()
            -- Both client and server events for flexibility
            TriggerClientEvent("SPZ:firstTimePlayer", source)
            TriggerEvent("SPZ:firstTimePlayer", source)
        end)
        return
    end

    -- 5. Warm session cache & Start playtime tracker
    profile.joinedAt = os.time()
    
    -- Ensure it's in the cache for the current source ID
    exports["spz-identity"]:GetProfile(source) 

    -- Send initial sync
    local syncData = exports["spz-identity"]:GetSyncSubset(profile)
    TriggerClientEvent("SPZ:syncProfile", source, syncData)

    -- 6. Finalize connection
    if deferrals then deferrals.done() end

    -- 7. Signal that the player is ready
    SetTimeout(100, function()
        TriggerEvent("SPZ:playerReady", source, profile)
    end)
end

AddEventHandler("SPZ:playerConnected", OnPlayerConnected)
