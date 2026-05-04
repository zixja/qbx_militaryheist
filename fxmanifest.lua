fx_version 'cerulean'
game 'gta5'

author 'T2 Development'
description 'QBox Military Base Heist'
version '1.1.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/utils.lua'
}

client_scripts {
    'client/main.lua',
    'client/guards.lua',
    'client/loot.lua'
}

server_scripts {
    'server/cooldown.lua',
    'server/rewards.lua',
    'server/main.lua'
}
