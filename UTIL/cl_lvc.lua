--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Last revision: FEBRUARY 23 2021 (VERS. 3.2.0)
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: cl_lvc.lua
PURPOSE: Core Functionality and User Input
---------------------------------------------------
]]

--GLOBAL VARIABLES used in both menu.lua and client.lua
key_lock = false
tone_main_reset_standby = reset_to_standby_default
tone_airhorn_intrp = airhorn_interrupt_default
park_kill = park_kill_default

airhorn_button_SFX = false
manu_button_SFX = false
activity_reminder_index = 1
last_activity_timer = 0

local light_start_pos = nil
local light_end_pos = nil
local light_direction = nil
tkd_masterswitch = true
tkd_intensity = tkd_intensity_default
tkd_radius = tkd_radius_default
tkd_distance = tkd_distance_default
tkd_falloff = tkd_falloff_default
tkd_scheme = 1
tkd_mode = tkd_highbeam_integration_default
tkd_sync_radius = tkd_sync_radius_default^2
local tkd_scheme_lookup = {
	{ start_y = 1.0, start_z = 1.0, end_y = 10.0, end_z = -1.0},
	{ start_y = 1.0, start_z = 2.0, end_y = 10.0, end_z = 0.0},
	{ start_y = 1.5, start_z = 1.0, end_y = 10.0, end_z = 1.0},
	{ start_y = 2.25, start_z = 1.0, end_y = 10.0, end_z = 1.0},
}


button_sfx_scheme = default_sfx_scheme_name
on_volume = default_on_volume	
off_volume = default_off_volume	
upgrade_volume = default_upgrade_volume	
downgrade_volume = default_downgrade_volume
hazards_volume = default_hazards_volume
lock_volume = default_lock_volume
lock_reminder_volume = default_lock_reminder_volume
activity_reminder_volume = default_reminder_volume

last_veh = nil
veh = nil
player_is_emerg_driver = false
repo_version = nil
							
--LOCAL VARIABLES
local playerped = nil
local activity_reminder_lookup = { [2] = 30000, [3] = 60000, [4] = 120000, [5] = 300000, [6] = 600000 } 
local count_bcast_timer = 0
local delay_bcast_timer = 200

local count_sndclean_timer = 0
local delay_sndclean_timer = 400

local actv_ind_timer = false
local count_ind_timer = 0
local delay_ind_timer = 180

local actv_lxsrnmute_temp = false
local srntone_temp = 0
local dsrn_mute = true

local state_indic = {}
local state_lxsiren = {}
local state_pwrcall = {}
local state_airmanu = {}
local state_tkd = {}
local veh_dist = {}

local ind_state_o = 0
local ind_state_l = 1
local ind_state_r = 2
local ind_state_h = 3

local snd_lxsiren = {}
local snd_pwrcall = {}
local snd_airmanu = {}


TriggerEvent('chat:addSuggestion', '/lvclock', 'Toggle Luxart Vehicle Control Keybinding Lockout.')

----------------THREADED FUNCTIONS----------------
-- Set check variable `player_is_emerg_driver` if player is driver of emergency vehicle.
-- Disables controls faster than previous thread. 
Citizen.CreateThread(function()
	while true do
		playerped = GetPlayerPed(-1)	
		--IS IN VEHICLE
		player_is_emerg_driver = false
		if IsPedInAnyVehicle(playerped, false) then
			veh = GetVehiclePedIsUsing(playerped)	
			--IS DRIVER
			if GetPedInVehicleSeat(veh, -1) == playerped then
				print(GetPedInVehicleSeat(veh, -1))
				--IS EMERGENCY VEHICLE
				if GetVehicleClass(veh) == 18 then
					player_is_emerg_driver = true
					DisableControlAction(0, 86, true) -- INPUT_VEH_HORN	
					DisableControlAction(0, 172, true) -- INPUT_CELLPHONE_UP  
					DisableControlAction(0, 81, true) -- INPUT_VEH_NEXT_RADIO
					DisableControlAction(0, 82, true) -- INPUT_VEH_PREV_RADIO
					DisableControlAction(0, 84, true) -- INPUT_VEH_PREV_RADIO_TRACK  
					DisableControlAction(0, 83, true) -- INPUT_VEH_NEXT_RADIO_TRACK 
					DisableControlAction(0, 19, true) -- INPUT_CHARACTER_WHEEL 
					if IsControlReleased(0, 243) then
						DisableControlAction(0, 85, true) -- INPUT_VEH_RADIO_WHEEL 
					end
					DisableControlAction(0, 80, true) -- INPUT_VEH_CIN_CAM														 									   								
				end
			end
		end
		Citizen.Wait(1)
	end
end)

------TAKE DOWN THREADS------
-- TKDs: DrawTakeDowns Thread of vehicles within range
Citizen.CreateThread(function()
	while true do
		if tkd_masterswitch then	
			for veh,state in pairs(state_tkd) do
				if veh_dist[veh] ~= nil and veh_dist[veh] < tkd_sync_radius then
					if state then
						DrawTakeDown(veh)
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
				TogTkdStateForVeh(veh, true)
			else
				TogTkdStateForVeh(veh, false)
			end
			Citizen.Wait(50)
		else
			Citizen.Wait(1000)
		end
	end
end)

------PARK KILL THREADS------
--Kill siren on Exit
Citizen.CreateThread(function()
	while park_kill or park_kill_masterswitch do
		while park_kill and playerped ~= nil and veh ~= nil do
			if GetIsTaskActive(playerped, 2) then
				if not tone_main_reset_standby and state_lxsiren[veh] ~= 0 then
					tone_main_mem_id = state_lxsiren[veh]
				end
				SetLxSirenStateForVeh(veh, 0)
				SetPowercallStateForVeh(veh, 0)
				SetAirManuStateForVeh(veh, 0)								 
				count_bcast_timer = delay_bcast_timer
				Citizen.Wait(1000)		
			end
			Citizen.Wait(0)		
		end
		Citizen.Wait(1000)
	end
end)

------ACTIVITY REMINDER FUNCTIONALITY------
Citizen.CreateThread(function()
	while true do
		while activity_reminder_index > 1 and player_is_emerg_driver do
			if IsVehicleSirenOn(veh) and state_lxsiren[veh] == 0 and state_pwrcall[veh] == 0 then
				if last_activity_timer < 1 then
					PlayAudio("Reminder", activity_reminder_volume) 
					SetActivityTimer()
				end
			end
			Citizen.Wait(100)
		end
		Citizen.Wait(1000)
	end
end) 

-- Activity Reminder Timer
Citizen.CreateThread(function()
	while true do
		if veh ~= nil then
			while activity_reminder_index > 1 and IsVehicleSirenOn(veh) do
				if last_activity_timer > 1 then
					Citizen.Wait(1000)
					last_activity_timer = last_activity_timer - 1000
				else
					Citizen.Wait(100)
					SetActivityTimer()
				end
			end
		end
		Citizen.Wait(1000)
	end
end)

------VEHICLE CHANGE DETECTION AND TRIGGER------
Citizen.CreateThread(function()
	while true do
		if player_is_emerg_driver and veh ~= nil then
			if last_veh == nil then
				UTIL:UpdateApprovedTones(veh)
				Storage:LoadSettings()
				UTIL:BuildToneOptions()
				last_veh = veh
				SetVehRadioStation(veh, "OFF")
			else
				if last_veh ~= veh then
					UTIL:UpdateApprovedTones(veh)
					Storage:ResetSettings()
					Storage:LoadSettings()
					UTIL:BuildToneOptions()
					last_veh = veh
					SetVehRadioStation(veh, "OFF")
				end
			end
		end
		Citizen.Wait(1000)
	end
end)

--------------REGISTERED COMMANDS---------------
--Toggle LUX lock command
RegisterCommand('lvclock', function(source, args)
	if player_is_emerg_driver then	
		key_lock = not key_lock
		PlayAudio("Key_Lock", lock_volume, true) 
		HUD:SetItemState("lock", key_lock) 
		--if HUD is visible do not show notification
		if not HUD:GetHudState() then
			if key_lock then
				HUD:ShowNotification("Siren Control Box: ~r~Locked")
			else
				HUD:ShowNotification("Siren Control Box: ~g~Unlocked")				
			end
		end
	end
end)

RegisterKeyMapping("lvclock", "LVC: Lock out controls", "keyboard", lockout_default_hotkey)

------------------------------------------------
--Dynamically Run RegisterCommand and KeyMapping functions for all 14 possible sirens
--Then at runtime "slide" all sirens down removing any restricted sirens.
function RegisterKeyMaps()
	for i, _ in ipairs(SIRENS) do
		if i ~= 1 then
			local command = "_lvc_siren_" .. i-1
			local description = "LVC Siren: " .. MakeOrdinal(i-1)
			
			RegisterCommand(command, function(source, args)
				if veh ~= nil and player_is_emerg_driver ~= nil then
					if IsVehicleSirenOn(veh) and player_is_emerg_driver and not key_lock then
						local proposed_tone = UTIL:GetToneAtPos(i)
						local tone_option = UTIL:GetToneOption(proposed_tone)
						if i-1 < #UTIL:GetApprovedTonesTable() then
							if tone_option ~= nil then
								if tone_option == 1 or tone_option == 3 then
									if ( state_lxsiren[veh] ~= proposed_tone or state_lxsiren[veh] == 0 ) then
										PlayAudio("Upgrade", upgrade_volume)
										SetLxSirenStateForVeh(veh, proposed_tone)
										count_bcast_timer = delay_bcast_timer
									else
										PlayAudio("Downgrade", downgrade_volume)
										SetLxSirenStateForVeh(veh, 0)
										count_bcast_timer = delay_bcast_timer				
									end
								end
							else
								HUD:ShowNotification("~r~LVC ERROR 2: ~s~Nil value caught.\ndetails: (" .. i .. "," .. proposed_tone .. "," .. UTIL:GetVehicleProfileName() .. ")")
								HUD:ShowNotification("~b~LVC ERROR 2: ~s~Try switching vehicles and switching back OR loading profile settings (if save present).")
							end
						end
					end
				end
			end)
			
			--CHANGE BELOW if you'd like to change which keys are used for example NUMROW1 through 0
			if i > 0 and i < 11 and main_siren_set_register_keys_set_defaults then
				RegisterKeyMapping(command, description, "keyboard", i-1)
			elseif i == 11 and main_siren_set_register_keys_set_defaults then
				RegisterKeyMapping(command, description, "keyboard", "0")		
			else
				RegisterKeyMapping(command, description, "keyboard", '')				
			end
		end
	end
end

--On resource start/restart
Citizen.CreateThread(function()
	Citizen.Wait(500)
	SetNuiFocus( false )
	UTIL:FixOversizeKeys()
	RegisterKeyMaps()
	Storage:SetBackupTable()
	local resourceName = string.lower( GetCurrentResourceName() )
	SendNUIMessage( { _type = "setResourceName", name = resourceName } )
end)

------------------------------------------------
-------------------FUNCTIONS--------------------
------------------------------------------------
function SetActivityTimer()
	last_activity_timer = activity_reminder_lookup[activity_reminder_index] or 0
end

---------------------------------------------------------------------
--Make number into ordinal number, used for FiveM RegisterKeys
function MakeOrdinal(number)
	local sufixes = { "th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th" }
	local mod = (number % 100)
	if mod == 11 or mod == 12 or mod == 13 then
		return number .. "th"
	else
		return number..sufixes[(number % 10) + 1]
	end
end

---------------------------------------------------------------------
-- Coordinate calculations and drawing of spotlight on passed vehicle.
function DrawTakeDown(veh)
	if DoesEntityExist(veh) and not IsEntityDead(veh) and veh_dist[veh] ~= nil then
		light_start_pos = GetOffsetFromEntityInWorldCoords(veh, 0.0, tkd_scheme_lookup[tkd_scheme].start_y, tkd_scheme_lookup[tkd_scheme].start_z) 
		light_end_pos = GetOffsetFromEntityInWorldCoords(veh, 0.0, tkd_scheme_lookup[tkd_scheme].end_y, tkd_scheme_lookup[tkd_scheme].end_z)
		light_direction = vector3(light_end_pos-light_start_pos)	
		DrawSpotLight(light_start_pos, light_direction, 200, 200, 255, tkd_distance+0.0, tkd_intensity+0.0, 0.0, tkd_radius+0.0, tkd_falloff+veh_dist[veh]/2+0.0)

		if tkd_debug_flag then
			DrawLine(light_start_pos, light_end_pos, 255, 0, 0, 255)
		end
	end
end

---------------------------------------------------------------------
function PlayAudio(soundFile, soundVolume, schemeless)
	local schemeless = schemeless or false
	if not schemeless then
		soundFile = button_sfx_scheme .. "/" .. soundFile;
	end
	SendNUIMessage({
	  _type  = 'audio',
	  file   = soundFile,
	  volume = soundVolume
	})
end

---------------------------------------------------------------------
function CleanupSounds()
	if count_sndclean_timer > delay_sndclean_timer then
		count_sndclean_timer = 0
		for k, v in pairs(state_lxsiren) do
			if v > 0 then
				if not DoesEntityExist(k) or IsEntityDead(k) then
					if snd_lxsiren[k] ~= nil then
						StopSound(snd_lxsiren[k])
						ReleaseSoundId(snd_lxsiren[k])
						snd_lxsiren[k] = nil
						state_lxsiren[k] = nil
					end
				end
			end
		end
		for k, v in pairs(state_pwrcall) do
			if v > 0 then
				if not DoesEntityExist(k) or IsEntityDead(k) then
					if snd_pwrcall[k] ~= nil then
						StopSound(snd_pwrcall[k])
						ReleaseSoundId(snd_pwrcall[k])
						snd_pwrcall[k] = nil
						state_pwrcall[k] = nil
					end
				end
			end
		end
		for k, v in pairs(state_airmanu) do
			if v == true then
				if not DoesEntityExist(k) or IsEntityDead(k) or IsVehicleSeatFree(k, -1) then
					if snd_airmanu[k] ~= nil then
						StopSound(snd_airmanu[k])
						ReleaseSoundId(snd_airmanu[k])
						snd_airmanu[k] = nil
						state_airmanu[k] = nil
					end
				end
			end
		end		
		for k, v in pairs(state_tkd) do
			if v == true then
				if not DoesEntityExist(k) or IsEntityDead(k) then
					state_tkd[k] = nil
				end
			end
		end
	else
		count_sndclean_timer = count_sndclean_timer + 1
	end
end
---------------------------------------------------------------------
function TogIndicStateForVeh(veh, newstate)
	if DoesEntityExist(veh) and not IsEntityDead(veh) then
		if newstate == ind_state_o then
			SetVehicleIndicatorLights(veh, 0, false) -- R
			SetVehicleIndicatorLights(veh, 1, false) -- L
		elseif newstate == ind_state_l then
			SetVehicleIndicatorLights(veh, 0, false) -- R
			SetVehicleIndicatorLights(veh, 1, true) -- L
		elseif newstate == ind_state_r then
			SetVehicleIndicatorLights(veh, 0, true) -- R
			SetVehicleIndicatorLights(veh, 1, false) -- L
		elseif newstate == ind_state_h then
			SetVehicleIndicatorLights(veh, 0, true) -- R
			SetVehicleIndicatorLights(veh, 1, true) -- L
		end
		state_indic[veh] = newstate
	end
end

---------------------------------------------------------------------
function TogMuteDfltSrnForVeh(veh, toggle)
	if DoesEntityExist(veh) and not IsEntityDead(veh) then
		DisableVehicleImpactExplosionActivation(veh, toggle)
	end
end

---------------------------------------------------------------------
function SetLxSirenStateForVeh(veh, newstate)
	if DoesEntityExist(veh) and not IsEntityDead(veh) then
		if newstate ~= state_lxsiren[veh] then
				
			if snd_lxsiren[veh] ~= nil then
				StopSound(snd_lxsiren[veh])
				ReleaseSoundId(snd_lxsiren[veh])
				snd_lxsiren[veh] = nil
			end					  
			if newstate ~= 0 then			
				snd_lxsiren[veh] = GetSoundId()
				PlaySoundFromEntity(snd_lxsiren[veh], SIRENS[newstate].String, veh, SIRENS[newstate].Ref, 0, 0)	
				TogMuteDfltSrnForVeh(veh, true)		
			end
			state_lxsiren[veh] = newstate
		end
	end
end

---------------------------------------------------------------------
function SetPowercallStateForVeh(veh, newstate)
	if DoesEntityExist(veh) and not IsEntityDead(veh) then
		if newstate ~= state_pwrcall[veh] then
			if snd_pwrcall[veh] ~= nil then
				StopSound(snd_pwrcall[veh])
				ReleaseSoundId(snd_pwrcall[veh])
				snd_pwrcall[veh] = nil
			end
			if newstate ~= 0 then
				snd_pwrcall[veh] = GetSoundId()
				PlaySoundFromEntity(snd_pwrcall[veh], SIRENS[newstate].String, veh, SIRENS[newstate].Ref, 0, 0)	
			end
			state_pwrcall[veh] = newstate
		end
	end
end

---------------------------------------------------------------------
function SetAirManuStateForVeh(veh, newstate)
	if DoesEntityExist(veh) and not IsEntityDead(veh) then
		if newstate ~= state_airmanu[veh] then
			if snd_airmanu[veh] ~= nil then
				StopSound(snd_airmanu[veh])
				ReleaseSoundId(snd_airmanu[veh])
				snd_airmanu[veh] = nil
			end
			if newstate ~= 0 then
				snd_airmanu[veh] = GetSoundId()
				PlaySoundFromEntity(snd_airmanu[veh], SIRENS[newstate].String, veh, SIRENS[newstate].Ref, 0, 0)
			end
			state_airmanu[veh] = newstate
		end
	end
end

---------------------------------------------------------------------
function TogTkdStateForVeh(veh, toggle)
	if DoesEntityExist(veh) and not IsEntityDead(veh) then
		if toggle ~= state_tkd[veh] then
			state_tkd[veh] = toggle
		end
	end
end

------------------------------------------------
----------------EVENT HANDLERS------------------
------------------------------------------------
RegisterNetEvent("lvc_TogIndicState_c")
AddEventHandler("lvc_TogIndicState_c", function(sender, newstate)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local veh = GetVehiclePedIsUsing(ped_s)
				TogIndicStateForVeh(veh, newstate)
			end
		end
	end
end)

---------------------------------------------------------------------
RegisterNetEvent("lvc_TogDfltSrnMuted_c")
AddEventHandler("lvc_TogDfltSrnMuted_c", function(sender, toggle)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local veh = GetVehiclePedIsUsing(ped_s)
				TogMuteDfltSrnForVeh(veh, toggle)
			end
		end
	end
end)

---------------------------------------------------------------------
RegisterNetEvent("lvc_SetLxSirenState_c")
AddEventHandler("lvc_SetLxSirenState_c", function(sender, newstate)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local veh = GetVehiclePedIsUsing(ped_s)
				SetLxSirenStateForVeh(veh, newstate)
			end
		end
	end
end)

---------------------------------------------------------------------
RegisterNetEvent("lvc_SetPwrcallState_c")
AddEventHandler("lvc_SetPwrcallState_c", function(sender, newstate)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local veh = GetVehiclePedIsUsing(ped_s)
				SetPowercallStateForVeh(veh, newstate)
			end
		end
	end
end)

---------------------------------------------------------------------
RegisterNetEvent("lvc_SetAirManuState_c")
AddEventHandler("lvc_SetAirManuState_c", function(sender, newstate)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local veh = GetVehiclePedIsUsing(ped_s)
				SetAirManuStateForVeh(veh, newstate)
			end
		end
	end
end)

---------------------------------------------------------------------
RegisterNetEvent("lvc_TogTkdState_c")
AddEventHandler("lvc_TogTkdState_c", function(sender, toggle)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local veh = GetVehiclePedIsUsing(ped_s)
				TogTkdStateForVeh(veh, toggle)
			end
		end
	end
end)
---------------------------------------------------------------------
RegisterNetEvent("lvc_ShareAudio_c")
AddEventHandler("lvc_ShareAudio_c", function(sender, version)
	repo_version = version
end)

---------------------------------------------------------------------
local actv_manu  
local actv_horn 
Citizen.CreateThread(function()
	while true do
		CleanupSounds()
		DistantCopCarSirens(false)
		----- IS IN VEHICLE -----
		local playerped = GetPlayerPed(-1)		
		if IsPedInAnyVehicle(playerped, false) then	
			----- IS DRIVER -----
			local veh = GetVehiclePedIsUsing(playerped)				
			if GetPedInVehicleSeat(veh, -1) == playerped then			
				if state_indic[veh] ~= ind_state_o and state_indic[veh] ~= ind_state_l and state_indic[veh] ~= ind_state_r and state_indic[veh] ~= ind_state_h then
					state_indic[veh] = ind_state_o
				end
				
				-- INDIC AUTO CONTROL
				if actv_ind_timer == true then	
					if state_indic[veh] == ind_state_l or state_indic[veh] == ind_state_r then
						if GetEntitySpeed(veh) < 6 then
							count_ind_timer = 0
						else
							if count_ind_timer > delay_ind_timer then
								count_ind_timer = 0
								actv_ind_timer = false
								state_indic[veh] = ind_state_o
								TogIndicStateForVeh(veh, state_indic[veh])
								count_bcast_timer = delay_bcast_timer
							else
								count_ind_timer = count_ind_timer + 1
							end
						end
					end
				end
				
				
				--- IS EMERG VEHICLE ---
				if GetVehicleClass(veh) == 18 and UpdateOnscreenKeyboard() ~= 0 then
					if state_lxsiren[veh] == nil then
						state_lxsiren[veh] = 0
					end

					if state_pwrcall[veh] == nil then
						state_pwrcall[veh] = 0
					end

					if state_airmanu[veh] == nil then
							state_airmanu[veh] = 0
					end
					TogMuteDfltSrnForVeh(veh, true)
					dsrn_mute = true
					
					if not IsVehicleSirenOn(veh) and state_lxsiren[veh] > 0 then
						SetLxSirenStateForVeh(veh, 0)
						count_bcast_timer = delay_bcast_timer
					end
					if not IsVehicleSirenOn(veh) and state_pwrcall[veh] > 0 then
						SetPowercallStateForVeh(veh, 0)
						count_bcast_timer = delay_bcast_timer
					end
				
					----- CONTROLS -----
					if not IsPauseMenuActive() then
						if not key_lock then
							-- TOG DFLT SRN LIGHTS
							if IsDisabledControlJustReleased(0, 85) or IsDisabledControlJustReleased(0, 246) and IsControlReleased(0, 243) then
								SetActivityTimer()
								if IsVehicleSirenOn(veh) then
									PlayAudio("Off", off_volume) -- Off
									HUD:SetItemState("switch", false) 
									HUD:SetItemState("siren", false) 
									SetVehicleSiren(veh, false)
									--If the siren was on, save it in memory
									if state_lxsiren[veh] > 0 and not tone_main_reset_standby then
										tone_main_mem_id = state_lxsiren[veh]
									end
								else
									PlayAudio("On", on_volume) -- On
									HUD:SetItemState("switch", true) 
									Citizen.Wait(150)
									SetVehicleSiren(veh, true)
									count_bcast_timer = delay_bcast_timer
								end		
							
							-- TOG LX SIREN
							elseif IsDisabledControlJustReleased(0, 19) or IsDisabledControlJustReleased(0, 82) then
								SetActivityTimer()
								if state_lxsiren[veh] == 0 then
									if IsVehicleSirenOn(veh) then
										PlayAudio("Upgrade", upgrade_volume) 
										HUD:SetItemState("siren", true) 
										if not tone_main_reset_standby then
											local tone_mem_id = UTIL:GetToneID('MAIN_MEM')
											local option = UTIL:GetToneOption(tone_mem_id)
											if UTIL:IsApprovedTone(tone_mem_id) and option ~= 3 and option ~= 4 then
												SetLxSirenStateForVeh(veh, tone_mem_id)
											else
												tone = UTIL:GetNextSirenTone(tone_mem_id, veh, true) 
												UTIL:SetToneByID('MAIN_MEM', tone)
												SetLxSirenStateForVeh(veh, tone)
											end
										else
											local option = UTIL:GetToneOption(2)
											if option == 3 or option == 4 then
												tone = UTIL:GetNextSirenTone(2, veh, true) 
											else
												tone = UTIL:GetToneAtPos(2)
											end
											SetLxSirenStateForVeh(veh, tone)
										end
										count_bcast_timer = delay_bcast_timer
									end
								else
									PlayAudio("Downgrade", downgrade_volume) -- Downgrade
									if state_pwrcall[veh] == 0 then
										HUD:SetItemState("siren", false) 
									end
									if not tone_main_reset_standby then
										UTIL:SetToneByID('MAIN_MEM', state_lxsiren[veh])
									end
									SetLxSirenStateForVeh(veh, 0)
									count_bcast_timer = delay_bcast_timer
								end
								
							-- POWERCALL
							elseif IsDisabledControlJustReleased(0, 172) and not IsMenuOpen() then --disable up arrow only in tone mode since testing would be beneficial 
								SetActivityTimer()
								if state_pwrcall[veh] == 0 then
									if IsVehicleSirenOn(veh) then
										PlayAudio("Upgrade", upgrade_volume) 
										HUD:SetItemState("siren", true) 
										local tone_aux_id = UTIL:GetToneID('AUX')
										if tone_aux_id ~= nil then
											if UTIL:IsApprovedTone(tone_aux_id) then
												SetPowercallStateForVeh(veh, tone_aux_id)
											else
												UTIL:SetToneByPos('AUX', 2)
												SetPowercallStateForVeh(veh, UTIL:GetToneID('AUX'))
											end
										else
											UTIL:SetToneByPos('AUX', 3)
											SetPowercallStateForVeh(veh, UTIL:GetToneID('AUX'))	
										end
										count_bcast_timer = delay_bcast_timer
									end
								else
									PlayAudio("Downgrade", downgrade_volume) -- Downgrade
									if state_lxsiren[veh] == 0 then
										HUD:SetItemState("siren", false) 
									end 
									SetPowercallStateForVeh(veh, 0)
									count_bcast_timer = delay_bcast_timer
								end
							--TKDs
							elseif IsControlPressed(0, tkd_combokey) or tkd_combokey == 0 then
								DisableControlAction(0, tkd_key, true)
								if IsDisabledControlJustReleased(0, tkd_key) then
									if state_tkd[veh] == true then
										if tkd_mode == 2 then
											SetVehicleFullbeam(veh, false)
										end
										TogTkdStateForVeh(veh, false)										
										PlayAudio("Downgrade", downgrade_volume) 
									else
										if tkd_mode == 2 then
											SetVehicleFullbeam(veh, true)
										end
										TogTkdStateForVeh(veh, true)
										PlayAudio("Upgrade", upgrade_volume) 										
									end
									HUD:SetItemState("tkd", state_tkd[veh]) 
									count_bcast_timer = delay_bcast_timer
								end
							end
							
							-- BROWSE LX SRN TONES
							if state_lxsiren[veh] > 0 then
								if ( IsDisabledControlJustReleased(0, 80) or IsDisabledControlJustReleased(0, 81) ) then
									if IsVehicleSirenOn(veh) then
										PlayAudio("Upgrade", upgrade_volume)
										HUD:SetItemState("horn", false) 
										SetLxSirenStateForVeh(veh, UTIL:GetNextSirenTone(state_lxsiren[veh], veh, true))
										count_bcast_timer = delay_bcast_timer
									end
								elseif IsDisabledControlPressed(0, 80) or IsDisabledControlPressed(0, 81) then
									HUD:SetItemState("horn", true) 
								end
							end
										
							-- MANU
							if state_lxsiren[veh] < 1 then
								if IsDisabledControlPressed(0, 80) or (IsDisabledControlPressed(0, 81) and not IsMenuOpen()) then
									SetActivityTimer()
									actv_manu = true
									HUD:SetItemState("siren", true) 
								else
									if actv_manu then
										HUD:SetItemState("siren", false) 
									end	
									actv_manu = false
								end
							else
								if actv_manu then
									HUD:SetItemState("siren", false) 
								end							
								actv_manu = false
							end
							
							-- HORN
							if IsDisabledControlPressed(0, 86) then
								SetActivityTimer()
								actv_horn = true
								HUD:SetItemState("horn", true) 
							else
								if actv_horn then
									HUD:SetItemState("horn", false) 
								end
								actv_horn = false
							end
							
							
							--AIRHORN AND MANU BUTTON SFX
							if airhorn_button_SFX then
								if IsDisabledControlJustPressed(0, 86) then
									PlayAudio("Press", upgrade_volume)									
								end								
								if IsDisabledControlJustReleased(0, 86) then
									PlayAudio("Release", upgrade_volume)									
								end
							end							
							if manu_button_SFX and state_lxsiren[veh] == 0 then
								if IsDisabledControlJustPressed(0, 80) or IsDisabledControlJustPressed(0, 81) then
									PlayAudio("Press", upgrade_volume)									
								end								
								if IsDisabledControlJustReleased(0, 80) or IsDisabledControlJustReleased(0, 81) then
									PlayAudio("Release", upgrade_volume)									
								end
							end
						else
							if (IsDisabledControlJustReleased(0, 86) or 
								IsDisabledControlJustReleased(0, 81) or 
								IsDisabledControlJustReleased(0, 80) or 
								IsDisabledControlJustReleased(0, 81) or
								IsDisabledControlJustReleased(0, 172) or 
								IsDisabledControlJustReleased(0, 19) or 
								IsDisabledControlJustReleased(0, 82) or
								IsDisabledControlJustReleased(0, 85) or 
								IsDisabledControlJustReleased(0, 246)) then
									if locked_press_count % reminder_rate == 0 then
										PlayAudio("Locked_Press", lock_reminder_volume, true) -- lock reminder
										HUD:ShowNotification("~y~~h~Reminder:~h~ ~s~Your siren control box is ~r~locked~s~.")
									end
									locked_press_count = locked_press_count + 1
							end								
						end
					end
					
					---- ADJUST HORN / MANU STATE ----
					local hmanu_state_new = 0
					if actv_horn == true and actv_manu == false then
						if UTIL:GetToneID('ARHRN') ~= nil then
							hmanu_state_new = UTIL:GetToneID('ARHRN')
						end
					elseif actv_horn == false and actv_manu == true then
						if UTIL:GetToneID('PMANU') ~= nil then
							hmanu_state_new = UTIL:GetToneID('PMANU')
						end
					elseif actv_horn == true and actv_manu == true then
						if UTIL:GetToneID('SMANU') ~= nil then
							hmanu_state_new = UTIL:GetToneID('SMANU')
						end
					end
					if tone_airhorn_intrp then
						if hmanu_state_new == UTIL:GetToneID('ARHRN') then
							if state_lxsiren[veh] > 0 and actv_lxsrnmute_temp == false then
								srntone_temp = state_lxsiren[veh]
								SetLxSirenStateForVeh(veh, 0)
								actv_lxsrnmute_temp = true
							end
						else
							if actv_lxsrnmute_temp == true then
								SetLxSirenStateForVeh(veh, srntone_temp)
								actv_lxsrnmute_temp = false
							end
						end 
					end
					
					if state_airmanu[veh] ~= hmanu_state_new then
						SetAirManuStateForVeh(veh, hmanu_state_new)
						count_bcast_timer = delay_bcast_timer
					end	
				end
				
					
				--- IS ANY LAND VEHICLE ---	
				if GetVehicleClass(veh) ~= 14 and GetVehicleClass(veh) ~= 15 and GetVehicleClass(veh) ~= 16 and GetVehicleClass(veh) ~= 21 then
				
					----- CONTROLS -----
					if not IsPauseMenuActive() then
					
						-- IND L
						if IsDisabledControlJustReleased(0, left_signal_key) then -- INPUT_VEH_PREV_RADIO_TRACK
							local cstate = state_indic[veh]
							if cstate == ind_state_l then
								state_indic[veh] = ind_state_o
								actv_ind_timer = false
							else
								state_indic[veh] = ind_state_l
								actv_ind_timer = true
							end
							TogIndicStateForVeh(veh, state_indic[veh])
							count_ind_timer = 0
							count_bcast_timer = delay_bcast_timer			
						-- IND R
						elseif IsDisabledControlJustReleased(0, right_signal_key) then -- INPUT_VEH_NEXT_RADIO_TRACK
							local cstate = state_indic[veh]
							if cstate == ind_state_r then
								state_indic[veh] = ind_state_o
								actv_ind_timer = false
							else
								state_indic[veh] = ind_state_r
								actv_ind_timer = true
							end
							TogIndicStateForVeh(veh, state_indic[veh])
							count_ind_timer = 0
							count_bcast_timer = delay_bcast_timer
						-- IND H
						elseif IsControlPressed(0, 202) then -- INPUT_FRONTEND_CANCEL / Backspace
							if GetLastInputMethod(0) then -- last input was with kb
								Citizen.Wait(hazard_hold_duration)
								if IsControlPressed(0, 202) then -- INPUT_FRONTEND_CANCEL / Backspace
									local cstate = state_indic[veh]
									if cstate == ind_state_h then
										state_indic[veh] = ind_state_o
										PlayAudio("Hazards_Off", hazards_volume, true) -- Hazards On
									else
										state_indic[veh] = ind_state_h
										PlayAudio("Hazards_On", hazards_volume, true) -- Hazards On
									end
									TogIndicStateForVeh(veh, state_indic[veh])
									actv_ind_timer = false
									count_ind_timer = 0
									count_bcast_timer = delay_bcast_timer
									Citizen.Wait(300)
								end
							end
						end
					end
					
					
					----- AUTO BROADCAST VEH STATES -----
					if count_bcast_timer > delay_bcast_timer then
						count_bcast_timer = 0
						--- IS EMERG VEHICLE ---
						if GetVehicleClass(veh) == 18 then
							TriggerServerEvent("lvc_TogDfltSrnMuted_s", dsrn_mute)
							TriggerServerEvent("lvc_SetLxSirenState_s", state_lxsiren[veh])
							TriggerServerEvent("lvc_TogPwrcallState_s", state_pwrcall[veh])
							TriggerServerEvent("lvc_SetAirManuState_s", state_airmanu[veh])
							TriggerServerEvent("lvc_TogTkdState_s", state_tkd[veh])
						end
						--- IS ANY OTHER VEHICLE ---
						TriggerServerEvent("lvc_TogIndicState_s", state_indic[veh])
					else
						count_bcast_timer = count_bcast_timer + 1
					end
				end
			end
		end
		Citizen.Wait(0)
	end
end)