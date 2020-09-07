<p align="center">
<img align="center" width="800" src="https://i.gyazo.com/c45881d46eeef83e03634a6a251ab849.png">
</p>

# Luxart Vehicle Control v3
Over the past months, I have been slowing integrating additonal features into Faction's release (v2.0) of Lt. Caine's Luxart Vehicle Control resource, I would now like to release these to the public. 
## Additional Functionality:

__LuxHUD:__ 
A small togglable and adjustable visual representation of the scripts functionality modeled after real siren controllers. Includes 3 position switch, siren, horn, takedown, and lockout textures. Includes ability to move and save location and opacity of HUD. 
<p align="center">
<img align="center" width="530" src="https://i.gyazo.com/5b30d59b82922c3555bdee92ca4c15ff.jpg">
<img align="center" width="530" src="https://i.gyazo.com/04206551d05f3554eeb9f0b8f8ff6928.jpg">
</p>

__Additional Tones ("Siren Mastery"):__
Add support for up to 6 additional vanilla tones: `RESIDENT_VEHICLES_SIREN_WAIL_01,2,3` and `RESIDENT_VEHICLES_SIREN_QUICK_01,2,3`. With a plethora of customization on how LVC works for you. Some examples: an expanded siren set for all to use including custom created sweeps/autocycles, department specific siren such as Paleto using one siren pack and LSPD using another, the options are endless. 
<p align="center">
<img align="center" width="530" src="https://i.gyazo.com/48e92fb46f97e6f3b310826302992b43.png">
</p>

__ELS Style Hotkey Assignments:__
Cycle your tones like single player ELS with player definied hotkey assignments. For example use your numrow or numpad to change sirens on the fly. 
<p align="center">
<img align="center" width="530" src="https://i.gyazo.com/ef0c9c862bf02c839ce1c94a4b490f74.png">
</p>

__Adjustable Manual / Auxilary Tones:__
Change which tone to use for each manual tone (primary and secondary) as well as the auxiliary tone. These are also saved to the client requiring no changes at relog. 
<p align="center">
<img align="center" width="530" src="https://i.gyazo.com/ea4b046dcf4363168320aa051a93ecde.png">
</p>

__Lockout:__
Ability to lock all siren/light controls using a player set key to prevent activation while typing (or eating). Locking/Unlocking shows on screen notification and audible tone. Includes reminder tone every X key presses, where X can be set by server developers. 
<p align="center">
<img align="center" width="530" src="https://i.gyazo.com/74ec018e67d7ec9fc299f806a3f25bdf.png">
</p>

__Hazards Delay:__
Customizable "Hold-to-activate/deactivate" hazard lights to prevent accidental activation when navigating trainers/vMenu.

__Hazards SoundFX:__
Added activation/deactivation sound effect of toggle switch based off IRL vehicle toggle switches.

__Config.lua:__ 
One stop shop for all customizable settings to reduce server developer workload.

_*comments removed for size, see comments & descriptions of each setting in config.lua_
```
---------------LOCKOUT FUNCTIONALITY---------------
lockout_master_switch = true			
lockout_hotkey_assignment = true		
lockout_default_hotkey = ''
locked_press_count = 5    
reminder_rate = 10

-----------------HUD FUNCTIONALITY-----------------
hud_first_default = false
hud_bgd_opacity = 155
hud_button_on_opacity = 255
hud_button_off_opacity = 175

--------------TURN SIGNALS / HAZARDS--------------
hazard_key = 202
hazard_hold_duration = 750
left_signal_key = 84
right_signal_key = 83

-------------CUSTOM MANU/HORN/SIREN---------------
custom_manual_tones_master_switch = true
custom_aux_tones_master_switch = true

---------------SOUND EFFECT VOLUMES---------------
on_volume = 0.5			
off_volume = 0.7			
upgrade_volume = 0.7		
downgrade_volume = 1
hazards_volumne = 0.09
lock_volume = 0.25
lock_reminder_volume = 0.2

```

## How to install:
1. Add lux_vehcontrol folder into your server resources.
2. Add `ensure lux_vehcontrol` or `start lux_vehcontrol` to server.cfg

__If you DO NOT stream commonmenu.ytd with another resource:__

2. Keep the stream folder present, you don't need to move or change a thing. Continue to step #4.

__If you stream commonmenu.ytd with another resource (for example to stream custom vMenu textures):__

2. Navigate to `lux_vehcontrol/extras/RawTextures` add all textures to other resource's commonmenu.ytd. 
3. Remove or Rename stream folder to prevent overriding othe resource's commonmenu.ytd. 
4. Open config.lua and configure to your liking. Install any additional tones you would like to enable locally.
5. Enjoy!

## Credits:
Luxart Vehicle Control was an ingenious creation by __Lt. Caine__! Thank you! 

ELS Clicks added by __Faction__, this added realism pushed me to get into developing in the first place. Thank you!

__All credit to those above who contributed there projects can be found here:__
* Luxart Vehicle Control (Original Release) by Lt. Caine: https://forum.cfx.re/t/release-luxart-vehicle-control/17304
* Luxart Vehicle Control ELS Clicks by Faction: https://forum.cfx.re/t/release-luxart-vehicle-control-els-clicks/921644
