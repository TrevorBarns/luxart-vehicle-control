------------------MENU KEYBINDING------------------
open_menu_key = 'O'
--	Sets default key for RegisterKeyMapping. Examples: 'l','F5', etc. DEFAULT: 'O', users may set one in their GTA V > Settings > Hotkeys > FiveM settings. 
--		More info: https://cookbook.fivem.net/2020/01/06/using-the-new-console-key-bindings/
--		List of Keys: https://pastebin.com/u9ewvWWZ


--------------------TAKE DOWNS---------------------
tkd_key = 74
--	Key to toggle TKD light. (default: 74 (H))
tkd_combokey = 21 
--  Key that needs to be pressed in combination with tkd_key. Set to 0 to disable. (default: 21 (Left Shift))
tkd_intensity_default = 100
--  Overall brightness of TKD light.
tkd_radius_default = 50
--  Angle of spread from 0 (narrow/small) to 90 (almost 180 degrees)
tkd_distance_default = 50
--	Max distance light can reach. 
tkd_falloff_default = 1000
--	How fast the light fades/appears dim at distance, this has massive effect on percieved intesity and distance.
tkd_sync_radius_default = 400
--	Distance to "sync" / display vehicles TKD light. Larger the number the slower the script depending on players and # of TKDs on. (default: 400) 
tkd_set_highbeams_default = true
--	Determines if highbeams are enabled / disabled with TKD light.
tkd_debug_flag = true
--	Used to debug / view spotlight angle.


--------------TURN SIGNALS / HAZARDS---------------
hazard_key = 202	
left_signal_key = 84
right_signal_key = 83
hazard_hold_duration = 750
--	Time in milliseconds backspace must be pressed to turn on / off hazard lights. 


---------------LOCKOUT FUNCTIONALITY---------------
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


-------------CUSTOM MANU/HORN/SIREN---------------
custom_manual_tones_master_switch = true
--	Enables manual tone settings menu items to change which tone is played for the primary and secondary manual tones.
custom_aux_tones_master_switch = true
--	Enables auxiliary tone settings menu item so players can change which tone is played when AUX siren (Up-Arrow) is enabled. 
main_siren_set_register_keys_set_defaults = true
--	Enables RegisterKeyMapping for all main_allowed_tones and sets the default keys to numrow 1-0.


---------------SOUND EFFECT VOLUMES---------------
button_sfx_scheme_choices = { 'SSP2000', 'SSP3000', 'Cencom', 'ST300' }
--Customize which button SFX schemes are avalible. An item here must match exactly the folder name located in `lux_vehcontrol\html\sounds`, recommend NOT using spaces instead use a dash (e.g. Cencom-Gold)
default_sfx_scheme_name = 'SSP2000'
default_on_volume = 0.5			
default_off_volume = 0.7			
default_upgrade_volume = 0.5		
default_downgrade_volume = 0.7
default_hazards_volume = 0.09
default_lock_volume = 0.25
default_lock_reminder_volume = 0.2
default_reminder_volume = 0.09