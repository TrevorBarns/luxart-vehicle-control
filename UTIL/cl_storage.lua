--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: cl_storage.lua
PURPOSE: Handle save/load functions and version 
		 checking
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
STORAGE = { }

local save_prefix = 'lvc_'..community_id..'_'
local repo_version = nil
local backup_tone_table = {}
local custom_tone_names = false
local SIRENS_backup_string = nil
local profiles = { }

--	forward local fn declaration
local IsNewerVersion
 
------------------------------------------------
--Deletes all saved KVPs for that vehicle profile
--	This should never be removed. It is the only easy way for end users to delete LVC data.
RegisterCommand('lvcfactoryreset', function(source, args)
	local choice = HUD:FrontEndAlert(Lang:t('warning.warning'), Lang:t('warning.factory_reset'), Lang:t('warning.facory_reset_options'))
	if choice then
		STORAGE:FactoryReset()
	end
end)

function STORAGE:FactoryReset()
	STORAGE:DeleteKVPs(save_prefix)
	STORAGE:ResetSettings()
	UTIL:Print(Lang:t('info.factory_reset_success_console'), true)
	HUD:ShowNotification(Lang:t('info.factory_reset_success_frontend'), true)
end

--Prints all KVP keys and values to console
--if GetResourceMetadata(GetCurrentResourceName(), 'debug_mode', 0) == 'true' then
	RegisterCommand('lvcdumpkvp', function(source, args)
		UTIL:Print('^4LVC ^5STORAGE: ^7Dumping KVPs...')
		local handle = StartFindKvp(save_prefix);
		local key = FindKvp(handle)
		while key ~= nil do
			if GetResourceKvpString(key) ~= nil then
				UTIL:Print('^4LVC ^5STORAGE Found: ^7"'..key..'" "'..GetResourceKvpString(key)..'", STRING', true)
			elseif GetResourceKvpInt(key) ~= nil then
				UTIL:Print('^4LVC ^5STORAGE Found: ^7"'..key..'" "'..GetResourceKvpInt(key)..'", INT', true)
			elseif GetResourceKvpFloat(key) ~= nil then
				UTIL:Print('^4LVC ^5STORAGE Found: ^7"'..key..'" "'..GetResourceKvpFloat(key)..'", FLOAT', true)
			end
			key = FindKvp(handle)
			Wait(0)
		end
		UTIL:Print('^4LVC ^5STORAGE: ^7Finished Dumping KVPs...')
	end)
--end
------------------------------------------------
-- Resource Start Initialization
CreateThread(function()
	TriggerServerEvent('lvc:GetRepoVersion_s')
	STORAGE:FindSavedProfiles()
end)

--[[Function for Deleting KVPs]]
function STORAGE:DeleteKVPs(prefix)
	local handle = StartFindKvp(prefix);
	local key = FindKvp(handle)
	while key ~= nil do
		DeleteResourceKvp(key)
		UTIL:Print('^3LVC Info: Deleting Key \'' .. key .. '\'', true)
		key = FindKvp(handle)
		Wait(0)
	end
end

--[[Getter for current version used in RageUI.]]
function STORAGE:GetCurrentVersion()
	local curr_version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
	if curr_version ~= nil then
		return curr_version
	else
		return 'unknown'
	end
end

--[[Getter for repo version used in RageUI.]]
function STORAGE:GetRepoVersion()
	return repo_version
end

--[[Getter for out-of-date notification for RageUI.]]
function STORAGE:GetIsNewerVersion()
	return IsNewerVersion(repo_version, STORAGE:GetCurrentVersion())
end

--[[Saves HUD settings, separated from SaveSettings]]
function STORAGE:SaveHUDSettings()
	local hud_save_data = { Show_HUD = HUD:GetHudState(),
							HUD_Scale = HUD:GetHudScale(), 
							HUD_pos = HUD:GetHudPosition(),
							HUD_backlight_mode = HUD:GetHudBacklightMode(),
						  }
	SetResourceKvp(save_prefix .. 'hud_data',  json.encode(hud_save_data))
end


--[[Saves all KVP values.]]
function STORAGE:SaveSettings()
	UTIL:Print('^4LVC: ^5STORAGE: ^7Saving Settings...')
	SetResourceKvp(save_prefix..'save_version', STORAGE:GetCurrentVersion())

	--HUD Settings
	STORAGE:SaveHUDSettings()
	
	--Tone Names
	if custom_tone_names then
		local tone_names = { }
		for i, siren_pkg in pairs(SIRENS) do
			table.insert(tone_names, siren_pkg.Name)
		end
		SetResourceKvp(save_prefix .. 'tone_names', json.encode(tone_names))
		UTIL:Print('^4LVC ^5STORAGE: ^7saving '..save_prefix..'tone_names...')		
	end
	
	--Profile Specific Settings
	if UTIL:GetVehicleProfileName() ~= nil then
		local profile_name = string.gsub(UTIL:GetVehicleProfileName(), ' ', '_')
		if profile_name ~= nil then
			local tone_options_encoded = json.encode(UTIL:GetToneOptionsTable())
			local profile_save_data = {  PMANU 				= UTIL:GetToneID('PMANU'), 
										 SMANU 				= UTIL:GetToneID('SMANU'),
										 AUX   				= UTIL:GetToneID('AUX'),
										 airhorn_intrp 		= tone_airhorn_intrp,
										 main_reset_standby = tone_main_reset_standby,
										 park_kill 			= park_kill,
										 tone_options 		= tone_options_encoded,															  
									   }
							
			SetResourceKvp(save_prefix .. 'profile_'..profile_name..'!',  json.encode(profile_save_data))
			UTIL:Print('^4LVC ^5STORAGE: ^7saving '..save_prefix .. 'profile_'..profile_name..'!')

			--Audio Settings
			local audio_save_data = {	
										radio_masterswitch			= AUDIO.radio_masterswitch,				
										button_sfx_scheme 			= AUDIO.button_sfx_scheme,
										on_volume 					= AUDIO.on_volume,
										off_volume 					= AUDIO.off_volume,
										upgrade_volume 				= AUDIO.upgrade_volume,
										downgrade_volume 			= AUDIO.downgrade_volume,
										activity_reminder_volume 	= AUDIO.activity_reminder_volume,
										hazards_volume 				= AUDIO.hazards_volume,
										lock_volume 				= AUDIO.lock_volume,
										lock_reminder_volume 		= AUDIO.lock_reminder_volume,
										airhorn_button_SFX 			= AUDIO.airhorn_button_SFX,
										manu_button_SFX 			= AUDIO.manu_button_SFX,
										activity_reminder_index 	= AUDIO:GetActivityReminderIndex(),	
									}						
			SetResourceKvp(save_prefix..'profile_'..profile_name..'_audio_data',  json.encode(audio_save_data))
			UTIL:Print('^4LVC ^5STORAGE: ^7saving profile_'..profile_name..'_audio_data')
		else
			HUD:ShowNotification('~b~LVC: ~r~SAVE ERROR~s~: profile_name after gsub is nil.', true)
		end
	else
		HUD:ShowNotification('~b~LVC: ~r~SAVE ERROR~s~: UTIL:GetVehicleProfileName() returned nil.', true)
	end
	UTIL:Print('^4LVC ^5STORAGE: ^7Finished Saving Settings...')
end

------------------------------------------------
--[[Loads all KVP values.]]
function STORAGE:LoadSettings(profile_name)	
	UTIL:Print('^4LVC ^5STORAGE: ^7Loading Settings...')
	local comp_version = GetResourceMetadata(GetCurrentResourceName(), 'compatible', 0)
	local save_version = GetResourceKvpString(save_prefix .. 'save_version')
	local incompatible = IsNewerVersion(comp_version, save_version) == 'older'

	--Is save present if so what version
	if incompatible then
		AddTextEntry('lvc_mismatch_version','~y~~h~Warning:~h~ ~s~Luxart Vehicle Control Save Version Mismatch.\n~b~Compatible Version: ' .. comp_version .. '\n~o~Save Version: ' .. save_version .. '~s~\nYou may experience issues, to prevent this message from appearing verify settings and resave.')
		SetNotificationTextEntry('lvc_mismatch_version')
		DrawNotification(false, true)
	end
	
	local hud_save_data = GetResourceKvpString(save_prefix..'hud_data')
	if hud_save_data ~= nil then
		hud_save_data = json.decode(hud_save_data)
		HUD:SetHudState(hud_save_data.Show_HUD)
		HUD:SetHudScale(hud_save_data.HUD_Scale)
		HUD:SetHudPosition(hud_save_data.HUD_pos)
		HUD:SetHudBacklightMode(hud_save_data.HUD_backlight_mode)
		UTIL:Print('^4LVC ^5STORAGE: ^7loaded HUD data.')		
	end
	
	if save_version ~= nil then
		--Tone Names
		if main_siren_settings_masterswitch then
			local tone_names = GetResourceKvpString(save_prefix..'tone_names')
			if tone_names ~= nil then
				tone_names = json.decode(tone_names)
				for i, name in pairs(tone_names) do
					if SIRENS[i] ~= nil then
						SIRENS[i].Name = name
					end
				end
			end
			UTIL:Print('^4LVC ^5STORAGE: ^7loaded custom tone names.')
		end
		
		--Profile Specific Settings
		if UTIL:GetVehicleProfileName() ~= false then
			local profile_name = profile_name or string.gsub(UTIL:GetVehicleProfileName(), ' ', '_')	
			if profile_name ~= nil then
				local profile_save_data = GetResourceKvpString(save_prefix..'profile_'..profile_name..'!')
				if profile_save_data ~= nil then
					profile_save_data = json.decode(profile_save_data)
					UTIL:SetToneByID('PMANU', profile_save_data.PMANU)
					UTIL:SetToneByID('SMANU', profile_save_data.SMANU)
					UTIL:SetToneByID('AUX', profile_save_data.AUX)
					if main_siren_settings_masterswitch then
						tone_airhorn_intrp 		= profile_save_data.airhorn_intrp
						tone_main_reset_standby = profile_save_data.main_reset_standby
						park_kill 				= profile_save_data.park_kill
						local tone_options = json.decode(profile_save_data.tone_options)
							if tone_options ~= nil then
								for tone_id, option in pairs(tone_options) do
									tone_id = tonumber(tone_id)
									option = tonumber(option)
									if SIRENS[tone_id] ~= nil then
										UTIL:SetToneOption(tone_id, option)
									end
								end
							end
					end
					UTIL:Print('^4LVC ^5STORAGE: ^7loaded '..profile_name..'.')
				end
				--Audio Settings 
				local audio_save_data = GetResourceKvpString(save_prefix..'profile_'..profile_name..'_audio_data')
				if audio_save_data ~= nil then
					audio_save_data = json.decode(audio_save_data)
					if audio_save_data.radio_masterswitch ~= nil then
						AUDIO.radio_masterswitch			= audio_save_data.radio_masterswitch
					end
					AUDIO.button_sfx_scheme 		= audio_save_data.button_sfx_scheme
					AUDIO.on_volume 				= audio_save_data.on_volume
					AUDIO.off_volume 				= audio_save_data.off_volume
					AUDIO.upgrade_volume 			= audio_save_data.upgrade_volume
					AUDIO.downgrade_volume 			= audio_save_data.downgrade_volume
					AUDIO.activity_reminder_volume 	= audio_save_data.activity_reminder_volume
					AUDIO.hazards_volume 			= audio_save_data.hazards_volume
					AUDIO.lock_volume 				= audio_save_data.lock_volume
					AUDIO.lock_reminder_volume 		= audio_save_data.lock_reminder_volume
					AUDIO.airhorn_button_SFX 		= audio_save_data.airhorn_button_SFX
					AUDIO.manu_button_SFX 			= audio_save_data.manu_button_SFX
					AUDIO:SetActivityReminderIndex(audio_save_data.activity_reminder_index)
					UTIL:Print('^4LVC ^5STORAGE: ^7loaded audio data.')
				end
			else
				HUD:ShowNotification('~b~LVC:~r~ LOADING ERROR~s~: profile_name after gsub is nil.', true)
			end
		end
	end
	UTIL:Print('^4LVC ^5STORAGE: ^7Finished Loading Settings...')
end

------------------------------------------------
--[[Resets all KVP/menu values to their default.]]
function STORAGE:ResetSettings()
	UTIL:Print('^4LVC ^5STORAGE: ^7Resetting Settings...')

	--Storage State
	custom_tone_names 		= false
	profiles = { }
	STORAGE:FindSavedProfiles()

	--LVC State
	key_lock 				= false				
	tone_main_reset_standby = reset_to_standby_default
	tone_airhorn_intrp 		= airhorn_interrupt_default
	park_kill 				= park_kill_default

	--HUD State
	HUD:SetHudState(hud_first_default)
	HUD:SetHudScale(0.7)
	HUD:ResetPosition()
	HUD:SetHudBacklightMode(1)
	
	--Extra Tone Resets
	UTIL:SetToneByPos('ARHRN', 1)
	UTIL:SetToneByPos('PMANU', 2)
	UTIL:SetToneByPos('SMANU', 3)
	UTIL:SetToneByPos('AUX', 2)
	UTIL:SetToneByPos('MAIN_MEM', 2)

	STORAGE:RestoreBackupTable()
	UTIL:BuildToneOptions()
	
	--Audio Settings
	AUDIO.radio_masterswitch 		= true
	AUDIO.airhorn_button_SFX 		= false
	AUDIO.manu_button_SFX 			= false
	AUDIO:SetActivityReminderIndex(1)

	AUDIO.button_sfx_scheme 		= default_sfx_scheme_name
	AUDIO.on_volume 				= default_on_volume	
	AUDIO.off_volume 				= default_off_volume	
	AUDIO.upgrade_volume 			= default_upgrade_volume	
	AUDIO.downgrade_volume 			= default_downgrade_volume
	AUDIO.hazards_volume 			= default_hazards_volume
	AUDIO.lock_volume 				= default_lock_volume
	AUDIO.lock_reminder_volume 		= default_lock_reminder_volume
	AUDIO.activity_reminder_volume 	= default_reminder_volume
	UTIL:Print('^4LVC ^5STORAGE: ^7Finished Resetting Settings...')
end

------------------------------------------------
--[[Find all profile names of all saved KVP.]]
function STORAGE:FindSavedProfiles()
	local handle = StartFindKvp(save_prefix..'profile_');
	local key = FindKvp(handle)
	while key ~= nil do
		if string.match(key, '(.*)!$') then
			local saved_profile_name = string.match(key, save_prefix..'profile_(.*)!$')
			
			--Duplicate checking
			local found = false
			for _, profile_name in ipairs(profiles) do
				if profile_name == saved_profile_name then
					found = true
				end
			end
			
			if not found then
				table.insert(profiles, saved_profile_name)
			end
		end
		key = FindKvp(handle)
		Wait(0)
	end
end

function STORAGE:GetSavedProfiles()
	local cur_profile = UTIL:GetVehicleProfileName()
	for i, profile in ipairs(profiles) do
		if profile == cur_profile then
			table.remove(profiles, i)
		end
	end
	
	return profiles
end
------------------------------------------------
--[[Setter for JSON string backup of SIRENS table in case of reset since we modify SIREN table directly.]]
function STORAGE:SetBackupTable()
	SIRENS_backup_string = json.encode(SIRENS)
end

--[[Setter for SIRENS table using backup string of table.]]
function STORAGE:RestoreBackupTable()
	SIRENS = json.decode(SIRENS_backup_string)
end

--[[Setter for bool that is used in saving to determine if tone strings have been modified.]]
function STORAGE:SetCustomToneStrings(toggle)
	custom_tone_names = toggle
end

------------------------------------------------
--HELPER FUNCTIONS for main siren settings saving:end
--Compare Version Strings: Is version newer than test_version
IsNewerVersion = function(version, test_version)
	if version == nil or test_version == nil then
		return 'unknown'
	end

	if type(version) == 'string' then
		version = semver(version)
	end
	if type(test_version) == 'string' then
		test_version = semver(test_version)
	end

	if version > test_version then
		return 'older'
	elseif version < test_version then
		return 'newer'
	elseif version == test_version then
		return 'equal'
	end
end

---------------------------------------------------------------------
--[[Callback for Server -> Client version update.]]
RegisterNetEvent('lvc:SendRepoVersion_c')
AddEventHandler('lvc:SendRepoVersion_c', function(version)
	repo_version = version
end)