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
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
---------------------------------------------------
]]

RMenu.Add('lvc', 'tkdsettings', RageUI.CreateSubMenu(RMenu:Get('lvc', 'plugins'),' ', Lang:t('plugins.menu_tkd'), 0, 0, "lvc", "lvc_plugin_logo"))
RMenu:Get('lvc', 'tkdsettings'):DisplayGlare(false)

CreateThread(function()
    while true do
		--TKD SETTINGS
		RageUI.IsVisible(RMenu:Get('lvc', 'tkdsettings'), function()			
			RageUI.List(Lang:t('plugins.tkd_integration'), { Lang:t('plugins.tkd_integration_off'), Lang:t('plugins.tkd_integration_set_highbeam'), Lang:t('plugins.tkd_integration_highbeam_set_tkd') }, tkd_mode, Lang:t('plugins.tkd_integration_desc'), {}, true, {
			  onListChange = function(Index, Item)
				tkd_mode = Index
			  end,
			})			
			RageUI.List(Lang:t('plugins.tkd_position'), {'1', '2', '3', '4'}, tkd_scheme, Lang:t('plugins.tkd_position_desc'), {}, true, {
			  onListChange = function(Index, Item)
				tkd_scheme = Index
			  end,
			})
			RageUI.Slider(Lang:t('plugins.tkd_intensity'), tkd_intensity, 150, 15, Lang:t('plugins.tkd_intensity_desc'), false, {}, true, {
			  onSliderChange = function(Index)
				tkd_intensity = Index
			  end,	  
			})					
			RageUI.Slider(Lang:t('plugins.tkd_radius'), tkd_radius, 90, 9, Lang:t('plugins.tkd_radius_desc'), false, {}, true, {
			  onSliderChange = function(Index)
				tkd_radius = Index
			  end,	  
			})			
			RageUI.Slider(Lang:t('plugins.tkd_distance'), tkd_distance, 250, 25, Lang:t('plugins.tkd_distance_desc'), false, {}, true, {
			  onSliderChange = function(Index)
				tkd_distance = Index
			  end,	  
			})				
			RageUI.Slider(Lang:t('plugins.tkd_falloff'), tkd_falloff, 2000, 200, Lang:t('plugins.tkd_falloff_desc'), false, {}, true, {
			  onSliderChange = function(Index)
				tkd_falloff = Index
			  end,	  
			})	
        end)
        Wait(0)
	end
end)