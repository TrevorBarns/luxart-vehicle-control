# Luxart Vehicle Control v3
Over the past months, I have been slowing integrating additonal features into Faction's release (v2.0) of Lt. Caine's Luxart Vehicle Control resource, I would now like to release these to the public. 
## Additional Functionality:
__Lockout:__
Ability to lock all siren/light controls using a player set key to prevent activation while typing (or eating). Locking/Unlocking shows on screen notification and audible tone. Includes reminder tone every X key presses, where X can be set by server developers. 

__LuxHUD:__ 
A small togglable visual representation of the scripts functionality modeled after real siren controllers. Includes 3 position switch, siren, horn, takedown, and lockout textures. 

![LuxHUD](https://i.gyazo.com/27138d952f247ebbf64a26b0d85e06f6.png)

__Hazards Delay:__
Customizable "Hold-to-activate/deactivate" hazard lights to prevent accidental activation when navigating trainers/vMenu.

__Hazards SoundFX:__
Added activation/deactivation sound effect of toggle switch based off IRL vehicle toggle switches.

__Config.lua:__ 
One stop shop for all customizable settings to reduce server developer workload.
```
---------------LOCKOUT FUNCTIONALITY---------------
lockout_master_switch = true			
lockout_hotkey_assignment = true		
lockout_default_hotkey = ''
locked_press_count = 5    
reminder_rate = 10

-----------------HUD FUNCTIONALITY-----------------
hud_first_default = false
hud_bg_opacity = 155
hud_button_on_opacity = 255
hud_button_off_opacity = 175

--------------TURN SIGNALS / HAZARDS--------------
hazard_key = 202
hazard_hold_duration = 750
left_signal_key = 84
right_signal_key = 83

---------------SOUND EFFECT VOLUMES---------------
 on_volume = 0.5			
 off_volume = 0.7			
 upgrade_volume = 0.7		
 downgrade_volume = 1
 hazards_volumne = 0.09
 lockreminder_volume = 0.2
```

## How to install:
1. Add lux_vehcontrol folder into your server resources.
2. Add `ensure lux_vehcontrol` or `start lux_vehcontrol` to server.cfg

__If you DO NOT stream commonmenu.ytd with another resource:__

2. Keep the stream folder present, you don't need to move or change a thing. Continue to step #4.

__If you stream commonmenu.ytd with another resource (for example to stream custom vMenu textures):__

2. Navigate to `lux_vehcontrol/stream/RawTextures` add all textures to other resource's commonmenu.ytd. 
3. Remove or Rename stream folder to prevent overriding othe resource's commonmenu.ytd. 
4. Open config.lua and configure to your liking. 
5. Enjoy!

## Credits:
Luxart Vehicle Control was an ingenious creation by __Lt. Caine__! Thank you!
ELS Clicks added by __Faction__, this added realism pushed me to get into developing in the first place. Thank you!

