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
RMenu.Add('lvc', 'maintone', RageUI.CreateSubMenu(RMenu:Get('lvc', 'main'),"Luxart Vehicle Control", "Main Tone Selection Menu"))
RMenu:Get('lvc', 'main'):DisplayGlare(false)
RMenu:Get('lvc', 'maintone'):DisplayGlare(false)

main_tone_settings = nil
main_tone_choices = { 'Cycle & Button', 'Cycle Only', 'Button Only', 'Disabled' } 
settings_init = false

--Strings for Save/Load confirmation, not ideal but it works. 
local confirm_save_message
local confirm_load_message
local confirm_save_description
local confirm_load_description

Keys.Register(open_menu_key, open_menu_key, 'LVC: Open Menu', function()
	if not key_lock and player_is_emerg_driver then
		confirm_save_message = nil
		confirm_load_message = nil
		confirm_save_description = nil
		confirm_load_description = nil
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
	for i, v in ipairs(tone_table) do
		if i ~= 1 then
			table.insert(list, {i,1})
		end
	end
	return list
end

--Find index at which a given siren tone is at.
function GetIndex(tone_id)
	for i, tone in ipairs(tone_list) do
		if tone_id == tone.Value then
			return i
		end
	end
end

--Returns true if any menu is open
function IsMenuOpen()
	return RageUI.Visible(RMenu:Get('lvc', 'main')) or RageUI.Visible(RMenu:Get('lvc', 'maintone'))
end

--Loads settings and builds first table states, also updates tone_list every second for vehicle changes
Citizen.CreateThread(function()
    while true do
		if not settings_init then
			main_tone_settings = GetTonesList()
			settings_init = true
		end

		tone_list = GetApprovedTonesList()
		Citizen.Wait(1000)
	end
end)

Citizen.CreateThread(function()
    while true do
		--Main Menu Visible
	    RageUI.IsVisible(RMenu:Get('lvc', 'main'), function()
			--Disable up arrow default action (next weapon) when menu is open
			DisableControlAction(0, 99, true) 
			--Main Siren Settings Button
			RageUI.Button('Save Settings', confirm_save_description or "Save LVC settings.", {RightLabel = confirm_save_message or ""}, true, {
			  onSelected = function()
				if confirm_save_message == "Are you sure?" then
					SaveSettings()
					confirm_save_message = nil
					confirm_save_description = nil
				else 
					confirm_save_message = "Are you sure?" 
					confirm_save_description = "~r~This will override any exisiting save data for this vehicle profile ("..GetVehicleProfileName()..")."
					confirm_load_message = nil
					confirm_save_description = nil
				end
			  end,
			})			
			RageUI.Button('Load Settings', confirm_load_description or "Load LVC settings. This should be done after switching vehicles.", {RightLabel = confirm_load_message or ""}, true, {
			  onSelected = function()
				if confirm_load_message == "Are you sure?" then
					LoadSettings()
					confirm_load_message = nil
					confirm_load_description = nil
				else 
					confirm_load_message = "Are you sure?" 
					confirm_load_description = "~r~This will override any unsaved settings."
					confirm_save_message = nil
					confirm_save_description = nil

				end
			  end,
			})
			RageUI.Separator("Siren Settings")
			RageUI.Button('Main Siren Settings', "Change which/how each available primary tone is used.", {RightLabel = "→→→"}, true, {
			  onSelected = function()

			  end,
			}, RMenu:Get('lvc', 'maintone'))
			--PMT List
			RageUI.List('Primary Manual Tone', tone_list, GetIndex(tone_PMANU_id), "Change your primary manual tone. Key: R", {}, true, {
			  onListChange = function(Index, Item)
				tone_PMANU_id = Item.Value;
				
			  end,
			})
			--SMT List
			RageUI.List('Secondary Manual Tone', tone_list, GetIndex(tone_SMANU_id), "Change your secondary manual tone. Key: E+R", {}, true, {
			  onListChange = function(Index, Item)
				tone_SMANU_id = Item.Value;
				
			  end,
			})
			--AST List
			RageUI.List('Auxiliary Siren Tone', tone_list, GetIndex(tone_AUX_id), "Change your auxiliary/dual siren tone. Key: ↑", {}, true, {
			  onListChange = function(Index, Item)
				tone_AUX_id = Item.Value;
				
			  end,
			})
			--Begin HUD Settings
			RageUI.Separator("HUD Settings")
			RageUI.Checkbox('HUD Visible', "Toggles whether the LVC HUD is on screen.", show_HUD, {}, {
			  onSelected = function(Index)
				  show_HUD = Index
				  
			  end
			})
			RageUI.Button('HUD Move Mode', "Move HUD position on screen.", {}, true, {
			  onSelected = function()
				RageUI.CloseAll()
				ExecuteCommand('lvchudmove')
				end,
			  });
			RageUI.Slider('HUD Background Opacity', hud_bgd_opacity, 255, 20, "Change opacity of of the HUD background rectangle.", true, {}, true, {
			  onSliderChange = function(Index)
				ShowHUD()
				hud_bgd_opacity = Index
			  end,
			})
			RageUI.Slider('HUD Button Opacity', hud_button_off_opacity, 255, 20, "Change opacity of inactive HUD buttons.", true, {}, true, {
			  onSliderChange = function(Index)
				ShowHUD()
				hud_button_off_opacity = Index 
			  end,
			})
        end)
		
	    RageUI.IsVisible(RMenu:Get('lvc', 'maintone'), function()
			--Disable up arrow default action (next weapon) when menu is open
			DisableControlAction(0, 99, true) 
			RageUI.Checkbox('Airhorn Interrupt Mode', "Toggles whether the airhorn interupts main siren.", tone_airhorn_intrp, {}, {
            onSelected = function(Index)
				
                tone_airhorn_intrp = Index
            end
            })
			for i, siren in pairs(main_tone_settings) do
				RageUI.List(tone_table[siren[1]], main_tone_choices, siren[2], "Change how is activated.\nCycle: play as you cycle through sirens using R or (B).\nButton: play when associated registered key is pressed.", {}, IsApprovedTone(veh, siren[1]), {
					onListChange = function(Index, Item)
						siren[2] = Index;
					end,
				})
			end
        end)
        Citizen.Wait(1)
	end
end)
