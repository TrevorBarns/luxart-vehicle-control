--------------------TAKE DOWNS---------------------
tkd_masterswitch = false
--	Enables plugin, allowing users to toggle takedowns.
tkd_key = 74
--	Key to toggle TKD light. (default: 74 (H))
tkd_combokey = 21 
--  Key that needs to be pressed in combination with tkd_key. Set to false to disable. (default: 21 (Left Shift))
tkd_intensity_default = 100
--  Overall brightness of TKD light.
tkd_radius_default = 50
--  Angle of spread from 0 (narrow/small) to 90 (almost 180 degrees)
tkd_distance_default = 50
--	Max distance light can reach. 
tkd_falloff_default = 1000
--	How fast the light fades/appears dim at distance, this has massive effect on perceived intensity and distance.
tkd_sync_radius = 400
--	Distance to 'sync' / display vehicles TKD light. Larger the number the slower the script depending on players and # of TKDs on. (default: 400) 
tkd_highbeam_integration_default = 2
--	1 - disabled, 2 - Takedown Set Highbeams, 3 - Highbeams Set Takedowns.
