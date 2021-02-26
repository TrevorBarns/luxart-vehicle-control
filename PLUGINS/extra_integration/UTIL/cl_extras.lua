--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Last revision: FEBRUARY 26 2021 (VERS. 3.2.1)
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

local brake_pedal
local accel_pedal
local extras = { }

------BRAKE, REVERSE, TKD - EXTRA INTEGRATION------
Citizen.CreateThread( function()
    while true do
        while extra_integration_masterswitch do
            if player_is_emerg_driver and veh ~= nil then				
				if brakes_ei_enabled and extras.Brake ~= nil then
					brake_pedal = GetVehicleWheelBrakePressure(veh, 0)
					if brake_pedal > 0.1 or ( GetEntitySpeed(veh) < 0.2 and GetIsVehicleEngineRunning(veh) ) then
						if not IsVehicleExtraTurnedOn(veh, extras.Brake) then
							SetVehicleExtra(veh, extras.Brake, false)
						end
					else
						if IsVehicleExtraTurnedOn(veh, extras.Brake) then
							SetVehicleExtra(veh, extras.Brake, true)
						end						
					end
				end				
				
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
			Citizen.Wait(50)
        end
		Citizen.Wait(1000)
    end
end)

-----------AUTO BRAKE LIGHTS INTEGRATION------------
Citizen.CreateThread(function()
	while true do
		if player_is_emerg_driver and veh ~= nil then
			if extra_integration_masterswitch and auto_brake_lights then
				if GetEntitySpeed(veh) < 0.2 and GetIsVehicleEngineRunning(veh) then
					SetVehicleBrakeLights(veh, true)
				end
			end
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
			HUD:ShowNotification("~b~LVC: ~r~Error: Extra "..extra_id.." does not exist for veh_name")
		end
	end
end

