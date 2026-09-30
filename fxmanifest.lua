fx_version 'cerulean'

game 'gta5'

description 'Xperience - XP Ranking System for FiveM'

author 'Mobius1'

version '0.2.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'common/utils.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/commands.lua'
}

client_scripts {
    'client/main.lua',
}

ui_page 'ui/ui.html'

files {
    'ui/ui.html',
    'ui/fonts/*.ttf',
    'ui/css/*.css',
    'ui/js/*.js'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
