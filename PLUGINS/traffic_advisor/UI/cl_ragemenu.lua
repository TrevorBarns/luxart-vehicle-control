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

RMenu.Add('lvc', 'tasettings', RageUI.CreateSubMenu(RMenu:Get('lvc', 'plugins'),"Luxart Vehicle Control", "Traffic Advisor Settings"))
RMenu:Get('lvc', 'tasettings'):DisplayGlare(false)

Citizen.CreateThread(function()
    while true do
		--TKD SETTINGS
		RageUI.IsVisible(RMenu:Get('lvc', 'tasettings'), function()	
			--[[
			RageUI.List('Combo Key', {"Disabled", "LSHIFT", "LCTRL", "LALT", "LSHIFT OR (X)", "LCTRL OR (L3)"}, ta_combokey_index, "Select key that needs to be held in addition to TA Keys to activate. '~b~( )~s~' indicates controller key.", {}, true, {
			  onListChange = function(Index, Item)
				ta_combokey_index = Index
			  end,
			})	]]		
			RageUI.List('TA HUD Pattern', {"1", "2", "3", "4", "5", "6", "7"}, hud_pattern, "Change pattern displayed on HUD traffic advisor indicators.", {}, true, {
			  onListChange = function(Index, Item)
				hud_pattern = Index
				HUD:SetItemState("ta_pattern", hud_pattern)
				HUD:SetItemState("ta", state_ta[veh])
			  end,
			})
			RageUI.Checkbox('Save TA State', "Preserves traffic advisor state on lights toggling. Unchecking this will turn TA extras off when lights are turned off.", save_ta_state, {}, {
			  onChecked = function()
				save_ta_state = true
			  end,          
			  onUnChecked = function()
				save_ta_state = false
			  end
			})					
			RageUI.Checkbox('Sync TA State', "~o~Coming Soon~c ~ When able, sync TA state to nearby vehicles.", false, {Enabled = false}, {
			  onChecked = function()
				sync_ta_state = true
			  end,          
			  onUnChecked = function()
				sync_ta_state = false
			  end
			})
        end)
        Citizen.Wait(0)
	end
end)