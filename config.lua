---------------LOCKOUT FUNCTIONALITY---------------
lockout_master_switch = true			
--	Enables chat command '/luxlockout' to lock out all sirenbox/turn signal keys.
lockout_hotkey_assignment = true		
--	Enables RegisterKeyMapping for '/luxlock' command (lockout_master_switch must be true)
lockout_default_hotkey = ''
--	Sets default key for RegisterKeyMapping. Examples: 'l','F5', etc. DEFAULT: NONE, users may set one in their GTA V > Settings > Hotkeys > FiveM settings. 
--		More info: https://cookbook.fivem.net/2020/01/06/using-the-new-console-key-bindings/
--		List of Keys: https://pastebin.com/u9ewvWWZ
locked_press_count = 5    
--	Inital press count for reminder e.g. if this is 5 and reminder_rate is 10 then, after 5 key presses it will remind you the first time, after that every 10 key presses. 
reminder_rate = 10
--	How often, in luxart key presses, to remind you that your siren controller is locked.


-----------------HUD FUNCTIONALITY-----------------
hud_first_default = false
--	First state of HUD, otherwise it uses the players KVP setting (previous state). 
hud_bgd_opacity = 155
--	Opacity of rectangle background behind buttons (default: 155)
hud_button_on_opacity = 255
--	Opacity of buttons in active/on state. (default: 255)
hud_button_off_opacity = 175
--	Opacity of buttons in inactive/off state. (default: 175)


--------------TURN SIGNALS / HAZARDS--------------
hazard_key = 202
--	Static/Fixed keybinding to toggle hazards: https://docs.fivem.net/docs/game-references/controls/
hazard_hold_duration = 750
--	Time in milliseconds backspace must be pressed to turn on / off hazard lights. 
left_signal_key = 84
--	Static/Fixed keybinding to toggle left indicator: https://docs.fivem.net/docs/game-references/controls/
right_signal_key = 83
--	Static/Fixed keybinding to toggle right indicator: https://docs.fivem.net/docs/game-references/controls/


-------------CUSTOM MANU/HORN/SIREN---------------
custom_manual_tones_master_switch = true
--	Enables chat command '/luxtonesmode' which allows players to change which tone is played for the primary and secondary manual tones.
custom_aux_tones_master_switch = true
--	Enables chat command '/luxtonesmode' which allows players to change which tone is played when AUX siren (Up-Arrow) is enabled. 
main_siren_last_state = true
--	Enables memory for main siren last state, meaning toggling siren using ALT will turn on last siren.
main_allowed_tones = { 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 } 
--	Choose which tones are allowed to be used as main tones see table below. 
manu_allowed_tones = { 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 } 
--	Choose which tones are allowed to be used as manual tones see table below. 
aux_allowed_tones = { 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 } 
--	Choose which tones are allowed to be used as AUX tone see table below. 
tone_table = { "Airhorn", "Wail", "Yelp", "Phaser", "Futura", "Hetro", "Sweep-1", "Sweep-2", "Hi-Low", "Whine Down", "Powercall", "QSiren", "Fire Yelp", "Pulsed Airhorn" } 
--				  1			2 		3		4			5		6		 7			8			 9			10			11			12			13				14
--	Set each siren name here. 
--[[
OPTIONS: 
	ID- Generic Name	(SIREN STRING)									[vehicles.awc name]
	1 - Airhorn 		(SIRENS_AIRHORN)								[AIRHORN_EQD]
	2 - Wail 			(VEHICLES_HORNS_SIREN_1)						[SIREN_PA20A_WAIL]
	3 - Yelp 			(VEHICLES_HORNS_SIREN_2)						[SIREN_2]
	4 - Priority 		(VEHICLES_HORNS_POLICE_WARNING)					[POLICE_WARNING]
	5 - CustomA* 		(RESIDENT_VEHICLES_SIREN_WAIL_01)				[SIREN_WAIL_01]
	6 - CustomB* 		(RESIDENT_VEHICLES_SIREN_WAIL_02)				[SIREN_WAIL_02]
	7 - CustomC* 		(RESIDENT_VEHICLES_SIREN_WAIL_03)				[SIREN_WAIL_03]
	8 - CustomE* 		(RESIDENT_VEHICLES_SIREN_QUICK_01)				[SIREN_QUICK_01]
	9 - CustomF* 		(RESIDENT_VEHICLES_SIREN_QUICK_02)				[SIREN_QUICK_02]
	10 - CustomG* 		(RESIDENT_VEHICLES_SIREN_QUICK_03)				[SIREN_QUICK_03]
	11 - Powercall 		(VEHICLES_HORNS_AMBULANCE_WARNING)				[AMBULANCE_WARNING]
	12 - Firesiren 		(RESIDENT_VEHICLES_SIREN_FIRETRUCK_WAIL_01)		[SIREN_FIRETRUCK_WAIL_01]
	13 - Firesiren2 	(RESIDENT_VEHICLES_SIREN_FIRETRUCK_QUICK_01)	[SIREN_FIRETRUCK_QUICK_01]
	14 - FireHorn	 	(VEHICLES_HORNS_FIRETRUCK_WARNING)				[FIRE_TRUCK_HORN]

	* Notice: 	Enabling these sirens will allow players to use NEW sirens, meaning peoples siren packs need to be updated or they will hear the default sound (yuck). 
				I recommend creating/provideing instructions on how to replace these default sirens AND/OR provide premade sirenpacks. 
]]

-- these models will use their real wail siren, as determined by their assigned audio hash in vehicles.meta
eModelsWithFireSrn =
{
	"FIRETRUK",
}

-- models listed below will use AMBULANCE_WARNING as auxiliary siren
eModelsWithPcall =
{	
	"AMBULANCE",
	"FIRETRUK",
	"LGUARD",
}
---------------SOUND EFFECT VOLUMES---------------
on_volume = 0.5			
off_volume = 0.7			
upgrade_volume = 0.7		
downgrade_volume = 1
hazards_volumne = 0.09
lock_volume = 0.25
lock_reminder_volume = 0.2
