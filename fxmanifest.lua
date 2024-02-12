fx_version "adamant"
game "gta5"

server_scripts {
	'config.lua',
	-- 'server.lua',
}

client_scripts {
	'config.lua',
	'client.lua',
}

ui_page "html/index.html"

files {
	'html/**/*',
	'peds.meta'
}

exports {
	'getStatusDungeon'
}
	
-- data_file 'PED_METADATA_FILE' 'peds.meta'