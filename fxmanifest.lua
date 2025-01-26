fx_version 'cerulean'
game 'gta5'

author 'Potyh'
description 'Trabajo de camionero'
version '1.0.0'

-- Archivos del cliente y servidor
client_scripts {
    'config.lua',
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

shared_script 'config.lua'
