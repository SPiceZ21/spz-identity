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
        profile = exports["spz-identity"]:CreateProfile(source, identifier, GetPlayerName(source))
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

    -- 4. Warm session cache & Start playtime tracker
    -- Note: CreateProfile already added it to cache if it was a new player.
    -- If it's an existing player, we need to ensure it's in ProfileCache for this source.
    -- Let's add a LoadProfile into cache mechanism or just use GetProfile(source)
    -- which forces a DB read + cache if missing.
    
    profile.joinedAt = os.time()
    
    -- Ensure it's in the cache for the current source ID
    -- We can call GetProfile(source) to trigger the cache fill if it's not there
    exports["spz-identity"]:GetProfile(source) 

    -- Send initial sync
    local syncData = exports["spz-identity"]:GetSyncSubset(profile)
    TriggerClientEvent("SPZ:syncProfile", source, syncData)

    -- 5. Finalize connection
    if deferrals then deferrals.done() end

    -- 6. Signal that the player is ready (wait a tick to ensure cache is solid)
    SetTimeout(100, function()
        TriggerEvent("SPZ:playerReady", source, profile)
    end)
end

AddEventHandler("SPZ:playerConnected", OnPlayerConnected)
