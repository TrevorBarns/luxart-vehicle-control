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

if ta_masterswitch then
	RMenu.Add('lvc', 'tasettings', RageUI.CreateSubMenu(RMenu:Get('lvc', 'plugins'),' ', Lang:t('plugins.menu_ta'), 0, 0, "lvc", "lvc_plugin_logo"))
	RMenu:Get('lvc', 'tasettings'):DisplayGlare(false)

	CreateThread(function()
		while true do
			--TKD SETTINGS
			RageUI.IsVisible(RMenu:Get('lvc', 'tasettings'), function()	
				--[[
				RageUI.List('Combo Key', {'Disabled', 'LSHIFT', 'LCTRL', 'LALT', 'LSHIFT OR (X)', 'LCTRL OR (L3)'}, ta_combokey_index, 'Select key that needs to be held in addition to TA Keys to activate. '~b~( )~s~' indicates controller key.', {}, true, {
				  onListChange = function(Index, Item)
					ta_combokey_index = Index
				  end,
				})	]]		
				RageUI.List(Lang:t('plugins.ta_pattern'), {'1', '2', '3', '4', '5', '6', '7'}, hud_pattern, Lang:t('plugins.ta_pattern_desc'), {}, true, {
				  onListChange = function(Index, Item)
					hud_pattern = Index
					HUD:SetItemState('ta_pattern', hud_pattern)
					HUD:SetItemState('ta', state_ta[veh])
				  end,
				})
				--[[
				RageUI.Checkbox('Disable Incorrect Combo Keys', 'Disables key mapping when a combo key that is not assigned is pressed.', block_incorrect_combo, {}, {
				  onChecked = function()
					block_incorrect_combo = true
				  end,          
				  onUnChecked = function()
					block_incorrect_combo = false
				  end
				})	]]			
				RageUI.Checkbox(Lang:t('plugins.ta_save'), Lang:t('plugins.ta_save_desc'), TA.preserve_ta_state, {}, {
				  onChecked = function()
					TA.preserve_ta_state = true
				  end,          
				  onUnChecked = function()
					TA.preserve_ta_state = false
				  end
				})					
				RageUI.Checkbox(Lang:t('plugins.ta_sync'), Lang:t('plugins.ta_sync_desc'), false, {Enabled = false}, {
				  onChecked = function()
					TA.sync_ta_state = true
				  end,          
				  onUnChecked = function()
					TA.sync_ta_state = false
				  end
				})
			end)
			Wait(0)
		end
	end)
end