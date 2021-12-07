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
local CONTROLS_RAW = LoadResourceFile(GetCurrentResourceName(), "PLUGINS/extra_controls/controls.json")
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
	  if EC.controls_enabled and not IsMenuOpen() then
		if player_is_emerg_driver and #EC.table > 0 then
			for _, tog_table in ipairs(EC.table) do
				if tog_table.Combo == false or IsControlPressed(0, tog_table.Combo) then
					if IsControlJustPressed(0, tog_table.Key) then
						if tog_table.State == nil then
							tog_table.State = true
						else
							tog_table.State = not tog_table.State
							if tog_table.Audio ~= nil and tog_table.Audio then
								if tog_table.State then
									PlayAudio("Downgrade", downgrade_volume)
								else
									PlayAudio("Upgrade", upgrade_volume)
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
		EC:UpdateExtrasTable(veh)
		EC:SetBackupTable()
		EC:RefreshRageIndexs()
	end
end)

--[[Sets extras table a copy of EXTRA_CONTROLS for this vehicle]]
function EC:UpdateExtrasTable(veh)
	local veh_name = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
	local veh_name_wildcard = string.gsub(veh_name, "%d+", "#")

	if EXTRA_CONTROLS[veh_name] ~= nil then				--Does profile exist as outlined in vehicle.meta
		EC.table = EXTRA_CONTROLS[veh_name]
		EC.profile_name = veh_name
		UTIL:Print("EC. Profile found for "..veh_name, false)
	elseif EXTRA_CONTROLS[veh_name_wildcard] ~= nil then
		EC.table = EXTRA_CONTROLS[veh_name_wildcard]
		EC.profile_name = veh_name_wildcard
		UTIL:Print("EC. Wildcard profile found for "..veh_name..".", false)
	else
		if EXTRA_CONTROLS['DEFAULT'] ~= nil then
			EC.table = EXTRA_CONTROLS['DEFAULT']
			EC.profile_name = 'DEFAULT'
			UTIL:Print("EC. using default profile for "..veh_name, false)
		else
			EC.table = { }
			UTIL:Print("^3LVC WARNING: (EXTRA_CONTROLS) 'DEFAULT' table missing from EXTRA_CONTROLS table. Using empty table for "..veh_name, false)
		end
	end
end