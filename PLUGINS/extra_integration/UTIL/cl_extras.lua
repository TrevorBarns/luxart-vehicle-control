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
EI = { }

-- Local variable to be set, do not edit.
local enabled_triggers = {
	['Brake'] 		= false,
	['Reverse'] 	= false,
	['RIndicator'] 	= false,
	['LIndicator'] 	= false,
	['Takedowns'] 	= false,
	['DSeat']		= false,
	['DDoor']		= false,
	['PDoor'] 		= false,
	['Trunk'] 		= false,
	['MainSiren'] 	= false,
	['AuxSiren'] 	= false,
	['AirHorn'] 	= false,
	['Manu']		= false
}

local ei_active = false
local accel_pedal = 0
local extras = { }
local auto_park_time_lookup = { [2] = 30000, [3] = 60000, [4] = 300000 }
local profile = ''
local stopped_timer = 0
local auto_park_time_index = 2
local prior_state = { }
local blackout = false

----------------REGISTERED COMMANDS---------------
--Toggles blackout mode
RegisterCommand('lvcblackout', function(source, args, rawCommand)
	blackout = not blackout
	EI:Blackout(blackout)
end)

RegisterKeyMapping('lvcblackout', Lang:t('plugins.ei_control_desc'), 'keyboard', default_blackout_control)
TriggerEvent('chat:addSuggestion', '/lvcblackout', Lang:t('plugins.ei_command_desc'))

----------------THREADED FUNCTIONS----------------
--[[Startup Initialization]]
 CreateThread(function()
	Wait(500)
	UTIL:FixOversizeKeys(EXTRA_ASSIGNMENTS)
end) 

CreateThread( function()
	while ei_masterswitch do
		ei_active = player_is_emerg_driver
		Wait(2000)
	end
end)

--[[Function caller for extra state checking.]]
--	If driver then call RefreshExtras ever 50ms to toggle states.
CreateThread( function()
    while true do
        while ei_masterswitch do
			if ei_active and veh ~= nil and extras ~= false then
				EI:RefreshExtras() 
			end
			Wait(50)
        end
		Wait(500)
    end
end)

--[[Extra State Trigger Control]]
--	Determines vehicles state and sets Triggers
CreateThread( function()
    while true do
        while ei_masterswitch do
			if ei_active and veh ~= nil and extras ~= false then
				for extra_id, trigger_table in pairs(extras) do
					if trigger_table.toggle ~= nil then
						local t = trigger_table.toggle
						------------------------------------------------------------
						--BRAKE LIGHTS
						if brakes_ei_enabled and enabled_triggers['Brakes'] then
							if ( not auto_park or stopped_timer < auto_park_time_lookup[auto_park_time_index] ) and 	-- Auto Park Check
							   ( GetControlNormal(1, 72) > 0.1 or 														-- Brake (LTrigger) 0.0-1.0
							   ( GetControlNormal(1, 72) > 0.0 and GetControlNormal(1, 71) > 0.0 ) or 					-- Brake & Gas at same time
							   ( GetEntitySpeed(veh) < 0.2 and GetIsVehicleEngineRunning(veh) )) and					-- Vehicle is stopped 
							   ( not ( accel_pedal < 0.0 or tostring(accel_pedal) == '-0.0')) then						-- Is vehicle not reversing or at max reverse speed
								EI:SetState('Brake', true)
							else
								EI:SetState('Brake', false)				
							end
						elseif t['Brake'] ~= nil then
							EI:SetState('Brake', false)
						end
						------------------------------------------------------------
						--REVERSE LIGHTS
						if reverse_ei_enabled and enabled_triggers['Reverse'] then
							accel_pedal = GetVehicleThrottleOffset(veh)
							if accel_pedal < 0 or tostring(accel_pedal) == '-0.0' then
								EI:SetState('Reverse', true)
							else
								EI:SetState('Reverse', false)
							end
						end	
						------------------------------------------------------------
						--INDICATORS
						if indicators_ei_enabled and enabled_triggers['LIndicator'] and enabled_triggers['RIndicator'] then
							if state_indic[veh] == 1 then
								EI:SetState('LIndicator', true)
							elseif state_indic[veh] == 2 then
								EI:SetState('RIndicator', true)				
							elseif state_indic[veh] == 3 then
								EI:SetState('LIndicator', true)
								EI:SetState('RIndicator', true)							
							else
								EI:SetState('LIndicator', false)
								EI:SetState('RIndicator', false)											
							end
						end
						------------------------------------------------------------
						--TAKEDOWNS--
						if takedown_ei_enabled and tkd_masterswitch and enabled_triggers['Takedowns'] then
							if state_tkd[veh] ~= nil and state_tkd[veh] then
								EI:SetState('Takedowns', true)
							elseif trigger_table.active['Takedowns'] == true then
								EI:SetState('Takedowns', false)
							end
						end
						------------------------------------------------------------
						--DOORS--
						if door_ei_enabled then
							if enabled_triggers['DDoor'] then
								if GetVehicleDoorAngleRatio(veh, 0) > 0.0 then
									EI:SetState('DDoor', true)							
								elseif trigger_table.active['DDoor'] == true then
									EI:SetState('DDoor', false)		
								end
							end
							if enabled_triggers['PDoor'] then
								if GetVehicleDoorAngleRatio(veh, 1) > 0.0 then
									EI:SetState('PDoor', true)		
								elseif trigger_table.active['PDoor'] == true then
									EI:SetState('PDoor', false)		
								end
							end
							if enabled_triggers['Trunk'] then
								if GetVehicleDoorAngleRatio(veh, 5) > 0.0 then
									EI:SetState('Trunk', true)	
								elseif trigger_table.active['Trunk'] == true then
									EI:SetState('Trunk', false)	
								end
							end
						end						
						------------------------------------------------------------
						--SEATS--
						if seat_ei_enabled then
							if enabled_triggers['DSeat'] then
								if not IsVehicleSeatFree(veh, -1) then
									EI:SetState('DSeat', true)			
									Wait(1750)
								elseif trigger_table.active['DSeat'] == true then
									EI:SetState('DSeat', false)
									Wait(1750)									
								end
							end
						end
						------------------------------------------------------------
						--MAIN SIREN
						if siren_controller_ei_enabled then
							if enabled_triggers['MainSiren'] then
								if state_lxsiren[veh] ~= nil and state_lxsiren[veh] > 0 then
									EI:SetState('MainSiren', true)							
								elseif trigger_table.active['MainSiren'] == true then
									EI:SetState('MainSiren', false)		
								end
							end
							--AUXILARY SIREN
							if enabled_triggers['AuxSiren'] then
								if state_pwrcall[veh] ~= nil and state_pwrcall[veh] > 0 then
									EI:SetState('AuxSiren', true)							
								elseif trigger_table.active['AuxSiren'] == true then
									EI:SetState('AuxSiren', false)		
								end
							end	
							--AIRHORN
							if enabled_triggers['AirHorn'] then
								if actv_horn ~= nil and actv_horn and not actv_manu then
									EI:SetState('AirHorn', true)							
								elseif trigger_table.active['AirHorn'] == true then
									EI:SetState('AirHorn', false)		
								end
							end
							--MANUAL TONE
							if enabled_triggers['Manu'] then
								if actv_manu ~= nil and actv_manu then
									EI:SetState('Manu', true)							
								elseif trigger_table.active['Manu'] == true then
									EI:SetState('Manu', false)		
								end
							end
						end
						------------------------------------------------------------
					end 
				end
			end
			Wait(50)
        end
		Wait(1000)
    end
end)

--[[Auto Brake Light Control]]
--	Automatically turns on vehicle brake lights and forces off when in blackout mode.
CreateThread(function()
	while ei_masterswitch do
		if auto_brake_lights then
			if temp_blackout then
				SetVehicleLights(veh, 0)
			end
			
			if player_is_emerg_driver and veh ~= nil then
				if GetEntitySpeed(veh) < 0.2 and GetIsVehicleEngineRunning(veh) and ( not auto_park or stopped_timer < auto_park_time_lookup[auto_park_time_index] ) then
					SetVehicleBrakeLights(veh, true)
				end
			else
				Wait(500)
			end
		else
			temp_blackout = true
			SetVehicleLights(veh, 1)
			SetVehicleBrakeLights(veh, false)
		end
		Wait(0)
	end
end)

--[[Auto Park Control]]
--	Turns off brakelights after being stopped for extended period of time
CreateThread(function()
	while ei_masterswitch do
		if auto_brake_lights and auto_park then
			if player_is_emerg_driver and veh ~= nil then
				while GetEntitySpeed(veh) < 0.2 and GetIsVehicleEngineRunning(veh) and auto_park do
					if stopped_timer < auto_park_time_lookup[auto_park_time_index] then
						Wait(1000)
						stopped_timer = stopped_timer + 1000	
					end
					Wait(0)
				end
				stopped_timer = 0
			else
				Wait(500)
			end
		else
			Wait(500)
		end
		Wait(0)
	end
end)

---------------------FUNCTIONS--------------------
--[Toggles blackout mode]
--	Disabled vehicles headlights, 
function EI:Blackout(state)
	if state then
		prior_state.auto_brake_lights = auto_brake_lights
		prior_state.brakes_ei_enabled = brakes_ei_enabled
		
		auto_brake_lights = false
		brakes_ei_enabled = false
	else
		auto_brake_lights = prior_state.auto_brake_lights
		brakes_ei_enabled = prior_state.brakes_ei_enabled
	end
end

--[[Set state table]]
function EI:SetState(trigger_to_set, state)
	for extra_id, trigger_table in pairs(extras) do
		if trigger_table.toggle ~= nil then
			for i, trigger in ipairs(trigger_table.toggle) do
				if trigger == trigger_to_set then
					if state then
						trigger_table.active[trigger_to_set] = true
					else
						trigger_table.active[trigger_to_set] = nil						
					end
				end
			end
		end
	end
end

--[[Set extras state based on state table]]
function EI:RefreshExtras() 
	for extra_id, trigger_table in pairs(extras) do
		local count = 0
		for i,v in pairs(trigger_table.active) do
			--print(i, v)
			count = count + 1
		end
		
		local active = true
		if trigger_table.reverse then
			active = false
		end
		
		if count > 0 then
			UTIL:TogVehicleExtras(veh, extra_id, active, trigger_table.repair or false)
		else
			UTIL:TogVehicleExtras(veh, extra_id, not active, trigger_table.repair or false)
		end
	end
end

--[[RageUI Menu Getter/Setters]]
function EI:GetStoppedTimer()
	return stopped_timer
end

function EI:GetParkTimeIndex()
	return auto_park_time_index
end

function EI:SetParkTimeIndex(index)
	if index ~= nil and auto_park_time_lookup[index] ~= nil then
		auto_park_time_index = index
	end
end

function EI:SetAutoPark(state)
	auto_park = state
end

function EI:GetAutoBrakeLightsState()
	return auto_brake_lights
end

---------------------------------------------------------------------
--Triggered when vehicle changes (cl_lvc.lua)
RegisterNetEvent('lvc:onVehicleChange')
AddEventHandler('lvc:onVehicleChange', function()
	--disable (reset) all triggers to off before setting assigned triggers
	for trigger, state in ipairs(enabled_triggers) do
		state = false
	end

	if player_is_emerg_driver and veh ~= nil then
		extras, profile = UTIL:GetProfileFromTable('EXTRA_ASSIGNMENTS', EXTRA_ASSIGNMENTS, veh)
		if profile then
			for extra_id, trigger_table in pairs(extras) do
				--Initialize active tables
				trigger_table.active = { }
				
				--Alert if extra table found that does not align with vehicle configuration.
				if not DoesExtraExist(veh, extra_id) then
					UTIL:Print(Lang:t('plugins.ei_invalid_exta', { extra = extra_id, profile = profile}), true)
				end
				
				--Enable triggers for extras that exist
				if trigger_table.toggle ~= nil then
					for _, trigger in pairs(trigger_table.toggle) do
						if enabled_triggers[trigger] == false then
							enabled_triggers[trigger] = true
						end
					end
				end				
				if trigger_table.add ~= nil then
					for _, trigger in pairs(trigger_table.add) do
						if enabled_triggers[trigger] == false then
							enabled_triggers[trigger] = true
						end
					end
				end		
				if trigger_table.remove ~= nil then
					for _, trigger in pairs(trigger_table.remove) do
						if enabled_triggers[trigger] == false then
							enabled_triggers[trigger] = true
						end
					end
				end
			end
		end
	end
end)
