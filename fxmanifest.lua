
fx_version 'cerulean'
game 'gta5'
author 'Brozovec'
version '1.0'
lua54 'yes'

shared_scripts { 
	'@es_extended/imports.lua',
	'config.lua',
	'@ox_lib/init.lua',
	'@lb-phone'
}
	
client_scripts {
	'@PolyZone/client.lua',
	'@PolyZone/BoxZone.lua',
	'@PolyZone/CircleZone.lua',
	'client/*.lua',
	'config.lua',
}

server_scripts {
	'config.lua',
	'server/*.lua',
	'@oxmysql/lib/MySQL.lua'
}


server_exports {
    'GetConfigServer'
}

