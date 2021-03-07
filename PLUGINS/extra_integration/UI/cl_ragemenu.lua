--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: cl_ragemenu.lua
PURPOSE: Handle RageUI 
---------------------------------------------------
]]

RMenu.Add('lvc', 'extrasettings', RageUI.CreateSubMenu(RMenu:Get('lvc', 'plugins'),"Luxart Vehicle Control", "Extra Integration Settings"))
RMenu:Get('lvc', 'extrasettings'):DisplayGlare(false)


Citizen.CreateThread(function()
    while true do
		--TKD SETTINGS
		RageUI.IsVisible(RMenu:Get('lvc', 'extrasettings'), function()
			RageUI.Checkbox('Blackout', "Disabled auto brake lights on stop.", not auto_brake_lights, {}, {
            onChecked = function()
				auto_brake_lights = false
				brakes_ei_enabled = false
            end,          
			onUnChecked = function()
				auto_brake_lights = true
				brakes_ei_enabled = true
            end
            })

			RageUI.List('Auto Park Mode', {"Off", "1/2", "1", "5"}, auto_park_time_index, ("How long after being stopped to disable auto brake lights and put vehicle in \"park\". Options are in minutes. Timer (sec): %1.0f"):format((stopped_timer / 1000) or 0), {}, true, {
			  onListChange = function(Index, Item)
				if Index > 1 then
					auto_park_time_index = Index
					auto_park = true
				else
					auto_park = false
					auto_park_time_index = Index
				end
			  end,
			})		
        end)
		
        Citizen.Wait(0)
	end
end)