<div align="center">

<img src="https://github.com/SPiceZ21/spz-core-media-kit/raw/main/Banner/Banner%232.png" alt="SPiceZ-Core Banner" width="100%"/>

<br/>

# spz-identity

### Player Profiles & Driver Licensing

*The core data layer for driver progression, license tiers, rankings, and crew groups. Every other module that touches player data waits for this one.*

<br/>

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-orange.svg?style=flat-square)](https://www.gnu.org/licenses/gpl-3.0)
[![FiveM](https://img.shields.io/badge/FiveM-Compatible-orange?style=flat-square)](https://fivem.net)
[![Lua](https://img.shields.io/badge/Lua-5.4-blue?style=flat-square&logo=lua)](https://lua.org)
[![Status](https://img.shields.io/badge/Status-In%20Development-green?style=flat-square)]()

</div>

---

## Overview

`spz-identity` is the first module to touch the database after a player connects. It loads (or creates) the player profile, validates their license status, and fires `SPZ:playerReady` — the signal that all other modules use to safely begin interacting with that player.

It maintains a high-performance in-RAM session cache for zero-latency lookups during active races, with batch DB saves every 60 seconds and on disconnect.

> **Never use `SPZ:playerConnected` directly** — always wait for `SPZ:playerReady` from this module.

---

## Features

- **Profile Management** — CRUD operations with an optimized session cache and batched background DB saves. Includes soft-delete ban support.
- **Driver License System** — Four tiered classes (C → B → A → S) that gate race access. Promotion requires simultaneous satisfaction of points, finish count, and Safety Rating.
- **Dynamic Ranking** — Points-based championship standing within each license class. Ranks reset per season; license tiers never do.
- **Safety Rating (SR)** — Consistency score from 0.00 to 5.00. Drops on disconnect/DNF, rises on clean finishes and top-3 results. Acts as a promotion gate.
- **iRating (Skill)** — Elo-style raw skill metric starting at 1500. Used for future matchmaking within a class.
- **Crew System** — Player groups with 2–4 character uppercase tags shown in race overlays, leaderboards, and post-race stats.
- **Client-Side Sync** — Safe profile subset pushed to the client on connect and on every update. NUI reads this directly with no server round-trip.

---

## Dependencies

| Resource | Version | Role |
|---|---|---|
| `spz-lib` | 1.0.0+ | Callbacks, notify, logger |
| `spz-core` | 1.0.0+ | Event bus, session cache, state machine |
| `oxmysql` | 2.0.0+ | Profile persistence |

---

## Installation

1. Clone into your `resources/[spz]/` folder.
2. Import `server/db/schema.sql` into your database.
3. Add to `server.cfg` after dependencies:

```cfg
ensure spz-lib
ensure spz-core
ensure spz-identity
```

---

## Connect Flow

```
playerConnecting
  → extract license identifier
  → query players table
      ├── row found    → load into cache, warm session
      ├── no row       → CreateProfile with defaults (Class C, SR 2.0, iRating 1500)
      └── banned = 1   → deferrals.done("You are banned: [reason]")
  → fire SPZ:playerReady(source, profile)
```

---

## License Tiers

| Tier | Class | Unlock Requirements |
|---|---|---|
| 0 | **C — Street** | Default — all new players start here |
| 1 | **B — Sport** | 500 Class C pts + 5 top-3 finishes + SR ≥ 1.0 |
| 2 | **A — Pro** | 1000 Class B pts + 8 top-3 finishes + SR ≥ 1.5 |
| 3 | **S — Elite** | 2000 Class A pts + 12 top-3 finishes + SR ≥ 2.0 |

All three gates must be satisfied simultaneously for promotion to trigger.

---

## Exports Reference

### Server-Side

```lua
-- Profile
exports["spz-identity"]:GetProfile(source)                      -- full session profile
exports["spz-identity"]:GetProfileByIdentifier(identifier)      -- offline DB lookup
exports["spz-identity"]:UpdateProfile(source, { name?, rank?, license_tier? })
exports["spz-identity"]:SaveProfile(source)                     -- immediate DB flush
exports["spz-identity"]:BanPlayer(source, reason)               -- soft-delete (banned=1)

-- Licensing
exports["spz-identity"]:GetLicenseTier(source)                  -- 0–3
exports["spz-identity"]:HasLicense(source, tier)                -- bool
exports["spz-identity"]:UnlockLicense(source, tier, method)     -- method: "xp_threshold" | "admin_grant"
exports["spz-identity"]:GetLicenseHistory(source)               -- [{ tier, ts, method }]

-- Crews
exports["spz-identity"]:CreateCrew(source, name, tag)           -- tag: 2-4 uppercase chars
exports["spz-identity"]:JoinCrew(source, crewId)
exports["spz-identity"]:LeaveCrew(source)
exports["spz-identity"]:GetCrewTag(source)                      -- "[SPZ]" or nil
exports["spz-identity"]:GetCrewMembers(crewId)                  -- [source, ...]
```

### Client-Side

```lua
-- Synchronous local mirror — no server round-trip
exports["spz-identity"]:GetClientProfile()
-- Returns: { name, rank, license_tier, crew_tag, xp, class_points, sr, i_rating }
```

---

## Key Events

| Event | Direction | Payload | When |
|---|---|---|---|
| `SPZ:playerReady` | Server | `source, profile` | Profile loaded and safe to use |
| `SPZ:identityReady` | Client | `profileSubset` | Client sync complete — NUI can start |
| `SPZ:syncProfile` | Client | `changedKeys` | Profile updated server-side |
| `SPZ:licenseUnlocked` | Server + Client | `source, tier, tierName` | Promotion confirmed |

---

## Profile Object Shape

```lua
{
  id             = number,
  identifier     = string,    -- "license:xxxx"
  name           = string,
  playtime       = number,    -- seconds
  xp             = number,
  class_points   = number,    -- resets per season
  alltime_points = number,    -- never resets
  sr             = number,    -- Safety Rating 0.00–5.00
  i_rating       = number,    -- Elo-style skill rating (starts at 1500)
  rank           = string,    -- e.g. "B-3"
  license_tier   = number,    -- 0=C 1=B 2=A 3=S
  crew_id        = number,
  crew_tag       = string,    -- "[SPZ]" or nil
  banned         = bool,
}
```

---

<div align="center">

*Part of the [SPiceZ-Core](https://github.com/SPiceZ-Core) ecosystem*

**[Docs](https://github.com/SPiceZ-Core/spz-docs) · [Discord](https://discord.gg/) · [Issues](https://github.com/SPiceZ-Core/spz-identity/issues)**

</div>
