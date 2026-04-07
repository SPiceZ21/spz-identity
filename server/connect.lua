-- server/connect.lua

local function OnPlayerConnected(source, deferrals)
    if not deferrals then
        print(("^1[spz-identity] Error: Deferrals object missing in SPZ:playerConnected for %s^7"):format(source))
        return
    end

    deferrals.update("Loading your driver profile...")

    local identifier = GetPlayerIdentifierByType(source, 'license')
    if not identifier then
        deferrals.done("Connection failed: Could not find license identifier.")
        return
    end

    -- 1. Try to get profile by identifier
    local profile = exports["spz-identity"]:GetProfileByIdentifier(identifier)
    
    -- 2. If no profile, create it
    if not profile then
        deferrals.update("Creating new driver profile...")
        profile = exports["spz-identity"]:CreateProfile(source, identifier, GetPlayerName(source))
    end

    if not profile then
        deferrals.done("Connection failed: Could not create/load driver profile.")
        return
    end

    -- 3. Check for ban
    if profile.banned then
        deferrals.done("You are banned from this server. Reason: " .. (profile.ban_reason or "No reason provided."))
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
    deferrals.done()

    -- 6. Signal that the player is ready (wait a tick to ensure cache is solid)
    SetTimeout(100, function()
        TriggerEvent("SPZ:playerReady", source, profile)
    end)
end

AddEventHandler("SPZ:playerConnected", OnPlayerConnected)
