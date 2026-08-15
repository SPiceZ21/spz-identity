-- config.lua (operator edits this)

Config = {}

-- License promotion requirements (override defaults if needed)
Config.LicenseRequirements = {
    [1] = { points = 500,  top3 = 5,  min_sr = 1.0 },  -- C → B
    [2] = { points = 1000, top3 = 8,  min_sr = 1.5 },  -- B → A
    [3] = { points = 2000, top3 = 12, min_sr = 2.0 },  -- A → S
}

-- SR changes per race event
Config.SRChanges = {
    finish        =  0.10,
    top3          =  0.20,
    personal_best =  0.05,
    dnf           = -0.50,
    timeout       = -0.25,
}

-- iRating starting value for new players
Config.DefaultIRating = 1500

-- Default SR for new players
Config.DefaultSR = 2.0

-- Profile cache batch save interval (seconds)
Config.SaveInterval = 60

-- Crew tag constraints
Config.CrewTagMinLength = 2
Config.CrewTagMaxLength = 4

-- Cooldown between crew join/leave actions (seconds). Set 0 to disable.
Config.CrewCooldownSeconds = 3600

-- ── Discord profile fetch ────────────────────────────────────────────────────
-- Pulls each player's Discord avatar/banner/name via the Discord API and stores
-- it on their profile (avatar_url/banner_url) + statebags (spz:avatar, spz:banner,
-- spz:discordName). Requires a Discord BOT TOKEN, set as a PRIVATE server convar
-- in server.cfg (never setr — it must not replicate to clients):
--     set spz_discord_token "YOUR_BOT_TOKEN"
Config.Discord = {
    enabled       = true,
    overwriteName = false,  -- true = use Discord global_name as the driver username when none is set
}
