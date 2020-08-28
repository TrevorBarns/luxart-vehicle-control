fx_version 'adamant'
games { 'gta5' }

author 'TrevorBarns w/ credits see GitHub'
description 'A siren / emergency lights controller for FiveM.'
version '3.0.2'

ui_page('html/index.html')

files({
    'html/index.html',
	'html/sounds/*.ogg'
})

client_scripts {
	'settings.lua',
	'vehicles.lua',
	'client.lua'
}

server_script 'server.lua'