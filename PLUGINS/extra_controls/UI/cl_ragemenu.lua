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

if ec_masterswitch then
	RMenu.Add('lvc', 'extracontrols', RageUI.CreateSubMenu(RMenu:Get('lvc', 'plugins'),' ', Lang:t('plugins.menu_ec'), 0, 0, "lvc", "lvc_plugin_logo"))
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

	--	Handle user input to cancel confirmation message for SAVE/LOAD
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

	local is_loop_on = false
	--[[Loop to be called when dynamically created menus are opened,
		loop continues until closed updating the EC.is_menu_open var,
		which is used in cl_plugins.lua for IsPluginsMenuOpen()]]
	local function StartIsMenuOpenLoop()
		if not is_loop_on then
			is_loop_on = true
			CreateThread(function()
				while is_loop_on do
					EC.is_menu_open = false
					for i, extra_shortcut in ipairs(EC.table) do
						if RageUI.Visible(RMenu:Get('lvc', 'extracontrols_'..i)) then
							EC.is_menu_open = true
						end
					end
					if not EC.is_menu_open then
						is_loop_on = false
					end
					Wait(1)
				end
			end) 
		end
	end

	CreateThread(function()
		Wait(1000)
		local choice
		local shortcut_prefix
		if allow_custom_controls then
			shortcut_prefix = Lang:t('plugins.ec_shortcut_prefix_change')
		else
			shortcut_prefix = Lang:t('plugins.ec_shortcut_prefix_view')
		end
		
		while true do
				RageUI.IsVisible(RMenu:Get('lvc', 'extracontrols'), function()
					RageUI.Checkbox(Lang:t('menu.enabled'), Lang:t('plugins.ec_enabled_desc'), EC.controls_enabled, {}, {
					  onChecked = function()
						EC.controls_enabled = true
					  end,          
					  onUnChecked = function()
						EC.controls_enabled = false
					  end
					})
					
					RageUI.Separator(Lang:t('plugins.ec_shortcuts_separator'))
					--	Buttons for dynamic shortcut menu
					if #EC.table > 0 then
						for i, extra_shortcut in ipairs(EC.table) do
							RageUI.Button(extra_shortcut.Name, Lang:t('plugins.ec_shortcut_desc', { prefix = shortcut_prefix }), {RightLabel = '→→→'}, true, {
							  onSelected = function()												
								StartIsMenuOpenLoop()
							  end,
							}, RMenu:Get('lvc', 'extracontrols'..'_'..i))					
						end
						if allow_custom_controls then
							RageUI.Separator(Lang:t('menu.storage'))
							RageUI.Button(Lang:t('plugins.ec_save'), confirm_s_desc or Lang:t('plugins.ec_save_desc'), {RightLabel = confirm_s_msg or '('.. EC.profile .. ')', RightLabelOpacity = profile_s_op}, true, {
							  onSelected = function()
								if confirm_s_msg == Lang:t('menu.save_override') then
									EC:SaveSettings()
									HUD:ShowNotification(Lang:t('menu.save_success'), true)
									confirm_s_msg = nil
									confirm_s_desc = nil
									profile_s_op = 75
								else 
									RageUI.Settings.Controls.Back.Enabled = false 
									profile_s_op = 255
									confirm_s_msg = Lang:t('menu.save_override')
									confirm_s_desc = Lang:t('menu.save_override_desc', { profile = EC.profile })
									confirm_l_msg = nil
									profile_l_op = 75
									confirm_r_msg = nil
									confirm_d_msg = nil
								end
							  end,
							})								
							RageUI.Button(Lang:t('plugins.ec_load'), confirm_l_desc or Lang:t('plugins.ec_load_desc'), {RightLabel = confirm_l_msg or '('.. EC.profile .. ')', RightLabelOpacity = profile_l_op}, true, {
							  onSelected = function()
								if confirm_l_msg == Lang:t('menu.save_override') then
									EC:LoadSettings()
									HUD:ShowNotification(Lang:t('menu.load_success'), true)
									confirm_l_msg = nil
									confirm_l_desc = nil
									profile_l_op = 75
								else 
									RageUI.Settings.Controls.Back.Enabled = false 
									profile_l_op = 255
									confirm_l_msg = Lang:t('menu.save_override')
									confirm_l_desc = Lang:t('menu.load_override')
									confirm_s_msg = nil
									profile_s_op = 75
									confirm_r_msg = nil
									confirm_d_msg = nil
								end						  
							  end,
							})			
							RageUI.Button(Lang:t('plugins.ec_reset'), Lang:t('plugins.ec_reset_desc'), {RightLabel = confirm_r_msg}, true, {
							  onSelected = function()
								if confirm_r_msg == Lang:t('menu.save_override') then
									EC:LoadBackupTable()
									HUD:ShowNotification(Lang:t('menu.reset_success'), true)
									confirm_r_msg = nil
								else 
									RageUI.Settings.Controls.Back.Enabled = false 
									confirm_r_msg = Lang:t('menu.save_override')
									confirm_l_msg = nil
									profile_l_op = 75
									confirm_s_msg = nil
									profile_s_op = 75
									confirm_d_msg = nil
								end
							  end,
							})						
							RageUI.Button(Lang:t('plugins.ec_factory_reset'), Lang:t('plugins.ec_factory_reset_desc'), {RightLabel = confirm_d_msg}, true, {
							  onSelected = function()
								if confirm_d_msg == Lang:t('menu.save_override') then
									EC:DeleteProfiles()
									UTIL:Print(Lang:t('plugins.ec_factory_reset_success_console'), true)
									HUD:ShowNotification(Lang:t('plugins.ec_factory_reset_success_frontend'), true)
									confirm_d_msg = nil
								else 
									RageUI.Settings.Controls.Back.Enabled = false 
									confirm_d_msg = Lang:t('menu.save_override')
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
						RageUI.Button(Lang:t('plugins.ec_no_shortcuts'), Lang:t('plugins.ec_no_shortcuts_desc'), {RightLabel = '→→→'}, false, {
						  onSelected = function()
						  end,
						})					
					end
				end)
				if allow_custom_controls then
					for i, extra_shortcut in ipairs(EC.table) do
						RageUI.IsVisible(RMenu:Get('lvc', 'extracontrols_'..i), function()
							RageUI.List(Lang:t('plugins.ec_combo'), EC.approved_combo_strings, EC.combo_id[i], Lang:t('plugins.ec_combo_desc'), {}, EC.combo_id[i] ~= nil, {
							  onListChange = function(Index, Item)
								EC.combo_id[i] = Index
								extra_shortcut.Combo = CONTROLS.COMBOS[Index]
							  end,
							})					
							RageUI.List(Lang:t('plugins.ec_key'), EC.approved_key_strings, EC.key_id[i], Lang:t('plugins.ec_key_desc'), {}, true, {
							  onListChange = function(Index, Item)
								EC.key_id[i] = Index
								extra_shortcut.Key = CONTROLS.KEYS[Index]
							  end,
							})	
							RageUI.Checkbox(Lang:t('plugins.ec_controller_support'), Lang:t('plugins.ec_controller_support_desc'), extra_shortcut.Controller_Support, { Enabled = EC.combo_id[i] == 1}, {
							  onChecked = function()
								extra_shortcut.Controller_Support = true
							  end,          
							  onUnChecked = function()
								extra_shortcut.Controller_Support = false
							  end
							})
						end)
					end
				else
					for i, extra_shortcut in ipairs(EC.table) do
						RageUI.IsVisible(RMenu:Get('lvc', 'extracontrols_'..i), function()
							RageUI.Button(Lang:t('plugins.ec_combo'), Lang:t('plugins.ec_combo_desc'), {RightLabel = EC.approved_combo_strings[EC.combo_id[i]]}, true, {})							
							RageUI.Button(Lang:t('plugins.ec_key'), Lang:t('plugins.ec_key_desc'), {RightLabel = EC.approved_key_strings[EC.key_id[i]]}, true, {})	
						end)
					end
				end

			Wait(0)
		end
	end)
end