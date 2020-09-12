--[[
---------------------------------------------------
LUXART VEHICLE CONTROL (FOR FIVEM)
---------------------------------------------------
Last revision: AUGUST 27, 2020  (VERS.3.04)
Coded by Lt.Caine
ELS Clicks by Faction
Additions by TrevorBarns
---------------------------------------------------
FILE: menu.lua
PURPOSE: Handle RageUI menu stuff
---------------------------------------------------
]]

RMenu.Add('lvc', 'main', RageUI.CreateMenu("Luxart Vehicle Control", "Main Menu"))
RMenu.Add('lvc', 'saveload', RageUI.CreateSubMenu(RMenu:Get('lvc', 'main'),"Luxart Vehicle Control", "Storage Management"))
RMenu.Add('lvc', 'maintone', RageUI.CreateSubMenu(RMenu:Get('lvc', 'main'),"Luxart Vehicle Control", "Main Tone Selection Menu"))
RMenu.Add('lvc', 'hudsettings', RageUI.CreateSubMenu(RMenu:Get('lvc', 'main'),"Luxart Vehicle Control", "HUD Settings"))
RMenu.Add('lvc', 'audiosettings', RageUI.CreateSubMenu(RMenu:Get('lvc', 'main'),"Luxart Vehicle Control", "Audio Settings"))
RMenu.Add('lvc', 'about', RageUI.CreateSubMenu(RMenu:Get('lvc', 'main'),"Luxart Vehicle Control", "About Luxart Vehicle Control"))
RMenu:Get('lvc', 'main'):SetTotalItemsPerPage(12)
RMenu:Get('lvc', 'main'):DisplayGlare(false)
RMenu:Get('lvc', 'saveload'):DisplayGlare(false)
RMenu:Get('lvc', 'maintone'):DisplayGlare(false)
RMenu:Get('lvc', 'hudsettings'):DisplayGlare(false)
RMenu:Get('lvc', 'audiosettings'):DisplayGlare(false)
RMenu:Get('lvc', 'about'):DisplayGlare(false)

main_tone_settings = nil
main_tone_choices = { 'Cycle & Button', 'Cycle Only', 'Button Only', 'Disabled' } 
settings_init = false

--Strings for Save/Load confirmation, not ideal but it works. 
local ok_to_disable  = true
local confirm_s_msg
local confirm_l_msg
local confirm_fr_msg
local confirm_s_desc
local confirm_l_desc
local confirm_fr_desc
local profile_s_op = 75
local profile_l_op = 75
local github_index = 1
local hazard_state = false
local button_sfx_scheme_id = 1


Keys.Register(open_menu_key, open_menu_key, 'LVC: Open Menu', function()
	if not key_lock and player_is_emerg_driver and UpdateOnscreenKeyboard() ~= 0 then
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
		RageUI.Visible(RMenu:Get('lvc', 'main'), not RageUI.Visible(RMenu:Get('lvc', 'main')))
	end
end)

--Returns table of all approved tones
function GetApprovedTonesList()
	local list = { } 
	local pending_tone = 0
	for i, _ in ipairs(tone_table) do
		if i ~= 1 then
			pending_tone = GetTone(veh,i)
			if IsApprovedTone(veh, pending_tone) and i <= GetToneCount(veh) then
				table.insert(list, { Name = tone_table[pending_tone], Value = pending_tone })
			end
		end
	end
	return list
end

--Returns table of all tones with settings value
function GetTonesList()
	local list = { } 
	for index, _ in ipairs(tone_table) do
		if index ~= 1 and IsApprovedTone(veh, index) then
			table.insert(list, {index,1})
		end
	end	
	return list
end

--Find index at which a given siren tone is at.
function GetToneIndex(tone_id)
	for i, tone in ipairs(tone_list) do
		if tone_id == tone.Value then
			return i
		end
	end
end

--Find index at which a given siren tone is at.
function GetIndex(item, tbl)
	for i, j in ipairs(tbl) do
		if item == j then
			return i
		end
	end
end

--Returns true if any menu is open
function IsMenuOpen()
	return RageUI.Visible(RMenu:Get('lvc', 'main')) or 
	RageUI.Visible(RMenu:Get('lvc', 'maintone')) or 
	RageUI.Visible(RMenu:Get('lvc', 'hudsettings')) or 
	RageUI.Visible(RMenu:Get('lvc', 'audiosettings')) or 
	RageUI.Visible(RMenu:Get('lvc', 'about'))
end

--Ensure not all sirens are disabled
function SetCheckVariable() 
	ok_to_disable = false
	local count = 0
	for i, siren in ipairs(main_tone_settings) do
		if siren[2] < 4 then
			count = count + 1
		end
	end
	if count > 1 then
		ok_to_disable = true
	end
end


--Loads settings and builds first table states, also updates tone_list every second for vehicle changes
Citizen.CreateThread(function()
    while true do
		if not settings_init and player_is_emerg_driver then
			main_tone_settings = GetTonesList()
			settings_init = true
		end

		tone_list = GetApprovedTonesList()
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
					profile_s_op = 50
					confirm_l_msg = nil
					confirm_l_desc = nil
					profile_l_opprofile_l_op = 50
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
		--Main Menu Visible
	    RageUI.IsVisible(RMenu:Get('lvc', 'main'), function()
			RageUI.Button('Storage Management', "Save / Load LVC profiles.", {RightLabel = "→→→"}, true, {
			  onSelected = function()

			  end,
			}, RMenu:Get('lvc', 'saveload'))
			RageUI.Separator("Siren Settings")
			RageUI.Button('Main Siren Settings', "Change which/how each available primary tone is used.", {RightLabel = "→→→"}, true, {
			  onSelected = function()

			  end,
			}, RMenu:Get('lvc', 'maintone'))
			if custom_manual_tones_master_switch then
				--PMT List
				RageUI.List('Primary Manual Tone', tone_list, GetToneIndex(tone_PMANU_id), "Change your primary manual tone. Key: R", {}, true, {
				  onListChange = function(Index, Item)
					tone_PMANU_id = Item.Value;
					
				  end,
				})
				--SMT List
				RageUI.List('Secondary Manual Tone', tone_list, GetToneIndex(tone_SMANU_id), "Change your secondary manual tone. Key: E+R", {}, true, {
				  onListChange = function(Index, Item)
					tone_SMANU_id = Item.Value;
					
				  end,
				})
			end
			if custom_aux_tones_master_switch then
				--AST List
				RageUI.List('Auxiliary Siren Tone', tone_list, GetToneIndex(tone_AUX_id), "Change your auxiliary/dual siren tone. Key: ↑", {}, true, {
				  onListChange = function(Index, Item)
					tone_AUX_id = Item.Value;
					
				  end,
				})
			end
			RageUI.Checkbox('Siren Park Kill', "Toggles whether your sirens turn off automatically when you exit your vehicle. ", park_kill, {}, {
			  onSelected = function(Index)
				  park_kill = Index
			  end
			})
			--Begin HUD Settings
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
			RageUI.Button('More Information', "Learn more about Luxart Vehicle Control.", {RightLabel = "→→→"}, true, {
			  onSelected = function()

			  end,
			}, RMenu:Get('lvc', 'about'))
        end)
		---------------------------------------------------------------------
		----------------------------SAVE LOAD MENU---------------------------
		---------------------------------------------------------------------
	    RageUI.IsVisible(RMenu:Get('lvc', 'saveload'), function()
			RageUI.Button('Save Settings', confirm_s_desc or "Save LVC settings.", {RightLabel = confirm_s_msg or "(".. GetVehicleProfileName() .. ")", RightLabelOpacity = profile_s_op or 255}, true, {
				onSelected = function()
					if confirm_s_msg == "Are you sure?" then
						RageUI.Settings.Controls.Back.Enabled = true
						SaveSettings()
						confirm_s_msg = nil
						confirm_s_desc = nil
						profile_s_op = 75
					else 
						RageUI.Settings.Controls.Back.Enabled = false 
						profile_s_op = nil
						confirm_s_msg = "Are you sure?" 
						confirm_s_desc = "~r~This will override any exisiting save data for this vehicle profile ("..GetVehicleProfileName()..")."
						confirm_l_msg = nil
					end
				end,
			})			
			RageUI.Button('Load Settings', confirm_l_desc or "Load LVC settings. This should be done after switching vehicles.", {RightLabel = confirm_l_msg or "(".. GetVehicleProfileName() .. ")", RightLabelOpacity = profile_l_op or 255}, true, {
			  onSelected = function()
				if confirm_l_msg == "Are you sure?" then
					RageUI.Settings.Controls.Back.Enabled = true
					LoadSettings()
					confirm_l_msg = nil
					confirm_l_desc = nil
					profile_l_op = 75
				else 
					RageUI.Settings.Controls.Back.Enabled = false 
					profile_l_op = nil
					confirm_l_msg = "Are you sure?" 
					confirm_l_desc = "~r~This will override any unsaved settings."
					confirm_s_msg = nil

				end
			  end,
			})			
			RageUI.Separator("Advanced Settings")
			RageUI.Button('Factory Reset', confirm_l_desc or "~r~Delete all LVC KVP settings stored locally.", {RightLabel = confirm_fr_msg, RightLabelOpacity = 255}, true, {
			  onSelected = function()
				if confirm_fr_msg == "Are you sure?" then
					RageUI.CloseAll()
					Citizen.Wait(100)
					ExecuteCommand('lvcfactoryreset')
					RageUI.Settings.Controls.Back.Enabled = true
					confirm_fr_msg = nil
				else 
					RageUI.Settings.Controls.Back.Enabled = false 
					confirm_fr_msg = "Are you sure?" 
					confirm_l_msg = nil
					confirm_s_msg = nil
				end
			  end,
			})
        end)	
		---------------------------------------------------------------------
		----------------------------MAIN TONE MENU---------------------------
		---------------------------------------------------------------------	
	    RageUI.IsVisible(RMenu:Get('lvc', 'maintone'), function()
			RageUI.Checkbox('Airhorn Interrupt Mode', "Toggles whether the airhorn interupts main siren.", tone_airhorn_intrp, {}, {
            onSelected = function(Index)				
                tone_airhorn_intrp = Index
            end	
			})
			RageUI.Checkbox('Reset to Standby', "When enabled, the primary siren will reset to 1st siren. When disabled, the last played tone will resume.", tone_main_reset_standby, {}, {
            onSelected = function(Index)
				tone_main_reset_standby = Index
            end
            })
			for i, siren in pairs(main_tone_settings) do
				RageUI.List(tone_table[siren[1]], main_tone_choices, siren[2], "Change how is activated.\nCycle: play as you cycle through sirens using R or (B).\nButton: play when associated registered key is pressed.", {}, IsApprovedTone(veh, siren[1]), {
					onListChange = function(Index, Item)
						if Index < 3 or ok_to_disable then
							siren[2] = Index;
						else
							ShowNotification("~y~LVC Info~s~: Action prohibited, cannot disable all sirens.") 
						end
						SetCheckVariable()
					end,
				})
			end
        end)	
		---------------------------------------------------------------------
		-------------------------OTHER SETTINGS MENU-------------------------
		---------------------------------------------------------------------
	    RageUI.IsVisible(RMenu:Get('lvc', 'hudsettings'), function()
			RageUI.Checkbox('HUD Visible', "Toggles whether the LVC HUD is on screen.\nCan't see it? Ensure HUD is enabled.", show_HUD, {}, {
			  onSelected = function(Index)
				  show_HUD = Index
				  
			  end
			})
			RageUI.Button('HUD Move Mode', "Move HUD position on screen.", {}, true, {
			  onSelected = function()
					TogMoveMode()
				end,
			  });
			RageUI.Slider('HUD Background Opacity', hud_bgd_opacity, 255, 20, "Change opacity of of the HUD background rectangle.", true, {}, true, {
			  onSliderChange = function(Index)
				ShowHUD()
				--Stupid way to check if a KVP was found.
				if Index == 0 then
					Index = 1
				end
				hud_bgd_opacity = Index
			  end,
			})
			RageUI.Slider('HUD Button Opacity', hud_button_off_opacity, 255, 20, "Change opacity of inactive HUD buttons.", true, {}, true, {
			  onSliderChange = function(Index)
				ShowHUD()
				--Stupid way to check if a KVP was found.
				if Index == 0 then
					Index = 1
				end
				hud_button_off_opacity = Index 
			  end,
			})
        end)	    
		--AUDIO SETTINGS MENU
		RageUI.IsVisible(RMenu:Get('lvc', 'audiosettings'), function()
			RageUI.List("Sirenbox SFX Scheme", button_sfx_scheme_choices, button_sfx_scheme_id, "Change what SFX to use for siren box clicks.", {}, true, {
			  onListChange = function(Index, Item)
				button_sfx_scheme_id = Index
				button_sfx_scheme = button_sfx_scheme_choices[button_sfx_scheme_id]
			  end,				
			})
			RageUI.Checkbox('Manual Button Clicks', "When enabled, your manual tone button (default: R) will activate the upgrade SFX.", manu_button_SFX, {}, {
            onSelected = function(Index)
				manu_button_SFX = Index
            end
            })			
			RageUI.Checkbox('Airhorn Button Clicks', "When enabled, your airhorn button (default: E) will activate the upgrade SFX.", airhorn_button_SFX, {}, {
            onSelected = function(Index)
				airhorn_button_SFX = Index
            end
            })
			RageUI.Slider('On Volume', (on_volume*100), 100, 2, "Set volume of light slider / button. Plays when lights are turned ~g~on~s~. Press Enter to play the sound.", true, {}, true, {
			  onSliderChange = function(Index)
				on_volume = (Index / 100)
			  end,
			  onSelected = function(Index, Item)
				TriggerEvent("lux_vehcontrol:ELSClick", button_sfx_scheme .. "/" .. "On", on_volume)
			  end,
			})			
			RageUI.Slider('Off Volume', (off_volume*100), 100, 2, "Set volume of light slider / button. Plays when lights are turned ~r~off~s~. Press Enter to play the sound.", true, {}, true, {
			  onSliderChange = function(Index)
				off_volume = (Index/100)
			  end,
			  onSelected = function(Index, Item)
				TriggerEvent("lux_vehcontrol:ELSClick", button_sfx_scheme .. "/" .. "Off", off_volume)
			  end,
			})			
			RageUI.Slider('Upgrade Volume', (upgrade_volume*100), 100, 2, "Set volume of siren button. Plays when siren is turned ~g~on~s~. Press Enter to play the sound.", true, {}, true, {
			  onSliderChange = function(Index)
				upgrade_volume = (Index/100)
			  end,
			  onSelected = function(Index, Item)
				TriggerEvent("lux_vehcontrol:ELSClick", button_sfx_scheme .. "/" .. "Upgrade", upgrade_volume)
			  end,			  
			})			
			RageUI.Slider('Downgrade Volume', (downgrade_volume*100), 100, 2, "Set volume of siren button. Plays when siren is turned ~r~off~s~. Press Enter to play the sound.", true, {}, true, {
			  onSliderChange = function(Index)
				downgrade_volume = (Index/100)
			  end,
			  onSelected = function(Index, Item)
				TriggerEvent("lux_vehcontrol:ELSClick", button_sfx_scheme .. "/" .. "Downgrade", downgrade_volume)
			  end,			  
			})					
			RageUI.Slider('Lock Volume', (lock_volume*100), 100, 2, "Set volume of lock notification sound. Plays when siren box lockout is toggled. Press Enter to play the sound.", true, {}, true, {
			  onSliderChange = function(Index)
				lock_volume = (Index/100)			
			  end,
			  onSelected = function(Index, Item)
				TriggerEvent("lux_vehcontrol:ELSClick", "Key_Lock", lock_volume)
			  end,			  
			})					
			RageUI.Slider('Lock Reminder Volume', (lock_volume*100), 100, 2, "Set volume of lock reminder sound. Plays when locked out keys are pressed repeatedly. Press Enter to play the sound.", true, {}, true, {
			  onSliderChange = function(Index)
				lock_volume = (Index/100)
			  end,
			  onSelected = function(Index, Item)
				TriggerEvent("lux_vehcontrol:ELSClick", "Locked_Press", on_volume)
			  end,			  
			})			
			RageUI.Slider('Hazards Volume', (hazards_volume*100), 100, 2, "Set volume of hazards button. Plays when hazards are toggled. Press Enter to play the sound.", true, {}, true, {
			  onSliderChange = function(Index)
				hazards_volume = (Index/100)
			  end,
			  onSelected = function(Index, Item)
				if hazard_state then
					TriggerEvent("lux_vehcontrol:ELSClick", "Hazards_On", hazards_volume)
				else
					TriggerEvent("lux_vehcontrol:ELSClick", "Hazards_Off", hazards_volume)
				end
				hazard_state = not hazard_state
			  end,			  
			})
        end)
		
		---------------------------------------------------------------------
		------------------------------ABOUT MENU-----------------------------
		---------------------------------------------------------------------
	    RageUI.IsVisible(RMenu:Get('lvc', 'about'), function()
			if curr_version_text ~= nil then
				if curr_version ~= repo_version then
					RageUI.Button('Current Version', "This server is running " .. curr_version_text, { RightLabel = "~o~~h~" .. curr_version_text or "unknown" }, true, {
					  onSelected = function()
					  end,
					  });	
					RageUI.Button('Latest Version', "The latest update is v." .. repo_version .. ". Contact a server developer.", {RightLabel = repo_version_text or "unknown"}, true, {
						onSelected = function()
					end,
					});
				else
					RageUI.Button('Current Version', "This server is running " .. curr_version_text, { RightLabel = curr_version_text or "unknown" }, true, {
					  onSelected = function()
					  end,
					  });			
				end
			end
			RageUI.List('Launch GitHub Page', {"Main Repository", "Siren Repository", "File Bug Report"}, github_index, "View the project and more info on GitHub.", {}, true, {
			  onListChange = function(Index, Item)
				github_index = Index
			  end,
			  onSelected = function()
				if github_index == 1 then
					TriggerServerEvent('lvc_OpenLink_s', "https://github.com/TrevorBarns/luxart-vehicle-control")
				elseif github_index	== 2 then
					TriggerServerEvent('lvc_OpenLink_s', "https://github.com/TrevorBarns/luxart-vehicle-control-extras")			
				else
					TriggerServerEvent('lvc_OpenLink_s', "https://github.com/TrevorBarns/luxart-vehicle-control/issues/new")			
				end
			  end,
			})
			RageUI.Button('Developer\'s Discord', "Join my discord for support, future updates, and other resources.", {}, true, {
				onSelected = function()
				TriggerServerEvent('lvc_OpenLink_s', "https://discord.gg/HGBp3un")
			end,
			});	
			RageUI.Button('About / Credits', "Originally designed and created by ~b~Lt. Caine~s~. ELS SoundFX by ~b~Faction~s~. Version 3 expansion by ~b~Trevor Barns~s~. Special thanks to Lt. Cornelius, bakerxgooty, MrLucky8.\nThe RageUI team and ", {}, true, {
				onSelected = function()
			end,
			});
			  
        end)
        Citizen.Wait(1)
	end
end)
