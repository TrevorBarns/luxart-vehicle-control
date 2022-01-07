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
]]
--Read controls from controls.json file
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

--Generate required tables for control modification.
Citizen.CreateThread(function()
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

--Control Handling
Citizen.CreateThread(function()
	while ec_masterswitch do
	  if EC.controls_enabled and not IsMenuOpen() and not key_lock then
		if player_is_emerg_driver and #EC.table > 0 then
			for _, tog_table in ipairs(EC.table) do
				if tog_table.Combo == 0 or IsControlPressed(0, tog_table.Combo) then
					if IsControlJustPressed(0, tog_table.Key) then
						if tog_table.State == nil then
							tog_table.State = true
						else
							tog_table.State = not tog_table.State
							if tog_table.Audio ~= nil and tog_table.Audio then
								if tog_table.State then
									AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
								else
									AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
								end
							end
						end
						UTIL:TogVehicleExtras(veh, tog_table.Extras, tog_table.State)
					end
				end
			end
		else
			Citizen.Wait(500)
		end
	  else
		Citizen.Wait(500)
	  end
	  Citizen.Wait(0)
	end
end)

---------------------------------------------------------------------
--Triggered when vehicle changes (cl_lvc.lua)
RegisterNetEvent('lvc:onVehicleChange')
AddEventHandler('lvc:onVehicleChange', function()
	if player_is_emerg_driver and veh ~= nil then
		EC.table, EC.profile = UTIL:GetProfileFromTable('EC', EXTRA_CONTROLS, veh)
		
		EC:SetBackupTable()
		EC:LoadSettings()		
				
		--[[Verify all controls are approved, if not reset to none and notify]]
		for i, tog_table in pairs(EC.table) do
			local found_combo = false
			local found_key = false
			
			for i, control in pairs(CONTROLS.COMBOS) do 
				if tog_table.Combo == control then
					found_combo = true
				end		
			end	

			if not found_combo then
				HUD:ShowNotification('~b~LVC ~y~Warning P404:~s~ attempted to use control but was not approved. See console.', true)
				UTIL:Print(('^3LVC Warning P404: attempted to use control "%s" but, was unable to locate CONTROLS.COMBOS table. Try factory resetting or report to server developer.'):format(tog_table.Combo), true)
				tog_table.Combo = 0
			end				
			
			for i, control in pairs(CONTROLS.KEYS) do 
				if tog_table.Key == control then
					found_key = true
				end
			end
			
			if not found_key then
				HUD:ShowNotification('~b~LVC ~y~Warning P404:~s~ attempted to use control but was not approved. See console.', true)
				UTIL:Print(('^3LVC Warning P404: attempted to use control "%s" but, was unable to locate CONTROLS.KEYS table. Try factory resetting or report to server developer.'):format(tog_table.Key), true)
				tog_table.Key = 0
			end	
		end
		
		EC:RefreshRageIndexs()
	end
end)