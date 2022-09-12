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
EI.blackout = false
EI.auto_park_state = false

if ei_masterswitch then
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

	local auto_park_time_lookup = { [1] = 0, [2] = 15000, [3] = 30000, [4] = 60000, [5] = 300000 }
	local auto_park_time_index = 2

	local accel_pedal = 0
	local stopped_timer = 0
	local extras = { }
	local profile = false
	local previous_brake_ei_enabled = false

	----------------REGISTERED COMMANDS---------------
	--Toggles blackout mode
	RegisterCommand('lvcblackout', function(source, args, rawCommand)
		if player_is_emerg_driver then
			EI:SetBlackoutState(not EI.blackout)
		end
	end)

	RegisterKeyMapping('lvcblackout', Lang:t('plugins.ei_control_desc'), 'keyboard', default_blackout_control)
	TriggerEvent('chat:addSuggestion', '/lvcblackout', Lang:t('plugins.ei_command_desc'))

	----------------THREADED FUNCTIONS----------------
	--[[Startup Initialization]]
	 CreateThread(function()
		Wait(500)
		UTIL:FixOversizeKeys(EXTRA_ASSIGNMENTS)
	end) 

	--[[Function caller for extra state checking.]]
	--	If driver then call RefreshExtras ever 50ms to toggle states.
	CreateThread( function()
		while true do
			if veh ~= nil and profile ~= false then
				EI:RefreshExtras() 
			else
				Wait(500)
			end
			Wait(50)
		end
	end)

	--[[Extra State Trigger Control]]
	--	Determines vehicles state and sets Triggers
	CreateThread( function()
		while true do
			if veh ~= nil and profile ~= false then
				if player_is_emerg_driver or run_when_out_of_vehicle then
					for _, trigger_table in pairs(extras) do
						if trigger_table.toggle ~= nil then
							------------------------------------------------------------
							--BRAKE LIGHTS
							if brakes_ei_enabled and enabled_triggers['Brake'] then
								accel_pedal = GetVehicleThrottleOffset(veh)
								if ( not auto_park or stopped_timer < auto_park_time_lookup[auto_park_time_index] ) and 	-- Auto Park Check
								   ( GetControlNormal(1, 72) > 0.1 or 														-- Brake (LTrigger) 0.0-1.0
								   ( GetControlNormal(1, 72) > 0.0 and GetControlNormal(1, 71) > 0.0 ) or 					-- Brake & Gas at same time
								   ( GetEntitySpeed(veh) < 0.2 and GetIsVehicleEngineRunning(veh) )) and					-- Vehicle is stopped 
								   ( not ( accel_pedal < 0.0 or tostring(accel_pedal) == '-0.0')) then						-- Is vehicle not reversing or at max reverse speed
									EI:SetState('Brake', true)
								elseif trigger_table.active['Brake'] == true then
									EI:SetState('Brake', false)				
								end
							end
							------------------------------------------------------------
							--REVERSE LIGHTS
							if reverse_ei_enabled and enabled_triggers['Reverse'] then
								accel_pedal = GetVehicleThrottleOffset(veh)
								if accel_pedal < 0 or tostring(accel_pedal) == '-0.0' then
									EI:SetState('Reverse', true)
								elseif trigger_table.active['Reverse'] == true then
									EI:SetState('Reverse', false)
								end
							end	
							------------------------------------------------------------
							--INDICATORS
							if indicators_ei_enabled and enabled_triggers['LIndicator'] or enabled_triggers['RIndicator'] then
								if state_indic[veh] == 1 then
									EI:SetState('LIndicator', true)
								elseif state_indic[veh] == 2 then
									EI:SetState('RIndicator', true)				
								elseif state_indic[veh] == 3 then
									EI:SetState('LIndicator', true)
									EI:SetState('RIndicator', true)							
								elseif trigger_table.active['LIndicator'] or trigger_table.active['RIndicator'] then
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
										Wait(100)
									elseif trigger_table.active['DDoor'] == true then
										EI:SetState('DDoor', false)		
									end
								end
								if enabled_triggers['PDoor'] then
									if GetVehicleDoorAngleRatio(veh, 1) > 0.0 then
										EI:SetState('PDoor', true)		
										Wait(100)
									elseif trigger_table.active['PDoor'] == true then
										EI:SetState('PDoor', false)		
									end
								end
								if enabled_triggers['Trunk'] then
									if GetVehicleDoorAngleRatio(veh, 5) > 0.0 then
										EI:SetState('Trunk', true)	
										Wait(100)
									elseif trigger_table.active['Trunk'] == true then
										EI:SetState('Trunk', false)	
									end
								end
							end	
							------------------------------------------------------------
							-- SEAT DETECTION (deactivate)
							if seat_ei_enabled then
								if enabled_triggers['DSeat'] then
									if trigger_table.active['DSeat'] == true then
										Wait(1000)
										EI:SetState('DSeat', false)
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
					Wait(50)
				else
					Wait(50)
				end
			else
				Wait(500)
			end
		end
	end)
	
	--[[Auto Park Control]]
	--	Turns off brakelights after being stopped for extended period of time, only for LVC menu enabled vehicles (emergency class)
	CreateThread(function()
		while true do
			if veh ~= nil and profile ~= false then
				if auto_brake_lights and auto_park and not EI.blackout then
					if player_is_emerg_driver then
						while GetEntitySpeed(veh) < 0.1 and GetIsVehicleEngineRunning(veh) and auto_park and not EI.blackout do
							if stopped_timer < auto_park_time_lookup[auto_park_time_index] then
								Wait(1000)
								stopped_timer = stopped_timer + 1000	
							end
							Wait(0)
						end
						stopped_timer = 0
						EI.auto_park_state = false
					else
						Wait(500)
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
		
	CreateThread(function()
		while true do
			if stopped_timer > 0 and not EI.auto_park_state then
				if stopped_timer >= auto_park_time_lookup[auto_park_time_index] then
					EI.auto_park_state = true
				end
			else
				Wait(1000)
			end
			Wait(0)
		end
	end)	
	

	---------------------FUNCTIONS--------------------
	--[Toggles blackout mode]
	--	Disabled vehicles headlights, 
	function EI:SetBlackoutState(state)
		EI.blackout = state
		stopped_timer = 0
		if EI.blackout then
			SetVehicleLights(veh, 1)
			previous_brake_ei_enabled = brakes_ei_enabled
			brakes_ei_enabled = false
			AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
		else
			SetVehicleLights(veh, 0)
			brakes_ei_enabled = previous_brake_ei_enabled
			AUDIO:Play('Downgrade', AUDIO.downgrade_volume)
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

	function EI:GetBlackOutState()
		return EI.blackout
	end

	---------------------------------------------------------------------
	--Clear brakelights and handle exit vehicle state
	RegisterNetEvent('lvc:onVehicleExit')
	AddEventHandler('lvc:onVehicleExit', function()
		if veh ~= nil and profile ~= false then
			-- SEAT DETECTION (activation)
			if seat_ei_enabled then
				if enabled_triggers['DSeat'] then
					if not IsVehicleSeatFree(veh, -1) then
						EI:SetState('DSeat', true)
					end
				end
			end
		end
	end)

	--Triggered when vehicle changes (cl_lvc.lua)
	RegisterNetEvent('lvc:onVehicleChange')
	AddEventHandler('lvc:onVehicleChange', function()
		--disable (reset) all triggers to off before setting assigned triggers
		for trigger, state in ipairs(enabled_triggers) do
			state = false
		end

		extras, profile = UTIL:GetProfileFromTable('EXTRA INTEGRATIONS', EXTRA_ASSIGNMENTS, veh, true)
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
	end)
end