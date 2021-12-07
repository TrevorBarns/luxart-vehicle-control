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

RMenu.Add('lvc', 'extracontrols', RageUI.CreateSubMenu(RMenu:Get('lvc', 'plugins'),"Luxart Vehicle Control", "Extra Controls Settings"))
RMenu:Get('lvc', 'extracontrols'):DisplayGlare(false)
RMenu:Get('lvc', 'extracontrols'):SetTotalItemsPerPage(13)

--RageUI Confirm UI elements
local confirm_d_msg
local confirm_s_msg
local confirm_l_msg
local confirm_s_desc
local confirm_l_desc
local profile_s_op = 75
local profile_l_op = 75

--Create Menus
RegisterNetEvent('lvc:onVehicleChange')
AddEventHandler('lvc:onVehicleChange', function()
	Citizen.CreateThread(function()
		Citizen.Wait(500)
		if player_is_emerg_driver and veh ~= nil then
			if #EC.table > 0 then
				for i, extra_shortcut in ipairs(EC.table) do
					RMenu.Add('lvc', 'extracontrols'..'_'..i, RageUI.CreateSubMenu(RMenu:Get('lvc', 'extracontrols'),"Luxart Vehicle Control", extra_shortcut.Name))
					RMenu:Get('lvc', 'extracontrols'..'_'..i):DisplayGlare(false)
				end
			end
		end
	end)
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
					confirm_d_msg = nil
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

Citizen.CreateThread(function()
	Citizen.Wait(1000)
	local choice
    while true do
			RageUI.IsVisible(RMenu:Get('lvc', 'extracontrols'), function()
				RageUI.Checkbox('Enabled', "Toggle extra controls functionality.", EC.controls_enabled, {}, {
				onChecked = function()
					EC.controls_enabled = true
				end,          
				onUnChecked = function()
					EC.controls_enabled = false
				end
				})
				
				if allow_custom_controls then
					RageUI.Separator("Shortcuts")
					
					if #EC.table > 0 then
						for i, extra_shortcut in ipairs(EC.table) do
							RageUI.Button(extra_shortcut.Name, "Change shortcut's settings.", {RightLabel = "→→→"}, true, {
							  onSelected = function()
							  end,
							}, RMenu:Get('lvc', 'extracontrols'..'_'..i))					
						end
						RageUI.Separator("Storage Management")
						RageUI.Button("Save Profile Controls", confirm_s_desc or "Store new controls to client-side storage (KVP).", {RightLabel = confirm_s_msg or "(".. EC.profile_name .. ")", RightLabelOpacity = profile_s_op}, true, {
						  onSelected = function()
							if confirm_s_msg == "Are you sure?" then
								EC:SaveSettings()
								HUD:ShowNotification("~g~Success~s~: Your settings have been saved.", true)
								confirm_s_msg = nil
								confirm_s_desc = nil
								profile_s_op = 75
							else 
								RageUI.Settings.Controls.Back.Enabled = false 
								profile_s_op = 255
								confirm_s_msg = "Are you sure?" 
								confirm_s_desc = "~r~This will override any existing extra controls data for this vehicle profile ("..EC.profile_name..")."
								confirm_l_msg = nil
								profile_l_op = 75
								confirm_r_msg = nil
								confirm_d_msg = nil
							end
						  end,
						})								
						RageUI.Button("Load Profile Controls", confirm_l_desc or "Load saved controls from client-side storage (KVP).", {RightLabel = confirm_l_msg or "(".. EC.profile_name .. ")", RightLabelOpacity = profile_l_op}, true, {
						  onSelected = function()
							if confirm_l_msg == "Are you sure?" then
								EC:LoadSettings()
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
								confirm_d_msg = nil
							end						  
						  end,
						})			
						RageUI.Button("Reset Profile Controls", "~r~Reset this profiles controls to default, preserves existing saves. Will override any unsaved settings.", {RightLabel = confirm_r_msg}, true, {
						  onSelected = function()
							if confirm_r_msg == "Are you sure?" then
								EC:LoadBackupTable()
								HUD:ShowNotification("~g~Success~s~: Settings have been reset.", true)
								confirm_r_msg = nil
							else 
								RageUI.Settings.Controls.Back.Enabled = false 
								confirm_r_msg = "Are you sure?" 
								confirm_l_msg = nil
								profile_l_op = 75
								confirm_s_msg = nil
								profile_s_op = 75
								confirm_d_msg = nil
							end
						  end,
						})						
						RageUI.Button("Delete All Profile Controls", "~r~Delete all Extra Controls saved data from client-side storage (KVP).", {RightLabel = confirm_d_msg}, true, {
						  onSelected = function()
							if confirm_d_msg == "Are you sure?" then
								EC:DeleteProfiles()
								UTIL:Print("Success: cleared all extra controls data.", true)
								HUD:ShowNotification("~g~Success~s~: You have deleted all extra controls data and reset extra controls plugin.", true)
								confirm_d_msg = nil
							else 
								RageUI.Settings.Controls.Back.Enabled = false 
								confirm_d_msg = "Are you sure?" 
								confirm_l_msg = nil
								profile_l_op = 75
								confirm_s_msg = nil
								profile_s_op = 75
								confirm_r_msg = nil
							end
						  end,
						})	
					else
						RageUI.Button("(None)", "No shortcuts found.", {RightLabel = "→→→"}, false, {
						  onSelected = function()
						  end,
						})					
					end
				end
			end)
			if allow_custom_controls then
				for i, extra_shortcut in ipairs(EC.table) do
					RageUI.IsVisible(RMenu:Get('lvc', 'extracontrols'..'_'..i), function()
						RageUI.List('Combo', EC.approved_combo_strings, EC.combo_id[i], "Key that needs to be pressed in addition to 'Key' to toggle extras. ~m~Format: (KEYBOARD | CONTROLLER)", {}, true, {
						  onListChange = function(Index, Item)
							EC.combo_id[i] = Index
							if Index > 1 then
								extra_shortcut.Combo = CONTROLS.COMBOS[Index]
							else
								extra_shortcut.Combo = false
							end
						  end,
						})					
						RageUI.List('Key', EC.approved_key_strings, EC.key_id[i], "Key that needs to be pressed in addition to 'Combo' to toggle extras.", {}, true, {
						  onListChange = function(Index, Item)
							EC.key_id[i] = Index
							if Index > 1 then
								extra_shortcut.Key = CONTROLS.KEYS[Index]
							else
								extra_shortcut.Key = false
							end
						  end,
						})	
					end)
				end
			end

        Citizen.Wait(0)
	end
end)


	

