-- server/connect.lua
--
-- Profile loading, split across the two moments FiveM actually gives you.
--
-- The old version did everything in one pass at connect time and then pushed
-- the result straight to the client with TriggerClientEvent. That cannot work:
-- at `playerConnecting` / `playerJoining` the client is still on the loading
-- screen with none of its scripts running, so every event sent to it was
-- dropped on the floor. First-time players never received openCharacterCreation
-- and sat on a loading screen forever; returning players only ever got a menu
-- because spz-spawn happened to poll for one every 1.5 seconds.
--
-- It also took a `deferrals` argument that was never passed — the event that
-- invokes it carries only `source` — so every deferrals.update/done call in it
-- was dead code, and the connection was never actually held open for the DB.
--
-- The split now matches the lifecycle:
--
--   PrepareProfile(identifier)   during the deferral, before the player is in
--                                the session. DB only: look up or create, check
--                                the ban. No statebags (there is no Player yet)
--                                and no client events (there is no client yet).
--
--   AttachProfile(source)        when the CLIENT says it is running. Binds the
--                                prepared profile to the live source, writes the
--                                statebags, syncs, and fires SPZ:playerReady.
--
-- Nothing is ever sent to a client that has not announced itself.

-- Prepared profiles, keyed by license identifier rather than by source: the
-- source in playerConnecting is provisional and is not guaranteed to survive to
-- playerJoining, but the license is what identifies the human either way.
local Prepared = {}

-- ── Phase 1: during the deferral ──────────────────────────────────────────────

--- Load or create the profile for a connecting player.
--- Called by spz-core from inside the connection deferral, so it is allowed to
--- block: the player is held on "Loading your driver profile..." until it
--- returns, which is the entire point of a deferral.
---
--- @param identifier string license: identifier
--- @return table result { ok = boolean, reason = string?, firstTime = boolean? }
local function PrepareProfile(identifier)
    if not identifier then
        return { ok = false, reason = 'Could not find your Rockstar license identifier.' }
    end

    local profile = GetProfileByIdentifier(identifier)

    if not profile then
        -- CreateProfile wants a source for its statebag sync, which does not
        -- exist yet. Pass nil: the DB row is what matters here, and the
        -- statebags are written later by AttachProfile.
        profile = CreateProfile(nil, identifier)
    end

    if not profile then
        return { ok = false, reason = 'Could not create or load your driver profile. Try again shortly.' }
    end

    if profile.banned then
        return { ok = false, reason = 'You are banned from this server. Reason: ' .. (profile.ban_reason or 'No reason provided.') }
    end

    profile.preparedAt   = os.time()
    Prepared[identifier] = profile

    return { ok = true, firstTime = profile.first_time == 1 }
end

exports('PrepareProfile', PrepareProfile)

-- ── Phase 2: when the client announces itself ─────────────────────────────────

--- Bind a prepared profile to a live source and make it visible to everything
--- else. Idempotent: a client that retries its handshake gets the same answer
--- rather than a second SPZ:playerReady.
---
--- @param source number
--- @return table|nil profile
local function AttachProfile(source)
    if Player(source).state.identityReady then
        return GetProfile(source)
    end

    local identifier = GetPlayerIdentifierByType(source, 'license')
    local profile    = identifier and Prepared[identifier] or nil

    -- No prepared profile means the deferral did not run for this player — a
    -- resource restart mid-session is the usual cause. Fall back to a direct
    -- load rather than leaving them with nothing. Checked in this order so the
    -- common path never pays for the fallback's database read.
    if not profile then
        profile = GetProfile(source)
    end

    if not profile then
        print(('^1[spz-identity] No profile available for source %s — cannot attach^7'):format(tostring(source)))
        return nil
    end

    profile.joinedAt = profile.joinedAt or os.time()

    -- Bind to this source and publish. SyncProfileToStateBag also sets
    -- identityReady, which is what marks the handshake as complete.
    SetProfileForSource(source, profile)
    SyncProfileToStateBag(source, profile)

    TriggerClientEvent('SPZ:syncProfile', source, GetSyncSubset(profile))

    -- SPZ:playerReady means "this player has a usable identity", and seven
    -- resources act on it — nametags, crew radio, rivals, race reconnect,
    -- Discord. A first-time player has no username yet, so firing it here would
    -- hand all of them a half-built profile and then fire again after character
    -- creation, doubling every side effect. For them, character creation is what
    -- completes the identity, and that path fires it.
    if profile.first_time ~= 1 then
        TriggerEvent('SPZ:playerReady', source, profile)
    end

    if identifier then Prepared[identifier] = nil end

    return profile
end

exports('AttachProfile', AttachProfile)

-- ── Cleanup ───────────────────────────────────────────────────────────────────
--
-- A player who passes the deferral and then never joins (alt-F4 at the loading
-- screen) would otherwise leave their prepared profile in memory forever.

AddEventHandler('playerDropped', function()
    local identifier = GetPlayerIdentifierByType(source, 'license')
    if identifier then Prepared[identifier] = nil end
end)

CreateThread(function()
    while true do
        Wait(300000)  -- 5 min
        local now = os.time()
        for identifier, profile in pairs(Prepared) do
            if now - (profile.preparedAt or now) > 600 then
                Prepared[identifier] = nil
            end
        end
    end
end)
