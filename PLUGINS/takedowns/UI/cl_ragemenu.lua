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

RMenu.Add('lvc', 'tkdsettings', RageUI.CreateSubMenu(RMenu:Get('lvc', 'plugins'),"Luxart Vehicle Control", "Takedown Settings"))
RMenu:Get('lvc', 'tkdsettings'):DisplayGlare(false)

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
		RageUI.IsVisible(RMenu:Get('lvc', 'tkdsettings'), function()
			RageUI.Checkbox('Enabled', "Toggles takedown light functionality. All vehicles: your own and others.", tkd_masterswitch, {}, {
            onChecked = function()
				tkd_masterswitch = true
            end  ,          
			onUnChecked = function()
				tkd_masterswitch = false
            end
            })				
			RageUI.List('Integration', {"Off", "TKDs Set High-beams", "High-beams Set TKDs"}, tkd_mode, "Determines whether high-beams will auto toggle takedowns or visa versa.", {}, tkd_masterswitch, {
			  onListChange = function(Index, Item)
				tkd_mode = Index
			  end,
			})			
			RageUI.List('Position', {"1", "2", "3", "4"}, tkd_scheme, "Select predefined positions of light source.", {}, tkd_masterswitch, {
			  onListChange = function(Index, Item)
				tkd_scheme = Index
			  end,
			})
			RageUI.Slider('Intensity', tkd_intensity, 150, 15, "Set brightness/intensity of takedowns.", false, {}, tkd_masterswitch, {
			  onSliderChange = function(Index)
				tkd_intensity = Index
			  end,	  
			})					
			RageUI.Slider('Radius', tkd_radius, 90, 9, "Set width of takedowns.", false, {}, tkd_masterswitch, {
			  onSliderChange = function(Index)
				tkd_radius = Index
			  end,	  
			})			
			RageUI.Slider('Distance', tkd_distance, 250, 25, "Set the max distance the takedowns can travel.", false, {}, tkd_masterswitch, {
			  onSliderChange = function(Index)
				tkd_distance = Index
			  end,	  
			})				
			RageUI.Slider('Falloff', tkd_falloff, 2000, 200, "Set how fast light \"falls off\" or appears dim.", false, {}, tkd_masterswitch, {
			  onSliderChange = function(Index)
				tkd_falloff = Index
			  end,	  
			})	
        end)
        Citizen.Wait(0)
	end
end)