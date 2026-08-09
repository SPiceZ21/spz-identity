# spz-identity

> Player profiles, citizen IDs, licenses, ranks, crews · `v1.5.0`

## Overview

`spz-identity` is the player data layer. It resolves a connecting player to a profile,
runs first-time character creation, and owns usernames, citizen IDs, license tiers, rank
values, ratings and crew membership. Other modules read player data through its exports
rather than touching the `players` table.

## Connection flow

1. `spz-core` fires `SPZ:playerConnected`.
2. Identity looks the player up by license. No profile → `CreateProfile` with
   `first_time = 1`.
3. Returning player → cache warmed, `SPZ:playerReady` fires.
4. New player → `SPZ:openCharacterCreation` fires instead; `SPZ:playerReady` is withheld.
5. Creation submits gender, username, nation flag and a race number (1–99, validated
   unique server-side) → `first_time = 0`, then `SPZ:characterReady` and `SPZ:playerReady`.

Nation flag and race number are shown on nametags and in the standings tower. Flags ship
as local assets — no CDN.

## Structure

| Side | File | Purpose |
|---|---|---|
| Shared | `shared/licenses.lua` | License tier definitions |
| Shared | `shared/ranks.lua` | Rank thresholds and names |
| Shared | `shared/events.lua` | Event name constants |
| Server | `config.lua` | Identity configuration |
| Server | `server/main.lua` | Entry point, export registration |
| Server | `server/connect.lua` | Connect handler and profile resolution |
| Server | `server/citizen_id.lua` | Citizen ID generation and lookup |
| Server | `server/username.lua` | Username validation and uniqueness |
| Server | `server/profile.lua` | Profile read/write and caching |
| Server | `server/licenses.lua` | License state and unlock history |
| Server | `server/ranks.lua` | Rank calculation |
| Server | `server/ratings.lua` | SR / iRating persistence |
| Server | `server/crews.lua` | Crew creation and membership |
| Client | `client/main.lua` | Client-side identity init |
| Client | `client/sync.lua` | Profile subset sync |
| Client | `client/character_creation.lua` | First-time creation NUI bridge |
| UI | `ui/` | Character creation form (plain HTML/CSS/JS) |

## Exports

| Group | Exports |
|---|---|
| Profile | `GetProfile` · `CreateProfile` · `UpdateProfile` · `SaveProfile` · `GetClientProfile` · `GetSyncSubset` · `SetPlayerState` |
| Identity | `GetCitizenId` · `GetByCitizenId` · `GetUsername` · `GetPlatformName` · `GetPlaytime` |
| Licenses | `HasLicense` · `GetLicenseTier` · `UnlockLicense` · `GetLicenseHistory` |
| Ranks | `GetRankName` |
| Crews | `CreateCrew` · `JoinCrew` · `LeaveCrew` · `GetCrew` · `GetCrewTag` · `GetOnlineCrewMembers` · `GetCrewCooldownSeconds` |
| Admin | `BanPlayer` |

```lua
local profile = exports['spz-identity']:GetProfile(source)
```

## Events

| Event | Side | Meaning |
|---|---|---|
| `SPZ:openCharacterCreation` | Client | New player — open the creation form |
| `SPZ:characterCreated` | Server | NUI submitted gender + username |
| `SPZ:characterReady` | Server | Profile initialised |
| `SPZ:playerReady` | Server | Player data is safe to read |

## Schema

Owned by `spz-core/migrations/`. Key `players` columns:

| Column | Type | Default | Meaning |
|---|---|---|---|
| `id` | INT | auto | Primary key |
| `username` | VARCHAR | NULL | Unique racer name |
| `gender` | INT | NULL | 0 = male, 1 = female |
| `first_time` | INT | 1 | Character creation pending |
| `license_tier` | INT | 0 | 0 = C, 1 = B, 2 = A, 3 = S |

## Dependencies

`ox_lib` · `spz-core` · `oxmysql`

---

Part of [SPiceZ-Core](../README.md) · GPL-3.0
