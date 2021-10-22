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
]]

--GLOBAL VARIABLES used in cl_ragemenu, UTILs, and plug-ins.
--	GENERAL VARIABLES
key_lock = false
playerped = nil
last_veh = nil
veh = nil
trailer = nil
player_is_emerg_driver = false

--	MAIN SIREN SETTINGS
tone_main_reset_standby 	= reset_to_standby_default
tone_airhorn_intrp 			= airhorn_interrupt_default
park_kill 					= park_kill_default

--	AUDIO SETTINGS
radio_masterswitch 			= true
airhorn_button_SFX 			= false
manu_button_SFX 			= false
activity_reminder_index		= 1
last_activity_timer 		= 0

button_sfx_scheme			= default_sfx_scheme_name
on_volume					= default_on_volume	
off_volume					= default_off_volume	
upgrade_volume 				= default_upgrade_volume	
downgrade_volume 			= default_downgrade_volume
hazards_volume 				= default_hazards_volume
lock_volume 				= default_lock_volume
lock_reminder_volume		= default_lock_reminder_volume
activity_reminder_volume 	= default_reminder_volume
							
--LOCAL VARIABLES
local activity_reminder_lookup = { [2] = 30000, [3] = 60000, [4] = 120000, [5] = 300000, [6] = 600000 } 
local radio_wheel_active = false

local count_bcast_timer = 0
local delay_bcast_timer = 200

local count_sndclean_timer = 0
local delay_sndclean_timer = 400

local actv_ind_timer = false
local count_ind_timer = 0
local delay_ind_timer = 180

actv_lxsrnmute_temp = false
srntone_temp = 0
local dsrn_mute = true

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

----------------THREADED FUNCTIONS----------------
-- Set check variable `player_is_emerg_driver` if player is driver of emergency vehicle.
-- Disables controls faster than previous thread. 
Citizen.CreateThread(function()
	if GetCurrentResourceName() == 'lvc' then	
		if community_id ~= nil and community_id ~= "" then
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
							if IsControlPressed(0, 243) and radio_masterswitch then
								while IsControlPressed(0, 243) do
									radio_wheel_active = true
									SetControlNormal(0, 85, 1.0)
									Citizen.Wait(0)
								end
								Citizen.Wait(100)
								radio_wheel_active = false
							else
								DisableControlAction(0, 85, true) -- INPUT_VEH_RADIO_WHEEL
								SetVehicleRadioEnabled(veh, false)
							end
						end
					end
				end
				Citizen.Wait(1)
			end
		else
			Citizen.Wait(1000)
			HUD:ShowNotification("~b~~h~LVC~h~ ~r~~h~CONFIG ERROR~h~~s~: COMMUNITY ID MISSING. SEE LOGS. CONTACT SERVER DEVELOPER.", true)
			UTIL:Print("^1CONFIG ERROR: COMMUNITY ID NOT SET, THIS IS REQUIRED TO PREVENT CONFLICTS FOR PLAYERS WHO PLAY ON MULTIPLE SERVERS WITH LVC. PLEASE SET THIS IN SETTINGS.LUA.", true)
		end
	else
		Citizen.Wait(1000)
		HUD:ShowNotification("~b~~h~LVC~h~ ~r~~h~CONFIG ERROR~h~~s~: INVALID RESOURCE NAME. SEE LOGS. CONTRACT SERVER DEVELOPER.", true)
		UTIL:Print("^1CONFIG ERROR: INVALID RESOURCE NAME. PLEASE VERIFY RESOURCE FOLDER NAME READS '^3lvc^1' (CASE-SENSITIVE). THIS IS REQUIRED FOR PROPER SAVE / LOAD FUNCTIONALITY. PLEASE RENAME, REFRESH, AND ENSURE.", true)
	end
end)

-------------------HUD BACKLIGHT------------------
Citizen.CreateThread(function()
	local current_backlight_state
	while true do
		if player_is_emerg_driver then 
			while HUD:GetHudBacklightMode() == 1 do
				_, veh_lights, veh_headlights  = GetVehicleLightsState(veh)
				if veh_lights == 1 and veh_headlights == 0 and HUD:GetHudBacklightState() == false then
					HUD:SetHudBacklightState(true)
				elseif (veh_lights == 1 and veh_headlights == 1) or (veh_lights == 0 and veh_headlights == 1) and HUD:GetHudBacklightState() == false then
					HUD:SetHudBacklightState(true)
				elseif (veh_lights == 0 and veh_headlights == 0) and HUD:GetHudBacklightState() == true then
					HUD:SetHudBacklightState(false)	
				end
				Citizen.Wait(500)
			end		
		end
		Citizen.Wait(1000)
	end
end) 

----------------PARK KILL THREADS----------------
--Kill siren on Exit
Citizen.CreateThread(function()
	while park_kill or park_kill_masterswitch do
		while park_kill and playerped ~= nil and veh ~= nil do
			if GetIsTaskActive(playerped, 2) then
				if not tone_main_reset_standby and state_lxsiren[veh] ~= 0 then
					UTIL:SetToneByID('MAIN_MEM', state_lxsiren[veh])
				end
				SetLxSirenStateForVeh(veh, 0)
				SetPowercallStateForVeh(veh, 0)
				SetAirManuStateForVeh(veh, 0)	
				HUD:SetItemState("siren", false)
				HUD:SetItemState("horn", false)
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
	Citizen.Wait(1000)
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
		Citizen.Wait(1000)
	end
end)

RegisterNetEvent('lvc:onVehicleChange')
AddEventHandler('lvc:onVehicleChange', function()
	last_veh = veh
	UTIL:UpdateApprovedTones(veh)
	Storage:ResetSettings()
	Storage:LoadSettings()
	UTIL:BuildToneOptions()
	SetVehRadioStation(veh, "OFF")
	Citizen.Wait(500)
	SetVehRadioStation(veh, "OFF")
end)


--------------REGISTERED COMMANDS---------------
--Toggle LUX lock command
RegisterCommand('lvclock', function(source, args)
	CopyVehicleDamages(veh, 1000)
	if player_is_emerg_driver then	
		key_lock = not key_lock
		PlayAudio("Key_Lock", lock_volume, true) 
		HUD:SetItemState("lock", key_lock) 
		--if HUD is visible do not show notification
		if not HUD:GetHudState() then
			if key_lock then
				HUD:ShowNotification("Siren Control Box: ~r~Locked", true)
			else
				HUD:ShowNotification("Siren Control Box: ~g~Unlocked", true)				
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
										HUD:SetItemState("siren", true)
										PlayAudio("Upgrade", upgrade_volume)
										SetLxSirenStateForVeh(veh, proposed_tone)
										count_bcast_timer = delay_bcast_timer
									else
										if state_pwrcall[veh] == 0 then
											HUD:SetItemState("siren", false)
										end
										PlayAudio("Downgrade", downgrade_volume)
										SetLxSirenStateForVeh(veh, 0)
										count_bcast_timer = delay_bcast_timer				
									end
								end
							else
								HUD:ShowNotification("~b~~h~LVC~h~ ~r~~h~ERROR 2~h~~s~: Nil value caught.\ndetails: (" .. i .. "," .. proposed_tone .. "," .. UTIL:GetVehicleProfileName() .. ")", true)
								HUD:ShowNotification("~b~~h~LVC~h~ ~r~~h~ERROR 2~h~~s~: Try switching vehicles and switching back OR loading profile settings (if save present).", true)
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
	TriggerEvent('chat:addSuggestion', '/lvclock', 'Toggle Luxart Vehicle Control Keybinding Lockout.')
	SetNuiFocus( false )
	UTIL:FixOversizeKeys(SIREN_ASSIGNMENTS)
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
AddEventHandler('lvc:TogDfltSrnMuted_c', function(sender, toggle)
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
Citizen.CreateThread(function()
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
				--  FORCE RADIO ENABLED PER FRAME
				if radio_masterswitch then
					SetVehicleRadioEnabled(veh, true)
				end
				
				if UpdateOnscreenKeyboard() ~= 0 and not IsEntityDead(veh) then
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
					TogMuteDfltSrnForVeh(veh, true)
					dsrn_mute = true
					
					--- IF LIGHTS ARE OFF TURN OFF SIREN ---				
					if not IsVehicleSirenOn(veh) and state_lxsiren[veh] > 0 then
						--	SAVE TONE BEFORE TURNING OFF
						if not tone_main_reset_standby then
							UTIL:SetToneByID('MAIN_MEM', state_lxsiren[veh])
						end
						SetLxSirenStateForVeh(veh, 0)
						count_bcast_timer = delay_bcast_timer
					end
					if not IsVehicleSirenOn(veh) and state_pwrcall[veh] > 0 then
						SetPowercallStateForVeh(veh, 0)
						count_bcast_timer = delay_bcast_timer
					end
				
					----- CONTROLS -----
					if not IsPauseMenuActive() then
						if not key_lock and not radio_wheel_active then
							------ TOG DFLT SRN LIGHTS ------
							if IsDisabledControlJustReleased(0, 85) then
								if IsVehicleSirenOn(veh) then
									PlayAudio("Off", off_volume)
									--	SET NUI IMAGES
									HUD:SetItemState("switch", false) 
									HUD:SetItemState("siren", false) 
									--	TURN OFF SIRENS (R* LIGHTS)
									SetVehicleSiren(veh, false)
									if trailer ~= nil and trailer ~= 0 then
										SetVehicleSiren(trailer, false)
									end

								else
									PlayAudio("On", on_volume) -- On
									--	SET NUI IMAGES
									HUD:SetItemState("switch", true) 
									--	TURN OFF SIRENS (R* LIGHTS)
									SetVehicleSiren(veh, true)
									if trailer ~= nil and trailer ~= 0 then
										SetVehicleSiren(trailer, true)
									end
								end
								SetActivityTimer()							
								count_bcast_timer = delay_bcast_timer
							------ TOG LX SIREN ------
							elseif IsDisabledControlJustReleased(0, 19) then
								if state_lxsiren[veh] == 0 then
									if IsVehicleSirenOn(veh) then
										local new_tone = nil
										PlayAudio("Upgrade", upgrade_volume) 
										HUD:SetItemState("siren", true) 
										if not tone_main_reset_standby then
											--	GET THE SAVED TONE VERIFY IT IS APPROVED, AND NOT DISABLED / BUTTON ONLY
											local tone_mem_id = UTIL:GetToneID('MAIN_MEM')
											local option = UTIL:GetToneOption(tone_mem_id)
											if UTIL:IsApprovedTone(tone_mem_id) and option ~= 3 and option ~= 4 then
												SetLxSirenStateForVeh(veh, tone_mem_id)
											else
												new_tone = UTIL:GetNextSirenTone(tone_mem_id, veh, true) 
												UTIL:SetToneByID('MAIN_MEM', new_tone)
												SetLxSirenStateForVeh(veh, new_tone)
											end
											
										else
											local option = UTIL:GetToneOption(2)
											if option == 3 or option == 4 then
												new_tone = UTIL:GetNextSirenTone(2, veh, true) 
											else
												new_tone = UTIL:GetToneAtPos(2)
											end
											SetLxSirenStateForVeh(veh, new_tone)
										end
									end
								else
									PlayAudio("Downgrade", downgrade_volume) 
									-- ONLY CHANGE NUI STATE IF PWRCALL IS OFF AS WELL
									if state_pwrcall[veh] == 0 then
										HUD:SetItemState("siren", false) 
									end
									if not tone_main_reset_standby then
										UTIL:SetToneByID('MAIN_MEM', state_lxsiren[veh])
									end
									SetLxSirenStateForVeh(veh, 0)
								end
								SetActivityTimer()
								count_bcast_timer = delay_bcast_timer
							-- POWERCALL
							elseif IsDisabledControlJustReleased(0, 172) and not IsMenuOpen() then 
								if state_pwrcall[veh] == 0 then
									if IsVehicleSirenOn(veh) then
										PlayAudio("Upgrade", upgrade_volume) 
										HUD:SetItemState("siren", true) 
										SetPowercallStateForVeh(veh, UTIL:GetToneID('AUX'))
										count_bcast_timer = delay_bcast_timer
									end
								else
									PlayAudio("Downgrade", downgrade_volume) 
									if state_lxsiren[veh] == 0 then
										HUD:SetItemState("siren", false) 
									end 
									SetPowercallStateForVeh(veh, 0)
								end
								SetActivityTimer()
								count_bcast_timer = delay_bcast_timer
							end
							-- BROWSE LX SRN TONES
							if state_lxsiren[veh] > 0 then
								if IsDisabledControlJustReleased(0, 80) then
									PlayAudio("Upgrade", upgrade_volume)
									HUD:SetItemState("horn", false) 
									SetLxSirenStateForVeh(veh, UTIL:GetNextSirenTone(state_lxsiren[veh], veh, true))
									count_bcast_timer = delay_bcast_timer
								elseif IsDisabledControlPressed(0, 80) then
									HUD:SetItemState("horn", true) 
								end
							end
										
							-- MANU
							if state_lxsiren[veh] < 1 then
								if IsDisabledControlPressed(0, 80) then
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
								if IsDisabledControlJustPressed(0, 80) then
									PlayAudio("Press", upgrade_volume)									
								end								
								if IsDisabledControlJustReleased(0, 80) then
									PlayAudio("Release", upgrade_volume)									
								end
							end
						elseif not radio_wheel_active then
							if (IsDisabledControlJustReleased(0, 86) or 
								IsDisabledControlJustReleased(0, 172) or 
								IsDisabledControlJustReleased(0, 19) or 
								IsDisabledControlJustReleased(0, 85)) then
									if locked_press_count % reminder_rate == 0 then
										PlayAudio("Locked_Press", lock_reminder_volume, true) -- lock reminder
										HUD:ShowNotification("~y~~h~Reminder:~h~ ~s~Your siren control box is ~r~locked~s~.", true)
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
							Citizen.Wait(hazard_hold_duration)
							if IsControlPressed(0, hazard_key) then -- INPUT_FRONTEND_CANCEL / Backspace
								local cstate = state_indic[veh]
								if cstate == ind_state_h then
									state_indic[veh] = ind_state_o
									PlayAudio("Hazards_Off", hazards_volume, true) -- Hazards Off
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
						TriggerServerEvent('lvc:TogDfltSrnMuted_s', dsrn_mute)
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
		Citizen.Wait(0)
	end
end)