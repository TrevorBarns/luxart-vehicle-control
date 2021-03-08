--------------------EXTRA INTEGRATION SETTINGS---------------------
ei_masterswitch = false
--	Determines if extra_integration plugin can be activated.
brakes_ei_enabled = true
--	Enables brake pressure integration for EI.
reverse_ei_enabled = true
--	Enables reverse gear integration for EI.
indicators_ei_enabled = true
--	Enables indicator integration for EI. Requires extras to be mapped to indicator light_id. Flashes are not synced without this.
takedown_ei_enabled = true
--	Enables takedown integration for EI.
door_ei_enabled = true
--	Enables driver & passenger door triggers for EI.
siren_controller_ei_enabled = true
--	Enables air horn, siren, aux siren, and manual tone state triggers for EI.
auto_brake_lights = true
--	Enables auto-set client side brake lights on stop (speed = 0).
auto_park = true
--	Turns off brake lights after being stopped for auto_park_time. 

--[[ Documentation / Wiki: https://github.com/TrevorBarns/luxart-vehicle-control/wiki/Extra-Integrations ]]

EXTRA_ASSIGNMENTS = {
	['DEFAULT'] = { 
	
				  },
}