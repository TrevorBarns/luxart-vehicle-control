--------------------EXTRA INTEGRATION SETTINGS---------------------
ec_masterswitch = true
--	Determines if extra_integration plugin can be activated.
allow_custom_controls = true
--	Enabled/Disables menu which allows for custom controls to be set.
--[[ Documentation / Wiki: https://github.com/TrevorBarns/luxart-vehicle-control/wiki/Extra-Controls ]]

EXTRA_CONTROLS = {
	['DEFAULT'] = { 
			--  	{ '<name>, {<extras table>}, <default combo>, <key> }
			{ Name = 'Front Cut', Extras = {toggle = {1, 2}, repair = true}, Combo = 326, Key = 188 }, --LCTRL+UPARROW
				  },
}

CONTROLS = {
	--	   COMBOS = { <list of index/key ID of approved combo-keys> }, List of Controls: https://docs.fivem.net/docs/game-references/controls/
	--	   KEYS = { <list of index/key ID of approved toggle keys> }
	-- ex: COMBOS = { 326, 155, 19 },	--LCTRL, LSHIFT, LALT
	-- ex: KEYS = { 187, 188, 189, 190, 20 }, -- ARROW LFT, DWN, UP, RGT, Z 
	COMBOS = { },
	KEYS = { }
}