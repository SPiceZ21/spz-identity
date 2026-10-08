fx_version 'cerulean'
game 'gta5'

name 'spz-identity'
description 'SPiceZ-Core — Player profiles, licenses, crews'
version '1.8.1'
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
  'server/plates.lua',
  'server/licenses.lua',
  'server/ranks.lua',
  'server/crews.lua',
  'server/discord.lua',
}

client_scripts {
  'client/main.lua',
  'client/sync.lua',
  'client/character_creation.lua',
}

dependencies {
  'ox_lib',
  'spz-core',
  'oxmysql',
}

