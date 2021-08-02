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

--Create Menus
RegisterNetEvent('lvc:onVehicleChange')
AddEventHandler('lvc:onVehicleChange', function()
	Citizen.CreateThread(function()
		Citizen.Wait(500)
		if player_is_emerg_driver and veh ~= nil then
			if #EC.extras > 0 then
				for i, extra_shortcut in ipairs(EC.extras) do
					RMenu.Add('lvc', 'extracontrols'..'_'..i, RageUI.CreateSubMenu(RMenu:Get('lvc', 'extracontrols'),"Luxart Vehicle Control", extra_shortcut.Name))
					RMenu:Get('lvc', 'extracontrols'..'_'..i):DisplayGlare(false)
				end
			end
		end
	end)
end)


Citizen.CreateThread(function()
    while true do
		RageUI.IsVisible(RMenu:Get('lvc', 'extracontrols'), function()
			RageUI.Checkbox('Enabled', "Toggle extra controls functionality.", ec_controls_active, {}, {
            onChecked = function()
				ec_controls_active = true
            end,          
			onUnChecked = function()
				ec_controls_active = false
            end
            })
			
			if allow_custom_controls then
				RageUI.Separator("Shortcuts")
				
				if #EC.extras > 0 then
					for i, extra_shortcut in ipairs(EC.extras) do
						RageUI.Button(extra_shortcut.Name, "Change shortcut's settings.", {RightLabel = "→→→"}, true, {
						  onSelected = function()
						  end,
						}, RMenu:Get('lvc', 'extracontrols'..'_'..i))					
					end
				else
					RageUI.Button("(None)", "No shortcuts found.", {RightLabel = "→→→"}, false, {
					  onSelected = function()
					  end,
					})					
				end
			end
        end)
		
		if allow_custom_controls then
			for i, extra_shortcut in ipairs(EC.extras) do
				RageUI.IsVisible(RMenu:Get('lvc', 'extracontrols'..'_'..i), function()
					RageUI.List('Combo', approved_combo_strings, combo_id, "Key that needs to be pressed in addition to 'Key' to toggle extras.", {}, true, {
					  onListChange = function(Index, Item)
						combo_id = Index
						if Index > 1 then
							extra_shortcut.Combo = CONTROLS.COMBOS[Index-1]
						else
							extra_shortcut.Combo = false
						end
					  end,
					})					
					RageUI.List('Key', approved_key_strings, key_id, "Key that needs to be pressed in addition to 'Combo' to toggle extras.", {}, true, {
					  onListChange = function(Index, Item)
						key_id = Index
						if Index > 1 then
							extra_shortcut.Key = CONTROLS.KEYS[Index-1]
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


	

