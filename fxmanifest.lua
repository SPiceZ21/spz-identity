fx_version 'cerulean'
game 'gta5'

name 'spz-identity'
description 'SPiceZ-Core — Player profiles, licenses, crews'
version '1.5.0'
author 'SPiceZ-Core'

shared_scripts {
  'shared/licenses.lua',
  'shared/ranks.lua',
  'shared/events.lua',
}


server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'config.lua',
  'server/main.lua',
  'server/connect.lua',
  'server/citizen_id.lua',
  'server/username.lua',
  'server/profile.lua',
  'server/licenses.lua',
  'server/ranks.lua',
  'server/ratings.lua',
  'server/crews.lua',
}

client_scripts {
  'client/main.lua',
  'client/sync.lua',
  'client/character_creation.lua',
}

dependencies {
  'spz-lib',
  'spz-core',
  'oxmysql',
}

exports {
  'UpdateProfile',
  'HasLicense',
  'GetLicenseTier',
  'UnlockLicense',
  'GetCitizenId',
  'GetByCitizenId',
  'GetUsername',
}
