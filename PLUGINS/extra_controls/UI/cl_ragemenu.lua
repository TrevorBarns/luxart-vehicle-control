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

RMenu.Add('lvc', 'extracontrols', RageUI.CreateSubMenu(RMenu:Get('lvc', 'plugins'),'Luxart Vehicle Control', 'Extra Controls Settings'))
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
	CreateThread(function()
		Wait(500)
		if player_is_emerg_driver and veh ~= nil then
			if #EC.table > 0 then
				for i, extra_shortcut in ipairs(EC.table) do
					RMenu.Add('lvc', 'extracontrols_'..i, RageUI.CreateSubMenu(RMenu:Get('lvc', 'extracontrols'),'Luxart Vehicle Control', extra_shortcut.Name))
					RMenu:Get('lvc', 'extracontrols_'..i):DisplayGlare(false)
				end
			end
		end
	end)
end)

--Handle user input to cancel confirmation message for SAVE/LOAD
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
					confirm_d_msg = nil
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

CreateThread(function()
	Wait(1000)
	local choice
	local shortcut_prefix
	if allow_custom_controls then
		shortcut_prefix = "Change"
	else
		shortcut_prefix = "View"
	end
	
    while true do
			RageUI.IsVisible(RMenu:Get('lvc', 'extracontrols'), function()
				RageUI.Checkbox('Enabled', 'Toggle extra controls functionality.', EC.controls_enabled, {}, {
				onChecked = function()
					EC.controls_enabled = true
				end,          
				onUnChecked = function()
					EC.controls_enabled = false
				end
				})
				
					RageUI.Separator('Shortcuts')
					if #EC.table > 0 then
						for i, extra_shortcut in ipairs(EC.table) do
							RageUI.Button(extra_shortcut.Name, shortcut_prefix..' shortcut settings.', {RightLabel = '→→→'}, true, {
							  onSelected = function()
							  end,
							}, RMenu:Get('lvc', 'extracontrols'..'_'..i))					
						end
					if allow_custom_controls then
						RageUI.Separator('Storage Management')
						RageUI.Button('Save Profile Controls', confirm_s_desc or 'Store new controls to client-side storage (KVP).', {RightLabel = confirm_s_msg or '('.. EC.profile .. ')', RightLabelOpacity = profile_s_op}, true, {
						  onSelected = function()
							if confirm_s_msg == 'Are you sure?' then
								EC:SaveSettings()
								HUD:ShowNotification('~g~Success~s~: Your settings have been saved.', true)
								confirm_s_msg = nil
								confirm_s_desc = nil
								profile_s_op = 75
							else 
								RageUI.Settings.Controls.Back.Enabled = false 
								profile_s_op = 255
								confirm_s_msg = 'Are you sure?' 
								confirm_s_desc = '~r~This will override any existing extra controls data for this vehicle profile ('..EC.profile..').'
								confirm_l_msg = nil
								profile_l_op = 75
								confirm_r_msg = nil
								confirm_d_msg = nil
							end
						  end,
						})								
						RageUI.Button('Load Profile Controls', confirm_l_desc or 'Load saved controls from client-side storage (KVP).', {RightLabel = confirm_l_msg or '('.. EC.profile .. ')', RightLabelOpacity = profile_l_op}, true, {
						  onSelected = function()
							if confirm_l_msg == 'Are you sure?' then
								EC:LoadSettings()
								HUD:ShowNotification('~g~Success~s~: Your settings have been loaded.', true)
								confirm_l_msg = nil
								confirm_l_desc = nil
								profile_l_op = 75
							else 
								RageUI.Settings.Controls.Back.Enabled = false 
								profile_l_op = 255
								confirm_l_msg = 'Are you sure?' 
								confirm_l_desc = '~r~This will override any unsaved settings.'
								confirm_s_msg = nil
								profile_s_op = 75
								confirm_r_msg = nil
								confirm_d_msg = nil
							end						  
						  end,
						})			
						RageUI.Button('Reset Profile Controls', '~r~Reset this profiles controls to default, preserves existing saves. Will override any unsaved settings.', {RightLabel = confirm_r_msg}, true, {
						  onSelected = function()
							if confirm_r_msg == 'Are you sure?' then
								EC:LoadBackupTable()
								HUD:ShowNotification('~g~Success~s~: Settings have been reset.', true)
								confirm_r_msg = nil
							else 
								RageUI.Settings.Controls.Back.Enabled = false 
								confirm_r_msg = 'Are you sure?' 
								confirm_l_msg = nil
								profile_l_op = 75
								confirm_s_msg = nil
								profile_s_op = 75
								confirm_d_msg = nil
							end
						  end,
						})						
						RageUI.Button('Delete All Profile Controls', '~r~Delete all Extra Controls saved data from client-side storage (KVP).', {RightLabel = confirm_d_msg}, true, {
						  onSelected = function()
							if confirm_d_msg == 'Are you sure?' then
								EC:DeleteProfiles()
								UTIL:Print('Success: cleared all extra controls data.', true)
								HUD:ShowNotification('~g~Success~s~: You have deleted all extra controls data and reset the plugin.', true)
								confirm_d_msg = nil
							else 
								RageUI.Settings.Controls.Back.Enabled = false 
								confirm_d_msg = 'Are you sure?' 
								confirm_l_msg = nil
								profile_l_op = 75
								confirm_s_msg = nil
								profile_s_op = 75
								confirm_r_msg = nil
							end
						  end,
						})	
					end
				else
					RageUI.Button('(None)', 'No shortcuts found.', {RightLabel = '→→→'}, false, {
					  onSelected = function()
					  end,
					})					
				end
			end)
			if allow_custom_controls then
				for i, extra_shortcut in ipairs(EC.table) do
					RageUI.IsVisible(RMenu:Get('lvc', 'extracontrols_'..i), function()
						--DisableControls()
						RageUI.List('Combo', EC.approved_combo_strings, EC.combo_id[i], 'Control that needs to be pressed in addition to key to toggle extras. ~m~Format: (KEYBOARD | CONTROLLER)', {}, EC.combo_id[i] ~= nil, {
						  onListChange = function(Index, Item)
							EC.combo_id[i] = Index
								extra_shortcut.Combo = CONTROLS.COMBOS[Index]
						  end,
						})					
						RageUI.List('Key', EC.approved_key_strings, EC.key_id[i], 'Control that needs to be pressed in addition to combo-key to toggle extras. ~m~Format: (KEYBOARD | CONTROLLER)', {}, true, {
						  onListChange = function(Index, Item)
							EC.key_id[i] = Index
								extra_shortcut.Key = CONTROLS.KEYS[Index]
						  end,
						})	
					end)
				end
			else
				for i, extra_shortcut in ipairs(EC.table) do
					RageUI.IsVisible(RMenu:Get('lvc', 'extracontrols_'..i), function()
						RageUI.Button('Combo', 'Control that needs to be pressed in addition to key to toggle extras. ~m~Format: (KEYBOARD | CONTROLLER)', {RightLabel = EC.approved_combo_strings[EC.combo_id[i]]}, true, {})							
						RageUI.Button('Key', 'Control that needs to be pressed in addition to key to toggle extras. ~m~Format: (KEYBOARD | CONTROLLER)', {RightLabel = EC.approved_key_strings[EC.key_id[i]]}, true, {})	
					end)
				end
			end

        Wait(0)
	end
end)


	

