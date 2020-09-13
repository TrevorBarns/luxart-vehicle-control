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

--RUNTIME VARIABLES (Do not touch unless you know what you're doing.) 
--GLOBAL VARIABLES used in both menu.lua and client.lua
show_HUD = hud_first_default
key_lock = false
HUD_x_offset = 0
HUD_y_offset = 0
HUD_move_mode = false

tone_ARHRN_id = nil
tone_PMANU_id = nil
tone_SMANU_id = nil
tone_AUX_id = nil
tone_main_mem_id = nil
tone_main_reset_standby = true
tone_airhorn_intrp = true

airhorn_button_SFX = false
manu_button_SFX = false
button_sfx_scheme = default_sfx_scheme_name
on_volume = default_on_volume	
off_volume = default_off_volume	
upgrade_volume = default_upgrade_volume	
downgrade_volume = default_downgrade_volume
hazards_volume = default_hazards_volume
lock_volume = default_lock_volume
lock_reminder_volume = default_lock_reminder_volume

last_veh = nil
veh = nil
player_is_emerg_driver = false
park_kill = false
curr_version = nil
repo_version = nil

--LOCAL VARIABLES
local spawned = false
local playerped = nil
local siren_string_lookup = { "SIRENS_AIRHORN", "VEHICLES_HORNS_SIREN_1", "VEHICLES_HORNS_SIREN_2", "VEHICLES_HORNS_POLICE_WARNING",
							  "RESIDENT_VEHICLES_SIREN_WAIL_01", "RESIDENT_VEHICLES_SIREN_WAIL_02", "RESIDENT_VEHICLES_SIREN_WAIL_03",
							  "RESIDENT_VEHICLES_SIREN_QUICK_01", "RESIDENT_VEHICLES_SIREN_QUICK_02", "RESIDENT_VEHICLES_SIREN_QUICK_03",
							  "VEHICLES_HORNS_AMBULANCE_WARNING",
							  "VEHICLES_HORNS_FIRETRUCK_WARNING",
							  "RESIDENT_VEHICLES_SIREN_FIRETRUCK_WAIL_01",
							  "RESIDENT_VEHICLES_SIREN_FIRETRUCK_QUICK_01"
							}

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


TriggerEvent('chat:addSuggestion', '/lvchudmove', 'Toggle Luxart Vehicle Control HUD Move Mode.')
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
					DisableControlAction(0, 85, true) -- INPUT_VEH_RADIO_WHEEL 
					DisableControlAction(0, 80, true) -- INPUT_VEH_CIN_CAM														 									   								
				end
			end
		end
		Citizen.Wait(1)
	end
end)

-- ParkKill Functionality
Citizen.CreateThread(function()
	while true do
		while park_kill and playerped ~= nil and veh ~= nil do
			if GetIsTaskActive(playerped, 2) then
				if not tone_main_reset_standby then
					tone_main_mem_id = state_lxsiren[veh]
				end
				SetLxSirenStateForVeh(veh, 0)
				SetPowercallStateForVeh(veh, 0)
				count_bcast_timer = delay_bcast_timer
				Citizen.Wait(1000)		
			end
			Citizen.Wait(0)		
		end
		Citizen.Wait(1000)
	end
end)

-- Vehicle Change Check
Citizen.CreateThread(function()
	while true do
		if veh ~= nil then
			if last_veh == nil then
				last_veh = veh
			else
				if last_veh ~= veh then
					ResetSettings()
					last_veh = veh
				end
			end
		end
		Citizen.Wait(1000)
	end
end)

-- Move Move UI + Control handling
Citizen.CreateThread(function()
	local HUD_move_lg_increment = 0.0050
	local HUD_move_sm_increment = 0.0001
	while true do 
		--HUD MOVE MODE
		while HUD_move_mode and player_is_emerg_driver do
			ShowText(0.5, 0.75, 0, "~w~HUD Move Mode ~g~enabled~w~. To stop press ~b~Backspace ~w~/~b~ Right-Click ~w~/~b~ Esc~w~.")
			ShowText(0.5, 0.775, 0, "~w~← → left-right ↑ ↓ up-down\nCTRL + Arrow for fine control.")

			--FINE MOVEMENT
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
			--LARGE MOVEMENT
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
				
				--HANDLE EXIT CONDITION: BACKSPACE / ESC / RIGHT CLICK
				if IsControlPressed(0, 177) then
					TogMoveMode()
				end
			end
			
			--PREVENT HUD FROM LEAVING SCREEN
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

-- Main HUD UI drawing 
Citizen.CreateThread(function()
	local retrieval, veh_lights, veh_headlights 
	while true do
	
		--Ensure textures have streamed
		while not HasStreamedTextureDictLoaded("commonmenu") do
			RequestStreamedTextureDict("commonmenu", false);
			Citizen.Wait(0)
		end
		
		while show_HUD and player_is_emerg_driver and not IsHudHidden() do
			DrawRect(HUD_x_offset + 0.0828, HUD_y_offset + 0.724, 0.16, 0.06, 26, 26, 26, hud_bgd_opacity)
			if IsVehicleSirenOn(veh) then
				DrawSprite("commonmenu", "lux_switch_3_hud", HUD_x_offset + 0.025, HUD_y_offset + 0.725, 0.042, 0.06, 0.0, 200, 200, 200, hud_button_on_opacity)									
			else
				DrawSprite("commonmenu", "lux_switch_1_hud", HUD_x_offset + 0.025, HUD_y_offset + 0.725, 0.042, 0.06, 0.0, 200, 200, 200, hud_button_off_opacity)														
			end
			
			if state_lxsiren[veh] ~= nil then
				if state_lxsiren[veh] > 0 or state_pwrcall[veh] > 0 then
					DrawSprite("commonmenu", "lux_siren_on_hud", HUD_x_offset + 0.061, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_on_opacity)				
				else
					DrawSprite("commonmenu", "lux_siren_off_hud", HUD_x_offset + 0.061, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_off_opacity)										
				end
			else
				DrawSprite("commonmenu", "lux_siren_off_hud", HUD_x_offset + 0.061, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_off_opacity)										
			end
			
			if IsDisabledControlPressed(0, 86) and not key_lock then
				DrawSprite("commonmenu", "lux_horn_on_hud", HUD_x_offset + 0.0895, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_on_opacity)												
			else
				DrawSprite("commonmenu", "lux_horn_off_hud", HUD_x_offset + 0.0895, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_off_opacity)																			
			end
			
			if (IsDisabledControlPressed(0, 80) or IsDisabledControlPressed(0, 81)) and not key_lock then
				if state_lxsiren[veh] > 0 then
					DrawSprite("commonmenu", "lux_horn_on_hud", HUD_x_offset + 0.0895, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_on_opacity)
				else
					DrawSprite("commonmenu", "lux_siren_on_hud", HUD_x_offset + 0.061, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_on_opacity)	
				end
			end
			
			retrieval, veh_lights, veh_headlights  = GetVehicleLightsState(veh)
			if veh_lights == 1 and veh_headlights == 0 then
				DrawSprite("commonmenu", "lux_tkd_off_hud" ,HUD_x_offset + 0.118, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_off_opacity)																			
			elseif (veh_lights == 1 and veh_headlights == 1) or (veh_lights == 0 and veh_headlights == 1) then
				DrawSprite("commonmenu", "lux_tkd_on_hud", HUD_x_offset + 0.118, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_on_opacity)
			else
				DrawSprite("commonmenu", "lux_tkd_off_hud", HUD_x_offset + 0.118, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_off_opacity)																			
			end
			
			if key_lock then
				DrawSprite("commonmenu", "lux_lock_on_hud", HUD_x_offset + 0.1465, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_on_opacity)
			else
				DrawSprite("commonmenu", "lux_lock_off_hud", HUD_x_offset + 0.1465, HUD_y_offset + 0.725, 0.0275, 0.05, 0.0, 200, 200, 200, hud_button_off_opacity)					
			end
			Citizen.Wait(0)
		end
		Citizen.Wait(1000)
	end
end)

------------------STORAGE MANAGEMENT-----------------
--On Spawn Register Keys and Load Settings
AddEventHandler( "playerSpawned", function()
	if not spawned then
		RegisterKeyMaps()
		spawned = true
	end 
	LoadSettings()
	TriggerServerEvent('lvc_GetVersion_s')
end )

--------------REGISTERED COMMANDS---------------
--Deletes all saved KVPs for that vehicle profile
RegisterCommand('lvcfactoryreset', function(source, args)
	local choice = FrontEndAlert("Warning", "Are you sure you want to delete all saved LVC data and Factory Reset?")
	if choice then
		local save_prefix = "lvc_setting_"
		local handle = StartFindKvp(save_prefix);
		local key = FindKvp(handle)
		while key ~= nil do
			DeleteResourceKvp(key)
			print("LVC Info: Deleting Key \"" .. key .. "\"")
			key = FindKvp(handle)
			Citizen.Wait(0)
		end
		ResetSettings()
		print("LVC Info: Successfully cleared all save data.")
		ShowNotification("~g~LVC Info~s~: Successfully cleared all save data.")
	end
end)

------------------------------------------------
--Toggle LUX lock command
RegisterCommand('lvclock', function(source, args)
	if player_is_emerg_driver then	
		key_lock = not key_lock
		TriggerEvent("lux_vehcontrol:ELSClick", "Key_Lock", lock_volume) 
		--if HUD is visible do not show notification
		if not show_HUD then
			if key_lock then
				ShowNotification("Siren Control Box: ~r~Locked")
			else
				ShowNotification("Siren Control Box: ~g~Unlocked")				
			end
		end
	end
end)

RegisterKeyMapping("lvclock", "LVC: Lock out controls", "keyboard", lockout_default_hotkey)

------------------------------------------------
--Dynamically Run RegisterCommand and KeyMapping functions for all 14 possible sirens
--Then at runtime "slide" all sirens down removing any restricted sirens.
function RegisterKeyMaps()
	for i, _ in ipairs(tone_table) do
		if i ~= 1 then
			local command = "_lvc_siren_" .. i-1
			local description = "LVC Siren: " .. MakeOrdinal(i-1)
			
			RegisterCommand(command, function(source, args)
				if veh ~= nil and player_is_emerg_driver ~= nil then
					if IsVehicleSirenOn(veh) and player_is_emerg_driver and not key_lock then
						local proposed_tone = GetTone(veh, i)
						local tone_index = GetToneIndex(proposed_tone)
						if main_tone_settings[tone_index] ~= nil then
							local tone_setting = main_tone_settings[tone_index][2]
							if i <= GetToneCount(veh) and tone_setting == 1 or tone_setting == 3 then
								if ( state_lxsiren[veh] ~= proposed_tone or state_lxsiren[veh] == 0 ) then
									TriggerEvent("lux_vehcontrol:ELSClick", button_sfx_scheme .. "/" ..  "Upgrade", upgrade_volume)
									SetLxSirenStateForVeh(veh, proposed_tone)
									count_bcast_timer = delay_bcast_timer
								else
									TriggerEvent("lux_vehcontrol:ELSClick", button_sfx_scheme .. "/" ..  "Downgrade", downgrade_volume)
									SetLxSirenStateForVeh(veh, 0)
									count_bcast_timer = delay_bcast_timer				
								end
							end
						else
							ShowNotification("~r~LVC ERROR 2: ~s~Nil value caught.\ndetails: (" .. tone_index .. "," .. proposed_tone .. "," .. GetVehicleProfileName() .. ")")
							ShowNotification("~b~LVC ERROR 2: ~s~Try switching vehicles and switching back OR loading profile settings (if save present).")
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

--On resource restart
Citizen.CreateThread(function()
	RegisterKeyMaps()
	LoadSettings()
	TriggerServerEvent('lvc_GetVersion_s')
end)
------------------------------------------------
-------------------FUNCTIONS--------------------
------------------------------------------------
--Toggles HUD
function ShowHUD()
	if not show_HUD then
		show_HUD = true
	end
end

------------------------------------------------
--On screen GTA V notification
function ShowNotification(text)
	SetNotificationTextEntry("STRING")
	AddTextComponentString(text)
	DrawNotification(false, true)
end


------------------------------------------------
--Drawn On Screen Text at X, Y
function ShowText(x, y, align, text, scale)
	scale = scale or 0.4
	SetTextJustification(align)
	SetTextFont(0)
	SetTextProportional(1)
	SetTextScale(0.0, scale)
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

------------------------------------------------
--Fullscreen Confirmation Message
function FrontEndAlert(title, subtitle)
	AddTextEntry("FACES_WARNH2", "Warning")
	AddTextEntry("QM_NO_0", "Are you sure you want to delete all saved LVC data and Factory Reset?")
	local result = -1
	while result == -1 do
		DrawFrontendAlert("FACES_WARNH2", "QM_NO_0", 0, 0, "", 0, -1, 0, "", "", false, 0)
		ShowText(0.5, 0.75, 0, "~g~No: Escape \t ~r~Yes: Enter", 0.75)
		if IsDisabledControlJustReleased(2, 202) then
			return false
		end		
		if IsDisabledControlJustReleased(2, 201) then
			return true
		end
		Citizen.Wait(0)
	end
end

------------------------------------------------
--Toggles HUD move mode
function TogMoveMode()
	ShowHUD()
	if HUD_move_mode then		
		HUD_move_mode = false
		Citizen.Wait(100)
		RageUI.Visible(RMenu:Get('lvc', 'hudsettings'), true)
	else					
		HUD_move_mode = true
		RageUI.Visible(RMenu:Get('lvc', 'hudsettings'), false)
	end
end

------------------------------------------------
--Make number into ordinal number 
function MakeOrdinal(number)
	local sufixes = { "th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th" }
	local mod = (number % 100)
	if mod == 11 or mod == 12 or mod == 13 then
		return number .. "th"
	else
		return number..sufixes[(number % 10) + 1]
	end
end

------------------------------------------------
--Reset/Re-load Luxart Settings/Tables and mem_tone.
function ResetSettings() 
	settings_init = false
	LoadSettings()
	tone_main_mem_id = GetTone(veh, 2)
end

------------------------------------------------
--Save all settings
function SaveSettings()
	local save_prefix = "lvc_setting_"
	--Set KVP value to indicate there is a save present, if so what version
	local save_version = GetResourceKvpString(save_prefix .. "save_version")
	if curr_version ~= nil then
		SetResourceKvp(save_prefix .. "save_version", curr_version)
	else
		SetResourceKvp(save_prefix .. "save_version", "Unknown")
	end
	
	--General Settings
	SetResourceKvpInt(save_prefix .. "HUD",  BoolToInt(show_HUD))
	SetResourceKvpFloat(save_prefix .. "HUD_x_offset",  HUD_x_offset + .0)
	SetResourceKvpFloat(save_prefix .. "HUD_y_offset",  HUD_y_offset + .0)
	SetResourceKvpInt(save_prefix .. "hud_bgd_opacity",  hud_bgd_opacity)
	SetResourceKvpInt(save_prefix .. "hud_button_off_opacity",  hud_button_off_opacity)

	--Profile Specific Settings
	SetResourceKvpInt(save_prefix .. GetVehicleProfileName() .. "_tone_PMANU_id",  tone_PMANU_id)
	SetResourceKvpInt(save_prefix .. GetVehicleProfileName() .. "_tone_SMANU_id",  tone_SMANU_id)
	SetResourceKvpInt(save_prefix .. GetVehicleProfileName() .. "_tone_AUX_id",  tone_AUX_id)
	SetResourceKvpInt(save_prefix .. GetVehicleProfileName() .. "_tone_airhorn_intrp",  BoolToInt(tone_airhorn_intrp))
	SetResourceKvpInt(save_prefix .. GetVehicleProfileName() .. "_park_kill",  BoolToInt(park_kill))
		
	--Audio Settings
	SetResourceKvp(save_prefix .. "button_sfx_scheme",  button_sfx_scheme)
	SetResourceKvpFloat(save_prefix .. "audio_on_volume",  on_volume + .0)
	SetResourceKvpFloat(save_prefix .. "audio_off_volume",  off_volume + .0)
	SetResourceKvpFloat(save_prefix .. "audio_upgrade_volume",  upgrade_volume + .0)
	SetResourceKvpFloat(save_prefix .. "audio_downgrade_volume",  downgrade_volume + .0)
	SetResourceKvpFloat(save_prefix .. "audio_hazards_volume",  hazards_volume + .0)
	SetResourceKvpFloat(save_prefix .. "audio_lock_volume",  lock_volume + .0)
	SetResourceKvpFloat(save_prefix .. "audio_lock_reminder_volume",  lock_reminder_volume + .0)
	SetResourceKvpInt(save_prefix .. "audio_airhorn_button_SFX",  BoolToInt(airhorn_button_SFX))
	SetResourceKvpInt(save_prefix .. "audio_manu_button_SFX",  BoolToInt(manu_button_SFX))
	
	--Main Siren Settings
	settings_string = TableToString(main_tone_settings)
	SetResourceKvp(save_prefix .. GetVehicleProfileName(),  settings_string)
end

------------------------------------------------
--Load all settings
function LoadSettings()
	local save_prefix = "lvc_setting_"
	curr_version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
	save_version = GetResourceKvpString(save_prefix .. "save_version")
	--Is save present if so what version
	if curr_version ~= save_version and save_version ~= nil then
		ShowNotification("~r~~h~Warning:~h~ ~s~LVC Save Version Mismatch.\n~o~Save Ver: " .. save_version .. "~s~.\n~b~Resource Ver: " .. curr_version .. "~s~...")
		ShowNotification("...You may experience issues, to prevent this message from appearing resave vehicle profiles.")
	end
	
	--General Settings
	if save_version ~= nil then
		show_HUD = IntToBool(GetResourceKvpInt(save_prefix .. "HUD"))
		show_HUD = IntToBool(GetResourceKvpInt(save_prefix .. "HUD"))
		HUD_x_offset = GetResourceKvpFloat(save_prefix .. "HUD_x_offset")
		HUD_y_offset = GetResourceKvpFloat(save_prefix .. "HUD_y_offset")
		hud_bgd_opacity = GetResourceKvpInt(save_prefix .. "hud_bgd_opacity")
		hud_button_off_opacity = GetResourceKvpInt(save_prefix .. "hud_button_off_opacity")
		
		--Profile Specific Settings
		tone_PMANU_id = GetResourceKvpInt(save_prefix .. GetVehicleProfileName() .. "_tone_PMANU_id")
		tone_SMANU_id = GetResourceKvpInt(save_prefix .. GetVehicleProfileName() .. "_tone_SMANU_id")
		tone_AUX_id = GetResourceKvpInt(save_prefix .. GetVehicleProfileName() .. "_tone_AUX_id")
		tone_airhorn_intrp = IntToBool(GetResourceKvpInt(save_prefix .. GetVehicleProfileName() .. "_tone_airhorn_intrp"))
		park_kill = IntToBool(GetResourceKvpInt(save_prefix .. GetVehicleProfileName() .. "_park_kill"))
		
		--Audio Settings
		button_sfx_scheme = GetResourceKvpString(save_prefix .. "button_sfx_scheme")	
		on_volume = GetResourceKvpFloat(save_prefix .. "audio_on_volume")	
		off_volume = GetResourceKvpFloat(save_prefix .. "audio_off_volume")		
		upgrade_volume = GetResourceKvpFloat(save_prefix .. "audio_upgrade_volume")		
		downgrade_volume = GetResourceKvpFloat(save_prefix .. "audio_downgrade_volume")	
		hazards_volume = GetResourceKvpFloat(save_prefix .. "audio_hazards_volume")	
		lock_volume = GetResourceKvpFloat(save_prefix .. "audio_lock_volume")	
		lock_reminder_volume = GetResourceKvpFloat(save_prefix .. "audio_lock_reminder_volume")
		airhorn_button_SFX = IntToBool(GetResourceKvpInt(save_prefix .. "audio_airhorn_button_SFX"))
		manu_button_SFX = IntToBool(GetResourceKvpInt(save_prefix .. "audio_manu_button_SFX"))
		
		--Main Siren Settings
		if veh ~= nil then 
			settings_string = GetResourceKvpString(save_prefix .. GetVehicleProfileName())
			if settings_string ~= nil then
				main_tone_settings = { }
				settings_string_by_tone = Split(settings_string, "|")
				for i, v in ipairs(settings_string_by_tone) do
				  tone_settings = Split(settings_string_by_tone[i], ",")
				  table.insert(main_tone_settings, { tonumber(tone_settings[1]), tonumber(tone_settings[2])})
				end
				settings_init = true
			end
		end
	end
	--Resolve any issues from attempting to load any non-saved vehicles. 
	if tone_PMANU_id == nil then
		tone_PMANU_id = GetTone(veh, 2)
	elseif not IsApprovedTone(veh, tone_PMANU_id) then
		tone_PMANU_id = GetTone(veh, 2)			
	end
	if tone_SMANU_id == nil then
		tone_SMANU_id = GetTone(veh, 3)
	elseif not IsApprovedTone(veh, tone_SMANU_id) then
		tone_SMANU_id = GetTone(veh, 3)			
	end
	if tone_AUX_id == nil then
		tone_AUX_id = GetTone(veh, 3)
	elseif not IsApprovedTone(veh, tone_AUX_id) then
		tone_AUX_id = GetTone(veh, 3)			
	end
end

---------------------------------------------------------------------
--Gets next tone based off vehicle profile and current tone.
function GetNextTone(current_tone, veh, main_tone) 
	main_tone = main_tone or false
	local veh_name = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
	local temp_tone_array = nil
	local temp_pos = -1
	if _G[veh_name] ~= nil then
		temp_tone_array = _G[veh_name]
	else 
		temp_tone_array = DEFAULT
	end
	
	for i, allowed_tone in ipairs(temp_tone_array) do
		if allowed_tone == current_tone then
			temp_pos = i
		end
	end
	if temp_pos < #temp_tone_array then
		temp_pos = temp_pos+1
		result = temp_tone_array[temp_pos]
	else
		temp_pos = 2
		result = temp_tone_array[2]
	end

	if main_tone then
		--Check if the tone is set to 'disable' or 'button-only' if so, find next tone
		if main_tone_settings[temp_pos-1] ~= nil then
			if main_tone_settings[temp_pos-1][2] > 2 then
				result = GetNextTone(result, veh, main_tone)
			end
		else
			ShowNotification("~r~LVC ERROR 1: ~s~Nil value caught.\ndetails: (" .. temp_pos .. "," .. result .. "," .. GetVehicleProfileName() .. ")")
		end
	end
	
	return result
end

---------------------------------------------------------------------
--Gets tone by ID, returns first siren if not found
function GetTone(veh, postion) 
	local veh_name = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
	local temp_tone_array = nil
	if _G[veh_name] ~= nil then
		temp_tone_array = _G[veh_name]
	else 
		temp_tone_array = DEFAULT
	end
	
	if temp_tone_array[postion] ~= nil then
		return temp_tone_array[postion]
	else 
		return temp_tone_array[2]	
	end
end

------------------------------------------------
--Gets size of a tone table for vehicle profile
function GetToneCount(veh) 
	local veh_name = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
	local temp_tone_array = nil
	if _G[veh_name] ~= nil then
		temp_tone_array = _G[veh_name]
	else 
		temp_tone_array = DEFAULT
	end
	return #temp_tone_array
end

------------------------------------------------
--Used to verify tone is allowed before playing, necessary if player switches vehicles there for changing vehicle profiles. 
function IsApprovedTone(veh, tone) 
	local veh_name = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
	local temp_tone_array = nil

 	if _G[veh_name] ~= nil then
		temp_tone_array = _G[veh_name]
	else 
		temp_tone_array = DEFAULT
	end
	
	for i, allowed_tone in ipairs(temp_tone_array) do
		if allowed_tone == tone then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
--Check if vehicle profile table exists, if so return the name otherwise default
function GetVehicleProfileName()
	local veh_name = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
	if _G[veh_name] ~= nil then
		return veh_name
	else 
		return "DEFAULT"
	end

end

---------------------------------------------------------------------
--HELPER FUNCTIONS for main siren settings saving:
function Split(inputstr, sep)
	sep = sep or "%s"
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

function TableToString(tbl)
	local s = {""}
	for i=1,#tbl do
	  for j=1,#tbl[i] do
		s[#s+1] = tbl[i][j]
                if j ~= #tbl[i] then
		    s[#s+1] = ","
                end
	  end
	   s[#s+1] = "|"
	end

	s = table.concat(s)
	return s
end

function IntToBool(int_value)
	if int_value == 1 then
		return true
	else
		return false
	end
end

function BoolToInt(bool_value)
	if bool_value then
		return 1
	else
		return 0
	end
end

function BoolToString(bool_value)
	if bool_value then
		return "true"
	else
		return "false"
	end
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
			snd_lxsiren[veh] = GetSoundId()
			PlaySoundFromEntity(snd_lxsiren[veh], siren_string_lookup[newstate], veh, 0, 0, 0)	
			TogMuteDfltSrnForVeh(veh, true)			
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
			snd_pwrcall[veh] = GetSoundId()
			PlaySoundFromEntity(snd_pwrcall[veh], siren_string_lookup[newstate], veh, 0, 0, 0)	
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
			snd_airmanu[veh] = GetSoundId()
			PlaySoundFromEntity(snd_airmanu[veh], siren_string_lookup[newstate], veh, 0, 0, 0)
			state_airmanu[veh] = newstate
		end
	end
end

------------------------------------------------
----------------EVENT HANDLERS------------------
------------------------------------------------
AddEventHandler('lux_vehcontrol:ELSClick', function(soundFile, soundVolume)
SendNUIMessage({
  transactionType     = 'playSound',
  transactionFile     = soundFile,
  transactionVolume   = soundVolume
})
end)

---------------------------------------------------------------------
RegisterNetEvent("lvc_GetVersion_c")
AddEventHandler("lvc_GetVersion_c", function(sender, version)
	repo_version = version
	if repo_version ~= nil and curr_version ~= nil then
		curr_version_text = "v" .. curr_version
		repo_version_text = "v" .. repo_version
	end
end)

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
				
					SetVehRadioStation(veh, "OFF")
					SetVehicleRadioEnabled(veh, false)
					
					if 	( not state_lxsiren[veh] ~= 1 
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
							if IsDisabledControlJustReleased(0, 85) or IsDisabledControlJustReleased(0, 246) then
								if IsVehicleSirenOn(veh) then
									TriggerEvent("lux_vehcontrol:ELSClick", button_sfx_scheme .. "/" .. "Off", off_volume) -- Off
									SetVehicleSiren(veh, false)
									--If the siren was on, save it in memory
									if state_lxsiren[veh] > 0 and not tone_main_reset_standby then
										tone_main_mem_id = state_lxsiren[veh]
									end
								else
									TriggerEvent("lux_vehcontrol:ELSClick", button_sfx_scheme .. "/" .. "On", on_volume) -- On
									Citizen.Wait(150)
									SetVehicleSiren(veh, true)
									count_bcast_timer = delay_bcast_timer
								end		
							
							-- TOG LX SIREN
							elseif IsDisabledControlJustReleased(0, 19) or IsDisabledControlJustReleased(0, 82) then
								if state_lxsiren[veh] == 0 then
									if IsVehicleSirenOn(veh) then
										TriggerEvent("lux_vehcontrol:ELSClick", button_sfx_scheme .. "/" .. "Upgrade", upgrade_volume) -- Upgrade
										if not tone_main_reset_standby then
											if IsApprovedTone(veh, tone_main_mem_id) then
												SetLxSirenStateForVeh(veh, tone_main_mem_id)
											else
												tone_main_mem_id = GetTone(veh, 2)
												SetLxSirenStateForVeh(veh, tone_main_mem_id)
											end
										else
											SetLxSirenStateForVeh(veh, GetTone(veh, 2))
										end
										count_bcast_timer = delay_bcast_timer
									end
								else
									TriggerEvent("lux_vehcontrol:ELSClick", button_sfx_scheme .. "/" .. "Downgrade", downgrade_volume) -- Downgrade
									if not tone_main_reset_standby then
										tone_main_mem_id = state_lxsiren[veh]
									end
									SetLxSirenStateForVeh(veh, 0)
									count_bcast_timer = delay_bcast_timer
								end
								
							-- POWERCALL
							elseif IsDisabledControlJustReleased(0, 172) and not IsMenuOpen() then --disable up arrow only in tone mode since testing would be beneficial 
								if state_pwrcall[veh] == 0 then
									if IsVehicleSirenOn(veh) then
										TriggerEvent("lux_vehcontrol:ELSClick", button_sfx_scheme .. "/" .. "Upgrade", upgrade_volume) -- Upgrade
										if tone_AUX_id ~= nil then
											if IsApprovedTone(veh, tone_AUX_id) then
												SetPowercallStateForVeh(veh, tone_AUX_id)
											else
												tone_AUX_id = GetTone(veh, 3)
												SetPowercallStateForVeh(veh, tone_AUX_id)
											end
											SetPowercallStateForVeh(veh, tone_AUX_id)
										else
											tone_AUX_id = GetTone(veh, 3)
											SetPowercallStateForVeh(veh, tone_AUX_id)											
										end
										count_bcast_timer = delay_bcast_timer
									end
								else
									TriggerEvent("lux_vehcontrol:ELSClick", button_sfx_scheme .. "/" .. "Downgrade", downgrade_volume) -- Downgrade
									SetPowercallStateForVeh(veh, 0)
									count_bcast_timer = delay_bcast_timer
								end
								
							end
							
							-- BROWSE LX SRN TONES
							if state_lxsiren[veh] > 0 then
								if ( IsDisabledControlJustReleased(0, 80) or IsDisabledControlJustReleased(0, 81) ) and not ( IsDisabledControlPressed(0, 80) or IsDisabledControlPressed(0, 81) )  then
									if IsVehicleSirenOn(veh) then
										newstate = GetNextTone(state_lxsiren[veh], veh, true)
										TriggerEvent("lux_vehcontrol:ELSClick", button_sfx_scheme .. "/" .. "Upgrade", upgrade_volume)
										SetLxSirenStateForVeh(veh, newstate)
										count_bcast_timer = delay_bcast_timer
									end
								end
							end
										
							-- MANU
							if state_lxsiren[veh] < 1 then
								if IsDisabledControlPressed(0, 80) or (IsDisabledControlPressed(0, 81) and not IsMenuOpen()) then
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
							
							--AIRHORN AND MANU BUTTON SFX
							if airhorn_button_SFX then
								if IsDisabledControlJustPressed(0, 86) then
									TriggerEvent("lux_vehcontrol:ELSClick", button_sfx_scheme .. "/" .. "Press", upgrade_volume)									
								end								
								if IsDisabledControlJustReleased(0, 86) then
									TriggerEvent("lux_vehcontrol:ELSClick", button_sfx_scheme .. "/" .. "Release", upgrade_volume)									
								end
							end							
							if manu_button_SFX and state_lxsiren[veh] == 0 then
								if IsDisabledControlJustPressed(0, 80) or IsDisabledControlJustPressed(0, 81) then
									TriggerEvent("lux_vehcontrol:ELSClick", button_sfx_scheme .. "/" .. "Press", upgrade_volume)									
								end								
								if IsDisabledControlJustReleased(0, 80) or IsDisabledControlJustReleased(0, 81) then
									TriggerEvent("lux_vehcontrol:ELSClick", button_sfx_scheme .. "/" .. "Release", upgrade_volume)									
								end
							end
						elseif not HUD_move_mode then
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
										ShowNotification("~y~~h~Reminder:~h~ ~s~Your siren control box is ~r~locked~s~.")
									end
									locked_press_count = locked_press_count + 1
							end								
						end
					end
					
					---- ADJUST HORN / MANU STATE ----
					local hmanu_state_new = 0
					if actv_horn == true and actv_manu == false then
						if tone_ARHRN_id ~= nil then
							if IsApprovedTone(veh, tone_ARHRN_id) then
								hmanu_state_new = tone_ARHRN_id
							else
								hmanu_state_new = GetTone(veh, 1)
							end
						else
							tone_ARHRN_id = GetTone(veh, 1)
							hmanu_state_new = tone_ARHRN_id
						end
					elseif actv_horn == false and actv_manu == true then
						if tone_PMANU_id ~= nil then
							if IsApprovedTone(veh, tone_PMANU_id) then
								hmanu_state_new = tone_PMANU_id
							else
								hmanu_state_new = GetTone(veh, 2)
							end
						else
							tone_PMANU_id = GetTone(veh, 2)
							hmanu_state_new = tone_PMANU_id
						end
					elseif actv_horn == true and actv_manu == true then
						if tone_SMANU_id ~= nil then
							if IsApprovedTone(veh, tone_SMANU_id) then
								hmanu_state_new = tone_SMANU_id
							else
								hmanu_state_new = GetTone(veh, 3)
							end
						else
							tone_SMANU_id = GetTone(veh, 3)
							hmanu_state_new = tone_SMANU_id
						end
					end
					
					if tone_airhorn_intrp then
						if hmanu_state_new == GetTone(veh, 1) then
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
										TriggerEvent("lux_vehcontrol:ELSClick", "Hazards_Off", hazards_volume) -- Hazards On
									else
										state_indic[veh] = ind_state_h
										TriggerEvent("lux_vehcontrol:ELSClick", "Hazards_On", hazards_volume) -- Hazards On
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