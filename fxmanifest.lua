fx_version 'cerulean'
game 'gta5'

description 'spz-identity — Player Profiles & Licensing'
version '1.0.0'

shared_scripts {
    'config.lua',
    'shared/licenses.lua',
    'shared/ranks.lua',
    'shared/events.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/connect.lua',
    'server/profile.lua',
    'server/licenses.lua',
    'server/ranks.lua',
    'server/ratings.lua',
    'server/crews.lua'
}

client_scripts {
    'client/main.lua',
    'client/sync.lua'
}

lua54 'yes'
