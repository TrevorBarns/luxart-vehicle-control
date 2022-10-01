--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: cl_extracontrol.lua
PURPOSE: Contains threads, functions to toggle 
extras based on vehicle states / inputs.
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
if ec_masterswitch then	
	--	Read controls from controls.json file
	local CONTROLS_RAW = LoadResourceFile(GetCurrentResourceName(), 'PLUGINS/extra_controls/controls.json')
	local CONTROLS_LOOKUP = json.decode(CONTROLS_RAW)

	EC = { }
	EC.table = { }
	EC.approved_combo_strings = { }
	EC.approved_key_strings = { }
	EC.combo_override = false
	EC.controls_enabled = true
	EC.combo_id = {} 
	EC.key_id = {}
	EC.is_menu_open = false					   

	--	Set RageUI list index to current selection
	function EC:RefreshRageIndexs()
		for i, extra_shortcut in ipairs(EC.table) do
			EC.combo_id[i] = UTIL:IndexOf(CONTROLS.COMBOS, EC.table[i].Combo)
			EC.key_id[i] = UTIL:IndexOf(CONTROLS.KEYS, EC.table[i].Key)
		end
	end

	--	Generate required tables for control modification.
	CreateThread(function()
		table.insert(EC.approved_combo_strings, CONTROLS_LOOKUP[1])
		for i, control_id in ipairs(CONTROLS.COMBOS) do
			table.insert(EC.approved_combo_strings, CONTROLS_LOOKUP[control_id+2])
		end	
		
		table.insert(EC.approved_key_strings, CONTROLS_LOOKUP[1])	
		for i, control_id in ipairs(CONTROLS.KEYS) do
			table.insert(EC.approved_key_strings, CONTROLS_LOOKUP[control_id+2])	
		end
		table.insert(CONTROLS.COMBOS, 1, 0)	
		table.insert(CONTROLS.KEYS, 1, 0)	
	end)

	--	Control Handling
	CreateThread(function()
		while true do
			if EC.controls_enabled and not IsMenuOpen() and not key_lock then
				if player_is_emerg_driver and #EC.table > 0 then
					for _, tog_table in ipairs(EC.table) do
						if ( tog_table.Combo == 0 or IsControlPressed(0, tog_table.Combo) ) and ( IsUsingKeyboard(0) or tog_table.Controller_Support ) then
							if IsControlJustPressed(0, tog_table.Key) and ( IsUsingKeyboard(0) or tog_table.Controller_Support ) then
								if tog_table.State == nil then
									tog_table.State = true
								else
									tog_table.State = not tog_table.State
									if tog_table.Audio then
										AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
									end
								end
								UTIL:TogVehicleExtras(veh, tog_table.Extras, tog_table.State)
							end
						end
					end
				else
					Wait(500)
				end
			else
				Wait(500)
			end
			Wait(0)
		end
	end)

	---------------------------------------------------------------------
	--Triggered when vehicle changes (cl_lvc.lua)
	RegisterNetEvent('lvc:onVehicleChange')
	AddEventHandler('lvc:onVehicleChange', function()
		if player_is_emerg_driver and veh ~= nil then
			EC.table, EC.profile = UTIL:GetProfileFromTable('EXTRA CONTROLS', EXTRA_CONTROLS, veh, true)
			if EC.profile ~= false then
				Wait(500)
				EC:SetBackupTable()
				EC:LoadSettings()		

				--	Dynamically create shortcut menus
				if #EC.table > 0 then
					for i, extra_shortcut in ipairs(EC.table) do
						RMenu.Add('lvc', 'extracontrols_'..i, RageUI.CreateSubMenu(RMenu:Get('lvc', 'extracontrols'),' ', extra_shortcut.Name), 0, 0, "lvc", "lvc_plugin_logo")
						RMenu:Get('lvc', 'extracontrols_'..i):DisplayGlare(false)
					end
				end

				--[[Verify all controls are approved, if not reset to none and notify and set default parameters]]
				for i, tog_table in pairs(EC.table) do
					local found_combo = false
					local found_key = false
					
					for i, control in pairs(CONTROLS.COMBOS) do 
						if tog_table.Combo == control then
							found_combo = true
						end		
					end	

					if not found_combo then
						HUD:ShowNotification(Lang:t('plugins.ec_not_approved_frontend'), true)
						UTIL:Print(Lang:t('plugins.ec_not_approved_console', { control = tog_table.Combo, type = 'COMBO' }), true)
						tog_table.Combo = 0
					end				
					
					for i, control in pairs(CONTROLS.KEYS) do 
						if tog_table.Key == control then
							found_key = true
						end
					end
					
					if not found_key then
						HUD:ShowNotification(Lang:t('plugins.ec_not_approved_frontend'), true)
						UTIL:Print(Lang:t('plugins.ec_not_approved_console', { control = tog_table.Key, type = 'KEY' }), true)
						tog_table.Key = 0
					end	
				end

				EC:RefreshRageIndexs()
			end
		end
	end)
end