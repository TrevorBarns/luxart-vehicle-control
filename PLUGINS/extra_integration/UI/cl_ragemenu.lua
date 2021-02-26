--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Last revision: FEBRUARY 26 2021 (VERS. 3.2.1)
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

--Returns true if any menu is open
--[[
function IsMenuOpen()
	return RageUI.Visible(RMenu:Get('lvc', 'main')) or 
	RageUI.Visible(RMenu:Get('lvc', 'maintone')) or 
	RageUI.Visible(RMenu:Get('lvc', 'saveload')) or 
	RageUI.Visible(RMenu:Get('lvc', 'tkdsettings')) or 
	RageUI.Visible(RMenu:Get('lvc', 'audiosettings')) or 
	RageUI.Visible(RMenu:Get('lvc', 'hudsettings')) or 
	RageUI.Visible(RMenu:Get('lvc', 'about'))
end
]]

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
--[[
			RageUI.List('Auto Park Mode', {"Off", "1/2", "1", "5"}, brake_light_delay_index, ("How after being stopped to disable auto brake lights and put vehicle in \"park\". Options are in minutes. Timer (sec): %1.0f"):format((brake_light_timer / 1000) or 0), {}, auto_brake_lights, {
			  onListChange = function(Index, Item)
				brake_light_delay_index = Index
				EI:SetBrakeLightDelay()
			  end,
			})		
]]			
        end)
		
        Citizen.Wait(0)
	end
end)