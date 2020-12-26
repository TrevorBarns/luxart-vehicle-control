fx_version 'adamant'
games { 'gta5' }

author 'TrevorBarns w/ credits see GitHub'
description 'A siren / emergency lights controller for FiveM.'
version '3.1.5'
compatible '3.1.5'

ui_page('html/index.html')

files({
    'html/index.html',
	'html/sounds/*.ogg',
	'html/sounds/**/*.ogg'
})

	
client_scripts {
	'RMenu.lua',
    'menu/RageUI.lua',
    'menu/Menu.lua',
    'menu/MenuController.lua',
    'components/*.lua',
    'menu/elements/*.lua',
    'menu/items/*.lua',
    'menu/panels/*.lua',
    'menu/windows/*.lua',
	'SETTINGS.lua',
	'VEHICLES.lua',
	'client.lua',
	'menu.lua'
}

server_script {
	'server.lua'
}