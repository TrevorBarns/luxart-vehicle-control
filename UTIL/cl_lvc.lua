--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: cl_lvc.lua
PURPOSE: Core Functionality and User Input
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

--GLOBAL VARIABLES used in cl_ragemenu, UTILs, and plug-ins.
--	GENERAL VARIABLES
key_lock = false
playerped = nil
last_veh = nil
veh = nil
trailer = nil
player_is_emerg_driver = false
debug_mode = false

--	MAIN SIREN SETTINGS
tone_main_reset_standby 	= reset_to_standby_default
tone_airhorn_intrp 			= airhorn_interrupt_default
park_kill 					= park_kill_default

--LOCAL VARIABLES
local radio_wheel_active = false

local last_bcast_time = 0
local bcast_interval = 5000
local last_sndclean_time = 0
local sndclean_interval = 6666
local actv_ind_timer = false
local last_ind_time = 0
local ind_interval = 3000
local distant_sirens_disabled = false
local radio_enabled_for_veh = nil
local dflt_srn_muted_for_veh = nil
local cached_arhrn_id = nil
local cached_pmanu_id = nil
local cached_smanu_id = nil
local cached_veh_class = nil
local cached_veh_for_class = nil
local radio_disabled_frame = 0

actv_lxsrnmute_temp = false
local srntone_temp = 0
local dsrn_mute = true
local lights_on = false
local new_tone = nil
local tone_mem_id = nil
local tone_mem_option = nil
local default_tone = nil
local default_tone_option = nil

state_indic = {}
state_lxsiren = {}
state_pwrcall = {}
state_airmanu = {}
actv_manu = nil
actv_horn = nil

local update_data = {}

local ind_state_o = 0
local ind_state_l = 1
local ind_state_r = 2
local ind_state_h = 3

local snd_lxsiren = {}
local snd_pwrcall = {}
local snd_airmanu = {}

local RegisterKeyMaps, MakeOrdinal

CreateThread(function()
	if GetResourceState('lux_vehcontrol') ~= 'started' and GetResourceState('lux_vehcontrol') ~= 'starting' then
		if GetCurrentResourceName() == 'lvc' then
			if community_id ~= nil and community_id ~= '' then
				while true do
					playerped = PlayerPedId()
					--IS IN VEHICLE
					player_is_emerg_driver = false
					if IsPedInAnyVehicle(playerped, false) then
						veh = GetVehiclePedIsUsing(playerped)
						_, trailer = GetVehicleTrailerVehicle(veh)
						--IS DRIVER
						if GetPedInVehicleSeat(veh, -1) == playerped then
							--IS EMERGENCY VEHICLE
							if GetVehicleClass(veh) == 18 then
								player_is_emerg_driver = true
							end
						end
					end
					Wait(100)
				end
			else
				Wait(1000)
				HUD:ShowNotification(Lang:t('error.missing_community_id_frontend'), true)
				UTIL:Print(Lang:t('error.missing_community_id_console'), true)
			end
		else
			Wait(1000)
			HUD:ShowNotification(Lang:t('error.invalid_resource_name_frontend'), true)
			UTIL:Print(Lang:t('error.invalid_resource_name_console'), true)
		end
	else
		Wait(1000)
		HUD:ShowNotification(Lang:t('error.resource_conflict_frontend'), true)
		UTIL:Print(Lang:t('error.resource_conflict_console'), true)
	end
end)

CreateThread(function()
	debug_mode = GetResourceMetadata(GetCurrentResourceName(), 'debug_mode', 0) == 'true'
	TriggerEvent('chat:addSuggestion', Lang:t('command.lock_command'), Lang:t('command.lock_desc'))
	SetNuiFocus( false )

	UTIL:FixOversizeKeys(SIREN_ASSIGNMENTS)
	RegisterKeyMaps()
	STORAGE:SetBackupTable()
end)

local last_exit_check = 0
local exit_check_interval = 200
local last_speed_check = 0
local speed_check_interval = 100

CreateThread(function()
	while true do
		if player_is_emerg_driver and veh ~= nil then
			if last_veh == nil or last_veh ~= veh then
				TriggerEvent('lvc:onVehicleChange')
			end
		else
			distant_sirens_disabled = false
			radio_enabled_for_veh = nil
			dflt_srn_muted_for_veh = nil
		end
		Wait(1000)
	end
end)

------------REGISTERED VEHICLE EVENTS------------
--Kill siren on Exit
RegisterNetEvent('lvc:onVehicleExit')
AddEventHandler('lvc:onVehicleExit', function()
	if park_kill_masterswitch and park_kill then
		if not tone_main_reset_standby and state_lxsiren[veh] ~= 0 then
			UTIL:SetToneByID('MAIN_MEM', state_lxsiren[veh])
		end
		SetLxSirenStateForVeh(veh, 0)
		SetPowercallStateForVeh(veh, 0)
		SetAirManuStateForVeh(veh, 0)
		HUD:SetItemState('siren', false)
		HUD:SetItemState('horn', false)
		last_bcast_time = 0
	end
end)

RegisterNetEvent('lvc:onVehicleChange')
AddEventHandler('lvc:onVehicleChange', function()
	last_veh = veh
	UTIL:UpdateApprovedTones(veh)
	Wait(100)	--waiting for JS event handler
	STORAGE:ResetSettings()
	UTIL:BuildToneOptions()
	STORAGE:LoadSettings()
	HUD:RefreshHudItemStates()
	SetVehRadioStation(veh, 'OFF')
	Wait(500)
	SetVehRadioStation(veh, 'OFF')

	if state_lxsiren[veh] == nil then
		state_lxsiren[veh] = 0
	end
	if state_pwrcall[veh] == nil then
		state_pwrcall[veh] = 0
	end
	if state_airmanu[veh] == nil then
		state_airmanu[veh] = 0
	end
	if state_indic[veh] == nil then
		state_indic[veh] = ind_state_o
	end

	cached_arhrn_id = UTIL:GetToneID('ARHRN')
	cached_pmanu_id = UTIL:GetToneID('PMANU')
	cached_smanu_id = UTIL:GetToneID('SMANU')
end)

--------------REGISTERED COMMANDS---------------
--Toggle Debug Mode
RegisterCommand(Lang:t('command.debug_command'), function(source, args)
	debug_mode = not debug_mode
	HUD:ShowNotification(Lang:t('info.debug_mode_frontend', {state = debug_mode}), true)
	UTIL:Print(Lang:t('info.debug_mode_console', {state = debug_mode}), true)
	if debug_mode then
		TriggerEvent('lvc:onVehicleChange')
	end
end)

--Toggle LUX lock command
RegisterCommand(Lang:t('command.lock_command'), function(source, args)
	if player_is_emerg_driver then
		key_lock = not key_lock
		AUDIO:Play('Key_Lock', AUDIO.lock_volume, true)
		HUD:SetItemState('lock', key_lock)
		--if HUD is visible do not show notification
		if not HUD:GetHudState() then
			if key_lock then
				HUD:ShowNotification(Lang:t('info.locked'), true)
			else
				HUD:ShowNotification(Lang:t('info.unlocked'), true)
			end
		end
	end
end)

RegisterKeyMapping(Lang:t('command.lock_command'), Lang:t('control.lock_desc'), 'keyboard', lockout_default_hotkey)

------------------------------------------------
-------------------FUNCTIONS--------------------
------------------------------------------------
------------------------------------------------
--Dynamically Run RegisterCommand and KeyMapping functions for all 14 possible sirens
--Then at runtime 'slide' all sirens down removing any restricted sirens.
RegisterKeyMaps = function()
	for i, _ in ipairs(SIRENS) do
		if i ~= 1 then
			local command = '_lvc_siren_' .. i-1
			local description = Lang:t('control.siren_control_desc', {ord_num = MakeOrdinal(i-1)})

			RegisterCommand(command, function(source, args)
				if veh ~= nil and player_is_emerg_driver ~= nil then
					if IsVehicleSirenOn(veh) and player_is_emerg_driver and not key_lock then
						local proposed_tone = UTIL:GetToneAtPos(i)
						local tone_option = UTIL:GetToneOption(proposed_tone)
						if i-1 < #UTIL:GetApprovedTonesTable() then
							if tone_option ~= nil then
								if tone_option == 1 or tone_option == 3 then
									if ( state_lxsiren[veh] ~= proposed_tone or state_lxsiren[veh] == 0 ) then
										HUD:SetItemState('siren', true)
										AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
										SetLxSirenStateForVeh(veh, proposed_tone)
										count_bcast_timer = delay_bcast_timer
									else
										if state_pwrcall[veh] == 0 then
											HUD:SetItemState('siren', false)
										end
										AUDIO:Play('Downgrade', AUDIO.downgrade_volume)
										SetLxSirenStateForVeh(veh, 0)
										count_bcast_timer = delay_bcast_timer
									end
								end
							else
								HUD:ShowNotification(Lang:t('error.reg_keymap_nil_1', {i = i, proposed_tone = proposed_tone, profile_name = UTIL:GetVehicleProfileName()}), true)
								HUD:ShowNotification(Lang:t('error.reg_keymap_nil_2'), true)
							end
						end
					end
				end
			end)

			--CHANGE BELOW if you'd like to change which keys are used for example NUMROW1 through 0
			if i > 0 and i < 11 and main_siren_set_register_keys_set_defaults then
				RegisterKeyMapping(command, description, 'keyboard', i-1)
			elseif i == 11 and main_siren_set_register_keys_set_defaults then
				RegisterKeyMapping(command, description, 'keyboard', '0')
			else
				RegisterKeyMapping(command, description, 'keyboard', '')
			end
		end
	end
end

--Make number into ordinal number, used for FiveM RegisterKeys
MakeOrdinal = function(number)
	local sufixes = { 'th', 'st', 'nd', 'rd', 'th', 'th', 'th', 'th', 'th', 'th' }
	local mod = (number % 100)
	if mod == 11 or mod == 12 or mod == 13 then
		return number .. 'th'
	else
		return number..sufixes[(number % 10) + 1]
	end
end

--Broadcast local vehicle state to other resources
BroadcastPlayerVehicleState = function(vehicle)
	if veh == vehicle then
		update_data = {
			['state_lxsiren'] = state_lxsiren[veh],
			['state_indic'] = state_indic[veh],
			['state_pwrcall'] = state_pwrcall[veh],
			['state_airmanu'] = state_airmanu[veh],
			['actv_manu'] = actv_manu,
			['actv_horn'] = actv_horn
		}
		TriggerEvent('lvc:UpdateThirdParty', update_data)
	end
end	

---------------------------------------------------------------------
local function CleanupSounds()
	local current_time = GetGameTimer()
	if current_time - last_sndclean_time > sndclean_interval then
		last_sndclean_time = current_time
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
	end
end
---------------------------------------------------------------------
function TogIndicStateForVeh(vehicle, newstate)
	if DoesEntityExist(vehicle) and not IsEntityDead(vehicle) then
		if newstate == ind_state_o then
			SetVehicleIndicatorLights(vehicle, 0, false) -- R
			SetVehicleIndicatorLights(vehicle, 1, false) -- L
		elseif newstate == ind_state_l then
			SetVehicleIndicatorLights(vehicle, 0, false) -- R
			SetVehicleIndicatorLights(vehicle, 1, true) -- L
		elseif newstate == ind_state_r then
			SetVehicleIndicatorLights(vehicle, 0, true) -- R
			SetVehicleIndicatorLights(vehicle, 1, false) -- L
		elseif newstate == ind_state_h then
			SetVehicleIndicatorLights(vehicle, 0, true) -- R
			SetVehicleIndicatorLights(vehicle, 1, true) -- L
		end
		state_indic[vehicle] = newstate
		BroadcastPlayerVehicleState(vehicle)
	end
end

---------------------------------------------------------------------
function TogMuteDfltSrnForVeh(vehicle, toggle)
	if DoesEntityExist(vehicle) and not IsEntityDead(vehicle) then
		DisableVehicleImpactExplosionActivation(vehicle, toggle)
	end
end

---------------------------------------------------------------------
function SetLxSirenStateForVeh(vehicle, newstate)
	if DoesEntityExist(vehicle) and not IsEntityDead(vehicle) then
		if newstate ~= state_lxsiren[vehicle] and newstate ~= nil then
			if snd_lxsiren[vehicle] ~= nil then
				StopSound(snd_lxsiren[vehicle])
				ReleaseSoundId(snd_lxsiren[vehicle])
				snd_lxsiren[vehicle] = nil
			end
			if newstate ~= 0 then
				snd_lxsiren[vehicle] = GetSoundId()
				PlaySoundFromEntity(snd_lxsiren[vehicle], SIRENS[newstate].String, vehicle, SIRENS[newstate].Ref, 0, 0)
				TogMuteDfltSrnForVeh(vehicle, true)
			end
			state_lxsiren[vehicle] = newstate
			BroadcastPlayerVehicleState(vehicle)
		end
	end
end

---------------------------------------------------------------------
function SetPowercallStateForVeh(vehicle, newstate)
	if DoesEntityExist(vehicle) and not IsEntityDead(vehicle) then
		if newstate ~= state_pwrcall[vehicle] and newstate ~= nil then
			if snd_pwrcall[vehicle] ~= nil then
				StopSound(snd_pwrcall[vehicle])
				ReleaseSoundId(snd_pwrcall[vehicle])
				snd_pwrcall[vehicle] = nil
			end
			if newstate ~= 0 then
				snd_pwrcall[vehicle] = GetSoundId()
				PlaySoundFromEntity(snd_pwrcall[vehicle], SIRENS[newstate].String, vehicle, SIRENS[newstate].Ref, 0, 0)
			end
			state_pwrcall[vehicle] = newstate
			BroadcastPlayerVehicleState(vehicle)
		end
	end
end

---------------------------------------------------------------------
function SetAirManuStateForVeh(vehicle, newstate)
	if DoesEntityExist(vehicle) and not IsEntityDead(vehicle) then
		if newstate ~= state_airmanu[vehicle] and newstate ~= nil then
			if snd_airmanu[vehicle] ~= nil then
				StopSound(snd_airmanu[vehicle])
				ReleaseSoundId(snd_airmanu[vehicle])
				snd_airmanu[vehicle] = nil
			end
			if newstate ~= 0 then
				snd_airmanu[vehicle] = GetSoundId()
				PlaySoundFromEntity(snd_airmanu[vehicle], SIRENS[newstate].String, vehicle, SIRENS[newstate].Ref, 0, 0)
			end
			state_airmanu[vehicle] = newstate
			BroadcastPlayerVehicleState(vehicle)
		end
	end
end

------------------------------------------------
----------------EVENT HANDLERS------------------
------------------------------------------------
RegisterNetEvent('lvc:TogIndicState_c')
AddEventHandler('lvc:TogIndicState_c', function(sender, newstate)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local vehicle = GetVehiclePedIsUsing(ped_s)
				TogIndicStateForVeh(vehicle, newstate)
			end
		end
	end
end)

---------------------------------------------------------------------
RegisterNetEvent('lvc:TogDfltSrnMuted_c')
AddEventHandler('lvc:TogDfltSrnMuted_c', function(sender)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local vehicle = GetVehiclePedIsUsing(ped_s)
				TogMuteDfltSrnForVeh(vehicle, true)
			end
		end
	end
end)

---------------------------------------------------------------------
RegisterNetEvent('lvc:SetLxSirenState_c')
AddEventHandler('lvc:SetLxSirenState_c', function(sender, newstate)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local vehicle = GetVehiclePedIsUsing(ped_s)
				SetLxSirenStateForVeh(vehicle, newstate)
			end
		end
	end
end)

---------------------------------------------------------------------
RegisterNetEvent('lvc:SetPwrcallState_c')
AddEventHandler('lvc:SetPwrcallState_c', function(sender, newstate)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local vehicle = GetVehiclePedIsUsing(ped_s)
				SetPowercallStateForVeh(vehicle, newstate)
			end
		end
	end
end)

---------------------------------------------------------------------
RegisterNetEvent('lvc:SetAirManuState_c')
AddEventHandler('lvc:SetAirManuState_c', function(sender, newstate)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local vehicle = GetVehiclePedIsUsing(ped_s)
				SetAirManuStateForVeh(vehicle, newstate)
			end
		end
	end
end)


---------------------------------------------------------------------
CreateThread(function()
	local controls_active = false
	local current_time = 0

	while true do
		CleanupSounds()

		if not player_is_emerg_driver then
			Wait(500)
		else
			if not distant_sirens_disabled then
				DistantCopCarSirens(false)
				distant_sirens_disabled = true
			end

			DisableControlAction(0, 80, true)
			DisableControlAction(0, 86, true)
			DisableControlAction(0, 172, true)
			DisableControlAction(0, 85, true)

			if AUDIO.radio_masterswitch and IsControlPressed(0, 243) then
				radio_wheel_active = true
				SetControlNormal(0, 85, 1.0)
				radio_disabled_frame = 0
			else
				if radio_wheel_active then
					radio_wheel_active = false
				end
				radio_disabled_frame = radio_disabled_frame + 1
				if radio_disabled_frame == 1 or radio_disabled_frame > 30 then
					if veh ~= nil then
						SetVehicleRadioEnabled(veh, false)
					end
					if radio_disabled_frame > 30 then
						radio_disabled_frame = 1
					end
				end
			end

			current_time = GetGameTimer()
			if current_time - last_exit_check > exit_check_interval then
				last_exit_check = current_time
				if playerped ~= nil and veh ~= nil then
					if GetIsTaskActive(playerped, 2) and GetVehiclePedIsIn(playerped, true) then
						TriggerEvent('lvc:onVehicleExit')
					end
				end
			end

			if veh ~= nil then
				if cached_veh_for_class ~= veh then
					cached_veh_class = GetVehicleClass(veh)
					cached_veh_for_class = veh
				end
				local is_emergency = cached_veh_class == 18
				local is_land_vehicle = cached_veh_class ~= 14 and cached_veh_class ~= 15 and cached_veh_class ~= 16 and cached_veh_class ~= 21

				controls_active = false
				local veh_siren_on = IsVehicleSirenOn(veh)

				if actv_ind_timer and (state_indic[veh] == ind_state_l or state_indic[veh] == ind_state_r) then
					if current_time - last_speed_check > speed_check_interval then
						last_speed_check = current_time
						if GetEntitySpeed(veh) < 6 then
							last_ind_time = current_time
						elseif current_time - last_ind_time > ind_interval then
							actv_ind_timer = false
							state_indic[veh] = ind_state_o
							TogIndicStateForVeh(veh, state_indic[veh])
							last_bcast_time = 0
						end
					end
				end

				if is_emergency then
					lights_on = veh_siren_on

					if radio_masterswitch and radio_enabled_for_veh ~= veh then
						SetVehicleRadioEnabled(veh, true)
						radio_enabled_for_veh = veh
					end

					if not IsEntityDead(veh) then
						if dflt_srn_muted_for_veh ~= veh then
							TogMuteDfltSrnForVeh(veh, true)
							dflt_srn_muted_for_veh = veh
						end

						--- IF LIGHTS ARE OFF TURN OFF SIREN ---
						if not lights_on and state_lxsiren[veh] ~= nil and state_lxsiren[veh] > 0 then
							--	SAVE TONE BEFORE TURNING OFF
							if not tone_main_reset_standby then
								UTIL:SetToneByID('MAIN_MEM', state_lxsiren[veh])
							end
							SetLxSirenStateForVeh(veh, 0)
							last_bcast_time = 0
						end
						if not lights_on and state_pwrcall[veh] ~= nil and state_pwrcall[veh] > 0 then
							SetPowercallStateForVeh(veh, 0)
							last_bcast_time = 0
						end

						----- CONTROLS -----
						if not IsPauseMenuActive() and UpdateOnscreenKeyboard() ~= 0 and not radio_wheel_active then
							if not key_lock then
								------ TOG DFLT SRN LIGHTS ------
								if IsDisabledControlJustReleased(0, 85) then
									controls_active = true
									if lights_on then
										AUDIO:Play('Off', AUDIO.off_volume)
										--	SET NUI IMAGES
										HUD:SetItemState('switch', false)
										HUD:SetItemState('siren', false)
										--	TURN OFF SIRENS (R* LIGHTS)
										SetVehicleSiren(veh, false)
										if trailer ~= nil and trailer ~= 0 then
											SetVehicleSiren(trailer, false)
										end

									else
										AUDIO:Play('On', AUDIO.on_volume) -- On
										--	SET NUI IMAGES
										HUD:SetItemState('switch', true)
										--	TURN OFF SIRENS (R* LIGHTS)
										SetVehicleSiren(veh, true)
										if trailer ~= nil and trailer ~= 0 then
											SetVehicleSiren(trailer, true)
										end
									end
									AUDIO:ResetActivityTimer()
									last_bcast_time = 0
								------ TOG LX SIREN ------
								elseif IsDisabledControlJustReleased(0, 19) then
									controls_active = true
									if state_lxsiren[veh] == 0 then
										if lights_on then
											AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
											HUD:SetItemState('siren', true)
											if not tone_main_reset_standby then
												--	GET THE SAVED TONE VERIFY IT IS APPROVED, AND NOT DISABLED / BUTTON ONLY
												tone_mem_id = UTIL:GetToneID('MAIN_MEM')
												tone_mem_option = UTIL:GetToneOption(tone_mem_id)
												if UTIL:IsApprovedTone(tone_mem_id) and tone_mem_option ~= 3 and tone_mem_option ~= 4 then
													SetLxSirenStateForVeh(veh, tone_mem_id)
												else
													new_tone = UTIL:GetNextSirenTone(tone_mem_id, veh, true)
													UTIL:SetToneByID('MAIN_MEM', new_tone)
													SetLxSirenStateForVeh(veh, new_tone)
												end

											else
												default_tone = UTIL:GetToneAtPos(2)
												default_tone_option = UTIL:GetToneOption(default_tone)
												if default_tone_option == 3 or default_tone_option == 4 then
													new_tone = UTIL:GetNextSirenTone(default_tone, veh, true)
												else
													new_tone = UTIL:GetToneAtPos(2)
												end
												SetLxSirenStateForVeh(veh, new_tone)
											end
										end
									else
										AUDIO:Play('Downgrade', AUDIO.downgrade_volume)
										-- ONLY CHANGE NUI STATE IF PWRCALL IS OFF AS WELL
										if state_pwrcall[veh] == 0 then
											HUD:SetItemState('siren', false)
										end
										if not tone_main_reset_standby then
											UTIL:SetToneByID('MAIN_MEM', state_lxsiren[veh])
										end
										SetLxSirenStateForVeh(veh, 0)
									end
									AUDIO:ResetActivityTimer()
									last_bcast_time = 0
								-- POWERCALL
								elseif IsDisabledControlJustReleased(0, 172) and not IsMenuOpen() then
									controls_active = true
									if state_pwrcall[veh] == 0 then
										if lights_on then
											AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
											HUD:SetItemState('siren', true)
											SetPowercallStateForVeh(veh, UTIL:GetToneID('AUX'))
											last_bcast_time = 0
										end
									else
										AUDIO:Play('Downgrade', AUDIO.downgrade_volume)
										if state_lxsiren[veh] == 0 then
											HUD:SetItemState('siren', false)
										end
										SetPowercallStateForVeh(veh, 0)
									end
									AUDIO:ResetActivityTimer()
									last_bcast_time = 0
								end
								-- CYCLE LX SRN TONES
								if state_lxsiren[veh] ~= nil and state_lxsiren[veh] > 0 then
									if IsDisabledControlJustReleased(0, 80) then
										controls_active = true
										AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
										HUD:SetItemState('horn', false)
										SetLxSirenStateForVeh(veh, UTIL:GetNextSirenTone(state_lxsiren[veh], veh, true))
										last_bcast_time = 0
									elseif IsDisabledControlPressed(0, 80) then
										controls_active = true
										HUD:SetItemState('horn', true)
									end
								end

								-- MANU
								if state_lxsiren[veh] == nil or state_lxsiren[veh] < 1 then
									if IsDisabledControlPressed(0, 80) then
										controls_active = true
										AUDIO:ResetActivityTimer()
										actv_manu = true
										HUD:SetItemState('siren', true)
									else
										if actv_manu then
											HUD:SetItemState('siren', false)
										end
										actv_manu = false
									end
								else
									if actv_manu then
										HUD:SetItemState('siren', false)
									end
									actv_manu = false
								end

								-- HORN
								if IsDisabledControlPressed(0, 86) then
									controls_active = true
									actv_horn = true
									AUDIO:ResetActivityTimer()
									HUD:SetItemState('horn', true)
								else
									if actv_horn or actv_manu then
										HUD:SetItemState('horn', false)
									end
									actv_horn = false
								end


								--AIRHORN AND MANU BUTTON SFX
								if AUDIO.airhorn_button_SFX then
									if IsDisabledControlJustPressed(0, 86) then
										controls_active = true
										AUDIO:Play('Press', AUDIO.upgrade_volume)
									end
									if IsDisabledControlJustReleased(0, 86) then
										controls_active = true
										AUDIO:Play('Release', AUDIO.upgrade_volume)
									end
								end
								if AUDIO.manu_button_SFX and (state_lxsiren[veh] == nil or state_lxsiren[veh] == 0) then
									if IsDisabledControlJustPressed(0, 80) then
										controls_active = true
										AUDIO:Play('Press', AUDIO.upgrade_volume)
									end
									if IsDisabledControlJustReleased(0, 80) then
										controls_active = true
										AUDIO:Play('Release', AUDIO.upgrade_volume)
									end
								end
							else
								if (IsDisabledControlJustReleased(0, 86) or
									IsDisabledControlJustReleased(0, 172) or
									IsDisabledControlJustReleased(0, 19) or
									IsDisabledControlJustReleased(0, 85)) then
										controls_active = true
										if locked_press_count % reminder_rate == 0 then
											AUDIO:Play('Locked_Press', AUDIO.lock_reminder_volume, true) -- lock reminder
											HUD:ShowNotification('~y~~h~Reminder:~h~ ~s~Your siren control box is ~r~locked~s~.', true)
										end
										locked_press_count = locked_press_count + 1
								end
							end
						end

						local hmanu_state_new = 0
						if actv_horn == true and actv_manu == false then
							hmanu_state_new = cached_arhrn_id
						elseif actv_horn == false and actv_manu == true then
							hmanu_state_new = cached_pmanu_id
						elseif actv_horn == true and actv_manu == true then
							hmanu_state_new = cached_smanu_id
						end
						if tone_airhorn_intrp then
							if hmanu_state_new == cached_arhrn_id then
								if state_lxsiren[veh] ~= nil and state_lxsiren[veh] > 0 and actv_lxsrnmute_temp == false then
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
							last_bcast_time = 0
						end
					end
				else
					if dflt_srn_muted_for_veh ~= veh then
						TogMuteDfltSrnForVeh(veh, true)
						dflt_srn_muted_for_veh = veh
					end
				end

				--- IS ANY LAND VEHICLE ---
				if is_land_vehicle then
					----- CONTROLS -----
					if not IsPauseMenuActive() then
						-- IND L
						if IsDisabledControlJustReleased(0, left_signal_key) then -- INPUT_VEH_PREV_RADIO_TRACK
							controls_active = true
							local cstate = state_indic[veh]
							if cstate == ind_state_l then
								state_indic[veh] = ind_state_o
								actv_ind_timer = false
							else
								state_indic[veh] = ind_state_l
								actv_ind_timer = true
							end
							TogIndicStateForVeh(veh, state_indic[veh])
							last_ind_time = current_time
							last_bcast_time = 0
						-- IND R
						elseif IsDisabledControlJustReleased(0, right_signal_key) then -- INPUT_VEH_NEXT_RADIO_TRACK
							controls_active = true
							local cstate = state_indic[veh]
							if cstate == ind_state_r then
								state_indic[veh] = ind_state_o
								actv_ind_timer = false
							else
								state_indic[veh] = ind_state_r
								actv_ind_timer = true
							end
							TogIndicStateForVeh(veh, state_indic[veh])
							last_ind_time = current_time
							last_bcast_time = 0
						-- IND H
						elseif IsControlPressed(0, hazard_key) then -- INPUT_FRONTEND_CANCEL / Backspace
							if GetLastInputMethod(0) then -- last input was with kb
								Wait(hazard_hold_duration)
								if IsControlPressed(0, hazard_key) then -- INPUT_FRONTEND_CANCEL / Backspace
									controls_active = true
									local cstate = state_indic[veh]
									if cstate == ind_state_h then
										state_indic[veh] = ind_state_o
										AUDIO:Play('Hazards_Off', AUDIO.hazards_volume, true) -- Hazards Off
									else
										state_indic[veh] = ind_state_h
										AUDIO:Play('Hazards_On', AUDIO.hazards_volume, true) -- Hazards On
									end
									TogIndicStateForVeh(veh, state_indic[veh])
									actv_ind_timer = false
									last_ind_time = current_time
									last_bcast_time = 0
									Wait(300)
								end
							end
						end
					end

					if current_time - last_bcast_time > bcast_interval then
						last_bcast_time = current_time
						if is_emergency then
							TriggerServerEvent('lvc:TogDfltSrnMuted_s')
							TriggerServerEvent('lvc:SetLxSirenState_s', state_lxsiren[veh])
							TriggerServerEvent('lvc:SetPwrcallState_s', state_pwrcall[veh])
							TriggerServerEvent('lvc:SetAirManuState_s', state_airmanu[veh])
						end
						TriggerServerEvent('lvc:TogIndicState_s', state_indic[veh])
					end
				end
			end

			if controls_active or actv_horn or actv_manu or radio_wheel_active then
				Wait(0)
			else
				Wait(8)
			end
		end
	end
end)
