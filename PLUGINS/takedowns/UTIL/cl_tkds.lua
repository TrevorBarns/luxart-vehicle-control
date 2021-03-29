--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: cl_tkds.lua
PURPOSE: Contains takedown threads, functions, etc.
---------------------------------------------------
]]

local count_tkdclean_timer = 0
local delay_tkdclean_timer = 400
local count_bcast_timer = 0
local delay_bcast_timer = 200
state_tkd = {}
local TKDS = {}

local light_start_pos = nil
local light_end_pos = nil
local light_direction = nil
local veh_dist = {}

tkd_intensity		= tkd_intensity_default
tkd_radius 			= tkd_radius_default
tkd_distance 		= tkd_distance_default
tkd_falloff 		= tkd_falloff_default
tkd_mode 			= tkd_highbeam_integration_default
tkd_sync_radius 	= tkd_sync_radius^2
tkd_scheme 			= 1

local tkd_scheme_lookup = {
	{ start_y = 1.0, start_z = 1.0, end_y = 10.0, end_z = -1.0},
	{ start_y = 1.0, start_z = 2.0, end_y = 10.0, end_z = 0.0},
	{ start_y = 1.5, start_z = 1.0, end_y = 10.0, end_z = 1.0},
	{ start_y = 2.25, start_z = 1.0, end_y = 10.0, end_z = 1.0},
}

------TAKE DOWN THREADS------
Citizen.CreateThread(function()
	while true do
		if tkd_masterswitch then	
			--CLEANUP DEAD TKDS
			if count_tkdclean_timer > delay_tkdclean_timer then
				count_tkdclean_timer = 0
				for k, v in pairs(state_tkd) do
					if v == true then
						if not DoesEntityExist(k) or IsEntityDead(k) then
							state_tkd[k] = nil
						end
					end
				end
			else
				count_tkdclean_timer = count_tkdclean_timer + 1
			end
			
			if player_is_emerg_driver and UpdateOnscreenKeyboard() ~= 0 then
				----- CONTROLS -----
				if not IsPauseMenuActive() then
					if not key_lock and tkd_mode ~= 3 then
						if IsControlPressed(0, tkd_combokey) or tkd_combokey == false  then
							DisableControlAction(0, tkd_key, true)
							if IsDisabledControlJustReleased(0, tkd_key) then
								if state_tkd[veh] == true then
									if tkd_mode == 2 then
										SetVehicleFullbeam(veh, false)
									end
									TKDS:TogTkdStateForVeh(veh, false)										
									PlayAudio("Downgrade", downgrade_volume) 
								else
									if tkd_mode == 2 then
										SetVehicleFullbeam(veh, true)
									end
									TKDS:TogTkdStateForVeh(veh, true)
									PlayAudio("Upgrade", upgrade_volume) 										
								end
								HUD:SetItemState("tkd", state_tkd[veh]) 
								count_bcast_timer = delay_bcast_timer
							end
						end
					end
				end
			end
			----- AUTO BROADCAST VEH STATES -----
			if count_bcast_timer > delay_bcast_timer then
				count_bcast_timer = 0
				TriggerServerEvent('lvc:TogTkdState_s', state_tkd[veh])
			else
				count_bcast_timer = count_bcast_timer + 1
			end		
		else
			Citizen.Wait(500)	
		end
		Citizen.Wait(0)
	end
end)
-----------------------------
-- TKDs: DrawTakeDowns Thread of vehicles within range
Citizen.CreateThread(function()
	while true do
		if tkd_masterswitch then	
			for veh,state in pairs(state_tkd) do
				if veh_dist[veh] ~= nil and veh_dist[veh] < tkd_sync_radius then
					if state then
						TKDS:DrawTakeDown(veh)
					end
				end
			end
		end
		Citizen.Wait(0)
	end
end)

-- Set vehicles distances in table for DrawTakeDowns Thread
Citizen.CreateThread(function()
	while true do
		if tkd_masterswitch then	
			for veh,_ in pairs(state_tkd) do
				if DoesEntityExist(veh) and not IsEntityDead(veh) then
					veh_dist[veh] = Vdist2(GetEntityCoords(playerped), GetEntityCoords(veh))
				end
			end
		end
		Citizen.Wait(500)
	end
end)

--Get Headlight State for TKD Trigger
Citizen.CreateThread(function()
	while true do
		if tkd_masterswitch and player_is_emerg_driver and tkd_mode == 3 then	
			_, veh_lights, veh_headlights  = GetVehicleLightsState(veh)
			if (veh_lights == 1 and veh_headlights == 1) or (veh_lights == 0 and veh_headlights == 1) then
				TKDS:TogTkdStateForVeh(veh, true)
			else
				TKDS:TogTkdStateForVeh(veh, false)
			end
			Citizen.Wait(50)
		else
			Citizen.Wait(1000)
		end
	end
end)

---------------------------------------------------------------------
function TKDS:TogTkdStateForVeh(veh, toggle)
	if DoesEntityExist(veh) and not IsEntityDead(veh) then
		if toggle ~= state_tkd[veh] then
			state_tkd[veh] = toggle
		end
	end
end
---------------------------------------------------------------------
-- Coordinate calculations and drawing of spotlight on passed vehicle.
function TKDS:DrawTakeDown(veh)
	if DoesEntityExist(veh) and not IsEntityDead(veh) and veh_dist[veh] ~= nil then
		light_start_pos = GetOffsetFromEntityInWorldCoords(veh, 0.0, tkd_scheme_lookup[tkd_scheme].start_y, tkd_scheme_lookup[tkd_scheme].start_z) 
		light_end_pos = GetOffsetFromEntityInWorldCoords(veh, 0.0, tkd_scheme_lookup[tkd_scheme].end_y, tkd_scheme_lookup[tkd_scheme].end_z)
		light_direction = vector3(light_end_pos-light_start_pos)	
		DrawSpotLight(light_start_pos, light_direction, 200, 200, 255, tkd_distance+0.0, tkd_intensity+0.0, 0.0, tkd_radius+0.0, tkd_falloff+veh_dist[veh]/2+0.0)

		if GetResourceMetadata(GetCurrentResourceName(), 'debug_mode', 0) == 'true' then
			DrawLine(light_start_pos, light_end_pos, 255, 0, 0, 255)
		end
	end
end

---------------------------------------------------------------------
RegisterNetEvent('lvc:TogTkdState_c')
AddEventHandler('lvc:TogTkdState_c', function(sender, toggle)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local veh = GetVehiclePedIsUsing(ped_s)
				TKDS:TogTkdStateForVeh(veh, toggle)
			end
		end
	end
end)