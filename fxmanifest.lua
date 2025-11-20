fx_version 'cerulean'

game 'gta5'
author 'ESX-Framework - Linden - KASH'
description 'Allows players to have multiple characters on the same account.'
version '1.12.4'
lua54 'yes'

dependencies { 'es_extended', 'esx_context' }

shared_scripts { '@es_extended/imports.lua', '@es_extended/locale.lua', 'locales/*.lua', 'config.lua', '@ox_lib/init.lua', }

server_scripts {
    '@lele_networkprofiler/wrapper.lua',
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
    'server/modules/*.lua'
}

client_scripts {
   "client/modules/*.lua",
   'client/*.lua'
}

ui_page {'html/ui.html'}

files {
    'html/ui.html', 
    'html/**.*'
}

