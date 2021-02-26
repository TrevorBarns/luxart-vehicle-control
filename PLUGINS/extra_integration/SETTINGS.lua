--------------------EXTRA INTEGRATION SETTINGS---------------------
extra_integration_masterswitch = true
--	Determines if extra_integration plugin can be activated.
brakes_ei_enabled = true
--	Enables brake pressure integration for EI.
reverse_ei_enabled = true
--	Enables reverse gear integration for EI.
--indicators_ei_enabled = true
--	Enables indicator integration for EI. Doesn't work, does not sync with indicator flashes.
takedown_ei_enabled = true
--	Enables takedown integration for EI.
auto_brake_lights = true
--	Enables auto-set client side brake lights on stop (speed = 0).

EXTRA_ASSIGNMENTS = {
-- ['<modelName>'] = { (opt.) Brake = extra_#, (opt.) Reverse = extra_#, (opt.) LIndicator = extra_#, (opt.) RIndicator = extra_#, (opt.) Takedowns = extra_# },
['DEFAULT'] = { Brake = 1, Reverse = 12, LIndicator = 10, RIndicator = 11, Takedowns = 2 },
}