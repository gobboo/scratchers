fx_version 'cerulean'
games { 'gta5' }

author 'Gobbo'
description 'Gambling addicted scratchers yay'
version '1.0.0'

lua54 'yes'

dependencies {
	'ox_lib',
	'ox_inventory',
}

ui_page 'web/dist/index.html'

shared_scripts {
	'@ox_core/lib/init.lua',
	'modules/**/sh_*.lua'
}

server_scripts {
	'modules/**/sv_*.lua'
}

client_scripts {
	'modules/**/cl_*.lua'
}

files {
	'web/dist/**/*',
	'data/**/*.lua'
}