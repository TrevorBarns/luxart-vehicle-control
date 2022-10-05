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

local count_bcast_timer = 0
local delay_bcast_timer = 300

local count_sndclean_timer = 0
local delay_sndclean_timer = 400

local actv_ind_timer = false
local count_ind_timer = 0
local delay_ind_timer = 180

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

local ind_state_o = 0
local ind_state_l = 1
local ind_state_r = 2
local ind_state_h = 3

local snd_lxsiren = {}
local snd_pwrcall = {}
local snd_airmanu = {}

--	Local fn forward declaration
local RegisterKeyMaps, MakeOrdinal

----------------THREADED FUNCTIONS----------------
-- Set check variable `player_is_emerg_driver` if player is driver of emergency vehicle.
-- Disables controls faster than previous thread.
CreateThread(function()
	if GetResourceState('lux_vehcontrol') ~= 'started' and GetResourceState('lux_vehcontrol') ~= 'starting' then
		if GetCurrentResourceName() == 'lvc' then
			if community_id ~= nil and community_id ~= '' then
				while true do
					playerped = GetPlayerPed(-1)
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
								DisableControlAction(0, 80, true) -- INPUT_VEH_CIN_CAM
								DisableControlAction(0, 86, true) -- INPUT_VEH_HORN
								DisableControlAction(0, 172, true) -- INPUT_CELLPHONE_UP
							end
						end
					end
					Wait(1)
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

--On resource start/restart
CreateThread(function()
	debug_mode = GetResourceMetadata(GetCurrentResourceName(), 'debug_mode', 0) == 'true'
	TriggerEvent('chat:addSuggestion', Lang:t('command.lock_command'), Lang:t('command.lock_desc'))
	SetNuiFocus( false )
	
	UTIL:FixOversizeKeys(SIREN_ASSIGNMENTS)
	RegisterKeyMaps()
	STORAGE:SetBackupTable()
end)

-- Auxiliary Control Handling
--	Handles radio wheel controls and default horn on siren change playback. 
CreateThread(function()
	while true do
		if player_is_emerg_driver then
			-- RADIO WHEEL
			if IsControlPressed(0, 243) and AUDIO.radio_masterswitch then
				while IsControlPressed(0, 243) do
					radio_wheel_active = true
					SetControlNormal(0, 85, 1.0)
					Wait(0)
				end
				Wait(100)
				radio_wheel_active = false
			else
				DisableControlAction(0, 85, true) -- INPUT_VEH_RADIO_WHEEL
				SetVehicleRadioEnabled(veh, false)
			end
		end
		Wait(0)
	end
end)

------ON VEHICLE EXIT EVENT TRIGGER------
CreateThread(function()
	while true do
		if player_is_emerg_driver then
			while playerped ~= nil and veh ~= nil do
				if GetIsTaskActive(playerped, 2) and GetVehiclePedIsIn(ped, true) then
					TriggerEvent('lvc:onVehicleExit')
					Wait(1000)
				end
				Wait(0)
			end
		end
		Wait(1000)
	end
end)

------VEHICLE CHANGE DETECTION AND TRIGGER------
CreateThread(function()
	while true do
		if player_is_emerg_driver and veh ~= nil then
			if last_veh == nil then
				TriggerEvent('lvc:onVehicleChange')
			else
				if last_veh ~= veh then
					TriggerEvent('lvc:onVehicleChange')
				end
			end
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
		count_bcast_timer = delay_bcast_timer
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

---------------------------------------------------------------------
local function CleanupSounds()
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
		if newstate ~= state_lxsiren[veh] and newstate ~= nil then
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
		if newstate ~= state_pwrcall[veh] and newstate ~= nil then
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
		if newstate ~= state_airmanu[veh] and newstate ~= nil then
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
				local veh = GetVehiclePedIsUsing(ped_s)
				TogIndicStateForVeh(veh, newstate)
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
				local veh = GetVehiclePedIsUsing(ped_s)
				TogMuteDfltSrnForVeh(veh, true)
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
				local veh = GetVehiclePedIsUsing(ped_s)
				SetLxSirenStateForVeh(veh, newstate)
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
				local veh = GetVehiclePedIsUsing(ped_s)
				SetPowercallStateForVeh(veh, newstate)
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
				local veh = GetVehiclePedIsUsing(ped_s)
				SetAirManuStateForVeh(veh, newstate)
			end
		end
	end
end)


---------------------------------------------------------------------
CreateThread(function()
	while true do
		CleanupSounds()
		DistantCopCarSirens(false)
		----- IS IN VEHICLE -----
		if GetPedInVehicleSeat(veh, -1) == playerped then
			if state_indic[veh] == nil then
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
			if GetVehicleClass(veh) == 18 then
				lights_on = IsVehicleSirenOn(veh)
				--  FORCE RADIO ENABLED PER FRAME
				if radio_masterswitch then
					SetVehicleRadioEnabled(veh, true)
				end

				if not IsEntityDead(veh) then
					TogMuteDfltSrnForVeh(veh, true)
					--- SET INIT TABLE VALUES ---
					if state_lxsiren[veh] == nil then
						state_lxsiren[veh] = 0
					end
					if state_pwrcall[veh] == nil then
						state_pwrcall[veh] = 0
					end
					if state_airmanu[veh] == nil then
							state_airmanu[veh] = 0
					end

					--- IF LIGHTS ARE OFF TURN OFF SIREN ---
					if not lights_on and state_lxsiren[veh] > 0 then
						--	SAVE TONE BEFORE TURNING OFF
						if not tone_main_reset_standby then
							UTIL:SetToneByID('MAIN_MEM', state_lxsiren[veh])
						end
						SetLxSirenStateForVeh(veh, 0)
						count_bcast_timer = delay_bcast_timer
					end
					if not lights_on and state_pwrcall[veh] > 0 then
						SetPowercallStateForVeh(veh, 0)
						count_bcast_timer = delay_bcast_timer
					end

					----- CONTROLS -----
					if not IsPauseMenuActive() and UpdateOnscreenKeyboard() ~= 0 and not radio_wheel_active then
						if not key_lock then
							------ TOG DFLT SRN LIGHTS ------
							if IsDisabledControlJustReleased(0, 85) then
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
								count_bcast_timer = delay_bcast_timer
							------ TOG LX SIREN ------
							elseif IsDisabledControlJustReleased(0, 19) then
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
								count_bcast_timer = delay_bcast_timer
							-- POWERCALL
							elseif IsDisabledControlJustReleased(0, 172) and not IsMenuOpen() then
								if state_pwrcall[veh] == 0 then
									if lights_on then
										AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
										HUD:SetItemState('siren', true)
										SetPowercallStateForVeh(veh, UTIL:GetToneID('AUX'))
										count_bcast_timer = delay_bcast_timer
									end
								else
									AUDIO:Play('Downgrade', AUDIO.downgrade_volume)
									if state_lxsiren[veh] == 0 then
										HUD:SetItemState('siren', false)
									end
									SetPowercallStateForVeh(veh, 0)
								end
								AUDIO:ResetActivityTimer()
								count_bcast_timer = delay_bcast_timer
							end
							-- CYCLE LX SRN TONES
							if state_lxsiren[veh] > 0 then
								if IsDisabledControlJustReleased(0, 80) then
									AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
									HUD:SetItemState('horn', false)
									SetLxSirenStateForVeh(veh, UTIL:GetNextSirenTone(state_lxsiren[veh], veh, true))
									count_bcast_timer = delay_bcast_timer
								elseif IsDisabledControlPressed(0, 80) then
									HUD:SetItemState('horn', true)
								end
							end

							-- MANU
							if state_lxsiren[veh] < 1 then
								if IsDisabledControlPressed(0, 80) then
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
									AUDIO:Play('Press', AUDIO.upgrade_volume)
								end
								if IsDisabledControlJustReleased(0, 86) then
									AUDIO:Play('Release', AUDIO.upgrade_volume)
								end
							end
							if AUDIO.manu_button_SFX and state_lxsiren[veh] == 0 then
								if IsDisabledControlJustPressed(0, 80) then
									AUDIO:Play('Press', AUDIO.upgrade_volume)
								end
								if IsDisabledControlJustReleased(0, 80) then
									AUDIO:Play('Release', AUDIO.upgrade_volume)
								end
							end
						else
							if (IsDisabledControlJustReleased(0, 86) or
								IsDisabledControlJustReleased(0, 172) or
								IsDisabledControlJustReleased(0, 19) or
								IsDisabledControlJustReleased(0, 85)) then
									if locked_press_count % reminder_rate == 0 then
										AUDIO:Play('Locked_Press', AUDIO.lock_reminder_volume, true) -- lock reminder
										HUD:ShowNotification('~y~~h~Reminder:~h~ ~s~Your siren control box is ~r~locked~s~.', true)
									end
									locked_press_count = locked_press_count + 1
							end
						end
					end

					---- ADJUST HORN / MANU STATE ----
					local hmanu_state_new = 0
					if actv_horn == true and actv_manu == false then
						hmanu_state_new = UTIL:GetToneID('ARHRN')
					elseif actv_horn == false and actv_manu == true then
						hmanu_state_new = UTIL:GetToneID('PMANU')
					elseif actv_horn == true and actv_manu == true then
						hmanu_state_new = UTIL:GetToneID('SMANU')
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
			else
				-- DISABLE SIREN AUDIO FOR ALL VEHICLES NOT VC_EMERGENCY (VEHICLES.META)
				TogMuteDfltSrnForVeh(veh, true)
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
					elseif IsControlPressed(0, hazard_key) then -- INPUT_FRONTEND_CANCEL / Backspace
						if GetLastInputMethod(0) then -- last input was with kb
							Wait(hazard_hold_duration)
							if IsControlPressed(0, hazard_key) then -- INPUT_FRONTEND_CANCEL / Backspace
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
								count_ind_timer = 0
								count_bcast_timer = delay_bcast_timer
								Wait(300)
							end
						end
					end
				end

				----- AUTO BROADCAST VEH STATES -----
				if count_bcast_timer > delay_bcast_timer then
					count_bcast_timer = 0
					--- IS EMERG VEHICLE ---
					if GetVehicleClass(veh) == 18 then
						TriggerServerEvent('lvc:TogDfltSrnMuted_s')
						TriggerServerEvent('lvc:SetLxSirenState_s', state_lxsiren[veh])
						TriggerServerEvent('lvc:SetPwrcallState_s', state_pwrcall[veh])
						TriggerServerEvent('lvc:SetAirManuState_s', state_airmanu[veh])
					end
					--- IS ANY OTHER VEHICLE ---
					TriggerServerEvent('lvc:TogIndicState_s', state_indic[veh])
				else
					count_bcast_timer = count_bcast_timer + 1
				end
			end
		end
		Wait(0)
	end
end)