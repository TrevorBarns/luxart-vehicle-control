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
tone_airhorn_intrp = true
veh = nil
player_is_emerg_driver = false

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

--------------REGISTERED COMMANDS---------------
--/lvchudmove - Set move mode
RegisterCommand('lvchudmove', function(source, args)
	if player_is_emerg_driver then
		ShowHUD()
		if HUD_move_mode then		--If already in move mode transitioning out of move mode 
			HUD_move_mode = false
			RageUI.Visible(RMenu:Get('lvc', 'main'), true)
		else					--If not in move mode first entering, lock and start. 
			HUD_move_mode = true
		end
	end
end)

--/lvclock - set keylock
RegisterCommand('lvclock', function(source, args)
	if player_is_emerg_driver then	
		key_lock = not key_lock
		TriggerEvent("lux_vehcontrol:ELSClick", "Key_Lock", lock_volume) -- Off
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

--Dynamically Run RegisterCommand and KeyMapping functions for all 14 possible sirens
--Then at runtime "slide" all sirens down removing any disabled/restricted sirens.
function RegisterKeyMaps()
	local written_number = { "1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th", "9th", "10th", "11th", "12th", "13th", "14th" }
	for i, _ in ipairs(tone_table) do
		if i ~= 1 then
			local command = "_lvc_siren_" .. i-1
			local description = "LVC Siren: " .. written_number[i-1]
			
			RegisterCommand(command, function(source, args)
				if IsVehicleSirenOn(veh) and player_is_emerg_driver then
					local proposed_tone = GetTone(veh, i)
					local tone_setting = main_tone_settings[proposed_tone-1][2]
					if i <= GetToneCount(veh) and tone_setting < 4 and tone_setting ~= 2 then
						if ( state_lxsiren[veh] ~= proposed_tone or state_lxsiren[veh] == 0 ) then
							TriggerEvent("lux_vehcontrol:ELSClick", "Upgrade", upgrade_volume)
							SetLxSirenStateForVeh(veh, proposed_tone)
							count_bcast_timer = delay_bcast_timer
						else
							TriggerEvent("lux_vehcontrol:ELSClick", "Downgrade", downgrade_volume)
							SetLxSirenStateForVeh(veh, 0)
							count_bcast_timer = delay_bcast_timer				
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

----------------THREADED FUNCTIONS----------------
-- IS PLAYER SUPPOSED TO HAVE ACCESS TO LVC? 
-- player_is_emerg_driver is true if yes. 
Citizen.CreateThread(function()
	while true do
		player_is_emerg_driver = false	
		playerped = GetPlayerPed(-1)	
		--IS IN VEHICLE
		if IsPedInAnyVehicle(playerped, false) then
			veh = GetVehiclePedIsUsing(playerped)	
			--IS DRIVER
			if GetPedInVehicleSeat(veh, -1) == playerped then
				--IS EMERGENCY VEHICLE
				if GetVehicleClass(veh) == 18 then
					player_is_emerg_driver = true
				end
			end
		end
		Citizen.Wait(1000)
	end
end)

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
					ExecuteCommand("lvchudmove")
					RageUI.Visible(RMenu:Get('lvc', 'main'), true)
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

-- HUD DRAWING 
Citizen.CreateThread(function()
	local retrieval, veh_lights, veh_headlights 
	while true do
		while show_HUD and player_is_emerg_driver do
			DisableControlAction(0, 80, true)  
			DisableControlAction(0, 81, true) 
			DisableControlAction(0, 86, true) 
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
		if main_siren_register_keys_master_switch then
			RegisterKeyMaps()
		end
		LoadSettings()
		spawned = true
	end 
end )

--Ensure textures have streamed
Citizen.CreateThread(function()
	while not HasStreamedTextureDictLoaded("commonmenu") do
		RequestStreamedTextureDict("commonmenu", false);
		Citizen.Wait(0)
	end
end)

function SaveSettings()
	local save_prefix = "lvc_setting_"
	--HUD Settings
	if show_HUD then
		SetResourceKvpInt(save_prefix .. "HUD",  1)
	else
		SetResourceKvpInt(save_prefix .. "HUD",  0)
	end
	SetResourceKvpFloat(save_prefix .. "HUD_x_offset",  HUD_x_offset)
	SetResourceKvpFloat(save_prefix .. "HUD_y_offset",  HUD_y_offset)
	SetResourceKvpInt(save_prefix .. "hud_bgd_opacity",  hud_bgd_opacity)
	SetResourceKvpInt(save_prefix .. "hud_button_off_opacity",  hud_button_off_opacity)
	--Tone Settings
	SetResourceKvpInt(save_prefix .. GetVehicleProfileName() .. "_tone_PMANU_id",  tone_PMANU_id)
	SetResourceKvpInt(save_prefix .. GetVehicleProfileName() .. "_tone_SMANU_id",  tone_SMANU_id)
	SetResourceKvpInt(save_prefix .. GetVehicleProfileName() .. "_tone_AUX_id",  tone_AUX_id)
	if tone_airhorn_intrp then
		SetResourceKvpInt(save_prefix .. GetVehicleProfileName() .. "_tone_airhorn_intrp",  1)
	else
		SetResourceKvpInt(save_prefix .. GetVehicleProfileName() .. "_tone_airhorn_intrp",  0)
	end
	
	--Main Siren Settings
	settings_string = TableToString(main_tone_settings)
	SetResourceKvp(save_prefix .. GetVehicleProfileName(),  settings_string)
end

function LoadSettings()
	local save_prefix = "lvc_setting_"
	show_HUD_int = GetResourceKvpInt(save_prefix .. "HUD")
	if show_HUD_int == 0 then
		show_HUD = false
	else
		show_HUD = true
	end
	--Position
	HUD_x_offset = GetResourceKvpFloat(save_prefix .. "HUD_x_offset")
	HUD_y_offset = GetResourceKvpFloat(save_prefix .. "HUD_y_offset")
	--Opacity
	hud_bgd_opacity = GetResourceKvpInt(save_prefix .. "hud_bgd_opacity")
	hud_button_off_opacity = GetResourceKvpInt(save_prefix .. "hud_button_off_opacity")
	--Tones
	tone_PMANU_id = GetResourceKvpInt(save_prefix .. GetVehicleProfileName() .. "_tone_PMANU_id")
	tone_SMANU_id = GetResourceKvpInt(save_prefix .. GetVehicleProfileName() .. "_tone_SMANU_id")
	tone_AUX_id = GetResourceKvpInt(save_prefix .. GetVehicleProfileName() .. "_tone_AUX_id")
	tone_airhorn_intrp_int = GetResourceKvpInt(save_prefix .. GetVehicleProfileName() .. "_tone_airhorn_intrp")
	if tone_airhorn_intrp_int == 0 then
		tone_airhorn_intrp_int = false
	else
		tone_airhorn_intrp_int = true
	end

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
		else
			main_tone_settings = GetTonesList()
			settings_init = true
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

function GetVehicleProfileName()
	local veh_name = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
	if _G[veh_name] ~= nil then
		return veh_name
	else 
		return "DEFAULT"
	end

end

---------------------------------------------------------------------
--Gets next tone based off tone_type: Manual, Main, Aux; handles array looping and checks to see if ambulance or firetruk.
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
		result = temp_tone_array[temp_pos+1]
	else
		result = temp_tone_array[2]
	end
	
	if main_tone then
		--Check if the tone is set to disable or button only if so, find next tone
		while main_tone_settings[result - 1][2] > 2 do
			result = GetNextTone(result, veh, main_tone) 
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

--Gets size of a tone table for vehicle profile
---------------------------------------------------------------------
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

--Used to verify tone is allowed before playing necessary if player switches vehicles there for changing vehicle profiles. 
---------------------------------------------------------------------
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
function ShowHUD()
	if not show_HUD then
		show_HUD = true
	end
end

---------------------------------------------------------------------
function ShowNotification(text)
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
function TogPowercallStateForVeh(veh, newstate)
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
									if state_lxsiren[veh] > 0 then
										tone_main_mem_id = state_lxsiren[veh]
									end
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
									TriggerEvent("lux_vehcontrol:ELSClick", "Downgrade", downgrade_volume) -- Downgrade
									if main_siren_last_state then
										tone_main_mem_id = state_lxsiren[veh]
									end
									SetLxSirenStateForVeh(veh, 0)
									count_bcast_timer = delay_bcast_timer
								end
								
							-- POWERCALL
							elseif IsDisabledControlJustReleased(0, 172) and not IsMenuOpen() then --disable up arrow only in tone mode since testing would be beneficial 
								if state_pwrcall[veh] == 0 then
									if IsVehicleSirenOn(veh) then
										TriggerEvent("lux_vehcontrol:ELSClick", "Upgrade", upgrade_volume) -- Upgrade
										if tone_AUX_id ~= nil then
											if IsApprovedTone(veh, tone_AUX_id) then
												TogPowercallStateForVeh(veh, tone_AUX_id)
											else
												tone_AUX_id = GetTone(veh, 3)
												TogPowercallStateForVeh(veh, tone_AUX_id)
											end
											TogPowercallStateForVeh(veh, tone_AUX_id)
										else
											tone_AUX_id = GetTone(veh, 3)
											TogPowercallStateForVeh(veh, tone_AUX_id)											
										end
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
										newstate = GetNextTone(state_lxsiren[veh], veh, true)
										TriggerEvent("lux_vehcontrol:ELSClick", "Upgrade", upgrade_volume)
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
						if hmanu_state_new == 1 then
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
										TriggerEvent("lux_vehcontrol:ELSClick", "Hazards_Off", hazards_volumne) -- Hazards On
									else
										state_indic[veh] = ind_state_h
										TriggerEvent("lux_vehcontrol:ELSClick", "Hazards_On", hazards_volumne) -- Hazards On
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