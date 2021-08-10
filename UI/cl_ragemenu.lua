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
]]

RMenu.Add('lvc', 'main', RageUI.CreateMenu("Luxart Vehicle Control", "Main Menu"))
RMenu.Add('lvc', 'maintone', RageUI.CreateSubMenu(RMenu:Get('lvc', 'main'),"Luxart Vehicle Control", "Main Siren Settings"))
RMenu.Add('lvc', 'hudsettings', RageUI.CreateSubMenu(RMenu:Get('lvc', 'main'),"Luxart Vehicle Control", "HUD Settings"))
RMenu.Add('lvc', 'audiosettings', RageUI.CreateSubMenu(RMenu:Get('lvc', 'main'),"Luxart Vehicle Control", "Audio Settings"))
RMenu.Add('lvc', 'plugins', RageUI.CreateSubMenu(RMenu:Get('lvc', 'main'),"Luxart Vehicle Control", "Plugins"))
RMenu.Add('lvc', 'saveload', RageUI.CreateSubMenu(RMenu:Get('lvc', 'main'),"Luxart Vehicle Control", "Storage Management"))
RMenu.Add('lvc', 'copyprofile', RageUI.CreateSubMenu(RMenu:Get('lvc', 'main'),"Luxart Vehicle Control", "Copy Profile Settings"))
RMenu.Add('lvc', 'about', RageUI.CreateSubMenu(RMenu:Get('lvc', 'main'),"Luxart Vehicle Control", "About Luxart Vehicle Control"))
RMenu:Get('lvc', 'main'):SetTotalItemsPerPage(13)
RMenu:Get('lvc', 'audiosettings'):SetTotalItemsPerPage(12)
RMenu:Get('lvc', 'main'):DisplayGlare(false)
RMenu:Get('lvc', 'maintone'):DisplayGlare(false)
RMenu:Get('lvc', 'hudsettings'):DisplayGlare(false)
RMenu:Get('lvc', 'audiosettings'):DisplayGlare(false)
RMenu:Get('lvc', 'plugins'):DisplayGlare(false)
RMenu:Get('lvc', 'saveload'):DisplayGlare(false)
RMenu:Get('lvc', 'copyprofile'):DisplayGlare(false)
RMenu:Get('lvc', 'about'):DisplayGlare(false)


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
local hazard_state = false
local button_sfx_scheme_id = 1
local sl_btn_debug_msg = ""
local settings_init = false

local profiles = { }
local TonesTable = { }
local PMANU
local SMANU
local AUX

Keys.Register(open_menu_key, open_menu_key, 'LVC: Open Menu', function()
	if not key_lock and player_is_emerg_driver and UpdateOnscreenKeyboard() ~= 0 and settings_init then
		if UTIL:GetVehicleProfileName() == "DEFAULT" then
			local veh_name = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
			sl_btn_debug_msg = " Using ~b~DEFAULT~s~ profile for \"~b~" .. veh_name .. "~s~\"."
		else
			sl_btn_debug_msg = ""
		end
		TonesTable = UTIL:GetApprovedTonesTableNameAndID()
		profiles = Storage:GetSavedProfiles()
		RageUI.Visible(RMenu:Get('lvc', 'main'), not RageUI.Visible(RMenu:Get('lvc', 'main')))
	end
end)

--Returns true if any menu is open
function IsMenuOpen()
	return 	RageUI.Visible(RMenu:Get('lvc', 'main')) or 
			RageUI.Visible(RMenu:Get('lvc', 'maintone')) or 
			RageUI.Visible(RMenu:Get('lvc', 'hudsettings')) or 		
			RageUI.Visible(RMenu:Get('lvc', 'audiosettings')) or 
			RageUI.Visible(RMenu:Get('lvc', 'saveload')) or 
			RageUI.Visible(RMenu:Get('lvc', 'copyprofile')) or 
			RageUI.Visible(RMenu:Get('lvc', 'about')) or
			RageUI.Visible(RMenu:Get('lvc', 'plugins')) or 
			IsPluginMenuOpen()
end


--Loads settings and builds first table states, also updates tone_list every second for vehicle changes
Citizen.CreateThread(function()
    while true do
		if not settings_init and player_is_emerg_driver and veh ~= nil then
			UTIL:UpdateApprovedTones(veh)
			settings_init = true
		end
		Citizen.Wait(1000)
	end
end)

--Handle user input to cancel confirmation message for SAVE/LOAD
Citizen.CreateThread(function()
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
					Citizen.Wait(10)
					RageUI.Settings.Controls.Back.Enabled = true
					break
				end
			end
			Citizen.Wait(0)
		end
		Citizen.Wait(100)
	end
end)

--Handle Disabling Controls while menu open
Citizen.CreateThread(function()
Citizen.Wait(1000)
	while true do 
		while IsMenuOpen() do
			DisableControlAction(0, 27, true) 
			DisableControlAction(0, 99, true) 
			DisableControlAction(0, 172, true) 
			DisableControlAction(0, 173, true) 
			DisableControlAction(0, 174, true) 
			DisableControlAction(0, 175, true) 
			Citizen.Wait(0)
		end
		Citizen.Wait(100)
	end
end)

Citizen.CreateThread(function()
	while true do
		if IsMenuOpen() then
			if (not player_is_emerg_driver) then
				RageUI.CloseAll()
			end
		end
		Citizen.Wait(500)
	end
end)

Citizen.CreateThread(function()
    while true do
		--Main Menu Visible
	    RageUI.IsVisible(RMenu:Get('lvc', 'main'), function()
			RageUI.Separator("Siren Settings")
			RageUI.Button('Main Siren Settings', "Change which/how each available primary tone is used.", {RightLabel = "→→→"}, true, {
			}, RMenu:Get('lvc', 'maintone'))
			
			
			if custom_manual_tones_master_switch then
				--PRIMARY MANUAL TONE List
				--Get Current Tone ID and index ToneTable offset by 1 to correct air horn missing
				PMANU = UTIL:GetTonePos('PMANU')
				RageUI.List('Primary Manual Tone', TonesTable, PMANU-1, "Change your primary manual tone.", {}, true, {
				  onListChange = function(Index, Item)
					UTIL:SetToneByID('PMANU', Item.Value)
				  end,
				  onSelected = function()
					proposed_name = HUD:KeyboardInput("Enter new tone name for " .. SIRENS[PMANU].String .. ":", SIRENS[PMANU].Name, 15)
					if proposed_name ~= nil then
						UTIL:ChangeToneString(PMANU, proposed_name)
						TonesTable = UTIL:GetApprovedTonesTableNameAndID()
					end
				  end,
				})
				
				--SECONDARY MANUAL TONE List
				--Get Current Tone ID and index ToneTable offset by 1 to correct air horn missing
				SMANU = UTIL:GetTonePos('SMANU')
				RageUI.List('Secondary Manual Tone', TonesTable, SMANU-1, "Change your secondary manual tone.", {}, true, {
				  onListChange = function(Index, Item)
					UTIL:SetToneByID('SMANU', Item.Value)
				  end,
				  onSelected = function()
					proposed_name = HUD:KeyboardInput("Enter new tone name for " .. SIRENS[SMANU].String .. ":", SIRENS[SMANU].Name, 15)
					if proposed_name ~= nil then
						UTIL:ChangeToneString(SMANU, proposed_name)
						TonesTable = UTIL:GetApprovedTonesTableNameAndID()
					end
				  end,
				})
			end

			--AUXILARY MANUAL TONE List
			--Get Current Tone ID and index ToneTable offset by 1 to correct air horn missing
			if custom_aux_tones_master_switch then
				--AST List
				AUX = UTIL:GetTonePos('AUX')
				RageUI.List('Auxiliary Siren Tone', TonesTable, AUX-1, "Change your auxiliary/dual siren tone.", {}, true, {
				  onListChange = function(Index, Item)
					UTIL:SetToneByID('AUX', Item.Value)
				  end,
				  onSelected = function()
					proposed_name = HUD:KeyboardInput("Enter new tone name for " .. SIRENS[AUX].String .. ":", SIRENS[AUX].Name, 15)
					if proposed_name ~= nil then
						UTIL:ChangeToneString(AUX, proposed_name)
						TonesTable = UTIL:GetApprovedTonesTableNameAndID()
					end
				  end,
				})
			end
			
			--SIREN PARK KILL
			if park_kill_masterswitch then
				RageUI.Checkbox('Siren Park Kill', "Toggles whether your sirens turn off automatically when you exit your vehicle. ", park_kill, {}, {
				  onSelected = function(Index)
					  park_kill = Index
				  end
				})
			end
			--MAIN MENU TO SUBMENU BUTTONS
			RageUI.Separator("Other Settings")
			RageUI.Button('HUD Settings', "Open HUD settings menu.", {RightLabel = "→→→"}, true, {
			  onSelected = function()
			  end,
			}, RMenu:Get('lvc', 'hudsettings'))					
			RageUI.Button('Audio Settings', "Open audio settings menu.", {RightLabel = "→→→"}, true, {
			  onSelected = function()
			  end,
			}, RMenu:Get('lvc', 'audiosettings'))			
			RageUI.Separator("Miscellaneous")	
			if plugins_installed then
				RageUI.Button('Plugins', "Open Plugins Menu.", {RightLabel = "→→→"}, true, {
				  onSelected = function()
				  end,
				}, RMenu:Get('lvc', 'plugins'))		
			end
			RageUI.Button('Storage Management', "Save / Load vehicle profiles.", {RightLabel = "→→→"}, true, {
			  onSelected = function()
			  end,
			}, RMenu:Get('lvc', 'saveload'))			
			RageUI.Button('More Information', "Learn more about Luxart Vehicle Control.", {RightLabel = "→→→"}, true, {
			  onSelected = function()
			  end,
			}, RMenu:Get('lvc', 'about'))
        end)
		---------------------------------------------------------------------
		----------------------------MAIN TONE MENU---------------------------
		---------------------------------------------------------------------	
	    RageUI.IsVisible(RMenu:Get('lvc', 'maintone'), function()
			local approved_tones = UTIL:GetApprovedTonesTable()
			if airhorn_interrupt_masterswitch then
				RageUI.Checkbox('Airhorn Interrupt Mode', "Toggles whether the air horn interrupts main siren.", tone_airhorn_intrp, {}, {
				  onChecked = function()
					tone_airhorn_intrp = true
				  end,
				  onUnChecked = function()
					tone_airhorn_intrp = false
				  end,	
				})
			end
			if reset_to_standby_masterswitch then
				RageUI.Checkbox('Reset to Standby', "~g~Enabled~s~, the primary siren will reset to 1st siren on siren toggle. ~r~Disabled~s~, the last played tone will resume on siren toggle.", tone_main_reset_standby, {}, {
				  onChecked = function()
					tone_main_reset_standby = true
				  end,
				  onUnChecked = function()
					tone_main_reset_standby = false
				  end,
				})
			end
			if main_siren_settings_masterswitch then
				for i, tone in pairs(approved_tones) do
					if i ~= 1 then
						RageUI.List(SIRENS[tone].Name, { 'Cycle & Button', 'Cycle Only', 'Button Only', 'Disabled' }, UTIL:GetToneOption(tone), "~g~Cycle:~s~ play as you cycle through sirens.\n~g~Button:~s~ play when registered key is pressed.\n~b~Select to rename siren tones.", {}, true, {
							onListChange = function(Index, Item)
								if UTIL:IsOkayToDisable() or Index < 3 then
									UTIL:SetToneOption(tone, Index)
								else
									HUD:ShowNotification("~y~~h~Info:~h~ ~s~Luxart Vehicle Control\nAction prohibited, cannot disable all sirens.", true) 
								end
							end,
							onSelected = function()
								proposed_name = HUD:KeyboardInput("Enter new tone name for " .. SIRENS[tone].String .. ":", SIRENS[tone].Name, 15)
								if proposed_name ~= nil then
									UTIL:ChangeToneString(tone, proposed_name)
									TonesTable = UTIL:GetApprovedTonesTableNameAndID()
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
			RageUI.Checkbox('Enabled', "Toggles whether HUD is displayed. Requires GTA V HUD to be enabled.", hud_state, {}, {
				onChecked = function()
					HUD:SetHudState(true)
				end,
				onUnChecked = function()
					HUD:SetHudState(false)
				end,
			})
			RageUI.Button('Move Mode', "Move HUD position on screen. To exit ~r~right-click~s~ or hit '~r~Esc~s~'.", {}, hud_state, {
				onSelected = function()
					HUD:SetMoveMode(true, true)
				end,
				});		
			RageUI.Slider('Scale', (HUD:GetHudScale()*4), 6, 0.2, "Change opacity of of the HUD background rectangle.", false, {}, hud_state, {
				onSliderChange = function(Index)
				HUD:SetHudScale(Index/4)
				end,
			});			
			RageUI.List('Backlight', {"Auto", "Off", "On"}, hud_backlight_mode, "Changes HUD backlight behavior. ~b~Auto~s~ is determined by headlight state.", {}, true, {
			  onListChange = function(Index, Item)
				hud_backlight_mode = Index
				HUD:SetHudBacklightMode(hud_backlight_mode)
			  end,
			})	
			RageUI.Button('Reset', "Reset HUD position to default.", {}, hud_state, {
				onSelected = function()
					HUD:ResetPosition()
					HUD:SetHudState(false)
					HUD:SetHudState(true)
				end,
			});
		end)	    
		--AUDIO SETTINGS MENU
		RageUI.IsVisible(RMenu:Get('lvc', 'audiosettings'), function()
			RageUI.Checkbox('Radio Controls', "When enabled, the tilde key will act as a radio wheel key.", radio_masterswitch, {}, {
			  onChecked = function()
				  radio_masterswitch = true
			  end,
			  onUnChecked = function()
				  radio_masterswitch = false
			  end,
            })
			RageUI.List("Siren Box SFX Scheme", button_sfx_scheme_choices, button_sfx_scheme_id, "Change what SFX to use for siren box clicks.", {}, true, {
			  onListChange = function(Index, Item)
				button_sfx_scheme_id = Index
				button_sfx_scheme = button_sfx_scheme_choices[button_sfx_scheme_id]
			  end,				
			})
			RageUI.Checkbox('Manual Button Clicks', "When enabled, your manual tone button will activate the upgrade SFX.", manu_button_SFX, {}, {
			  onChecked = function()
				  manu_button_SFX = true
			  end,
			  onUnChecked = function()
				  manu_button_SFX = false
			  end,
            })			
			RageUI.Checkbox('Air Horn Button Clicks', "When enabled, your air horn button will activate the upgrade SFX.", airhorn_button_SFX, {}, {
			  onChecked = function()
				  airhorn_button_SFX = true
			  end,
			  onUnChecked = function()
				  airhorn_button_SFX = false
			  end,
            })
			RageUI.List('Activity Reminder', {"Off", "1/2", "1", "2", "5", "10"}, activity_reminder_index, ("Receive reminder tone that your lights are on. Options are in minutes. Timer (sec): %1.0f"):format((last_activity_timer / 1000) or 0), {}, true, {
			  onListChange = function(Index, Item)
				activity_reminder_index = Index
				SetActivityTimer()
			  end,
			})			
			RageUI.Slider('On Volume', (on_volume*100), 100, 2, "Set volume of light slider / button. Plays when lights are turned ~g~on~s~. Press Enter to play the sound.", true, {MuteOnSelected = true}, true, {
			  onSliderChange = function(Index)
				on_volume = (Index / 100)
			  end,
			  onSelected = function(Index, Item)
				TriggerEvent("audio", "On", on_volume)
			  end,
			})			
			RageUI.Slider('Off Volume', (off_volume*100), 100, 2, "Set volume of light slider / button. Plays when lights are turned ~r~off~s~. Press Enter to play the sound.", true, {MuteOnSelected = true}, true, {
			  onSliderChange = function(Index)
				off_volume = (Index/100)
			  end,
			  onSelected = function(Index, Item)
				TriggerEvent("audio", "Off", off_volume)
			  end,
			})			
			RageUI.Slider('Upgrade Volume', (upgrade_volume*100), 100, 2, "Set volume of siren button. Plays when siren is turned ~g~on~s~. Press Enter to play the sound.", true, {MuteOnSelected = true}, true, {
			  onSliderChange = function(Index)
				upgrade_volume = (Index/100)
			  end,
			  onSelected = function(Index, Item)
				TriggerEvent("audio", "Upgrade", upgrade_volume)
			  end,			  
			})			
			RageUI.Slider('Downgrade Volume', (downgrade_volume*100), 100, 2, "Set volume of siren button. Plays when siren is turned ~r~off~s~. Press Enter to play the sound.", true, {MuteOnSelected = true}, true, {
			  onSliderChange = function(Index)
				downgrade_volume = (Index/100)
			  end,
			  onSelected = function(Index, Item)
				TriggerEvent("audio", "Downgrade", downgrade_volume)
			  end,			  
			})	
			RageUI.Slider('Activity Reminder Volume', (activity_reminder_volume*500), 100, 2, "Set volume of activity reminder tone. Plays when lights are ~g~on~s~, siren is ~r~off~s~, and timer is has finished. Press Enter to play the sound.", true, {MuteOnSelected = true}, true, {
			  onSliderChange = function(Index)
				activity_reminder_volume = (Index/500)
			  end,
			  onSelected = function(Index, Item)
				TriggerEvent("audio", "Reminder", activity_reminder_volume)
			  end,			  
			})				
			RageUI.Slider('Hazards Volume', (hazards_volume*100), 100, 2, "Set volume of hazards button. Plays when hazards are toggled. Press Enter to play the sound.", true, {MuteOnSelected = true}, true, {
			  onSliderChange = function(Index)
				hazards_volume = (Index/100)
			  end,
			  onSelected = function(Index, Item)
				if hazard_state then
					TriggerEvent("audio", "Hazards_On", hazards_volume, true)
				else
					TriggerEvent("audio", "Hazards_Off", hazards_volume, true)
				end
				hazard_state = not hazard_state
			  end,			  
			})
			RageUI.Slider('Lock Volume', (lock_volume*100), 100, 2, "Set volume of lock notification sound. Plays when siren box lockout is toggled. Press Enter to play the sound.", true, {}, true, {
			  onSliderChange = function(Index)
				lock_volume = (Index/100)			
			  end,
			  onSelected = function(Index, Item)
				TriggerEvent("audio", "Key_Lock", lock_volume, true)
			  end,			  
			})					
			RageUI.Slider('Lock Reminder Volume', (lock_reminder_volume*100), 100, 2, "Set volume of lock reminder sound. Plays when locked out keys are pressed repeatedly. Press Enter to play the sound.", true, {}, true, {
			  onSliderChange = function(Index)
				lock_reminder_volume = (Index/100)
			  end,
			  onSelected = function(Index, Item)
				TriggerEvent("audio", "Locked_Press", lock_reminder_volume, true)
			  end,			  
			})
        end)
		---------------------------------------------------------------------
		----------------------------SAVE LOAD MENU---------------------------
		---------------------------------------------------------------------
	    RageUI.IsVisible(RMenu:Get('lvc', 'saveload'), function()
			RageUI.Button('Save Settings', confirm_s_desc or "Save LVC settings." .. sl_btn_debug_msg, {RightLabel = confirm_s_msg or "(".. UTIL:GetVehicleProfileName() .. ")", RightLabelOpacity = profile_s_op}, true, {
				onSelected = function()
					if confirm_s_msg == "Are you sure?" then
						Storage:SaveSettings()
						HUD:ShowNotification("~g~Success~s~: Your settings have been saved.", true)
						confirm_s_msg = nil
						confirm_s_desc = nil
						profile_s_op = 75
					else 
						RageUI.Settings.Controls.Back.Enabled = false 
						profile_s_op = 255
						confirm_s_msg = "Are you sure?" 
						confirm_s_desc = "~r~This will override any existing save data for this vehicle profile ("..UTIL:GetVehicleProfileName()..")."
						confirm_l_msg = nil
						profile_l_op = 75
						confirm_r_msg = nil
						confirm_fr_msg = nil
					end
				end,
			})			
			RageUI.Button('Load Settings', confirm_l_desc or "Load LVC settings." .. sl_btn_debug_msg, {RightLabel = confirm_l_msg or "(".. UTIL:GetVehicleProfileName() .. ")", RightLabelOpacity = profile_l_op}, true, {
			  onSelected = function()
				if confirm_l_msg == "Are you sure?" then
					Storage:LoadSettings()
					TonesTable = UTIL:GetApprovedTonesTableNameAndID()
					HUD:ShowNotification("~g~Success~s~: Your settings have been loaded.", true)
					confirm_l_msg = nil
					confirm_l_desc = nil
					profile_l_op = 75
				else 
					RageUI.Settings.Controls.Back.Enabled = false 
					profile_l_op = 255
					confirm_l_msg = "Are you sure?" 
					confirm_l_desc = "~r~This will override any unsaved settings."
					confirm_s_msg = nil
					profile_s_op = 75
					confirm_r_msg = nil
					confirm_fr_msg = nil
				end
			  end,
			})
			RageUI.Separator("Advanced Settings")
			RageUI.Button('Copy Settings', "Copy profile settings from another vehicle.", {RightLabel = "→→→"}, #profiles > 0, {
			}, RMenu:Get('lvc', 'copyprofile'))
			RageUI.Button('Reset Settings', "~r~Reset LVC to it's default state, preserves existing saves. Will override any unsaved settings.", {RightLabel = confirm_r_msg}, true, {
			  onSelected = function()
				if confirm_r_msg == "Are you sure?" then
					Storage:ResetSettings()
					HUD:ShowNotification("~g~Success~s~: Settings have been reset.", true)
					confirm_r_msg = nil
				else 
					RageUI.Settings.Controls.Back.Enabled = false 
					confirm_r_msg = "Are you sure?" 
					confirm_l_msg = nil
					profile_l_op = 75
					confirm_s_msg = nil
					profile_s_op = 75
					confirm_fr_msg = nil
				end
			  end,
			})			
			RageUI.Button('Factory Reset', "~r~Permanently delete any saves, resetting LVC to its default state.", {RightLabel = confirm_fr_msg}, true, {
			  onSelected = function()
				if confirm_fr_msg == "Are you sure?" then
					RageUI.CloseAll()
					Citizen.Wait(100)
					ExecuteCommand('lvcfactoryreset')
					confirm_fr_msg = nil
				else 
					RageUI.Settings.Controls.Back.Enabled = false 
					confirm_fr_msg = "Are you sure?" 
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
				if profile_name ~= UTIL:GetVehicleProfileName() then
					profile_c_op[i] = profile_c_op[i] or 75
					RageUI.Button(profile_name, confirm_c_desc[i] or "Attempt to load settings from profile \"~b~"..profile_name.."~s~\".", {RightLabel = confirm_c_msg[i] or "Load", RightLabelOpacity = profile_c_op[i]}, true, {
					  onSelected = function()
						if confirm_c_msg[i] == "Are you sure?" then
							Storage:LoadSettings(profile_name)
							TonesTable = UTIL:GetApprovedTonesTableNameAndID()
							HUD:ShowNotification("~g~Success~s~: Your settings have been loaded.", true)
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
							confirm_c_msg[i] = "Are you sure?" 
							confirm_c_desc[i] = "~r~This will override any unsaved settings."
						end
					  end,
					})
				end
			end
		end)	
		---------------------------------------------------------------------
		------------------------------ABOUT MENU-----------------------------
		---------------------------------------------------------------------
	    RageUI.IsVisible(RMenu:Get('lvc', 'about'), function()
			local curr_version = Storage:GetCurrentVersion()
			local repo_version = Storage:GetRepoVersion()
			if curr_version ~= nil then
				if Storage:GetIsNewerVersion() == 'older' then
					RageUI.Button('Current Version', "This server is running " .. curr_version ..", an old version.", { RightLabel = "~o~~h~" .. curr_version or "unknown" }, true, {
					  onSelected = function()
					  end,
					  });	
					RageUI.Button('Latest Version', "The latest update is " .. repo_version .. ".", {RightLabel = repo_version or "unknown"}, true, {
						onSelected = function()
					end,
					});
				elseif Storage:GetIsNewerVersion() == 'equal' then
					RageUI.Button('Current Version', "This server is running " .. curr_version .. ", the latest version.", { RightLabel = curr_version or "unknown" }, true, {
					  onSelected = function()
					  end,
					  });			
				elseif Storage:GetIsNewerVersion() == 'newer' then
					RageUI.Button('Current Version', "This server is running " .. curr_version .. ", an ~y~experimental~s~ version.", { RightLabel = curr_version or "unknown" }, true, {
					  onSelected = function()
					  end,
					  });					
				end
			end
			RageUI.Button('About / Credits', "Originally designed and created by ~b~Lt. Caine~s~. ELS SoundFX by ~b~Faction~s~. Version 3 expansion by ~b~Trevor Barns~s~.\n\nSpecial thanks to Lt. Cornelius, bakerxgooty, MrLucky8, xotikorukx, the RageUI team, and everyone else who helped beta test, this would not have been possible without you all!", {}, true, {
				onSelected = function()
			end,
			});
			  
        end)
        Citizen.Wait(0)
	end
end)