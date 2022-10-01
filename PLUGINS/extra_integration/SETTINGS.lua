--------------------EXTRA INTEGRATION SETTINGS---------------------
ei_masterswitch = false
--	Determines if extra_integration plugin can be activated.
ei_run_out_of_vehicle = false
--  Continue running state checks when player is out of vehicle, only after EI vehicle was last driven. (this is necessary for proper seat / door check)
--		Disable this to improve runtime efficiency. (Default: Disabled / False)
brakes_ei_enabled = true
--	Enables brake pressure integration.
reverse_ei_enabled = true
--	Enables reverse gear integration.
indicators_ei_enabled = true
--	Enables indicator integration. Requires extras to be mapped to indicator light_id. Flashes are not synced without this.
takedown_ei_enabled = true
--	Enables takedown integration.
seat_ei_enabled = true
--	Enabled driver seat detection.
door_ei_enabled = true
--	Enables driver & passenger door triggers.
siren_controller_ei_enabled = true
--	Enables air horn, siren, aux siren, and manual tone state triggers.
auto_brake_lights = true
--	Enables auto-set client side brake lights on stop (speed = 0) for both emergency and non-emergency vehicles.
auto_park = true
--	Turns off brake lights after being stopped for auto_park_time. 
default_blackout_control = ''
--	Toggles vehicles headlights, brakelights controls: https://pastebin.com/u9ewvWWZ (Default: None/Disabled)

--[[ Documentation / Wiki: https://github.com/TrevorBarns/luxart-vehicle-control/wiki/Extra-Integrations ]]
EXTRA_ASSIGNMENTS = {
	['DEFAULT'] = {}	-- autopark functionality requires default table
	--[<gameName>] = { 
					--[<extra_id>] = { repair = <true/false>, toggle = {<string(s)>}, reverse = <true/false>}
	--			},
}
