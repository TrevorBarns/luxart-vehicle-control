-------------------MENU SETTINGS-------------------
open_menu_key = 'O'
--	Sets default key for RegisterKeyMapping. Examples: 'l','F5', etc. DEFAULT: NONE, users may set one in their GTA V > Settings > Hotkeys > FiveM settings. 
--		More info: https://cookbook.fivem.net/2020/01/06/using-the-new-console-key-bindings/
--		List of Keys: https://pastebin.com/u9ewvWWZ

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
main_siren_register_keys_master_switch = true
--	Enables RegisterKeyMapping for all main_allowed_tones without a default key (unbinded)
main_siren_set_register_keys_set_defaults = true


---------------SOUND EFFECT VOLUMES---------------
on_volume = 0.5			
off_volume = 0.7			
upgrade_volume = 0.7		
downgrade_volume = 1
hazards_volumne = 0.09
lock_volume = 0.25
lock_reminder_volume = 0.2
