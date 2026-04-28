<div align="center">

<img src="https://github.com/SPiceZ21/spz-core-media-kit/raw/main/Banner/Banner%232.png" alt="SPiceZ-Core Banner" width="100%"/>

<br/>

# spz-identity
> Player profiles, licenses, crews · `v1.3.4`

## Scripts

| Side   | File                       | Purpose                                          |
| ------ | -------------------------- | ------------------------------------------------ |
| Shared | `shared/licenses.lua`      | License tier definitions and constants           |
| Shared | `ranks.lua`                | Rank definitions and thresholds                  |
| Shared | `events.lua`               | Shared event name constants                      |
| Server | `@oxmysql`                 | oxmysql database library import                  |
| Server | `config.lua`               | Identity configuration                           |
| Server | `server/main.lua`          | Entry point, event and export registration       |
| Server | `connect.lua`              | Player connect handler and initial data load     |
| Server | `citizen_id.lua`           | Citizen ID generation and lookup                 |
| Server | `username.lua`             | Username assignment and validation               |
| Server | `profile.lua`              | Player profile read/write                        |
| Server | `licenses.lua`             | License state persistence and updates            |
| Server | `ranks.lua`                | Rank calculation and promotion                   |
| Server | `ratings.lua`              | Player rating (iRating/SR) persistence           |
| Server | `crews.lua`                | Crew membership management                       |
| Client | `client/main.lua`          | Client-side identity initialization              |
| Client | `client/sync.lua`          | State sync to server                             |

## Exports

| Export            | Description                                        |
| ----------------- | -------------------------------------------------- |
| `GetProfile`      | Retrieve a player's full profile                   |
| `UpdateProfile`   | Update profile fields for a player                 |
| `GetPlayerState`  | Get a player's current state object                |
| `SetPlayerState`  | Set a player's state value                         |
| `HasLicense`      | Check whether a player holds a specific license    |
| `GetLicenseTier`  | Get the tier level of a player's license           |
| `UnlockLicense`   | Grant a license to a player                        |
| `GetCitizenId`    | Get a player's citizen ID                          |
| `GetByCitizenId`  | Look up a player by citizen ID                     |
| `GetUsername`     | Get a player's display username                    |
| `IsFirstTime`     | Check if this is the player's first connection     |

## Dependencies
- spz-lib
- spz-core
- oxmysql

## CI
Built and released via `.github/workflows/release.yml` on push to `main`.
