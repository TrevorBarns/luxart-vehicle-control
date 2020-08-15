resource_manifest_version '77731fab-63ca-442c-a67b-abc70f28dfa5'
ui_page('html/index.html')

files({
    'html/index.html',
	'html/sounds/On.ogg',
	'html/sounds/Upgrade.ogg',
	'html/sounds/Off.ogg',
	'html/sounds/Downgrade.ogg'
})

client_script 'client.lua'
server_script 'server.lua'