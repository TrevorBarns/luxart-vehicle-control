--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
Traffic Advisor Plugin by Dawson
---------------------------------------------------
FILE: cl_advisor.lua
PURPOSE: Contains threads, functions to 
change traffic advisor state through extras.
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
	TA = {}
	local taExtras = {}
	local profile = false
	local temp_hud_disable
	TA.preserve_ta_state = false
	TA.sync_ta_state = false
	TA.block_incorrect_combo = false
	state_ta = {}

	local count_taclean_timer = 0
	local delay_taclean_timer = 400
	local count_bcast_timer = 0
	local delay_bcast_timer = 200

	----------------THREADED FUNCTIONS----------------
	--[[TA State Syncing]]
	--Broadcasts TA states to other players and cleans up invalid entities. 
	CreateThread(function()
		while false do --Disabled until syncing implemented.
			--CLEANUP DEAD TA States
			if count_taclean_timer > delay_taclean_timer then
				count_taclean_timer = 0
				for k, v in pairs(state_ta) do
					if v > 0 then
						if not DoesEntityExist(k) or IsEntityDead(k) then
							state_ta[k] = nil
						end
					end
				end
			else
				count_taclean_timer = count_taclean_timer + 1
			end
			
			----- AUTO BROADCAST TA STATES -----
			if count_bcast_timer > delay_bcast_timer then
				count_bcast_timer = 0
				TriggerServerEvent('lvc:SetTAState_s', state_ta[veh])
			else
				count_bcast_timer = count_bcast_timer + 1
			end		
			Wait(0)
		end
	end)

	--[[Toggle TA when lights are turned on.]]
	CreateThread(function()
		while true do 
			if player_is_emerg_driver then
				if state_ta[veh] ~= nil and state_ta[veh] > 0 then
					if not IsVehicleSirenOn(veh) and not temp_hud_disable then
						HUD:SetItemState('ta', false)
						temp_hud_disable = true
						if not TA.preserve_ta_state then
							if state_ta[veh] == 1 then
								UTIL:TogVehicleExtras(veh, taExtras.left.off, true)
							elseif state_ta[veh] == 2 then
								UTIL:TogVehicleExtras(veh, taExtras.right.off, true)
							elseif state_ta[veh] == 3 then
								UTIL:TogVehicleExtras(veh, taExtras.middle.off, true)
							end
							state_ta[veh] = 0
						end
					elseif IsVehicleSirenOn(veh) and temp_hud_disable then
						HUD:SetItemState('ta', state_ta[veh])
						temp_hud_disable = false
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

	RegisterCommand('lvctogleftta', function(source, args, rawCommand)
		if ta_combokey == false or IsControlPressed(0, ta_combokey) then
			if player_is_emerg_driver and ( taExtras.lightbar ~= nil or taExtras.lightbar == -1 ) and veh ~= nil and not IsMenuOpen() and not key_lock then
				if ( IsVehicleExtraTurnedOn(veh, taExtras.lightbar) or taExtras.lightbar == -1 ) and IsVehicleSirenOn(veh) then
					if state_ta[veh] == 1 then
						UTIL:TogVehicleExtras(veh, taExtras.left.off, true)
						AUDIO:Play('Downgrade', AUDIO.downgrade_volume)
						state_ta[veh] = 0
					else
						UTIL:TogVehicleExtras(veh, taExtras.left.on, true)
						AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
						state_ta[veh] = 1
					end
					HUD:SetItemState('ta', state_ta[veh]) 					
				end
			end
		end
	end)

	RegisterCommand('lvctogrightta', function(source, args, rawCommand)
		if ta_combokey == false or IsControlPressed(0, ta_combokey) then
			if player_is_emerg_driver and ( taExtras.lightbar ~= nil or taExtras.lightbar == -1 ) and veh ~= nil and not IsMenuOpen() and not key_lock then
				if ( IsVehicleExtraTurnedOn(veh, taExtras.lightbar) or taExtras.lightbar == -1 ) and IsVehicleSirenOn(veh) then
					if state_ta[veh] == 2 then
						UTIL:TogVehicleExtras(veh, taExtras.right.off, true)
						AUDIO:Play('Downgrade', AUDIO.downgrade_volume)
						state_ta[veh] = 0
					else
						UTIL:TogVehicleExtras(veh, taExtras.right.on, true)
						AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
						state_ta[veh] = 2
					end
					HUD:SetItemState('ta', state_ta[veh]) 
				end
			end
		end
	end)

	RegisterCommand('lvctogmidta', function(source, args, rawCommand)
		if ta_combokey == false or IsControlPressed(0, ta_combokey) then
			if player_is_emerg_driver and ( taExtras.lightbar ~= nil or taExtras.lightbar == -1 ) and veh ~= nil and not IsMenuOpen() and not key_lock then
				if ( IsVehicleExtraTurnedOn(veh, taExtras.lightbar) or taExtras.lightbar == -1 ) and IsVehicleSirenOn(veh) then
					if state_ta[veh] == 3 then
						UTIL:TogVehicleExtras(veh, taExtras.middle.off, true)
						AUDIO:Play('Downgrade', AUDIO.downgrade_volume)
						state_ta[veh] = 0
					else
						UTIL:TogVehicleExtras(veh, taExtras.middle.on, true)
						AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
						state_ta[veh] = 3
					end
					HUD:SetItemState('ta', state_ta[veh]) 					
				end
			end
		end
	end)

	RegisterKeyMapping('lvctogleftta', Lang:t('plugins.ta_control_desc_left'), 'keyboard', 'left')
	RegisterKeyMapping('lvctogrightta', Lang:t('plugins.ta_control_desc_right'), 'keyboard', 'right')
	RegisterKeyMapping('lvctogmidta', Lang:t('plugins.ta_control_desc_middle'), 'keyboard', 'down')

	CreateThread(function()
		Wait(500)
		UTIL:FixOversizeKeys(TA_ASSIGNMENTS)
	end) 

	RegisterNetEvent('lvc:onVehicleChange')
	AddEventHandler('lvc:onVehicleChange', function()
		if player_is_emerg_driver and veh ~= nil then
			taExtras, profile = UTIL:GetProfileFromTable('TA ASSIGNMENTS', TA_ASSIGNMENTS, veh, true)
			hud_pattern = taExtras.hud_pattern or 1
			HUD:SetItemState('ta_pattern', hud_pattern)

			if state_ta[veh] == nil then
				state_ta[veh] = 0
			end
		end
	end)

	RegisterNetEvent('lvc:SetTAState_c')
	AddEventHandler('lvc:SetTAState_c', function(sender, newstate)
		local player_s = GetPlayerFromServerId(sender)
		local ped_s = GetPlayerPed(player_s)
		if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
			if ped_s ~= GetPlayerPed(-1) then
				if IsPedInAnyVehicle(ped_s, false) then
					local veh = GetVehiclePedIsUsing(ped_s)
					TA:SetTAStateForVeh(veh, newstate)
				end
			end
		end
	end)

	function TA:SetTAStateForVeh(veh, newstate)
		if DoesEntityExist(veh) and not IsEntityDead(veh) then
			if newstate ~= state_ta[veh] then
			  state_ta[veh] = newstate
			end
		end
	end
end
