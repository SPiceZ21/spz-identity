<div align="center">
  <img src="https://github.com/SPiceZ21/spz-core-media-kit/raw/main/Banner/Banner%232.png" alt="SPiceZ-Core Banner" width="100%">

  # spz-identity — Player Profiles & Licensing
  
  `SPiceZ-Core` | **Identity Module**
  
  *The core data layer for driver progression, ranking, and social groups.*
</div>

---

## 1. Overview

`spz-identity` is the foundation of the SPiceZ-Core ecosystem. It manages all persistent driver data, including licensing tiers, championship rankings, and crew memberships. Designed for high performance, it maintains an in-RAM session cache to ensure zero-latency lookups during races.

### Key Responsibilities:
- **Profile Management**: CRUD operations with an optimized session cache and batch-save system.
- **License System**: Tiered access (C → B → A → S) to racing classes.
- **Dynamic Ranking**: Points-based standing within each license class.
- **Safety & Skill Rating**: iRacing-inspired dual metric system (SR and iRating).
- **Crew Integration**: Group identification with tags shown in race overlays.
- **Client-Side Sync**: Real-time profile mirror for HUD and NUI components.

---

## 2. Dependencies

| Resource | Version | Role |
|---|---|---|
| `spz-lib` | 1.0.0+ | Callbacks, Notify, logger |
| `spz-core` | 1.0.0+ | Event bus & cache manager |
| `oxmysql` | 2.0.0+ | SQL Database operations |

---

## 3. Installation

1. Ensure all dependencies are installed.
2. Clone this repository into your `resources/[spz]` folder.
3. Import `server/db/schema.sql` into your database.
4. Add the following to your `server.cfg`:

```cfg
ensure spz-lib
ensure spz-core
ensure spz-identity
```

---

## 4. Developer Reference

### Server-Side Exports

```lua
-- Profile lookups
exports["spz-identity"]:GetProfile(source)             -- Current session profile
exports["spz-identity"]:GetProfileByIdentifier(id)     -- Database lookup (offline)

-- Updates & Persistence
exports["spz-identity"]:UpdateProfile(source, changes) -- Partial profile update
exports["spz-identity"]:SaveProfile(source)             -- Immediate DB flush
exports["spz-identity"]:BanPlayer(source, reason)       -- Soft-delete & block

-- Licensing
exports["spz-identity"]:GetLicenseTier(source)         -- 0 (C) through 3 (S)
exports["spz-identity"]:UnlockLicense(source, tier, "method")

-- Crews
exports["spz-identity"]:GetCrewTag(source)             -- e.g., "[SPZ]"
```

### Client-Side Exports

```lua
-- Sync Access
exports["spz-identity"]:GetClientProfile()            -- Synchronous local mirror
```

---

## 5. License

Part of the **SPiceZ-Core** private racing framework.  
*© 2026 SPiceZ Development Team. All rights reserved.*
