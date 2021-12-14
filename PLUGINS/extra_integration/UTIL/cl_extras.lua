--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: cl_extras.lua
PURPOSE: Contains threads, functions to toggle 
extras based on vehicle states / inputs.
---------------------------------------------------
]]
EI = { }

local accel_pedal = 0
local extras = { }
local auto_park_time_lookup = { [2] = 30000, [3] = 60000, [4] = 300000 }

stopped_timer = 0
auto_park_time_index = 2

------BRAKE, REVERSE, TKD - EXTRA INTEGRATION------
Citizen.CreateThread( function()
    while true do
        while ei_masterswitch do
            if veh ~= nil then	
				--BRAKE LIGHTS
				if player_is_emerg_driver and brakes_ei_enabled and extras.Brake ~= nil then
					if ( not auto_park or stopped_timer < auto_park_time_lookup[auto_park_time_index] ) and 	-- Auto Park Check
					   ( GetControlNormal(1, 72) > 0.1 or 														-- Brake (LTrigger) 0.0-1.0
					   ( GetControlNormal(1, 72) > 0.0 and GetControlNormal(1, 71) > 0.0 ) or 					-- Brake & Gas at same time
					   ( GetEntitySpeed(veh) < 0.2 and GetIsVehicleEngineRunning(veh) )) and					-- Vehicle is stopped 
					   ( not ( accel_pedal < 0.0 or tostring(accel_pedal) == '-0.0')) then						-- Is vehicle not reversing or at max reverse speed
						UTIL:TogVehicleExtras(veh, extras.Brake, true)
					else
						UTIL:TogVehicleExtras(veh, extras.Brake, false)				
					end
				elseif extras.Brake ~= nil then
					UTIL:TogVehicleExtras(veh, extras.Brake, false)
				end
				
				--REVERSE LIGHTS
				if player_is_emerg_driver and reverse_ei_enabled and extras.Reverse ~= nil then
					accel_pedal = GetVehicleThrottleOffset(veh)
					if accel_pedal < 0 or tostring(accel_pedal) == '-0.0' then
						UTIL:TogVehicleExtras(veh, extras.Reverse, true)
					else
						UTIL:TogVehicleExtras(veh, extras.Reverse, false)
					end
				end					
				
				--INDICATORS
				if player_is_emerg_driver and indicators_ei_enabled and extras.LIndicator ~= nil and extras.RIndicator ~= nil then
					if state_indic[veh] == 1 then
						UTIL:TogVehicleExtras(veh, extras.LIndicator, true)
					elseif state_indic[veh] == 2 then
						UTIL:TogVehicleExtras(veh, extras.RIndicator, true)				
					elseif state_indic[veh] == 3 then
						UTIL:TogVehicleExtras(veh, extras.LIndicator, true)
						UTIL:TogVehicleExtras(veh, extras.RIndicator, true)								
					else
						UTIL:TogVehicleExtras(veh, extras.LIndicator, false)
						UTIL:TogVehicleExtras(veh, extras.RIndicator, false)												
					end
				end
				
				--TAKEDOWNS
				if player_is_emerg_driver and takedown_ei_enabled and tkd_masterswitch and extras.Takedowns ~= nil then
					if state_tkd[veh] ~= nil then
						UTIL:TogVehicleExtras(veh, extras.Takedowns, state_tkd[veh])
					end
				end
				
				--DRIVERS DOOR
				if door_ei_enabled then
					if extras.DDoor ~= nil then
						if GetVehicleDoorAngleRatio(veh, 0) > 0.0 then
							UTIL:Print('EI: Drivers door open, calling EI function.', false)
							UTIL:TogVehicleExtras(veh, extras.DDoor, true)
						else
							UTIL:TogVehicleExtras(veh, extras.DDoor, false)
						end
					end
					if extras.PDoor ~= nil then
						if GetVehicleDoorAngleRatio(veh, 1) > 0.0 then
							UTIL:TogVehicleExtras(veh, extras.PDoor, true)
						else
							UTIL:TogVehicleExtras(veh, extras.PDoor, false)
						end
					end
					if extras.Trunk ~= nil then
						if GetVehicleDoorAngleRatio(veh, 5) > 0.0 then
							UTIL:TogVehicleExtras(veh, extras.Trunk, true)
						else
							UTIL:TogVehicleExtras(veh, extras.Trunk, false)
						end
					end
				end
				
				--SIREN CONTROLLER STATES
				if player_is_emerg_driver and siren_controller_ei_enabled then 
					if extras.MainSiren ~= nil then
						if state_lxsiren[veh] ~= nil and state_lxsiren[veh] > 0 then
							UTIL:TogVehicleExtras(veh, extras.MainSiren, true)
						else
							UTIL:TogVehicleExtras(veh, extras.MainSiren, false)
						end
					end					
					if extras.AuxSiren ~= nil then
						if state_pwrcall[veh] ~= nil and state_pwrcall[veh] > 0 then
							UTIL:TogVehicleExtras(veh, extras.AuxSiren, true)
						else
							UTIL:TogVehicleExtras(veh, extras.AuxSiren, false)
						end
					end					
					if extras.AirHorn ~= nil then
						if actv_horn ~= nil and actv_horn and not actv_manu then
							UTIL:TogVehicleExtras(veh, extras.AirHorn, true)
						else
							UTIL:TogVehicleExtras(veh, extras.AirHorn, false)
						end
					end					
					if extras.Manu ~= nil then
						if actv_manu ~= nil and actv_manu then
							UTIL:TogVehicleExtras(veh, extras.Manu, true)
						else
							UTIL:TogVehicleExtras(veh, extras.Manu, false)
						end
					end
				end
            end
			Citizen.Wait(0)
        end
		Citizen.Wait(1000)
    end
end)

-----------AUTO BRAKE LIGHTS INTEGRATION------------
Citizen.CreateThread(function()
	while true do
		if ei_masterswitch and auto_brake_lights then
			if player_is_emerg_driver and veh ~= nil then
				if GetEntitySpeed(veh) < 0.2 and GetIsVehicleEngineRunning(veh) and ( not auto_park or stopped_timer < auto_park_time_lookup[auto_park_time_index] ) then
					SetVehicleBrakeLights(veh, true)
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

Citizen.CreateThread(function()
	while true do
		if ei_masterswitch and auto_brake_lights and auto_park then
			if player_is_emerg_driver and veh ~= nil then
				while GetEntitySpeed(veh) < 0.2 and GetIsVehicleEngineRunning(veh) and auto_park do
					if stopped_timer < auto_park_time_lookup[auto_park_time_index] then
						Citizen.Wait(1000)
						stopped_timer = stopped_timer + 1000						
					end
					Citizen.Wait(0)
				end
				stopped_timer = 0
			else
				Citizen.Wait(500)
			end
		else
			Citizen.Wait(500)
		end
		Citizen.Wait(0)
	end
end)

--[[ Feature Removed
----------------HANDBRAKE TO PARK-----------------
Citizen.CreateThread(function()
	while true do
		if handbrake_to_park and auto_brake_lights then
			if player_is_emerg_driver and veh ~= nil then
				if GetEntitySpeed(veh) < 0.2 then
					if not parked then
						local count = 0
						if IsControlPressed(0, 76) then
							while IsControlPressed(0, 76) and count < 25 do
								count = count + 1
								HUD:ShowText(0.5, 0.7, 1, count, 0.5)
								Citizen.Wait(0)
							end
							if count == 25 then
								PlayAudio('Shift', 0.02, true)
								SetVehicleHandbrake(veh, true)
								parked = true
							end
						end
					else
						if park_hud_x ~= 0.0 or park_hud_y ~= 0.0 then
							HUD:ShowText(park_hud_x, park_hud_y, 1, '~r~P', 0.5)
							HUD:ShowText(park_hud_x + 0.003, park_hud_y + 0.019, 1, '~r~ARK', 0.15)
						end
						if IsControlJustPressed(0, 76) then
							PlayAudio('Shift', 0.02, true)
							SetVehicleHandbrake(veh, false)
							parked = false
						end
						DisableControlAction(0, 72)
						if IsDisabledControlPressed(0, 72) then
							SetControlNormal(0, 71, GetDisabledControlNormal(0, 72))
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
]]

---------------ON RESOURCE STARTUP-----------------
 Citizen.CreateThread(function()
	Citizen.Wait(500)
	UTIL:FixOversizeKeys(EXTRA_ASSIGNMENTS)
end) 

---------------------------------------------------------------------
--Triggered when vehicle changes (cl_lvc.lua)
RegisterNetEvent('lvc:onVehicleChange')
AddEventHandler('lvc:onVehicleChange', function()
	if player_is_emerg_driver and veh ~= nil then
		EI:UpdateExtrasTable(veh)
	end
end)

--[[Sets extras table a copy of EXTRA_ASSIGNMENTS for this vehicle]]
function EI:UpdateExtrasTable(veh)
	local veh_name = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
	local veh_name_wildcard = string.gsub(veh_name, '%d+', '#')

	if EXTRA_ASSIGNMENTS[veh_name] ~= nil then				--Does profile exist as outlined in vehicle.meta
		extras = EXTRA_ASSIGNMENTS[veh_name]
		UTIL:Print('EI: Profile found for '..veh_name, false)
	elseif EXTRA_ASSIGNMENTS[veh_name_wildcard] ~= nil then				
		extras = EXTRA_ASSIGNMENTS[veh_name_wildcard]
		UTIL:Print('EI: Wildcard profile found for '..veh_name, false)
	else
		if EXTRA_ASSIGNMENTS['DEFAULT'] ~= nil then
			extras = EXTRA_ASSIGNMENTS['DEFAULT']
			UTIL:Print('EI: using default profile for '..veh_name, false)
		else
			extras = { }
			UTIL:Print('^3LVC WARNING: (EXTRA_INTEGRATION) "DEFAULT" table missing from EXTRA_ASSIGNMENTS table. Using empty table for '..veh_name, false)
		end	end
end