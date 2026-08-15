-- server/discord.lua
-- Fetch a player's Discord profile (avatar, banner, name) via the Discord API and
-- merge it onto their SPiceZ profile so every UI (nametag, crew, spawn, leaderboard)
-- can show a real avatar. The bot token is read from a PRIVATE server convar:
--     set spz_discord_token "YOUR_BOT_TOKEN"
-- Use `set` (NOT setr) — the token must never replicate to clients.

local API = 'https://discord.com/api/v10'

local function token()
    return GetConvar('spz_discord_token', '')
end

-- Pull the numeric Discord id from the player's identifiers (discord:123456789).
local function discordIdOf(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        local d = id:match('^discord:(%d+)$')
        if d then return d end
    end
    return nil
end

local function avatarUrl(data)
    if data.avatar and data.avatar ~= '' then
        local ext = data.avatar:sub(1, 2) == 'a_' and 'gif' or 'png'
        return ('https://cdn.discordapp.com/avatars/%s/%s.%s?size=256'):format(data.id, data.avatar, ext)
    end
    -- Default avatar: new usernames (discriminator "0") key off the id, legacy off
    -- the 4-digit discriminator.
    local idx
    if not data.discriminator or data.discriminator == '0' then
        idx = math.floor((tonumber(data.id) or 0) / 4194304) % 6
    else
        idx = (tonumber(data.discriminator) or 0) % 5
    end
    return ('https://cdn.discordapp.com/embed/avatars/%d.png'):format(idx)
end

local function bannerUrl(data)
    if not data.banner or data.banner == '' then return nil end
    local ext = data.banner:sub(1, 2) == 'a_' and 'gif' or 'png'
    return ('https://cdn.discordapp.com/banners/%s/%s.%s?size=600'):format(data.id, data.banner, ext)
end

-- Fetch + apply. Safe to call repeatedly (e.g. /refreshdiscord).
local function FetchDiscordProfile(src)
    if not Config.Discord or Config.Discord.enabled == false then return end
    src = tonumber(src)
    if not src or src <= 0 then return end

    local tok = token()
    if tok == '' then
        print('^3[spz-identity] Discord fetch skipped — spz_discord_token convar not set.^7')
        return
    end

    local did = discordIdOf(src)
    if not did then return end  -- player has no Discord identifier (Discord not running)

    PerformHttpRequest(API .. '/users/' .. did, function(status, body)
        if status ~= 200 or not body then
            print(('^3[spz-identity] Discord fetch failed for src %s (HTTP %s)^7'):format(src, tostring(status)))
            return
        end

        local ok, data = pcall(json.decode, body)
        if not ok or type(data) ~= 'table' or not data.id then return end

        -- Player may have left while the request was in flight.
        if GetPlayerName(src) == nil then return end

        local avatar = avatarUrl(data)
        local banner = bannerUrl(data)
        local dname  = data.global_name or data.username

        local changes = { avatar_url = avatar }
        if banner then changes.banner_url = banner end
        if Config.Discord.overwriteName and dname and dname ~= '' then
            local prof = exports['spz-identity']:GetProfile(src)
            if prof and (not prof.username or prof.username == '' or prof.username == '**INVALID**') then
                changes.username = dname
            end
        end
        exports['spz-identity']:UpdateProfile(src, changes)

        -- Push to the statebags the UIs actually read, and re-run the nametag sync.
        local st = Player(src).state
        st:set('spz:avatar', avatar, true)
        st:set('avatarUrl', avatar, true)
        if banner then st:set('spz:banner', banner, true) end
        st:set('spz:discordId', did, true)
        st:set('spz:discordName', dname, true)
        TriggerEvent('SPZ:syncProfile', src)

        print(('^2[spz-identity] Discord profile loaded for src %s (%s)^7'):format(src, dname or '?'))
    end, 'GET', '', {
        ['Authorization'] = 'Bot ' .. tok,
        ['Content-Type']  = 'application/json',
    })
end

-- Fetch once the profile is ready.
AddEventHandler('SPZ:playerReady', function(source)
    FetchDiscordProfile(source)
end)

-- Manual refresh (self, or a target id for admins).
RegisterCommand('refreshdiscord', function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, 'spz.admin') then return end
    local target = tonumber(args[1]) or source
    if target > 0 then FetchDiscordProfile(target) end
end, false)

exports('FetchDiscordProfile', FetchDiscordProfile)
