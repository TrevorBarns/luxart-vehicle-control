resource_manifest_version '05cfa83c-a124-4cfa-a768-c24a5811d8f9'
ui_page('html/index.html')
files({
    'html/index.html',
	'html/sounds/On.ogg',
	'html/sounds/Upgrade.ogg',
	'html/sounds/Off.ogg',
	'html/sounds/Downgrade.ogg',
	'html/sounds/Hazards_On.ogg',
	'html/sounds/Hazards_Off.ogg',
	'html/sounds/Key_Lock.ogg',
	'html/sounds/Locked_Press.ogg'
})

client_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'