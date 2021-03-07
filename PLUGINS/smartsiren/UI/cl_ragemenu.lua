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

RMenu.Add('lvc', 'smartsiren', RageUI.CreateSubMenu(RMenu:Get('lvc', 'plugins'),"Luxart Vehicle Control", "Smart Siren Settings"))
RMenu:Get('lvc', 'smartsiren'):DisplayGlare(false)

Citizen.CreateThread(function()
    while true do		
		RageUI.IsVisible(RMenu:Get('lvc', 'smartsiren'), function()
			RageUI.Checkbox('Enabled', "Toggles Smart Siren functionality.", smart_siren_masterswitch, {}, {
            onChecked = function()
				smart_siren_masterswitch = true
            end,          
			onUnChecked = function()
				smart_siren_masterswitch = false
            end
            })				
        end)
        Citizen.Wait(0)
	end
end)