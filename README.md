# spz-identity

> Player profiles, licences, crews and vanity plates.

![version](https://img.shields.io/badge/version-1.8.1-ff6200) ![SPiceZ-Core](https://img.shields.io/badge/SPiceZ--Core-beta-18181b)

## Overview

Creates and caches each player's profile on join and exposes it to every other module through exports and statebags. Also owns driver licences (class unlocks), the crew backend and personal number plates.

## Features

- Profile created on first join, cached for the session
- Licence tiers that gate car classes
- Crew create / join / leave backend (UI is spz-crew)
- Personal vanity plates
- Optional Discord linking

## Requirements

| Resource | Type |
|---|---|
| `ox_lib` | third-party |
| `spz-core` | SPiceZ module |
| `oxmysql` | third-party |

## Installation

Included in the [txAdmin recipe](https://github.com/SPiceZ21/spz-txrecipe). Manual install:

1. Download `spz-identity` from GitHub (latest release, or the repository) into your `resources` folder.
2. Add to `server.cfg`, after its requirements:

```cfg
ensure spz-identity
```

## Configuration

- `config.lua`

See the file for every option.

## Commands

| Command | Who | Description |
|---|---|---|
| `/plate` | player | Set your personal plate |
| `/refreshdiscord` | player | Re-sync your Discord name/avatar (admins: for a player id) |

## Exports

| Export | Side |
|---|---|
| `AttachProfile` | server |
| `CreateCrew` | server |
| `GetClientProfile` | client |
| `GetCrew` | server |
| `GetCrewCooldownSeconds` | server |
| `GetOnlineCrewMembers` | server |
| `GetPlate` | server |
| `GetPlatformName` | server |
| `GetPlaytime` | server |
| `GetProfile` | server |
| `GetRankName` | server |
| `GetSyncSubset` | server |
| `JoinCrew` | server |
| `LeaveCrew` | server |
| `NormalisePlate` | server |
| `PrepareProfile` | server |
| `SetPlate` | server |
| `UnlockLicense` | server |
| `UpdateProfile` | server |

```lua
exports["spz-identity"]:AttachProfile(...)
```

---

Part of **SPiceZ-Core** — [documentation](https://github.com/SPiceZ21/Docs) · [all modules](https://github.com/SPiceZ21/Docs/blob/main/modules/README.md)
