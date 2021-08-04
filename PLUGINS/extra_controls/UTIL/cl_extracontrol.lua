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
CONTROLS_LOOKUP = json.decode(CONTROLS_RAW)

EC = { }
EC.extras = { }
approved_combo_strings = { }
approved_key_strings = { }
combo_override = false
combo_id = 1
key_id = 1
ec_controls_active = true

--Generate required tables for control modification.
Citizen.CreateThread(function()
	table.insert(approved_combo_strings, CONTROLS_LOOKUP[1])
	for i, control_id in ipairs(CONTROLS.COMBOS) do
		table.insert(approved_combo_strings, CONTROLS_LOOKUP[control_id+2])
	end	
	
	table.insert(approved_key_strings, CONTROLS_LOOKUP[1])	
	for i, control_id in ipairs(CONTROLS.KEYS) do
		table.insert(approved_key_strings, CONTROLS_LOOKUP[control_id+2])	
	end
end)

--Control Handling
Citizen.CreateThread(function()
	while ec_masterswitch do
	  if ec_controls_active and not IsMenuOpen() then
		if player_is_emerg_driver and #EC.extras > 0 then
			for _, tog_table in ipairs(EC.extras) do
				if tog_table.Combo == false or IsControlPressed(0, tog_table.Combo) then
					if IsControlJustPressed(0, tog_table.Key) then
						if tog_table.State == nil then
							tog_table.State = true
						else
							tog_table.State = not tog_table.State
						end
						EC:TogVehicleExtras(veh, tog_table.Extras, tog_table.State)
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

--[[This function looks like #!*& for user convenience (and my lack of skill or abundance of laziness), 
	it is called when needing to change an extra, it allows users to do things like ['<model>'] = { Brake = 1 } while 
	also allowing advanced users to write configs like this ['<model>'] = { Brake = { add = { 3, 4 }, remove = { 5, 6 }, repair = true } }
	which can add and remove multiple different extras at once and adds flag to repair the vehicle
	for extras that are too large and require the vehicle to be reloaded. Once it figures out the 
	users config layout it calls itself again with the id we actually need toggled right now.]]
function EC:TogVehicleExtras(veh, extra_id, state, repair)
	local repair = repair or false
	if type(extra_id) == 'table' then
		-- Toggle Same Extras Mode
		if extra_id.toggle ~= nil then
			-- Toggle Multiple Extras
			if type(extra_id.toggle) == 'table' then
				for i, singe_extra_id in ipairs(extra_id.toggle) do
					EC:TogVehicleExtras(veh, singe_extra_id, state, extra_id.repair)
				end
			-- Toggle a Single Extra (no table)
			else
				EC:TogVehicleExtras(veh, extra_id.toggle, state, extra_id.repair)
			end
		-- Toggle Different Extras Mode
		elseif extra_id.add ~= nil and extra_id.remove ~= nil then
			if type(extra_id.add) == 'table' then
				for i, singe_extra_id in ipairs(extra_id.add) do
					EC:TogVehicleExtras(veh, singe_extra_id, state, extra_id.repair)
				end
			else
				EC:TogVehicleExtras(veh, extra_id.add, state, extra_id.repair)
			end
			if type(extra_id.remove) == 'table' then
				for i, singe_extra_id in ipairs(extra_id.remove) do
					EC:TogVehicleExtras(veh, singe_extra_id, not state, extra_id.repair)
				end
			else
				EC:TogVehicleExtras(veh, extra_id.remove, not state, extra_id.repair)
			end
		end
	else
		if state then
			if not IsVehicleExtraTurnedOn(veh, extra_id) then
				local doors =  { }
				if repair then
					for i = 0,6 do
						doors[i] = GetVehicleDoorAngleRatio(veh, i)
					end
				end
				SetVehicleAutoRepairDisabled(veh, not repair)
				SetVehicleExtra(veh, extra_id, false)
				UTIL:Print("EC: Toggling extra "..extra_id.." on", false)
				SetVehicleAutoRepairDisabled(veh, repair)
				if repair then
					for i = 0,6 do
						if doors[i] > 0.0 then
							SetVehicleDoorOpen(veh, i, false, false)
						end
					end
				end
			end
		else
			if IsVehicleExtraTurnedOn(veh, extra_id) then
				SetVehicleExtra(veh, extra_id, true)
				UTIL:Print("EC: Toggling extra "..extra_id.." off", false)
			end	
		end
	end
	SetVehicleAutoRepairDisabled(veh, false)
end

---------------------------------------------------------------------
--Triggered when vehicle changes (cl_lvc.lua)
RegisterNetEvent('lvc:onVehicleChange')
AddEventHandler('lvc:onVehicleChange', function()
	if player_is_emerg_driver and veh ~= nil then
		EC:UpdateExtrasTable(veh)
	end
end)

--[[Sets extras table a copy of EXTRA_CONTROLS for this vehicle]]
function EC:UpdateExtrasTable(veh)
	local veh_name = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
	local veh_name_wildcard = string.gsub(veh_name, "%d+", "#")

	if EXTRA_CONTROLS[veh_name] ~= nil then				--Does profile exist as outlined in vehicle.meta
		EC.extras = EXTRA_CONTROLS[veh_name]
		UTIL:Print("EC: Profile found for "..veh_name, false)
	elseif EXTRA_CONTROLS[veh_name_wildcard] ~= nil then
		EC.extras = EXTRA_CONTROLS[veh_name_wildcard]
		UTIL:Print("EC: Wildcard profile found for "..veh_name..".", false)
	else
		EC.extras = EXTRA_CONTROLS['DEFAULT']
		UTIL:Print("EC: Profile not found for "..veh_name.." using default.", false)
	end
end