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
auto_park 			 = auto_park
auto_park_time_index = 2
auto_brake_lights 	 = auto_brake_lights
brakes_ei_enabled 	 = brakes_ei_enabled



------BRAKE, REVERSE, TKD - EXTRA INTEGRATION------
Citizen.CreateThread( function()
    while true do
        while ei_masterswitch do
            if player_is_emerg_driver and veh ~= nil then	
				--BRAKE LIGHTS
				if extras.Brake ~= nil then
					if brakes_ei_enabled and extras.Brake ~= nil then
						if ( not auto_park or stopped_timer < auto_park_time_lookup[auto_park_time_index] ) and 	-- Auto Park Check
						   ( GetControlNormal(1, 72) > 0.1 or 														-- Brake (LTrigger) 0.0-1.0
						   ( GetControlNormal(1, 72) > 0.0 and GetControlNormal(1, 71) > 0.0 ) or 					-- Brake & Gas at same time
						   ( GetEntitySpeed(veh) < 0.2 and GetIsVehicleEngineRunning(veh) )) and					-- Vehicle is stopped 
						   ( not ( accel_pedal < 0 )) then															-- Is vehicle not reversing
							if not IsVehicleExtraTurnedOn(veh, extras.Brake) then
								SetVehicleExtra(veh, extras.Brake, false)
							end
						else
							if IsVehicleExtraTurnedOn(veh, extras.Brake) then
								SetVehicleExtra(veh, extras.Brake, true)
							end						
						end
					else
						if IsVehicleExtraTurnedOn(veh, extras.Brake) then
							SetVehicleExtra(veh, extras.Brake, true)
						end						
					end
				end
				
				--REVERSE LIGHTS
				if reverse_ei_enabled and extras.Reverse ~= nil then
					accel_pedal = GetVehicleThrottleOffset(veh)
					if accel_pedal < 0 then
						if not IsVehicleExtraTurnedOn(veh, extras.Reverse) then
							SetVehicleExtra(veh, extras.Reverse, false)
						end
					else
						if IsVehicleExtraTurnedOn(veh, extras.Reverse) then
							SetVehicleExtra(veh, extras.Reverse, true)
						end						
					end
				end					
				
				--TAKEDOWNS
				if takedown_ei_enabled and tkd_masterswitch and extras.Takedowns ~= nil then
					if state_tkd[veh] ~= nil and state_tkd[veh] then
						if not IsVehicleExtraTurnedOn(veh, extras.Takedowns) then
							SetVehicleExtra(veh, extras.Takedowns, false)
						end
					else
						if IsVehicleExtraTurnedOn(veh, extras.Takedowns) then
							SetVehicleExtra(veh, extras.Takedowns, true)
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
		if player_is_emerg_driver and veh ~= nil then
			if ei_masterswitch and auto_brake_lights then
				if GetEntitySpeed(veh) < 0.2 and GetIsVehicleEngineRunning(veh) and ( not auto_park or stopped_timer < auto_park_time_lookup[auto_park_time_index] ) then
					SetVehicleBrakeLights(veh, true)
				end
			end
		end
		Citizen.Wait(0)
	end
end)

Citizen.CreateThread(function()
	while true do
		if player_is_emerg_driver and veh ~= nil then
			if ei_masterswitch and auto_brake_lights and auto_park then
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

-----------INDICATORS EXTRA INTEGRATION------------
--[[
 Citizen.CreateThread(function()
	while true do
		if player_is_emerg_driver and veh ~= nil then
			if indicators_ei_enabled then
				while state_indic[veh] == 1 do
					SetVehicleExtra(veh, extras.LIndicator, false)
					Citizen.Wait(500)
					SetVehicleExtra(veh, extras.LIndicator, true)
					Citizen.Wait(500)
				end
				SetVehicleExtra(veh, extras.LIndicator, true)
				
				while state_indic[veh] == 2 do
					SetVehicleExtra(veh, extras.RIndicator, false)
					Citizen.Wait(500)
					SetVehicleExtra(veh, extras.RIndicator, true)
					Citizen.Wait(500)
				end
				SetVehicleExtra(veh, extras.RIndicator, true)
				
				while state_indic[veh] == 3 do
					SetVehicleExtra(veh, extras.LIndicator, false)
					SetVehicleExtra(veh, extras.RIndicator, false)
					Citizen.Wait(500)
					SetVehicleExtra(veh, extras.LIndicator, true)
					SetVehicleExtra(veh, extras.RIndicator, true)
					Citizen.Wait(500)
				end
				SetVehicleExtra(veh, extras.LIndicator, true)
				SetVehicleExtra(veh, extras.RIndicator, true)
			end
		end
		Citizen.Wait(0)
	end
end) 
]]

---------------ON RESOURCE STARTUP-----------------
 Citizen.CreateThread(function()
	Citizen.Wait(500)
	EI:FixOversizeKeys()
end) 

---------------------------------------------------------------------
--Triggered when vehicle changes (cl_lvc.lua)
RegisterNetEvent('lvc:onVehicleChange')
AddEventHandler('lvc:onVehicleChange', function()
	if player_is_emerg_driver and veh ~= nil then
		EI:UpdateExtrasTable(veh)
	end
end)

---------------------------------------------------------------------
--[[Shorten oversized <gameName> strings in EXTRA_ASSIGNMENTS (extra_integration/SETTINGS.LUA). 
    GTA only allows 11 characters. So to reduce confusion we'll shorten it if the user does not.]]
function EI:FixOversizeKeys()
	for i, tbl in pairs(EXTRA_ASSIGNMENTS) do
		if string.len(i) > 11 then
			local shortened_gameName = string.sub(i,1,11)
			EXTRA_ASSIGNMENTS[shortened_gameName] = EXTRA_ASSIGNMENTS[i]
			EXTRA_ASSIGNMENTS[i] = nil
		end
	end
end

--[[Sets extras table a copy of EXTRA_ASSIGNMENTS for this vehicle]]
function EI:UpdateExtrasTable(veh)
	local veh_name = UTIL:GetVehicleProfileName()
	if EXTRA_ASSIGNMENTS[veh_name] ~= nil then				--Does profile exist as outlined in vehicle.meta
		extras = EXTRA_ASSIGNMENTS[veh_name]
	else 
		extras = EXTRA_ASSIGNMENTS['DEFAULT']
	end
	
	for type, extra_id in pairs(extras) do
		if not DoesExtraExist(veh, extra_id) then
			HUD:ShowNotification("~b~LVC: ~r~Error: Extra "..extra_id.." does not exist for veh_name", true)
		end
	end
end

