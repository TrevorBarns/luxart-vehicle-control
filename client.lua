--[[
---------------------------------------------------
LUXART VEHICLE CONTROL ELS CLICKS (FOR FIVEM)
---------------------------------------------------
Last revision: MAY 01 2017 (VERS. 1.01)
Coded by Lt.Caine
ELS Clicks by Faction
Additonal Modification by TrevorBarns
---------------------------------------------------
NOTES
	LVC will automatically apply to all emergency vehicles (vehicle class 18)
---------------------------------------------------
CONTROLS	
	Right indicator:	=	(Next Custom Radio Track)
	Left indicator:		-	(Previous Custom Radio Track)
	Hazard lights:	Backspace	(Phone Cancel)
	Toggle emergency lights:	Y	(Text Chat Team)
	Airhorn:	E	(Horn)
	Toggle siren:	,	(Previous Radio Station)
	Manual siren / Change siren tone:	N	(Next Radio Station)
	Auxiliary siren:	Down Arrow	(Phone Up)
---------------------------------------------------
]]
local save_prefix = "lux_setting_"
local HUD_move_lg_increment = 0.0050
local HUD_move_sm_increment = 0.0001
local HUD_op_increment = 5
local button_delay = 300

--------------------------------------------------
--Runtime Variables (Do not touch unless you know what you're doing.) 
local show_HUD = hud_first_default
local HUD_x_offset = 0
local HUD_y_offset = 0
local HUD_move_mode = false
local HUD_op_bgd_offset = 0
local HUD_op_btn_offset = 0
local HUD_op_mode = false

local tone_mode = false
local tone_PMANU_id = 2
local tone_SMANU_id = 3
local tone_AUX_id = 2
local tone_main_mem_id = 0

local key_lock = false		
local spawned = false
local playerped = nil
local veh = nil
local player_is_emerg_driver = false

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

local ind_state_o = 0
local ind_state_l = 1
local ind_state_r = 2
local ind_state_h = 3

local snd_lxsiren = {}
local snd_pwrcall = {}
local snd_airmanu = {}


TriggerEvent('chat:addSuggestion', '/luxhud', 'Toggle Luxart Vehicle Control HUD.')
TriggerEvent('chat:addSuggestion', '/luxhudmove', 'Toggle Luxart Vehicle Control HUD Move Mode.')
TriggerEvent('chat:addSuggestion', '/luxhudopacity', 'Toggle Luxart Vehicle Control HUD Opacity Mode.')
TriggerEvent('chat:addSuggestion', '/luxlock', 'Toggle Luxart Vehicle Control Keybinding Lockout.')
TriggerEvent('chat:addSuggestion', '/luxtonemode', 'Change manual siren tones.')

--------------------------------------------------
-------------------HUD SECTION--------------------
--/luxhud - Main toggle for HUD
RegisterCommand('luxhud', function(source, args)
	if player_is_emerg_driver then
		show_HUD = not show_HUD
		if show_HUD then
			SetResourceKvpInt(save_prefix .. "HUD",  1)
		else
			SetResourceKvpInt(save_prefix .. "HUD",  0)
		end
	end
end)

--/luxhudopacity - Set opacity mode
RegisterCommand('luxhudopacity', function(source, args)
	if not HUD_move_mode and not tone_mode and player_is_emerg_driver then
		ShowHUD()
		if HUD_op_mode then		--If already in op_mode transitioning out of op_mode (end and save)
			HUD_op_mode = false
			SetResourceKvpFloat(save_prefix .. "HUD_op_bgd_offset",  HUD_op_bgd_offset)
			SetResourceKvpFloat(save_prefix .. "HUD_op_btn_offset",  HUD_op_btn_offset)
		else					--If not in op_mode first entering, lock and start. 
			HUD_op_mode = true
		end
	end
end)

--/luxhudopacity - user input function
Citizen.CreateThread(function()
	while true do
		while HUD_op_mode do
			ShowText(0.5, 0.75, 0, "~w~HUD Opacity Mode ~g~enabled~w~. To stop use '~b~/luxhudopacity~w~'.")
			ShowText(0.5, 0.775, 0, "~y~Background:~w~ ← → left-right ~y~Buttons:~w~ ↑ ↓ up-down")
			if IsDisabledControlPressed(0, 172) then	--Arrow Up
				if (HUD_op_btn_offset + hud_button_off_opacity) < 255 then
					HUD_op_btn_offset = HUD_op_btn_offset + HUD_op_increment
				end
			end
			if IsDisabledControlPressed(0, 173) then	--Arrow Down
				if (HUD_op_btn_offset + hud_button_off_opacity) > 10 then
					HUD_op_btn_offset = HUD_op_btn_offset - HUD_op_increment
				end
			end
			if IsDisabledControlPressed(0, 175) then	--Arrow Right
				if (HUD_op_bgd_offset + hud_bgd_opacity) < 255 then
					HUD_op_bgd_offset = HUD_op_bgd_offset + HUD_op_increment
				end
			end
			if IsDisabledControlPressed(0, 174) then	--Arrow Left
				if (HUD_op_bgd_offset + hud_bgd_opacity) > 10 then
					HUD_op_bgd_offset = HUD_op_bgd_offset - HUD_op_increment
				end
			end
			Citizen.Wait(0)
		end
		Citizen.Wait(1000)
	end
end)

--/luxhudmove - Set move mode
RegisterCommand('luxhudmove', function(source, args)
	if not HUD_op_mode and not tone_mode and player_is_emerg_driver then
		ShowHUD()
		if HUD_move_mode then		--If already in op_mode transitioning out of op_mode (end and save)
			HUD_move_mode = false
			SetResourceKvpFloat(save_prefix .. "HUD_x_offset",  HUD_x_offset)
			SetResourceKvpFloat(save_prefix .. "HUD_y_offset",  HUD_y_offset)
		else					--If not in op_mode first entering, lock and start. 
			HUD_move_mode = true
		end
	end
end)

--/luxhudmove - user input function
Citizen.CreateThread(function()
	while true do
		while HUD_move_mode do
			ShowText(0.5, 0.75, 0, "~w~HUD Move Mode ~g~enabled~w~. To stop use '~b~/luxhudmove~w~'.")
			ShowText(0.5, 0.775, 0, "~w~← → left-right ↑ ↓ up-down\nCTRL + Arrow for fine control.")
			if IsControlPressed(0, 224) then
				if IsDisabledControlPressed(0, 172) then	--Arrow Up
					HUD_y_offset = HUD_y_offset - HUD_move_sm_increment
				end
				if IsDisabledControlPressed(0, 173) then	--Arrow Down
					HUD_y_offset = HUD_y_offset + HUD_move_sm_increment
				end
				if IsDisabledControlPressed(0, 174) then	--Arrow Left
					HUD_x_offset = HUD_x_offset - HUD_move_sm_increment
				end
				if IsDisabledControlPressed(0, 175) then	--Arrow Right
					HUD_x_offset = HUD_x_offset + HUD_move_sm_increment
				end
			else
				if IsDisabledControlPressed(0, 172) then	--Arrow Up
					HUD_y_offset = HUD_y_offset - HUD_move_lg_increment
				end
				if IsDisabledControlPressed(0, 173) then	--Arrow Down
					HUD_y_offset = HUD_y_offset + HUD_move_lg_increment
				end
				if IsDisabledControlPressed(0, 174) then	--Arrow Left
					HUD_x_offset = HUD_x_offset - HUD_move_lg_increment
				end
				if IsDisabledControlPressed(0, 175) then	--Arrow Right
					HUD_x_offset = HUD_x_offset + HUD_move_lg_increment
				end
			end
			
			if HUD_x_offset > 1 then
				HUD_x_offset = HUD_x_offset - 0.01
			elseif HUD_x_offset < -0.15 then
				HUD_x_offset = HUD_x_offset + 0.01			
			end
			
			if HUD_y_offset > 0.3 then
				HUD_y_offset = HUD_y_offset - 0.01
			elseif HUD_y_offset < -0.75 then
				HUD_y_offset = HUD_y_offset + 0.01			
			end
			Citizen.Wait(0)
		end
		Citizen.Wait(1000)
	end
end)


------------------LUXLOCK SECTION-----------------
if lockout_master_switch then
	RegisterCommand('luxlock', function(source, args)
		if player_is_emerg_driver then	
			key_lock = not key_lock
			TriggerEvent("lux_vehcontrol:ELSClick", "Key_Lock", lock_volume) -- Off
			if key_lock then
				ShowDebug("Siren Control Box: ~r~Locked")
			else
				ShowDebug("Siren Control Box: ~g~Unlocked")				
			end
		end
	end)
	RegisterKeyMapping("luxlock", "Lock out LUX Controls", "keyboard", lockout_default_hotkey)
end

--------------MANU/HORN/SIREN SECTION-------------
--/luxtonemode -Set Tone Mode
if custom_manual_tones_master_switch or custom_aux_tones_master_switch then
	RegisterCommand('luxtonemode', function(source, args)
		if not HUD_move_mode and not HUD_op_mode and  player_is_emerg_driver then
			if tone_mode then		--If already in op_mode transitioning out of op_mode (end and save)
				tone_mode = false
				SetResourceKvpInt(save_prefix .. "tone_PMANU_id",  tone_PMANU_id)
				SetResourceKvpInt(save_prefix .. "tone_SMANU_id",  tone_SMANU_id)
				SetResourceKvpInt(save_prefix .. "tone_AUX_id",  tone_AUX_id)
			else					--If not in op_mode first entering, lock and start. 
				tone_mode = true
			end
		end
	end)
end

--/luxtonemode - user input function
Citizen.CreateThread(function()
	while true do
		while tone_mode do
			--Options: 1- Airhorn (restricted) 2- Wail 3-Yelp 4-Priority
			if custom_manual_tones_master_switch then
				if not IsControlPressed(0, 224) then
					--SECONDARY MANU
					if IsDisabledControlPressed(0, 172) then	--Arrow Up
						tone_SMANU_id = GetNextTone("MANU", tone_SMANU_id)
						if tone_SMANU_id == 11 and not usePowercallAuxSrn(veh) then 
							tone_SMANU_id = GetNextTone("MANU", tone_SMANU_id)
							while tone_SMANU_id > 11 and not useFiretruckSiren(veh) do 
								tone_SMANU_id = GetNextTone("MANU", tone_SMANU_id)
								Citizen.Wait(0)
							end
						end
						Citizen.Wait(button_delay)						
					end
					if IsDisabledControlPressed(0, 173) then	--Arrow Down
						tone_SMANU_id = GetPreviousTone("MANU", tone_SMANU_id)
						if tone_SMANU_id == 11 and not usePowercallAuxSrn(veh) then 
							tone_SMANU_id = GetPreviousTone("MANU", tone_SMANU_id)
							while tone_SMANU_id > 11 and not useFiretruckSiren(veh) do 
								tone_SMANU_id = GetPreviousTone("MANU", tone_SMANU_id)
								Citizen.Wait(0)
							end
						end
						Citizen.Wait(button_delay)
					end
					--PRIMARY MANU
					if IsDisabledControlPressed(0, 175) then	--Arrow Right
						tone_PMANU_id = GetNextTone("MANU", tone_PMANU_id)
						if tone_PMANU_id == 11 and not usePowercallAuxSrn(veh) then 
							tone_PMANU_id = GetNextTone("MANU", tone_PMANU_id)
							while tone_PMANU_id > 11 and not useFiretruckSiren(veh) do 
								tone_PMANU_id = GetNextTone("MANU", tone_PMANU_id)
								Citizen.Wait(0)
							end
						end
						Citizen.Wait(button_delay)
					end
					if IsDisabledControlPressed(0, 174) then	--Arrow Left
						tone_PMANU_id = GetPreviousTone("MANU", tone_PMANU_id)
						if tone_PMANU_id == 11 and not usePowercallAuxSrn(veh) then 
							tone_PMANU_id = GetPreviousTone("MANU", tone_PMANU_id)
							while tone_PMANU_id > 11 and not useFiretruckSiren(veh) do 
								tone_PMANU_id = GetPreviousTone("MANU", tone_PMANU_id)
								Citizen.Wait(0)
							end
						end
						Citizen.Wait(button_delay)
					end
				end
			end
			if custom_aux_tones_master_switch then
				if IsControlPressed(0, 224) then
					if IsDisabledControlPressed(0, 175) then	--Arrow Right
						tone_AUX_id = GetNextTone("AUX", tone_AUX_id)
						if tone_AUX_id == 11 and not usePowercallAuxSrn(veh) then 
							tone_AUX_id = GetNextTone("AUX", tone_AUX_id)
							while tone_AUX_id > 11 and not useFiretruckSiren(veh) do 
								tone_AUX_id = GetNextTone("AUX", tone_AUX_id)
								Citizen.Wait(0)
							end
						end
						Citizen.Wait(button_delay)
					end
					if IsDisabledControlPressed(0, 174) then 	--Arrow Left
						tone_AUX_id = GetPreviousTone("AUX", tone_AUX_id)
						while tone_AUX_id > 11 and not useFiretruckSiren(veh) do 
							tone_AUX_id = GetPreviousTone("AUX", tone_AUX_id)
							if tone_AUX_id == 11 and not usePowercallAuxSrn(veh) then 
								tone_AUX_id = GetPreviousTone("AUX", tone_AUX_id)
							end	
							Citizen.Wait(0)
						end							
						Citizen.Wait(button_delay)						
					end
				end
			end
			Citizen.Wait(0)
		end
		Citizen.Wait(1000)
	end
end)

--/luxtonemode - user input function
Citizen.CreateThread(function()
	while true do
		while tone_mode do
			ShowText(0.5, 0.750, 0, "~w~Tone mode ~g~enabled~w~. To stop use '~b~/luxtonemode~w~'.")
			if custom_manual_tones_master_switch then
				ShowText(0.35, 0.775, 1, "~w~ ← → left-right \t~y~Primary Manual Tone (default: R): ~w~" .. tone_table[tone_PMANU_id])
				ShowText(0.35, 0.800, 1, "~w~ ↑ ↓ up-down \t~y~Secondary Manual Tone (default: E + R): ~w~" .. tone_table[tone_SMANU_id])
			end
			if custom_aux_tones_master_switch then
				ShowText(0.325, 0.825, 1, "~w~ CTRL + ← → left-right \t~y~Auxiliary Tone (default: ↑): ~w~" .. tone_table[tone_AUX_id])			
			end
			Citizen.Wait(0)
		end
		Citizen.Wait(1000)
	end
end)

------------------LOAD SETTINGS SECTION-----------------
AddEventHandler( "playerSpawned", function()
	if not spawned then
		RegisterKeyMaps()
		--Position
		HUD_x_offset = GetResourceKvpFloat(save_prefix .. "HUD_x_offset")
		HUD_y_offset = GetResourceKvpFloat(save_prefix .. "HUD_y_offset")
		--Opacity
		HUD_op_bgd_offset = GetResourceKvpFloat(save_prefix .. "HUD_op_bgd_offset")
		HUD_op_btn_offset = GetResourceKvpFloat(save_prefix .. "HUD_op_btn_offset")
		--Tones
		tone_PMANU_id = GetResourceKvpInt(save_prefix .. "tone_PMANU_id")
		tone_SMANU_id = GetResourceKvpInt(save_prefix .. "tone_SMANU_id")
		tone_AUX_id = GetResourceKvpInt(save_prefix .. "tone_AUX_id")
		--HUD Main
		show_HUD_int = GetResourceKvpInt(save_prefix .. "HUD")
		if show_HUD_int == 0 then
			show_HUD = false
		else
			show_HUD = true
		end
		spawned = true
	end 
end )

--Ensure textures have streamed
Citizen.CreateThread(function()
	while !HasStreamedTextureDictLoaded("commonmenu") do
		RequestStreamedTextureDict("commonmenu", false);
		Citizen.Wait(0)
	end
end)

---------------------------------------------------------------------
function GetNextTone(tone_type, current_tone) 
	if tone_type == "MANU" then
		local temp_pos = -1
		for i, allowed_tone in ipairs(manu_allowed_tones) do
			if allowed_tone == current_tone then
				temp_pos = i
			end
		end
		if temp_pos < #manu_allowed_tones then
			return manu_allowed_tones[temp_pos+1]
		else
			return manu_allowed_tones[1]
		end
	elseif tone_type == "AUX" then
		local temp_pos = -1
		for i, allowed_tone in ipairs(aux_allowed_tones) do
			if allowed_tone == current_tone then
				temp_pos = i
			end
		end
		if temp_pos < #aux_allowed_tones then
			return aux_allowed_tones[temp_pos+1]					
		else
			return aux_allowed_tones[1]
		end
	elseif tone_type == "MAIN" then
		local temp_pos = -1
		for i, allowed_tone in ipairs(main_allowed_tones) do
			if allowed_tone == current_tone then
				temp_pos = i
			end
		end
		if temp_pos < #main_allowed_tones then
			return main_allowed_tones[temp_pos+1]					
		else
			return main_allowed_tones[1]
		end
	end	
	
	
end

---------------------------------------------------------------------
function GetPreviousTone(tone_type, current_tone) 
	if tone_type == "MANU" then
		local temp_pos = -1
		for i, allowed_tone in ipairs(manu_allowed_tones) do
			if allowed_tone == current_tone then
				temp_pos = i
			end
		end
		if temp_pos > 1 then
			return manu_allowed_tones[temp_pos-1]
		else
			return manu_allowed_tones[#manu_allowed_tones]
		end
	elseif tone_type == "AUX" then
		local temp_pos = -1
		for i, allowed_tone in ipairs(aux_allowed_tones) do
			if allowed_tone == current_tone then
				temp_pos = i
			end
		end
		if temp_pos > 1 then
			return aux_allowed_tones[temp_pos-1]
		else
			return aux_allowed_tones[#aux_allowed_tones]
		end
	elseif tone_type == "MAIN" then
		local temp_pos = -1
		for i, allowed_tone in ipairs(main_allowed_tones) do
			if allowed_tone == current_tone then
				temp_pos = i
			end
		end
		if temp_pos > 1 then
			return main_allowed_tones[temp_pos-1]
		else
			return main_allowed_tones[#main_allowed_tones]
		end
	end	
	
	
end

---------------------------------------------------------------------
function RegisterKeyMaps()
	for i, siren_id in ipairs(main_allowed_tones) do
		local command = "_lux_siren_" .. i 
		local description = "Siren " .. i .. ": " .. tone_table[siren_id]
		RegisterCommand(command, function(source, args)
			if IsVehicleSirenOn(veh) and player_is_emerg_driver then
				if state_lxsiren[veh] ~= siren_id or state_lxsiren[veh] == 0 then
					TriggerEvent("lux_vehcontrol:ELSClick", "Upgrade", upgrade_volume)
					SetLxSirenStateForVeh(veh, siren_id)
					count_bcast_timer = delay_bcast_timer
				else
					TriggerEvent("lux_vehcontrol:ELSClick", "Downgrade", downgrade_volume)
					SetLxSirenStateForVeh(veh, 0)
					count_bcast_timer = delay_bcast_timer				
				end
			end
		end)
		if i < 10 then
			RegisterKeyMapping(command, description, "keyboard", i)
		elseif i == 10 then
			RegisterKeyMapping(command, description, "keyboard", "0")		
		else
			RegisterKeyMapping(command, description, "keyboard", '')				
		end
	end
end
Citizen.CreateThread(function()
	RegisterKeyMaps()
end)

---------------------------------------------------------------------
function ShowHUD()
	if not show_HUD then
		show_HUD = true
	end
end

---------------------------------------------------------------------
function ShowDebug(text)
	SetNotificationTextEntry("STRING")
	AddTextComponentString(text)
	DrawNotification(false, false)
end

---------------------------------------------------------------------
function ShowText(x, y, align, text)
	SetTextJustification(align)
	SetTextFont(0)
	SetTextProportional(1)
	SetTextScale(0.0, 0.4)
	SetTextColour(128, 128, 128, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x, y)
	ResetScriptGfxAlign()
end

---------------------------------------------------------------------
function useFiretruckSiren(veh)
	local model = GetEntityModel(veh)
	for i = 1, #eModelsWithFireSrn, 1 do
		if model == GetHashKey(eModelsWithFireSrn[i]) then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
function usePowercallAuxSrn(veh)
	local model = GetEntityModel(veh)
	for i = 1, #eModelsWithPcall, 1 do
		if model == GetHashKey(eModelsWithPcall[i]) then
			return true
		end
	end
	return false
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
			if v == true then
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
		if newstate ~= state_lxsiren[veh] then
				
			if snd_lxsiren[veh] ~= nil then
				StopSound(snd_lxsiren[veh])
				ReleaseSoundId(snd_lxsiren[veh])
				snd_lxsiren[veh] = nil
			end
			
			if newstate == 1 then
				snd_lxsiren[veh] = GetSoundId()
				PlaySoundFromEntity(snd_lxsiren[veh], "SIRENS_AIRHORN", veh, 0, 0, 0)
				
			elseif newstate == 2 then
				snd_lxsiren[veh] = GetSoundId()
				PlaySoundFromEntity(snd_lxsiren[veh], "VEHICLES_HORNS_SIREN_1", veh, 0, 0, 0)
			
			elseif newstate == 3 then
				snd_lxsiren[veh] = GetSoundId()
				PlaySoundFromEntity(snd_lxsiren[veh], "VEHICLES_HORNS_SIREN_2", veh, 0, 0, 0)			
			
			elseif newstate == 4 then
				snd_lxsiren[veh] = GetSoundId()
				PlaySoundFromEntity(snd_lxsiren[veh], "VEHICLES_HORNS_POLICE_WARNING", veh, 0, 0, 0)
				
			elseif newstate == 5 then
				snd_lxsiren[veh] = GetSoundId()
				PlaySoundFromEntity(snd_lxsiren[veh], "RESIDENT_VEHICLES_SIREN_WAIL_01", veh, 0, 0, 0)

			elseif newstate == 6 then
				snd_lxsiren[veh] = GetSoundId()
				PlaySoundFromEntity(snd_lxsiren[veh], "RESIDENT_VEHICLES_SIREN_WAIL_02", veh, 0, 0, 0)
				
			elseif newstate == 7 then
				snd_lxsiren[veh] = GetSoundId()
				PlaySoundFromEntity(snd_lxsiren[veh], "RESIDENT_VEHICLES_SIREN_WAIL_03", veh, 0, 0, 0)		
			
			elseif newstate == 8 then
				snd_lxsiren[veh] = GetSoundId()
				PlaySoundFromEntity(snd_lxsiren[veh], "RESIDENT_VEHICLES_SIREN_QUICK_01", veh, 0, 0, 0)	
			
			elseif newstate == 9 then
				snd_lxsiren[veh] = GetSoundId()
				PlaySoundFromEntity(snd_lxsiren[veh], "RESIDENT_VEHICLES_SIREN_QUICK_02", veh, 0, 0, 0)	
			
			elseif newstate == 10 then
				snd_lxsiren[veh] = GetSoundId()
				PlaySoundFromEntity(snd_lxsiren[veh], "RESIDENT_VEHICLES_SIREN_QUICK_03", veh, 0, 0, 0)	
			
			elseif newstate == 11 and usePowercallAuxSrn(veh) then
				snd_lxsiren[veh] = GetSoundId()
				PlaySoundFromEntity(snd_lxsiren[veh], "VEHICLES_HORNS_AMBULANCE_WARNING", veh, 0, 0, 0)
			
			elseif newstate == 12 and useFiretruckSiren(veh) then
				snd_lxsiren[veh] = GetSoundId()
				PlaySoundFromEntity(snd_lxsiren[veh], "RESIDENT_VEHICLES_SIREN_FIRETRUCK_WAIL_01", veh, 0, 0, 0)
			
			elseif newstate == 13 and useFiretruckSiren(veh) then
				snd_lxsiren[veh] = GetSoundId()
				PlaySoundFromEntity(snd_lxsiren[veh], "RESIDENT_VEHICLES_SIREN_FIRETRUCK_QUICK_01", veh, 0, 0, 0)			
			
			elseif newstate == 14 and useFiretruckSiren(veh) then
				snd_lxsiren[veh] = GetSoundId()
				PlaySoundFromEntity(snd_lxsiren[veh], "VEHICLES_HORNS_FIRETRUCK_WARNING", veh, 0, 0, 0)
			end	
			TogMuteDfltSrnForVeh(veh, true)			
				
			state_lxsiren[veh] = newstate
		end
	end
end

---------------------------------------------------------------------
function TogPowercallStateForVeh(veh, newstate)
	if DoesEntityExist(veh) and not IsEntityDead(veh) then
		if newstate ~= state_pwrcall[veh] then
			if snd_pwrcall[veh] ~= nil then
				StopSound(snd_pwrcall[veh])
				ReleaseSoundId(snd_pwrcall[veh])
				snd_pwrcall[veh] = nil
			end
			if newstate == 1 then
				snd_pwrcall[veh] = GetSoundId()
				PlaySoundFromEntity(snd_pwrcall[veh], "SIRENS_AIRHORN", veh, 0, 0, 0)
				
			elseif newstate == 2 then
				snd_pwrcall[veh] = GetSoundId()
				PlaySoundFromEntity(snd_pwrcall[veh], "VEHICLES_HORNS_SIREN_1", veh, 0, 0, 0)
			
			elseif newstate == 3 then
				snd_pwrcall[veh] = GetSoundId()
				PlaySoundFromEntity(snd_pwrcall[veh], "VEHICLES_HORNS_SIREN_2", veh, 0, 0, 0)			
			
			elseif newstate == 4 then
				snd_pwrcall[veh] = GetSoundId()
				PlaySoundFromEntity(snd_pwrcall[veh], "VEHICLES_HORNS_POLICE_WARNING", veh, 0, 0, 0)
				
			elseif newstate == 5 then
				snd_pwrcall[veh] = GetSoundId()
				PlaySoundFromEntity(snd_pwrcall[veh], "RESIDENT_VEHICLES_SIREN_WAIL_01", veh, 0, 0, 0)

			elseif newstate == 6 then
				snd_pwrcall[veh] = GetSoundId()
				PlaySoundFromEntity(snd_pwrcall[veh], "RESIDENT_VEHICLES_SIREN_WAIL_02", veh, 0, 0, 0)
				
			elseif newstate == 7 then
				snd_pwrcall[veh] = GetSoundId()
				PlaySoundFromEntity(snd_pwrcall[veh], "RESIDENT_VEHICLES_SIREN_WAIL_03", veh, 0, 0, 0)		
			
			elseif newstate == 8 then
				snd_pwrcall[veh] = GetSoundId()
				PlaySoundFromEntity(snd_pwrcall[veh], "RESIDENT_VEHICLES_SIREN_QUICK_01", veh, 0, 0, 0)	
			
			elseif newstate == 9 then
				snd_pwrcall[veh] = GetSoundId()
				PlaySoundFromEntity(snd_pwrcall[veh], "RESIDENT_VEHICLES_SIREN_QUICK_02", veh, 0, 0, 0)	
			
			elseif newstate == 10 then
				snd_pwrcall[veh] = GetSoundId()
				PlaySoundFromEntity(snd_pwrcall[veh], "RESIDENT_VEHICLES_SIREN_QUICK_03", veh, 0, 0, 0)	
			
			elseif newstate == 11 and usePowercallAuxSrn(veh) then
				snd_pwrcall[veh] = GetSoundId()
				PlaySoundFromEntity(snd_pwrcall[veh], "VEHICLES_HORNS_AMBULANCE_WARNING", veh, 0, 0, 0)
			
			elseif newstate == 12 and useFiretruckSiren(veh) then
				snd_pwrcall[veh] = GetSoundId()
				PlaySoundFromEntity(snd_pwrcall[veh], "RESIDENT_VEHICLES_SIREN_FIRETRUCK_WAIL_01", veh, 0, 0, 0)
			
			elseif newstate == 13 and useFiretruckSiren(veh) then
				snd_pwrcall[veh] = GetSoundId()
				PlaySoundFromEntity(snd_pwrcall[veh], "RESIDENT_VEHICLES_SIREN_FIRETRUCK_QUICK_01", veh, 0, 0, 0)			
			
			elseif newstate == 14 and useFiretruckSiren(veh) then
				snd_pwrcall[veh] = GetSoundId()
				PlaySoundFromEntity(snd_pwrcall[veh], "VEHICLES_HORNS_FIRETRUCK_WARNING", veh, 0, 0, 0)
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
			
			if newstate == 1 then
				snd_airmanu[veh] = GetSoundId()
				PlaySoundFromEntity(snd_airmanu[veh], "SIRENS_AIRHORN", veh, 0, 0, 0)
				
			elseif newstate == 2 then
				snd_airmanu[veh] = GetSoundId()
				PlaySoundFromEntity(snd_airmanu[veh], "VEHICLES_HORNS_SIREN_1", veh, 0, 0, 0)
			
			elseif newstate == 3 then
				snd_airmanu[veh] = GetSoundId()
				PlaySoundFromEntity(snd_airmanu[veh], "VEHICLES_HORNS_SIREN_2", veh, 0, 0, 0)			
			
			elseif newstate == 4 then
				snd_airmanu[veh] = GetSoundId()
				PlaySoundFromEntity(snd_airmanu[veh], "VEHICLES_HORNS_POLICE_WARNING", veh, 0, 0, 0)
				
			elseif newstate == 5 then
				snd_airmanu[veh] = GetSoundId()
				PlaySoundFromEntity(snd_airmanu[veh], "RESIDENT_VEHICLES_SIREN_WAIL_01", veh, 0, 0, 0)

			elseif newstate == 6 then
				snd_airmanu[veh] = GetSoundId()
				PlaySoundFromEntity(snd_airmanu[veh], "RESIDENT_VEHICLES_SIREN_WAIL_02", veh, 0, 0, 0)
				
			elseif newstate == 7 then
				snd_airmanu[veh] = GetSoundId()
				PlaySoundFromEntity(snd_airmanu[veh], "RESIDENT_VEHICLES_SIREN_WAIL_03", veh, 0, 0, 0)		
			
			elseif newstate == 8 then
				snd_airmanu[veh] = GetSoundId()
				PlaySoundFromEntity(snd_airmanu[veh], "RESIDENT_VEHICLES_SIREN_QUICK_01", veh, 0, 0, 0)	
			
			elseif newstate == 9 then
				snd_airmanu[veh] = GetSoundId()
				PlaySoundFromEntity(snd_airmanu[veh], "RESIDENT_VEHICLES_SIREN_QUICK_02", veh, 0, 0, 0)	
			
			elseif newstate == 10 then
				snd_airmanu[veh] = GetSoundId()
				PlaySoundFromEntity(snd_airmanu[veh], "RESIDENT_VEHICLES_SIREN_QUICK_03", veh, 0, 0, 0)	
			
			elseif newstate == 11 and usePowercallAuxSrn(veh) then
				snd_airmanu[veh] = GetSoundId()
				PlaySoundFromEntity(snd_airmanu[veh], "VEHICLES_HORNS_AMBULANCE_WARNING", veh, 0, 0, 0)
			
			elseif newstate == 12 and useFiretruckSiren(veh) then
				snd_airmanu[veh] = GetSoundId()
				PlaySoundFromEntity(snd_airmanu[veh], "RESIDENT_VEHICLES_SIREN_FIRETRUCK_WAIL_01", veh, 0, 0, 0)
			
			elseif newstate == 13 and useFiretruckSiren(veh) then
				snd_airmanu[veh] = GetSoundId()
				PlaySoundFromEntity(snd_airmanu[veh], "RESIDENT_VEHICLES_SIREN_FIRETRUCK_QUICK_01", veh, 0, 0, 0)			
			
			elseif newstate == 14 and useFiretruckSiren(veh) then
				snd_airmanu[veh] = GetSoundId()
				PlaySoundFromEntity(snd_airmanu[veh], "VEHICLES_HORNS_FIRETRUCK_WARNING", veh, 0, 0, 0)
			end
			
			state_airmanu[veh] = newstate
		end
	end
end

---------------------------------------------------------------------
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

AddEventHandler('lux_vehcontrol:ELSClick', function(soundFile, soundVolume)
SendNUIMessage({
  transactionType     = 'playSound',
  transactionFile     = soundFile,
  transactionVolume   = soundVolume
})
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
RegisterNetEvent("lvc_TogPwrcallState_c")
AddEventHandler("lvc_TogPwrcallState_c", function(sender, newstate)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local veh = GetVehiclePedIsUsing(ped_s)
				TogPowercallStateForVeh(veh, newstate)
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

---------------------------------------------------------------------
--Onscreen UI
--Get variables needed for UI every 1 second (efficiency) 
--Get variables needed for UI every 1 second (efficiency) 
Citizen.CreateThread(function()
	while true do
		playerped = GetPlayerPed(-1)		
		if IsPedInAnyVehicle(playerped, false) then
			veh = GetVehiclePedIsUsing(playerped)	
			if GetPedInVehicleSeat(veh, -1) == playerped and GetVehicleClass(veh) == 18 then
				player_is_emerg_driver = true
			end
		end
		if veh == nil or veh == 0 then
			HUD_move_mode = false
			HUD_op_mode = false
			tone_mode = false
		end
		Citizen.Wait(1000)
	end
end)

--Draw Onscreen UI
Citizen.CreateThread(function()
	while true do
		while show_HUD do
		--- IS KEY LOCKED --- 
			if IsPedInAnyVehicle(playerped, false) then	
				----- IS DRIVER -----
				if GetPedInVehicleSeat(veh, -1) == playerped then
					--- IS EMERG VEHICLE ---
					if GetVehicleClass(veh) == 18 then	
						DisableControlAction(0, 80, true)  
						DisableControlAction(0, 81, true) 
						DisableControlAction(0, 86, true) 
						DrawRect(HUD_x_offset + 0.0828, HUD_y_offset + 0.724, 0.16, 0.06, 26, 26, 26, hud_bgd_opacity + HUD_op_bgd_offset)
						if IsVehicleSirenOn(veh) then
							DrawSprite("commonmenu", "lux_switch_3_hud", HUD_x_offset + 0.025, HUD_y_offset + 0.725, 0.042, 0.06, 0.0, 200, 200, 200, hud_button_on_opacity)									
						else
							DrawSprite("commonmenu", "lux_switch_1_hud", HUD_x_offset + 0.025, HUD_y_offset + 0.725, 0.042, 0.06, 0.0, 200, 200, 200, hud_button_off_opacity + HUD_op_btn_offset)														
						end
						
						if state_lxsiren[veh] ~= nil then
							if state_lxsiren[veh] > 0 or state_pwrcall[veh] > 0 then
								DrawSprite("commonmenu", "lux_siren_on_hud", HUD_x_offset + 0.061, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_on_opacity)				
							else
								DrawSprite("commonmenu", "lux_siren_off_hud", HUD_x_offset + 0.061, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_off_opacity + HUD_op_btn_offset)										
							end
						else
							DrawSprite("commonmenu", "lux_siren_off_hud", HUD_x_offset + 0.061, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_off_opacity + HUD_op_btn_offset)										
						end
						
						if IsDisabledControlPressed(0, 86) and not key_lock then
							DrawSprite("commonmenu", "lux_horn_on_hud", HUD_x_offset + 0.0895, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_on_opacity)												
						else
							DrawSprite("commonmenu", "lux_horn_off_hud", HUD_x_offset + 0.0895, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_off_opacity + HUD_op_btn_offset)																			
						end
						
						if (IsDisabledControlPressed(0, 80) or IsDisabledControlPressed(0, 81)) and not key_lock then
							if state_lxsiren[veh] > 0 then
								DrawSprite("commonmenu", "lux_horn_on_hud", HUD_x_offset + 0.0895, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_on_opacity)
							else
								DrawSprite("commonmenu", "lux_siren_on_hud", HUD_x_offset + 0.061, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_on_opacity)	
							end
						end
						
						local retrieval, veh_lights, veh_headlights  = GetVehicleLightsState(veh)
						if veh_lights == 1 and veh_headlights == 0 then
							DrawSprite("commonmenu", "lux_tkd_off_hud" ,HUD_x_offset + 0.118, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_off_opacity + HUD_op_btn_offset)																			
						elseif (veh_lights == 1 and veh_headlights == 1) or (veh_lights == 0 and veh_headlights == 1) then
							DrawSprite("commonmenu", "lux_tkd_on_hud", HUD_x_offset + 0.118, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_on_opacity)
						else
							DrawSprite("commonmenu", "lux_tkd_off_hud", HUD_x_offset + 0.118, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_off_opacity + HUD_op_btn_offset)																			
						end
						
						if key_lock then
							DrawSprite("commonmenu", "lux_lock_on_hud", HUD_x_offset + 0.1465, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_on_opacity)
						else
							DrawSprite("commonmenu", "lux_lock_off_hud", HUD_x_offset + 0.1465, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_off_opacity + HUD_op_btn_offset)					
						end
					end
				end
			end
			Citizen.Wait(0)
		end
		Citizen.Wait(1000)
	end
end)


---------------------------------------------------------------------
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
				
					DisableControlAction(0, 84, true) -- INPUT_VEH_PREV_RADIO_TRACK  
					DisableControlAction(0, 83, true) -- INPUT_VEH_NEXT_RADIO_TRACK 
					
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
					if GetVehicleClass(veh) == 18 then
						local actv_manu = false
						local actv_horn = false
						
						DisableControlAction(0, 86, true) -- INPUT_VEH_HORN	
						DisableControlAction(0, 172, true) -- INPUT_CELLPHONE_UP  
						DisableControlAction(0, 81, true) -- INPUT_VEH_NEXT_RADIO
						DisableControlAction(0, 82, true) -- INPUT_VEH_PREV_RADIO
						DisableControlAction(0, 19, true) -- INPUT_CHARACTER_WHEEL 
						DisableControlAction(0, 85, true) -- INPUT_VEH_RADIO_WHEEL 
						DisableControlAction(0, 80, true) -- INPUT_VEH_CIN_CAM 
					
						SetVehRadioStation(veh, "OFF")
						SetVehicleRadioEnabled(veh, false
						)
						if 	(	state_lxsiren[veh] ~= 1 
							and state_lxsiren[veh] ~= 2 
							and state_lxsiren[veh] ~= 3 
							and state_lxsiren[veh] ~= 4 
							and state_lxsiren[veh] ~= 5 
							and state_lxsiren[veh] ~= 6 
							and state_lxsiren[veh] ~= 7 
							and state_lxsiren[veh] ~= 8 
							and state_lxsiren[veh] ~= 9 
							and state_lxsiren[veh] ~= 10 
							and state_lxsiren[veh] ~= 11 
							and state_lxsiren[veh] ~= 12 
							and state_lxsiren[veh] ~= 13 
							and state_lxsiren[veh] ~= 14) then
								state_lxsiren[veh] = 0
						end

						if 	(	state_pwrcall[veh] ~= 1 
							and state_pwrcall[veh] ~= 2 
							and state_pwrcall[veh] ~= 3 
							and state_pwrcall[veh] ~= 4 
							and state_pwrcall[veh] ~= 5 
							and state_pwrcall[veh] ~= 6 
							and state_pwrcall[veh] ~= 7 
							and state_pwrcall[veh] ~= 8 
							and state_pwrcall[veh] ~= 9 
							and state_pwrcall[veh] ~= 10 
							and state_pwrcall[veh] ~= 11 
							and state_pwrcall[veh] ~= 12 
							and state_pwrcall[veh] ~= 13 
							and state_pwrcall[veh] ~= 14) then
								state_pwrcall[veh] = 0
						end

						if 	(	state_airmanu[veh] ~= 1 
							and state_airmanu[veh] ~= 2 
							and state_airmanu[veh] ~= 3 
							and state_airmanu[veh] ~= 4 
							and state_airmanu[veh] ~= 5 
							and state_airmanu[veh] ~= 6 
							and state_airmanu[veh] ~= 7 
							and state_airmanu[veh] ~= 8 
							and state_airmanu[veh] ~= 9 
							and state_airmanu[veh] ~= 10 
							and state_airmanu[veh] ~= 11 
							and state_airmanu[veh] ~= 12 
							and state_airmanu[veh] ~= 13 
							and state_airmanu[veh] ~= 14) then
								state_airmanu[veh] = 0
						end
						if useFiretruckSiren(veh) and state_lxsiren[veh] == 1 then
							TogMuteDfltSrnForVeh(veh, false)
							dsrn_mute = false
						else
							TogMuteDfltSrnForVeh(veh, true)
							dsrn_mute = true
						end
						
						if not IsVehicleSirenOn(veh) and state_lxsiren[veh] > 0 then
							SetLxSirenStateForVeh(veh, 0)
							count_bcast_timer = delay_bcast_timer
						end
						if not IsVehicleSirenOn(veh) and state_pwrcall[veh] > 0 then
							TogPowercallStateForVeh(veh, 0)
							count_bcast_timer = delay_bcast_timer
						end
					
						----- CONTROLS -----
						if not IsPauseMenuActive() then
							if not key_lock then
								-- TOG DFLT SRN LIGHTS
								if IsDisabledControlJustReleased(0, 85) or IsDisabledControlJustReleased(0, 246) then
									if IsVehicleSirenOn(veh) then
										TriggerEvent("lux_vehcontrol:ELSClick", "Off", off_volume) -- Off
										SetVehicleSiren(veh, false)
									else
										TriggerEvent("lux_vehcontrol:ELSClick", "On", on_volume) -- On
										Citizen.Wait(150)
										SetVehicleSiren(veh, true)
										count_bcast_timer = delay_bcast_timer
									end		
								
								-- TOG LX SIREN
								elseif IsDisabledControlJustReleased(0, 19) or IsDisabledControlJustReleased(0, 82) then
									if state_lxsiren[veh] == 0 then
										if IsVehicleSirenOn(veh) then
											TriggerEvent("lux_vehcontrol:ELSClick", "Upgrade", upgrade_volume) -- Upgrade
											if main_siren_last_state then
												SetLxSirenStateForVeh(veh, tone_main_mem_id)
											else
												SetLxSirenStateForVeh(veh, 2)
											end
											count_bcast_timer = delay_bcast_timer
										end
									else
										TriggerEvent("lux_vehcontrol:ELSClick", "Downgrade", downgrade_volume) -- Downgrade
										if main_siren_last_state then
											tone_main_mem_id = state_lxsiren[veh]
										end
										SetLxSirenStateForVeh(veh, 0)
										count_bcast_timer = delay_bcast_timer
									end
									
								-- POWERCALL
								elseif IsDisabledControlJustReleased(0, 172) and not (tone_mode or HUD_move_mode or HUD_op_mode) then --disable up arrow only in tone mode since testing would be beneficial 
									if state_pwrcall[veh] == 0 then
										if IsVehicleSirenOn(veh) then
											TriggerEvent("lux_vehcontrol:ELSClick", "Upgrade", upgrade_volume) -- Upgrade
											TogPowercallStateForVeh(veh, tone_AUX_id)
											count_bcast_timer = delay_bcast_timer
										end
									else
										TriggerEvent("lux_vehcontrol:ELSClick", "Downgrade", downgrade_volume) -- Downgrade
										TogPowercallStateForVeh(veh, 0)
										count_bcast_timer = delay_bcast_timer
									end
									
								end
								
								-- BROWSE LX SRN TONES
								if state_lxsiren[veh] > 0 then
									if IsDisabledControlJustReleased(0, 80) or IsDisabledControlJustReleased(0, 81) then
										if IsVehicleSirenOn(veh) then
											newstate = GetNextTone("MAIN", state_lxsiren[veh])
											TriggerEvent("lux_vehcontrol:ELSClick", "Upgrade", upgrade_volume)
											SetLxSirenStateForVeh(veh, newstate)
											count_bcast_timer = delay_bcast_timer
										end
									end
								end
											
								-- MANU
								if state_lxsiren[veh] < 1 then
									if IsDisabledControlPressed(0, 80) or IsDisabledControlPressed(0, 81) then
										actv_manu = true
									else
										actv_manu = false
									end
								else
									actv_manu = false
								end
								
								-- HORN
								if IsDisabledControlPressed(0, 86) then
									actv_horn = true
								else
									actv_horn = false
								end
							elseif not HUD_move_mode and not HUD_op_mode then
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
											TriggerEvent("lux_vehcontrol:ELSClick", "Locked_Press", lock_reminder_volume) -- lock reminder
											ShowDebug("~y~~h~Reminder:~h~ ~s~Your siren control box is ~r~locked~s~.")
										end
										locked_press_count = locked_press_count + 1
								end								
							end
						end
						
						---- ADJUST HORN / MANU STATE ----
						local hmanu_state_new = 0
						if actv_horn == true and actv_manu == false then
							hmanu_state_new = 1
							if useFiretruckSiren(veh) then
								hmanu_state_new = 14
							end
						elseif actv_horn == false and actv_manu == true then
							hmanu_state_new = tone_PMANU_id
						elseif actv_horn == true and actv_manu == true then
							hmanu_state_new = tone_SMANU_id
						end
						if hmanu_state_new == 1 then
							if not useFiretruckSiren(veh) then
								if state_lxsiren[veh] > 0 and actv_lxsrnmute_temp == false then
									srntone_temp = state_lxsiren[veh]
									SetLxSirenStateForVeh(veh, 0)
									actv_lxsrnmute_temp = true
								end
							end
						else
							if not useFiretruckSiren(veh) then
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
											TriggerEvent("lux_vehcontrol:ELSClick", "Hazards_Off", hazards_volumne) -- Hazards On
										else
											state_indic[veh] = ind_state_h
											TriggerEvent("lux_vehcontrol:ELSClick", "Hazards_On", hazards_volumne) -- Hazards On
										end
										TogIndicStateForVeh(veh, state_indic[veh])
										actv_ind_timer = false
										count_ind_timer = 0
										count_bcast_timer = delay_bcast_timer
										Citizen.Wait(button_delay)
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