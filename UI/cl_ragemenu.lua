--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: cl_ragemenu.lua
PURPOSE: Handle RageUI
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

RMenu.Add('lvc', 'main', RageUI.CreateMenu(' ', Lang:t('menu.main'), 0, 0, "lvc", "lvc_v3_logo"))
RMenu.Add('lvc', 'maintone', RageUI.CreateSubMenu(RMenu:Get('lvc', 'main'),' ', Lang:t('menu.siren'), 0, 0, "lvc", "lvc_v3_logo"))
RMenu.Add('lvc', 'hudsettings', RageUI.CreateSubMenu(RMenu:Get('lvc', 'main'),' ', Lang:t('menu.hud'), 0, 0, "lvc", "lvc_v3_logo"))
RMenu.Add('lvc', 'audiosettings', RageUI.CreateSubMenu(RMenu:Get('lvc', 'main'),' ', Lang:t('menu.audio'), 0, 0, "lvc", "lvc_v3_logo"))
RMenu.Add('lvc', 'volumesettings', RageUI.CreateSubMenu(RMenu:Get('lvc', 'audiosettings'),' ', Lang:t('menu.audio'), 0, 0, "lvc", "lvc_v3_logo"))
RMenu.Add('lvc', 'plugins', RageUI.CreateSubMenu(RMenu:Get('lvc', 'main'),' ', Lang:t('menu.plugins'), 0, 0, "lvc", "lvc_v3_logo"))
RMenu.Add('lvc', 'saveload', RageUI.CreateSubMenu(RMenu:Get('lvc', 'main'),' ', Lang:t('menu.storage'), 0, 0, "lvc", "lvc_v3_logo"))
RMenu.Add('lvc', 'copyprofile', RageUI.CreateSubMenu(RMenu:Get('lvc', 'saveload'),' ', Lang:t('menu.copy'), 0, 0, "lvc", "lvc_v3_logo"))
RMenu.Add('lvc', 'info', RageUI.CreateSubMenu(RMenu:Get('lvc', 'main'),' ', Lang:t('menu.more_info'), 0, 0, "lvc", "lvc_v3_logo"))
RMenu:Get('lvc', 'main'):SetTotalItemsPerPage(13)
RMenu:Get('lvc', 'volumesettings'):SetTotalItemsPerPage(12)
RMenu:Get('lvc', 'main'):DisplayGlare(false)
RMenu:Get('lvc', 'maintone'):DisplayGlare(false)
RMenu:Get('lvc', 'hudsettings'):DisplayGlare(false)
RMenu:Get('lvc', 'audiosettings'):DisplayGlare(false)
RMenu:Get('lvc', 'volumesettings'):DisplayGlare(false)
RMenu:Get('lvc', 'plugins'):DisplayGlare(false)
RMenu:Get('lvc', 'saveload'):DisplayGlare(false)
RMenu:Get('lvc', 'copyprofile'):DisplayGlare(false)
RMenu:Get('lvc', 'info'):DisplayGlare(false)


--Strings for Save/Load confirmation, not ideal but it works.
local ok_to_disable  = true
local confirm_s_msg
local confirm_l_msg
local confirm_fr_msg
local confirm_s_desc
local confirm_l_desc
local confirm_fr_desc
local confirm_c_msg = { }
local confirm_c_desc = { }
local profile_c_op = { }
local profile_s_op = 75
local profile_l_op = 75
local sl_btn_debug_msg = ''

local hazard_state = false
local button_sfx_scheme_id = -1
local profiles = { }
local tone_table = { }
local PMANU_POS, PMANU_ID, SMANU_POS, SMANU_ID, AUX_POS, AUX_ID

local curr_version
local repo_version
local newer_version
local version_description
local version_formatted

Keys.Register(open_menu_key, 'lvc', Lang:t('control.menu_desc'), function()
	if not key_lock and player_is_emerg_driver and UpdateOnscreenKeyboard() ~= 0 then
		if UTIL:GetVehicleProfileName() == 'DEFAULT' then
			local veh_name = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
			sl_btn_debug_msg = Lang:t('menu.storage_default_profile_msg', {veh = veh_name})
		else
			sl_btn_debug_msg = ''
		end
		tone_table = UTIL:GetApprovedTonesTableNameAndID()
		profiles = STORAGE:GetSavedProfiles()
		RageUI.Visible(RMenu:Get('lvc', 'main'), not RageUI.Visible(RMenu:Get('lvc', 'main')))
	end
end)

---------------------------------------------------------------------
-- Triggered when vehicle changes (cl_lvc.lua)
RegisterNetEvent('lvc:onVehicleChange')
AddEventHandler('lvc:onVehicleChange', function()
	CreateThread(function()
		Wait(500)
		button_sfx_scheme_id = UTIL:IndexOf(AUDIO.button_sfx_scheme_choices, AUDIO.button_sfx_scheme) or 1
	end)
end)

--Trims front off tone-strings longer than 36 characters for front-end display
local function TrimToneString(tone_string)
	if #tone_string > 36 then
		local trim_amount = #tone_string - 33
		tone_string = string.format("...%s", string.sub(tone_string, trim_amount, 37))
	end
	
	return tone_string
end
-- Returns true if any menu is open
function IsMenuOpen()
	return 	RageUI.Visible(RMenu:Get('lvc', 'main')) or
			RageUI.Visible(RMenu:Get('lvc', 'maintone')) or
			RageUI.Visible(RMenu:Get('lvc', 'hudsettings')) or
			RageUI.Visible(RMenu:Get('lvc', 'audiosettings')) or
			RageUI.Visible(RMenu:Get('lvc', 'volumesettings')) or
			RageUI.Visible(RMenu:Get('lvc', 'saveload')) or
			RageUI.Visible(RMenu:Get('lvc', 'copyprofile')) or
			RageUI.Visible(RMenu:Get('lvc', 'info')) or
			RageUI.Visible(RMenu:Get('lvc', 'plugins')) or
			IsPluginMenuOpen()
end

-- Handle user input to cancel confirmation message for SAVE/LOAD
CreateThread(function()
	while true do
		while not RageUI.Settings.Controls.Back.Enabled do
			for Index = 1, #RageUI.Settings.Controls.Back.Keys do
				if IsDisabledControlJustPressed(RageUI.Settings.Controls.Back.Keys[Index][1], RageUI.Settings.Controls.Back.Keys[Index][2]) then
					confirm_s_msg = nil
					confirm_s_desc = nil
					profile_s_op = 75
					confirm_l_msg = nil
					confirm_l_desc = nil
					profile_l_op = 75
					confirm_r_msg = nil
					confirm_fr_msg = nil
					for i, _ in ipairs(profiles) do
						profile_c_op[i] = 75
						confirm_c_msg[i] = nil
						confirm_c_desc[i] = nil
					end
					Wait(10)
					RageUI.Settings.Controls.Back.Enabled = true
					break
				end
			end
			Wait(0)
		end
		Wait(100)
	end
end)

-- Handle Disabling Controls while menu open
CreateThread(function()
	Wait(1000)
	while true do
		while IsMenuOpen() do
			DisableControlAction(0, 27, true)
			DisableControlAction(0, 99, true)
			DisableControlAction(0, 172, true)
			DisableControlAction(0, 173, true)
			DisableControlAction(0, 174, true)
			DisableControlAction(0, 175, true)
			Wait(0)
		end
		Wait(100)
	end
end)

-- Close menu when player exits vehicle
CreateThread(function()
	while true do
		if IsMenuOpen() then
			if (not player_is_emerg_driver) then
				RageUI.CloseAll()
			end
		end
		Wait(500)
	end
end)

-- Resource start version handling
CreateThread(function()
	Wait(500)
	curr_version = STORAGE:GetCurrentVersion()
	repo_version = STORAGE:GetRepoVersion()
	newer_version = STORAGE:GetIsNewerVersion()
	version_description = Lang:t('menu.latest_version_desc')
	version_formatted = curr_version or Lang:t('info.unknown')
	
	if newer_version == 'older' then
		version_description, version_formatted = Lang:t('menu.old_version_desc'), '~o~~h~'..curr_version		
	elseif newer_version == 'newer' then
		version_description = Lang:t('menu.experimental_version_desc')
	elseif newer_version == 'unknown' then
		version_description = Lang:t('menu.unknown_version_desc')
	end
end)

CreateThread(function()
    while true do
		--Main Menu Visible
	    RageUI.IsVisible(RMenu:Get('lvc', 'main'), function()
			RageUI.Separator(Lang:t('menu.siren_settings_seperator'))
			RageUI.Button(Lang:t('menu.siren'), Lang:t('menu.siren_desc'), {RightLabel = '→→→'}, true, {
			}, RMenu:Get('lvc', 'maintone'))


			if custom_manual_tones_master_switch then
				--PRIMARY MANUAL TONE List
				--Get Current Tone ID and index ToneTable offset by 1 to correct airhorn missing
				PMANU_POS = UTIL:GetTonePos('PMANU')
				PMANU_ID = UTIL:GetToneID('PMANU')
				if PMANU_POS ~= -1 then
					RageUI.List(Lang:t('menu.primary_manu'), tone_table, PMANU_POS-1, Lang:t('menu.primary_manu_desc'), {}, true, {
					  onListChange = function(Index, Item)
						UTIL:SetToneByID('PMANU', Item.Value)
					  end,
					  onSelected = function()
						proposed_name = HUD:KeyboardInput(Lang:t('menu.rename_tone', { tone_string = TrimToneString(SIRENS[PMANU_ID].String) }), SIRENS[PMANU_ID].Name, 15)
						if proposed_name ~= nil then
							UTIL:ChangeToneString(PMANU_POS, proposed_name)
							tone_table = UTIL:GetApprovedTonesTableNameAndID()
						end
					  end,
					})
				end				
				
				--SECONDARY MANUAL TONE List
				--Get Current Tone ID and index ToneTable offset by 1 to correct airhorn missing
				SMANU_POS = UTIL:GetTonePos('SMANU')
				SMANU_ID = UTIL:GetToneID('SMANU')
				if SMANU_POS ~= -1 then
					RageUI.List(Lang:t('menu.secondary_manu'), tone_table, SMANU_POS-1, Lang:t('menu.secondary_manu_desc'), {}, true, {
					  onListChange = function(Index, Item)
						UTIL:SetToneByID('SMANU', Item.Value)
					  end,
					  onSelected = function()
						proposed_name = HUD:KeyboardInput(Lang:t('menu.rename_tone', { tone_string = TrimToneString(SIRENS[SMANU_ID].String) }), SIRENS[SMANU_ID].Name, 15)
						if proposed_name ~= nil then
							UTIL:ChangeToneString(SMANU_POS, proposed_name)
							tone_table = UTIL:GetApprovedTonesTableNameAndID()
						end
					  end,
					})
				end
			end

			--AUXILARY MANUAL TONE List
			--Get Current Tone ID and index ToneTable offset by 1 to correct airhorn missing
			if custom_aux_tones_master_switch then
				--AST List
				AUX_POS = UTIL:GetTonePos('AUX')
				AUX_ID = UTIL:GetToneID('AUX')
				if AUX_POS ~= -1 then
					RageUI.List(Lang:t('menu.aux_tone'), tone_table, AUX_POS-1, Lang:t('menu.aux_tone_desc'), {}, true, {
					  onListChange = function(Index, Item)
						UTIL:SetToneByID('AUX', Item.Value)
					  end,
					  onSelected = function()
						proposed_name = HUD:KeyboardInput(Lang:t('menu.rename_tone', { tone_string = TrimToneString(SIRENS[AUX_ID].String) }), SIRENS[AUX_ID].Name, 15)
						if proposed_name ~= nil then
							UTIL:ChangeToneString(AUX_POS, proposed_name)
							tone_table = UTIL:GetApprovedTonesTableNameAndID()
						end
					  end,
					})
				end
			end

			--SIREN PARK KILL
			if park_kill_masterswitch then
				RageUI.Checkbox(Lang:t('menu.siren_park_kill'), Lang:t('menu.siren_park_kill_desc'), park_kill, {}, {
				  onSelected = function(Index)
					  park_kill = Index
				  end
				})
			end
			--MAIN MENU TO SUBMENU BUTTONS
			RageUI.Separator(Lang:t('menu.other_settings_seperator'))
			RageUI.Button(Lang:t('menu.hud'), Lang:t('menu.hud_desc'), {RightLabel = '→→→'}, true, {
			  onSelected = function()
			  end,
			}, RMenu:Get('lvc', 'hudsettings'))
			RageUI.Button(Lang:t('menu.audio'), Lang:t('menu.audio_desc'), {RightLabel = '→→→'}, true, {
			  onSelected = function()
			  end,
			}, RMenu:Get('lvc', 'audiosettings'))
			RageUI.Separator(Lang:t('menu.misc_settings_seperator'))
			if plugins_installed then
				RageUI.Button(Lang:t('menu.plugins'), Lang:t('menu.plugins_desc'), {RightLabel = '→→→'}, true, {
				  onSelected = function()
				  end,
				}, RMenu:Get('lvc', 'plugins'))
			end
			RageUI.Button(Lang:t('menu.storage'), Lang:t('menu.storage_desc'), {RightLabel = '→→→'}, true, {
			  onSelected = function()
			  end,
			}, RMenu:Get('lvc', 'saveload'))
			RageUI.Button(Lang:t('menu.more_info'), Lang:t('menu.more_info_desc'), {RightLabel = '→→→'}, true, {
			  onSelected = function()
			  end,
			}, RMenu:Get('lvc', 'info'))
        end)
		---------------------------------------------------------------------
		----------------------------MAIN TONE MENU---------------------------
		---------------------------------------------------------------------
	    RageUI.IsVisible(RMenu:Get('lvc', 'maintone'), function()
			local approved_tones = UTIL:GetApprovedTonesTable()
			if airhorn_interrupt_masterswitch then
				RageUI.Checkbox(Lang:t('menu.airhorn_interrupt'), Lang:t('menu.airhorn_interrupt_desc'), tone_airhorn_intrp, {}, {
				  onChecked = function()
					tone_airhorn_intrp = true
				  end,
				  onUnChecked = function()
					tone_airhorn_intrp = false
				  end,
				})
			end
			if reset_to_standby_masterswitch then
				RageUI.Checkbox(Lang:t('menu.reset_standby'), Lang:t('menu.reset_standby_desc'), tone_main_reset_standby, {}, {
				  onChecked = function()
					tone_main_reset_standby = true
				  end,
				  onUnChecked = function()
					tone_main_reset_standby = false
				  end,
				})
			end

			if main_siren_settings_masterswitch then
				RageUI.Separator(Lang:t('menu.tone_options_seperator'))
				for i, tone in pairs(approved_tones) do
					if i ~= 1 then
						RageUI.List(SIRENS[tone].Name, { Lang:t('menu.cycle_button'), Lang:t('menu.cycle_only'), Lang:t('menu.button_only'), Lang:t('menu.disabled') }, UTIL:GetToneOption(tone), '~g~Cycle:~s~ play as you cycle through sirens.\n~g~Button:~s~ play when registered key is pressed.\n~b~Select to rename siren tones.', {}, true, {
							onListChange = function(Index, Item)
								if UTIL:IsOkayToDisable() or Index < 3 then
									UTIL:SetToneOption(tone, Index)
								else
									HUD:ShowNotification(Lang:t('menu.unable_to_disable'), true)
								end
							end,
							onSelected = function()
								proposed_name = HUD:KeyboardInput(Lang:t('menu.rename_tone', { tone_string = TrimToneString(SIRENS[tone].String) }), SIRENS[tone].Name, 15)
								if proposed_name ~= nil then
									UTIL:ChangeToneString(tone, proposed_name)
									tone_table = UTIL:GetApprovedTonesTableNameAndID()
								end
							end,
						})
					end
				end
			end
        end)
		---------------------------------------------------------------------
		-------------------------OTHER SETTINGS MENU-------------------------
		---------------------------------------------------------------------
		--HUD SETTINGS
	    RageUI.IsVisible(RMenu:Get('lvc', 'hudsettings'), function()
			local hud_state = HUD:GetHudState()
			local hud_backlight_mode = HUD:GetHudBacklightMode()
			RageUI.Checkbox(Lang:t('menu.enabled'), Lang:t('menu.hud_enabled_desc'), hud_state, {}, {
				onChecked = function()
					HUD:SetHudState(true)
				end,
				onUnChecked = function()
					HUD:SetHudState(false)
				end,
			})
			RageUI.Button(Lang:t('menu.hud_move_mode'), Lang:t('menu.hud_move_mode_desc'), {}, hud_state, {
				onSelected = function()
					HUD:SetMoveMode(true, true)
				end,
			});
			RageUI.Slider(Lang:t('menu.hud_scale'), 4*HUD:GetHudScale(), 6, 0.2, Lang:t('menu.hud_scale_desc'), false, {}, hud_state, {
				onSliderChange = function(Index)
					HUD:SetHudScale(Index/4)
				end,
			});
			RageUI.List(Lang:t('menu.hud_backlight'), {Lang:t('menu.hud_backlight_auto'), Lang:t('menu.hud_backlight_off'), Lang:t('menu.hud_backlight_on') }, hud_backlight_mode, Lang:t('menu.hud_backlight_desc'), {}, hud_state, {
			  onListChange = function(Index, Item)
				hud_backlight_mode = Index
				HUD:SetHudBacklightMode(hud_backlight_mode)
			  end,
			})
			RageUI.Button(Lang:t('menu.hud_reset'), Lang:t('menu.hud_reset_desc'), {}, hud_state, {
				onSelected = function()
					HUD:ResetPosition()
					HUD:SetHudState(false)
					HUD:SetHudState(true)
				end,
			});
		end)
		--AUDIO SETTINGS MENU
		RageUI.IsVisible(RMenu:Get('lvc', 'audiosettings'), function()
			RageUI.Checkbox(Lang:t('menu.audio_radio'), Lang:t('menu.audio_radio_desc'), AUDIO.radio_masterswitch, {}, {
			  onChecked = function()
				  AUDIO.radio_masterswitch = true
			  end,
			  onUnChecked = function()
				  AUDIO.radio_masterswitch = false
			  end,
            })
			RageUI.Separator(Lang:t('menu.audio_sfx_separator'))
			RageUI.List(Lang:t('menu.audio_scheme'), AUDIO.button_sfx_scheme_choices, button_sfx_scheme_id, Lang:t('menu.audio_scheme_desc'), {}, true, {
			  onListChange = function(Index, Item)
				button_sfx_scheme_id = Index
				AUDIO.button_sfx_scheme = AUDIO.button_sfx_scheme_choices[button_sfx_scheme_id]
			  end,
			})
			RageUI.Checkbox(Lang:t('menu.audio_manu_sfx'), Lang:t('menu.audio_manu_sfx_desc'), AUDIO.manu_button_SFX, {}, {
			  onChecked = function()
				  AUDIO.manu_button_SFX = true
			  end,
			  onUnChecked = function()
				  AUDIO.manu_button_SFX = false
			  end,
            })
			RageUI.Checkbox(Lang:t('menu.audio_horn_sfx'), Lang:t('menu.audio_horn_sfx_desc'), AUDIO.airhorn_button_SFX, {}, {
			  onChecked = function()
				  AUDIO.airhorn_button_SFX = true
			  end,
			  onUnChecked = function()
				  AUDIO.airhorn_button_SFX = false
			  end,
            })
			RageUI.List(Lang:t('menu.audio_activity_reminder'), {'Off', '1/2', '1', '2', '5', '10'}, AUDIO:GetActivityReminderIndex(), Lang:t('menu.audio_activity_reminder_desc', { timer = ("%1.0f"):format(AUDIO:GetActivityTimer() / 1000) or 0}), {}, true, {
			  onListChange = function(Index, Item)
				AUDIO:SetActivityReminderIndex(Index)
				AUDIO:ResetActivityTimer()
			  end,
			})
			RageUI.Button(Lang:t('menu.audio_volumes'), Lang:t('menu.audio_volumes_desc'), {RightLabel = '→→→'}, true, {
			  onSelected = function()
			  end,
			}, RMenu:Get('lvc', 'volumesettings'))
        end)		
		--VOLUME SETTINGS MENU
		RageUI.IsVisible(RMenu:Get('lvc', 'volumesettings'), function()
			RageUI.Slider(Lang:t('menu.on_volume'), (AUDIO.on_volume*100), 100, 2, Lang:t('menu.on_volume_desc'), true, {MuteOnSelected = true}, true, {
			  onSliderChange = function(Index)
				AUDIO.on_volume = (Index / 100)
			  end,
			  onSelected = function(Index, Item)
				AUDIO:Play('On', AUDIO.on_volume)
			  end,
			})
			RageUI.Slider(Lang:t('menu.off_volume'), (AUDIO.off_volume*100), 100, 2, Lang:t('menu.off_volume_desc'), true, {MuteOnSelected = true}, true, {
			  onSliderChange = function(Index)
				AUDIO.off_volume = (Index/100)
			  end,
			  onSelected = function(Index, Item)
				AUDIO:Play('Off', AUDIO.off_volume)
			  end,
			})
			RageUI.Slider(Lang:t('menu.upgrade_volume'), (AUDIO.upgrade_volume*100), 100, 2, Lang:t('menu.upgrade_volume_desc'), true, {MuteOnSelected = true}, true, {
			  onSliderChange = function(Index)
				AUDIO.upgrade_volume = (Index/100)
			  end,
			  onSelected = function(Index, Item)
				AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
			  end,
			})
			RageUI.Slider(Lang:t('menu.downgrade_volume'), (AUDIO.downgrade_volume*100), 100, 2, Lang:t('menu.downgrade_volume_desc'), true, {MuteOnSelected = true}, true, {
			  onSliderChange = function(Index)
				AUDIO.downgrade_volume = (Index/100)
			  end,
			  onSelected = function(Index, Item)
				AUDIO:Play('Downgrade', AUDIO.downgrade_volume)
			  end,
			})
			RageUI.Slider(Lang:t('menu.reminder_volume'), (AUDIO.activity_reminder_volume*500), 100, 2, Lang:t('menu.reminder_volume_desc'), true, {MuteOnSelected = true}, true, {
			  onSliderChange = function(Index)
				AUDIO.activity_reminder_volume = (Index/500)
			  end,
			  onSelected = function(Index, Item)
				AUDIO:Play('Reminder', AUDIO.activity_reminder_volume)
			  end,
			})
			RageUI.Slider(Lang:t('menu.hazards_volume'), (AUDIO.hazards_volume*100), 100, 2, Lang:t('menu.hazards_volume_desc'), true, {}, true, {
			  onSliderChange = function(Index)
				AUDIO.hazards_volume = (Index/100)
			  end,
			  onSelected = function(Index, Item)
				if hazard_state then
					AUDIO:Play('Hazards_On', AUDIO.hazards_volume, true)
				else
					AUDIO:Play('Hazards_Off', AUDIO.hazards_volume, true)
				end
				hazard_state = not hazard_state
			  end,
			})
			RageUI.Slider(Lang:t('menu.lock_volume'), (AUDIO.lock_volume*100), 100, 2, Lang:t('menu.lock_volume_desc'), true, {}, true, {
			  onSliderChange = function(Index)
				AUDIO.lock_volume = (Index/100)
			  end,
			  onSelected = function(Index, Item)
				AUDIO:Play('Key_Lock', AUDIO.lock_volume, true)
			  end,
			})
			RageUI.Slider(Lang:t('menu.lock_reminder_volume'), (AUDIO.lock_reminder_volume*100), 100, 2, Lang:t('menu.lock_reminder_volume_desc'), true, {}, true, {
			  onSliderChange = function(Index)
				AUDIO.lock_reminder_volume = (Index/100)
			  end,
			  onSelected = function(Index, Item)
				AUDIO:Play('Locked_Press', AUDIO.lock_reminder_volume, true)
			  end,
			})
        end)
		---------------------------------------------------------------------
		----------------------------SAVE LOAD MENU---------------------------
		---------------------------------------------------------------------
	    RageUI.IsVisible(RMenu:Get('lvc', 'saveload'), function()
			RageUI.Button(Lang:t('menu.save'), confirm_s_desc or Lang:t('menu.save_desc') .. ' ' .. sl_btn_debug_msg, {RightLabel = confirm_s_msg or '('.. UTIL:GetVehicleProfileName() .. ')', RightLabelOpacity = profile_s_op}, true, {
				onSelected = function()
					if confirm_s_msg == Lang:t('menu.confirm') then
						STORAGE:SaveSettings()
						HUD:ShowNotification(Lang:t('menu.save_success'), true)
						confirm_s_msg = nil
						confirm_s_desc = nil
						profile_s_op = 75
					else
						RageUI.Settings.Controls.Back.Enabled = false
						profile_s_op = 255
						confirm_s_msg = Lang:t('menu.confirm')
						confirm_s_desc = Lang:t('menu.save_override_desc', { profile = UTIL:GetVehicleProfileName() })
						confirm_l_msg = nil
						profile_l_op = 75
						confirm_r_msg = nil
						confirm_fr_msg = nil
					end
				end,
			})
			RageUI.Button(Lang:t('menu.load'), confirm_l_desc or Lang:t('menu.load_desc') .. ' ' .. sl_btn_debug_msg, {RightLabel = confirm_l_msg or '('.. UTIL:GetVehicleProfileName() .. ')', RightLabelOpacity = profile_l_op}, true, {
			  onSelected = function()
				if confirm_l_msg == Lang:t('menu.confirm') then
					STORAGE:LoadSettings()
					tone_table = UTIL:GetApprovedTonesTableNameAndID()
					HUD:ShowNotification(Lang:t('menu.load_success'), true)
					confirm_l_msg = nil
					confirm_l_desc = nil
					profile_l_op = 75
				else
					RageUI.Settings.Controls.Back.Enabled = false
					profile_l_op = 255
					confirm_l_msg = Lang:t('menu.confirm')
					confirm_l_desc = Lang:t('menu.load_override')
					confirm_s_msg = nil
					profile_s_op = 75
					confirm_r_msg = nil
					confirm_fr_msg = nil
				end
			  end,
			})
			RageUI.Separator(Lang:t('menu.advanced_separator'))
			RageUI.Button(Lang:t('menu.copy'), Lang:t('menu.copy_desc'), {RightLabel = '→→→'}, #profiles > 0, {}, RMenu:Get('lvc', 'copyprofile'))
			RageUI.Button(Lang:t('menu.reset'), Lang:t('menu.reset_desc'), {RightLabel = confirm_r_msg}, true, {
			  onSelected = function()
				if confirm_r_msg == Lang:t('menu.confirm') then
					STORAGE:ResetSettings()
					HUD:ShowNotification(Lang:t('menu.reset_success'), true)
					confirm_r_msg = nil
				else
					RageUI.Settings.Controls.Back.Enabled = false
					confirm_r_msg = Lang:t('menu.confirm')
					confirm_l_msg = nil
					profile_l_op = 75
					confirm_s_msg = nil
					profile_s_op = 75
					confirm_fr_msg = nil
				end
			  end,
			})
			RageUI.Button(Lang:t('menu.factory_reset'), Lang:t('menu.factory_reset_desc'), {RightLabel = confirm_fr_msg}, true, {
			  onSelected = function()
				if confirm_fr_msg == Lang:t('menu.confirm') then
					RageUI.CloseAll()
					Wait(100)
					local choice = HUD:FrontEndAlert(Lang:t('warning.warning'), Lang:t('warning.factory_reset'), Lang:t('warning.facory_reset_options'))
					if choice then
						STORAGE:FactoryReset()
					else
						RageUI.Visible(RMenu:Get('lvc', 'saveload'), true)
					end
					confirm_fr_msg = nil
				else
					RageUI.Settings.Controls.Back.Enabled = false
					confirm_fr_msg = Lang:t('menu.confirm')
					confirm_l_msg = nil
					profile_l_op = 75
					confirm_s_msg = nil
					profile_s_op = 75
					confirm_r_msg = nil
				end
			  end,
			})
        end)

		--Copy Profiles Menu
	    RageUI.IsVisible(RMenu:Get('lvc', 'copyprofile'), function()
			for i, profile_name in ipairs(profiles) do
				profile_c_op[i] = profile_c_op[i] or 75
				RageUI.Button(profile_name, confirm_c_desc[i] or Lang:t('menu.load_copy_desc', { profile = profile_name }), {RightLabel = confirm_c_msg[i] or Lang:t('menu.load_copy'), RightLabelOpacity = profile_c_op[i]}, true, {
				  onSelected = function()
					if confirm_c_msg[i] == Lang:t('menu.confirm') then
						STORAGE:LoadSettings(profile_name)
						tone_table = UTIL:GetApprovedTonesTableNameAndID()
						HUD:ShowNotification(Lang:t('menu.load_success'), true)
						confirm_c_msg[i] = nil
						confirm_c_desc[i] = nil
						profile_c_op[i] = 75
					else
						RageUI.Settings.Controls.Back.Enabled = false
						for j, _ in ipairs(profiles) do
							if i ~= j then
								profile_c_op[j] = 75
								confirm_c_msg[j] = nil
								confirm_c_desc[j] = nil
							end
						end
						profile_c_op[i] = 255
						confirm_c_msg[i] = Lang:t('menu.confirm')
						confirm_c_desc[i] = Lang:t('menu.load_override')
					end
				  end,
				})
			end
		end)
		---------------------------------------------------------------------
		----------------------------MORE INFO MENU---------------------------
		---------------------------------------------------------------------
	    RageUI.IsVisible(RMenu:Get('lvc', 'info'), function()
			RageUI.Button(Lang:t('menu.current_version'), Lang:t('menu.version_string', { ver = version_formatted, ver_desc = version_description }), { RightLabel = version_formatted }, true, {
			  onSelected = function()
			  end,
			});
			if newer_version == 'older' then
				RageUI.Button(Lang:t('menu.latest_version'), Lang:t('menu.latest_version_desc', { ver = repo_version }), {RightLabel = repo_version or Lang:t('info.unknown')}, true, {
					onSelected = function()
				end,
				});
			end
			RageUI.Button(Lang:t('menu.about_credits'), Lang:t('menu.about_credits_desc'), {}, true, {
				onSelected = function()
			end,
			});
			RageUI.Button('Website', 'Learn more about Luxart Engineering and it\'s products at ~b~https://www.luxartengineering.com~w~!', {}, true, {
				onSelected = function()
			end,
			});
        end)
        Wait(0)
	end
end)