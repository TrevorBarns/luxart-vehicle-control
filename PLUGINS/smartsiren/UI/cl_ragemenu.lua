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

RMenu.Add('lvc', 'smartsiren', RageUI.CreateSubMenu(RMenu:Get('lvc', 'plugins'),"Luxart Vehicle Control", "Smart Siren Settings"))
RMenu:Get('lvc', 'smartsiren'):DisplayGlare(false)

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
		RageUI.IsVisible(RMenu:Get('lvc', 'smartsiren'), function()
			RageUI.Checkbox('Enabled', "Toggles Smart Sire functionality.", smart_siren_masterswitch, {}, {
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