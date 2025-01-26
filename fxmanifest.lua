fx_version 'cerulean'
game 'gta5'

author 'Potyh'
description 'Trabajo de camionero'
version '1.0.0'

client_scripts {
    'config.lua',
    'client/delivery_client.lua'
}

server_scripts {
    'server/delivery_server.lua'
}

shared_script 'config.lua'

dependencies {
    'qb-core',
    'qb-target',
    'origen_inventory'
}